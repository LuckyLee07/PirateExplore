// Real HttpClient lifecycle tests. Loopback fixture only; no desktop or saves.
#include "cocos2d.h"
#include "network/HttpClient.h"
#include "CCLuaEngine.h"
#include "tolua++.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <atomic>
#include <cassert>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <functional>
#include <mutex>
#include <string>
#include <thread>
#include <vector>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <poll.h>
#include <sstream>
#include <iomanip>
#include <sys/socket.h>

using namespace cocos2d;
using namespace cocos2d::network;
using Clock = std::chrono::steady_clock;
static std::atomic<int> destroyedRequests(0);
static const double shutdownBoundSeconds = 4.0;
static std::thread::id mainThread;

class TestApplication : public Application {
public:
    bool launchResult = true;
private:
    bool applicationDidFinishLaunching() override { return launchResult; }
    void applicationDidEnterBackground() override {}
    void applicationWillEnterForeground() override {}
};

// Observe the actual native dispatch queue under its existing lock. No sleeps
// are used to guess whether a worker has published its response callback.
class ObservedScheduler : public Scheduler {
public:
    size_t pending() {
        std::lock_guard<std::mutex> lock(_performMutex);
        return _functionsToPerform.size();
    }
    std::vector<std::function<void()>> takePending() {
        std::lock_guard<std::mutex> lock(_performMutex);
        std::vector<std::function<void()>> callbacks;
        callbacks.swap(_functionsToPerform);
        return callbacks;
    }
};
class TrackedRequest : public HttpRequest {
    ~TrackedRequest() override {
        assert(std::this_thread::get_id() == mainThread);
        ++destroyedRequests;
    }
};
class Observer : public Ref {
public:
    int calls = 0;
    HttpClient* expectedClient = nullptr;
    bool expectedSuccess = true;
    std::string expectedBody;
    std::string expectedTag;
    int token = 173;
    std::function<void()> afterResponse;
    void response(HttpClient* client, HttpResponse* response) {
        assert(std::this_thread::get_id() == mainThread);
        assert(client == expectedClient);
        assert(response && response->getHttpRequest());
        assert(response->isSucceed() == expectedSuccess);
        assert(response->getHttpRequest()->getUserData() == &token);
        assert(std::string(response->getHttpRequest()->getTag()) == expectedTag);
        if (expectedSuccess) {
            assert(response->getResponseCode() == 200);
            auto body = response->getResponseData();
            assert(std::string(body->begin(), body->end()) == expectedBody);
            auto headers = response->getResponseHeader();
            assert(std::string(headers->begin(), headers->end()).find("X-Coherent-Fixture: local") != std::string::npos);
        } else {
            assert(response->getResponseCode() < 200);
            assert(response->getErrorBuffer() && response->getErrorBuffer()[0]);
        }
        ++calls;
        if (afterResponse) afterResponse();
    }
};

static void waitFor(const std::function<bool()>& condition, const char* label) {
    auto deadline = Clock::now() + std::chrono::seconds(6);
    while (!condition()) {
        if (Clock::now() >= deadline) {
            std::fprintf(stderr, "Timed out waiting for %s\n", label);
            std::abort();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
}
static double elapsed(Clock::time_point start) {
    return std::chrono::duration<double>(Clock::now() - start).count();
}
static void boundedDestroy() {
    auto start = Clock::now();
    HttpClient::destroyInstance();
    double seconds = elapsed(start);
    std::printf("destroyInstance returned in %.3f seconds\n", seconds);
    assert(seconds < shutdownBoundSeconds);
}
static void send(Observer& observer, const std::string& url,
                 HttpRequest::Type method = HttpRequest::Type::GET,
                 const std::string& body = "") {
    auto client = HttpClient::getInstance();
    observer.expectedClient = client;
    auto request = new TrackedRequest();
    request->setUrl(url.c_str());
    request->setTag(observer.expectedTag.c_str());
    request->setUserData(&observer.token);
    request->setRequestType(method);
    request->setRequestData(body.data(), body.size());
    request->setHeaders({"X-Coherent-Request: local"});
    request->setResponseCallback(&observer, httpresponse_selector(Observer::response));
    client->send(request);
    request->release();
}
static void waitResponse(ObservedScheduler* scheduler, Observer& observer) {
    int calls = observer.calls;
    waitFor([&] { return scheduler->pending() > 0; }, "native scheduled HTTP response");
    assert(observer.calls == calls); // Worker's completion must not call user code.
    scheduler->update(0.0f);
    assert(observer.calls == calls + 1);
    scheduler->update(0.0f);
    assert(observer.calls == calls + 1); // Exactly once.
}
static void waitStall(const std::string& fixtures, const std::string& id) {
    waitFor([&] { return std::ifstream(fixtures + "/" + id).good(); }, "server accepting the in-flight stalled request");
}
static void startStalled(ObservedScheduler* scheduler, Observer& observer,
                         const std::string& base, const std::string& fixtures,
                         const std::string& id, int readTimeout = 60) {
    auto client = HttpClient::getInstance();
    client->setTimeoutForConnect(60);
    client->setTimeoutForRead(readTimeout);
    send(observer, base + "/stall/" + id);
    waitStall(fixtures, id);
    assert(scheduler->pending() == 0);
    for (int i = 0; i < 4; ++i) send(observer, base + "/must-not-start/" + std::to_string(i));
}

// Saturate a local listener without accepting connections. The next HTTP
// connect remains SYN_SENT, exercising cancellation before an HTTP exchange.
static void cancelPendingConnect(ObservedScheduler* scheduler, Observer& observer,
                                 const std::string& base) {
    int listener = socket(AF_INET, SOCK_STREAM, 0);
    assert(listener >= 0);
    sockaddr_in address = {};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    assert(bind(listener, reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0);
    assert(listen(listener, 1) == 0);
    socklen_t size = sizeof(address);
    assert(getsockname(listener, reinterpret_cast<sockaddr*>(&address), &size) == 0);
    std::vector<int> fillers;
    bool full = false;
    for (int i = 0; i < 8; ++i) {
        int socketFd = socket(AF_INET, SOCK_STREAM, 0);
        assert(socketFd >= 0);
        assert(fcntl(socketFd, F_SETFL, O_NONBLOCK) == 0);
        int connected = connect(socketFd, reinterpret_cast<sockaddr*>(&address), sizeof(address));
        pollfd ready = {socketFd, POLLOUT, 0};
        if (connected != 0 && poll(&ready, 1, 100) == 0) {
            close(socketFd);
            full = true;
            break;
        }
        int error = 0;
        socklen_t errorSize = sizeof(error);
        assert(getsockopt(socketFd, SOL_SOCKET, SO_ERROR, &error, &errorSize) == 0 && error == 0);
        fillers.push_back(socketFd);
    }
    assert(full && !fillers.empty());
    auto client = HttpClient::getInstance();
    client->setTimeoutForConnect(60);
    client->setTimeoutForRead(0);
    send(observer, "http://127.0.0.1:" + std::to_string(ntohs(address.sin_port)) + "/connect");
    std::ostringstream endpoint;
    endpoint << "0100007F:" << std::uppercase << std::hex << std::setw(4)
             << std::setfill('0') << ntohs(address.sin_port);
    waitFor([&] {
        std::ifstream sockets("/proc/net/tcp");
        std::string line;
        while (std::getline(sockets, line)) {
            std::istringstream row(line);
            std::string slot, local, remote, state;
            if (row >> slot >> local >> remote >> state)
                if (remote == endpoint.str() && state == "02") return true;
        }
        return false;
    }, "actual loopback HTTP socket in SYN_SENT");
    assert(scheduler->pending() == 0);
    for (int i = 0; i < 4; ++i) send(observer, base + "/must-not-start/" + std::to_string(i));
    boundedDestroy();
    assert(destroyedRequests == 5);
    scheduler->update(0.0f);
    assert(observer.calls == 0);
    for (int socketFd : fillers) close(socketFd);
    close(listener);
}

// Same headless native GL setup as coherent_pause_close_native.cpp. The shared
// pause Lua fixture is read-only and uses in-memory save doubles.
static void initializeSurfacelessGL() {
    auto getDisplay = reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));
    assert(getDisplay);
    EGLDisplay display = getDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, nullptr);
    assert(eglInitialize(display, nullptr, nullptr));
    assert(eglBindAPI(EGL_OPENGL_API));
    EGLint attrs[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT,
                     EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
    EGLConfig config;
    EGLint count = 0;
    assert(eglChooseConfig(display, attrs, &config, 1, &count) && count);
    EGLint size[] = {EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurface(display, config, size);
    assert(surface != EGL_NO_SURFACE);
    EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, nullptr);
    assert(context != EGL_NO_CONTEXT);
    assert(eglMakeCurrent(display, surface, surface, context));
    glewInit();
    assert(glCreateShader && glCreateProgram);
    Configuration::getInstance()->gatherGPUInfo();
}
static lua_State* openPauseFixture(Director* director, const char* script) {
    char cwd[4096];
    assert(getcwd(cwd, sizeof(cwd)));
    auto files = FileUtils::getInstance();
    files->addSearchPath(std::string(cwd) + "/src/engine/cocos2d-x/cocos/scripting/lua-bindings/script");
    files->addSearchPath(std::string(cwd) + "/bin/res/scripts");
    files->addSearchPath(std::string(cwd) + "/bin/res/assets");
    director->getEventDispatcher()->setEnabled(true);
    auto engine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(engine);
    auto L = engine->getLuaStack()->getLuaState();
    lua_pushboolean(L, true);
    lua_setglobal(L, "COHERENT_PAUSE_CLOSE_ENGINE_END");
    if (luaL_dofile(L, script)) {
        std::fprintf(stderr, "%s\n", lua_tostring(L, -1));
        std::abort();
    }
    return L;
}

int main(int argc, char** argv) {
    assert(argc == 5);
    std::setvbuf(stdout, nullptr, _IONBF, 0);
    mainThread = std::this_thread::get_id();
    const std::string scenario = argv[1], base = argv[2], fixtures = argv[3];
    assert(base.find("http://127.0.0.1:") == 0);
    TestApplication app;
    if (scenario == "application-launch-stop") {
        app.launchResult = false;
        assert(app.run() == 0); // Preserve the existing early-launch return contract.
        assert(destroyedRequests == 0);
    } else if (scenario == "no-request") {
        HttpClient::destroyInstance();
        HttpClient::getInstance();
        boundedDestroy();
        HttpClient::destroyInstance();
        assert(destroyedRequests == 0);
    } else {
        const bool pause = scenario.find("pause-") == 0;
        if (pause) initializeSurfacelessGL();
        auto director = Director::getInstance();
        auto scheduler = new ObservedScheduler();
        scheduler->scheduleUpdate(director->getActionManager(), Scheduler::PRIORITY_SYSTEM, false);
        director->setScheduler(scheduler);
        scheduler->release();
        Observer observer;
        if (scenario == "idle-malformed") {
            observer.expectedSuccess = false;
            observer.expectedTag = "malformed";
            send(observer, ""); // No DNS or remote network is involved.
            waitResponse(scheduler, observer);
            assert(destroyedRequests == 1);
            // Let the completed worker reach its predicate wait before shutdown.
            std::this_thread::sleep_for(std::chrono::milliseconds(30));
            boundedDestroy();
        } else if (scenario == "success") {
            const char* names[] = {"GET", "POST", "PUT", "DELETE"};
            const HttpRequest::Type methods[] = {HttpRequest::Type::GET, HttpRequest::Type::POST,
                                                 HttpRequest::Type::PUT, HttpRequest::Type::DELETE};
            for (int i = 0; i < 4; ++i) {
                std::string body = (i == 1 || i == 2) ? "payload-" + std::to_string(i) : "";
                observer.expectedTag = names[i];
                observer.expectedBody = std::string(names[i]) + ":" + body;
                send(observer, base + "/echo", methods[i], body);
                waitResponse(scheduler, observer);
                assert(destroyedRequests == i + 1);
            }
            boundedDestroy();
            assert(observer.calls == 4);
        } else if (scenario == "immediate-cancel") {
            observer.expectedSuccess = false;
            observer.expectedTag = "immediate-cancel";
            for (int cycle = 0; cycle < 64; ++cycle) {
                send(observer, "");
                boundedDestroy();
                assert(destroyedRequests == cycle + 1);
                scheduler->update(0.0f);
                assert(observer.calls == 0);
            }
        } else if (scenario == "cancel-inflight-queued" || scenario == "cancel-unlimited") {
            startStalled(scheduler, observer, base, fixtures, scenario, scenario == "cancel-unlimited" ? 0 : 60);
            boundedDestroy();
            assert(destroyedRequests == 5); // Cancel and release before destroy returns.
            scheduler->update(0.0f);
            assert(observer.calls == 0);
        } else if (scenario == "cancel-connect") {
            cancelPendingConnect(scheduler, observer, base);
        } else if (scenario == "recreate-stale") {
            for (int cycle = 0; cycle < 12; ++cycle) {
                observer.expectedTag = "old";
                observer.expectedBody = "GET:";
                send(observer, base + "/echo");
                waitFor([&] { return scheduler->pending() > 0; }, "old lifecycle dispatch");
                auto stale = scheduler->takePending();
                assert(!stale.empty());
                boundedDestroy();
                assert(destroyedRequests == 2 * cycle + 1);
                Observer fresh;
                fresh.expectedTag = "new";
                fresh.expectedBody = "GET:";
                send(fresh, base + "/echo");
                waitFor([&] { return scheduler->pending() > 0; }, "new lifecycle dispatch");
                for (auto& callback : stale) callback();
                assert(observer.calls == 0 && fresh.calls == 0); // Old dispatch cannot steal a new response.
                waitResponse(scheduler, fresh);
                boundedDestroy();
                assert(destroyedRequests == 2 * cycle + 2);
            }
        } else if (scenario == "destroy-in-callback") {
            observer.expectedTag = "destroy-in-callback";
            observer.expectedBody = "GET:";
            observer.afterResponse = [] { boundedDestroy(); };
            send(observer, base + "/echo");
            waitResponse(scheduler, observer);
            assert(destroyedRequests == 1);
            Observer fresh;
            fresh.expectedTag = "after-callback-destroy";
            fresh.expectedBody = "GET:";
            send(fresh, base + "/echo");
            waitResponse(scheduler, fresh);
            boundedDestroy();
            assert(destroyedRequests == 2);
        } else if (pause) {
            auto L = openPauseFixture(director, argv[4]);
            if (scenario == "pause-idle") {
                observer.expectedSuccess = false;
                observer.expectedTag = "pause-idle";
                send(observer, "");
                waitResponse(scheduler, observer);
            } else {
                assert(scenario == "pause-stalled");
                startStalled(scheduler, observer, base, fixtures, "pause-stalled");
            }
            auto start = Clock::now();
            // No explicit HttpClient cleanup here: production Director must do it.
            director->end();
            director->mainLoop();
            double seconds = elapsed(start);
            std::printf("Director::end/mainLoop returned in %.3f seconds\n", seconds);
            assert(seconds < shutdownBoundSeconds);
            lua_getglobal(L, "COHERENT_PAUSE_CLOSE_EXITED");
            assert(lua_tointeger(L, -1) == 5);
            lua_pop(L, 1);
            assert(destroyedRequests == (scenario == "pause-idle" ? 1 : 5));
            assert(observer.calls == (scenario == "pause-idle" ? 1 : 0));
        } else {
            std::fprintf(stderr, "Unknown scenario: %s\n", scenario.c_str());
            return 2;
        }
    }
    // Parent runner still requires normal process completion. Printing this is
    // deliberately insufficient because the original hang occurred after main.
    std::printf("PASS native HTTP shutdown assertions: %s\n", scenario.c_str());
    return 0;
}
