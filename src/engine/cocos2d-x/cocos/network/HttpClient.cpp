/****************************************************************************
 Copyright (c) 2012      greathqy
 Copyright (c) 2012      cocos2d-x.org
 Copyright (c) 2013-2014 Chukong Technologies Inc.
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "HttpClient.h"

#include <thread>
#include <queue>
#include <condition_variable>
#include <atomic>
#include <chrono>

#include <errno.h>

#include "CCVector.h"
#include "CCDirector.h"
#include "CCScheduler.h"

#include "curl/curl.h"

#include "platform/CCFileUtils.h"

NS_CC_BEGIN

namespace network {

static std::mutex       s_requestQueueMutex;
static std::mutex       s_responseQueueMutex;

static std::condition_variable		s_SleepCondition;


#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
typedef int int32_t;
#endif

static std::atomic<bool> s_need_quit(false);

static Vector<HttpRequest*>*  s_requestQueue = nullptr;
static Vector<HttpResponse*>* s_responseQueue = nullptr;

static HttpClient *s_pHttpClient = nullptr; // pointer to singleton

static char s_errorBuffer[CURL_ERROR_SIZE] = {0};

typedef size_t (*write_callback)(void *ptr, size_t size, size_t nmemb, void *stream);

static std::string s_cookieFilename = "";

// Callback function used by libcurl for collect response data
static size_t writeData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    std::vector<char> *recvBuffer = (std::vector<char>*)stream;
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    recvBuffer->insert(recvBuffer->end(), (char*)ptr, (char*)ptr+sizes);
    
    return sizes;
}

// Callback function used by libcurl for collect header data
static size_t writeHeaderData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    std::vector<char> *recvBuffer = (std::vector<char>*)stream;
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    recvBuffer->insert(recvBuffer->end(), (char*)ptr, (char*)ptr+sizes);
    
    return sizes;
}


static int processGetTask(HttpRequest *request, write_callback callback, void *stream, long *errorCode, write_callback headerCallback, void *headerStream);
static int processPostTask(HttpRequest *request, write_callback callback, void *stream, long *errorCode, write_callback headerCallback, void *headerStream);
static int processPutTask(HttpRequest *request, write_callback callback, void *stream, long *errorCode, write_callback headerCallback, void *headerStream);
static int processDeleteTask(HttpRequest *request, write_callback callback, void *stream, long *errorCode, write_callback headerCallback, void *headerStream);
// int processDownloadTask(HttpRequest *task, write_callback callback, void *stream, int32_t *errorCode);


// Worker thread
void HttpClient::networkThread(Scheduler* scheduler)
{    
    HttpRequest *request = nullptr;
    
    const auto callbackAlive = _callbackAlive;
    
    while (true) 
    {
        // Queue state and the sleep predicate share one mutex. A quit/request
        // arriving just before wait must not lose its notification.
        {
            std::unique_lock<std::mutex> lock(s_requestQueueMutex);
            s_SleepCondition.wait(lock, [] {
                return s_need_quit.load() || !s_requestQueue->empty();
            });
            if (s_need_quit.load())
                break;
            request = s_requestQueue->at(0);
            s_requestQueue->erase(0);
        }

        // step 2: libcurl sync access
        
        // Create a HttpResponse object, the default setting is http access failed
        HttpResponse *response = new HttpResponse(request);
        
        // request's refcount = 2 here, it's retained by HttpRespose constructor
        request->release();
        // ok, refcount = 1 now, only HttpResponse hold it.
        
        long responseCode = -1;
        int retValue = 0;

        // Process the request -> get response packet
        switch (request->getRequestType())
        {
            case HttpRequest::Type::GET: // HTTP GET
                retValue = processGetTask(request,
                                          writeData, 
                                          response->getResponseData(), 
                                          &responseCode,
                                          writeHeaderData,
                                          response->getResponseHeader());
                break;
            
            case HttpRequest::Type::POST: // HTTP POST
                retValue = processPostTask(request,
                                           writeData, 
                                           response->getResponseData(), 
                                           &responseCode,
                                           writeHeaderData,
                                           response->getResponseHeader());
                break;

            case HttpRequest::Type::PUT:
                retValue = processPutTask(request,
                                          writeData,
                                          response->getResponseData(),
                                          &responseCode,
                                          writeHeaderData,
                                          response->getResponseHeader());
                break;

            case HttpRequest::Type::DELETE:
                retValue = processDeleteTask(request,
                                             writeData,
                                             response->getResponseData(),
                                             &responseCode,
                                             writeHeaderData,
                                             response->getResponseHeader());
                break;
            
            default:
                CCASSERT(true, "CCHttpClient: unkown request type, only GET and POSt are supported");
                break;
        }
                
        // write data to HttpResponse
        response->setResponseCode(responseCode);
        
        if (retValue != 0) 
        {
            response->setSucceed(false);
            response->setErrorBuffer(s_errorBuffer);
        }
        else
        {
            response->setSucceed(true);
        }

        
        // add response packet into queue
        s_responseQueueMutex.lock();
        s_responseQueue->pushBack(response);
        s_responseQueueMutex.unlock();
        
        if (!s_need_quit.load()) {
            // The token outlives this client in an already queued callback.
            // It is invalidated on the Cocos thread before joining the worker,
            // so destruction/recreation cannot call a freed (or reused) this.
            scheduler->performFunctionInCocosThread([this, callbackAlive] {
                if (*callbackAlive)
                    dispatchResponseCallbacks();
            });
        }
    }
    
    // Queue ownership is released by the main thread after join. Request
    // callback targets can own Lua/native scene objects.

}

#if LIBCURL_VERSION_NUM >= 0x072000
static int cancelTransfer(void*, curl_off_t, curl_off_t, curl_off_t, curl_off_t)
#else
// The bundled mobile/Windows headers predate the 7.32 xfer-info API.
static int cancelTransfer(void*, double, double, double, double)
#endif
{
    return s_need_quit.load() ? 1 : 0;
}

//Configure curl's timeout property
static bool configureCURL(CURL *handle)
{
    if (!handle) {
        return false;
    }
    
    int32_t code;
    code = curl_easy_setopt(handle, CURLOPT_ERRORBUFFER, s_errorBuffer);
    if (code != CURLE_OK) {
        return false;
    }
    code = curl_easy_setopt(handle, CURLOPT_TIMEOUT, HttpClient::getInstance()->getTimeoutForRead());
    if (code != CURLE_OK) {
        return false;
    }
    code = curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, HttpClient::getInstance()->getTimeoutForConnect());
    if (code != CURLE_OK) {
        return false;
    }
    curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 0L);
    
    // FIXED #3224: The subthread of CCHttpClient interrupts main thread if timeout comes.
    // Document is here: http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOSIGNAL 
    curl_easy_setopt(handle, CURLOPT_NOSIGNAL, 1L);

    // Cancel even while curl_multi_perform is actively transferring data.
    curl_easy_setopt(handle, CURLOPT_NOPROGRESS, 0L);
#if LIBCURL_VERSION_NUM >= 0x072000
    curl_easy_setopt(handle, CURLOPT_XFERINFOFUNCTION, cancelTransfer);
#else
    curl_easy_setopt(handle, CURLOPT_PROGRESSFUNCTION, cancelTransfer);
#endif

    return true;
}

class CURLRaii
{
    /// Instance of CURL
    CURL *_curl;
    /// Keeps custom header data
    curl_slist *_headers;
public:
    CURLRaii()
        : _curl(curl_easy_init())
        , _headers(nullptr)
    {
    }

    ~CURLRaii()
    {
        if (_curl)
            curl_easy_cleanup(_curl);
        /* free the linked list for header data */
        if (_headers)
            curl_slist_free_all(_headers);
    }

    template <class T>
    bool setOption(CURLoption option, T data)
    {
        return CURLE_OK == curl_easy_setopt(_curl, option, data);
    }

    /**
     * @brief Inits CURL instance for common usage
     * @param request Null not allowed
     * @param callback Response write callback
     * @param stream Response write stream
     */
    bool init(HttpRequest *request, write_callback callback, void *stream, write_callback headerCallback, void *headerStream)
    {
        if (!_curl)
            return false;
        if (!configureCURL(_curl))
            return false;

        /* get custom header data (if set) */
       	std::vector<std::string> headers=request->getHeaders();
        if(!headers.empty())
        {
            /* append custom headers one by one */
            for (std::vector<std::string>::iterator it = headers.begin(); it != headers.end(); ++it)
                _headers = curl_slist_append(_headers,it->c_str());
            /* set custom headers for curl */
            if (!setOption(CURLOPT_HTTPHEADER, _headers))
                return false;
        }
        if (!s_cookieFilename.empty()) {
            if (!setOption(CURLOPT_COOKIEFILE, s_cookieFilename.c_str())) {
                return false;
            }
            if (!setOption(CURLOPT_COOKIEJAR, s_cookieFilename.c_str())) {
                return false;
            }
        }

        return setOption(CURLOPT_URL, request->getUrl())
                && setOption(CURLOPT_WRITEFUNCTION, callback)
                && setOption(CURLOPT_WRITEDATA, stream)
                && setOption(CURLOPT_HEADERFUNCTION, headerCallback)
                && setOption(CURLOPT_HEADERDATA, headerStream);
        
    }

    /// @param responseCode Null not allowed
    bool perform(long *responseCode)
    {
        // A single easy handle retains the existing request semantics, but
        // the multi wait lets shutdown cancel a stalled transfer every 100ms
        // instead of joining a blocking easy_perform until its read timeout.
        CURLM* multi = curl_multi_init();
        if (!multi)
            return false;
        CURLcode result = CURLE_ABORTED_BY_CALLBACK;
        CURLMcode status = curl_multi_add_handle(multi, _curl);
        int running = 1;
        while (status == CURLM_OK && running && !s_need_quit.load()) {
            status = curl_multi_perform(multi, &running);
            if (status == CURLM_OK && running && !s_need_quit.load()) {
#if LIBCURL_VERSION_NUM >= 0x071c00
                int ready = 0;
                status = curl_multi_wait(multi, nullptr, 0, 100, &ready);
                if (!ready)
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
#else
                // curl_multi_wait arrived in 7.28. Keep old SDKs buildable
                // without platform socket/select dependencies or a blocking
                // easy_perform. Polling still observes cancellation each turn.
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
#endif
            }
        }
        if (status == CURLM_OK && !s_need_quit.load()) {
            int pending = 0;
            while (CURLMsg* message = curl_multi_info_read(multi, &pending)) {
                if (message->msg == CURLMSG_DONE && message->easy_handle == _curl)
                    result = message->data.result;
            }
        }
        curl_multi_remove_handle(multi, _curl);
        curl_multi_cleanup(multi);
        if (result != CURLE_OK)
            return false;
        CURLcode code = curl_easy_getinfo(_curl, CURLINFO_RESPONSE_CODE, responseCode);
        if (code != CURLE_OK || !(*responseCode >= 200 && *responseCode < 300)) {
            CCLOGERROR("Curl curl_easy_getinfo failed: %s", curl_easy_strerror(code));
            return false;
        }
        // Get some mor data.
        
        return true;
    }
};

//Process Get Request
static int processGetTask(HttpRequest *request, write_callback callback, void *stream, long *responseCode, write_callback headerCallback, void *headerStream)
{
    CURLRaii curl;
    bool ok = curl.init(request, callback, stream, headerCallback, headerStream)
            && curl.setOption(CURLOPT_FOLLOWLOCATION, true)
            && curl.perform(responseCode);
    return ok ? 0 : 1;
}

//Process POST Request
static int processPostTask(HttpRequest *request, write_callback callback, void *stream, long *responseCode, write_callback headerCallback, void *headerStream)
{
    CURLRaii curl;
    bool ok = curl.init(request, callback, stream, headerCallback, headerStream)
            && curl.setOption(CURLOPT_POST, 1)
            && curl.setOption(CURLOPT_POSTFIELDS, request->getRequestData())
            && curl.setOption(CURLOPT_POSTFIELDSIZE, request->getRequestDataSize())
            && curl.perform(responseCode);
    return ok ? 0 : 1;
}

//Process PUT Request
static int processPutTask(HttpRequest *request, write_callback callback, void *stream, long *responseCode, write_callback headerCallback, void *headerStream)
{
    CURLRaii curl;
    bool ok = curl.init(request, callback, stream, headerCallback, headerStream)
            && curl.setOption(CURLOPT_CUSTOMREQUEST, "PUT")
            && curl.setOption(CURLOPT_POSTFIELDS, request->getRequestData())
            && curl.setOption(CURLOPT_POSTFIELDSIZE, request->getRequestDataSize())
            && curl.perform(responseCode);
    return ok ? 0 : 1;
}

//Process DELETE Request
static int processDeleteTask(HttpRequest *request, write_callback callback, void *stream, long *responseCode, write_callback headerCallback, void *headerStream)
{
    CURLRaii curl;
    bool ok = curl.init(request, callback, stream, headerCallback, headerStream)
            && curl.setOption(CURLOPT_CUSTOMREQUEST, "DELETE")
            && curl.setOption(CURLOPT_FOLLOWLOCATION, true)
            && curl.perform(responseCode);
    return ok ? 0 : 1;
}

// HttpClient implementation
HttpClient* HttpClient::getInstance()
{
    if (s_pHttpClient == nullptr) {
        s_pHttpClient = new HttpClient();
    }
    
    return s_pHttpClient;
}

void HttpClient::destroyInstance()
{
    CC_SAFE_DELETE(s_pHttpClient);
}

void HttpClient::enableCookies(const char* cookieFile) {
    if (cookieFile) {
        s_cookieFilename = std::string(cookieFile);
    }
    else {
        s_cookieFilename = (FileUtils::getInstance()->getWritablePath() + "cookieFile.txt");
    }
}

HttpClient::HttpClient()
: _callbackAlive(std::make_shared<bool>(true))
, _timeoutForConnect(30)
, _timeoutForRead(60)
{
}

HttpClient::~HttpClient()
{
    // Public lifecycle methods and response callbacks run on the Cocos thread.
    *_callbackAlive = false;
    {
        std::lock_guard<std::mutex> lock(s_requestQueueMutex);
        s_need_quit.store(true);
    }
    s_SleepCondition.notify_one();
    if (_thread.joinable())
        _thread.join();

    // send()/new HttpResponse each hold one reference in addition to the
    // Vector reference. Cancel both pending and completed work on this thread.
    if (s_requestQueue) {
        for (auto request : *s_requestQueue)
            request->release();
        delete s_requestQueue;
        s_requestQueue = nullptr;
    }
    if (s_responseQueue) {
        for (auto response : *s_responseQueue)
            response->release();
        delete s_responseQueue;
        s_responseQueue = nullptr;
    }
    s_pHttpClient = nullptr;
}

//Lazy create semaphore & mutex & thread
bool HttpClient::lazyInitThreadSemphore()
{
    if (s_requestQueue != nullptr) {
        return true;
    } else {
        
        s_requestQueue = new Vector<HttpRequest*>();
        s_responseQueue = new Vector<HttpResponse*>();
        
        s_need_quit.store(false);
        auto scheduler = Director::getInstance()->getScheduler();
        _thread = std::thread(&HttpClient::networkThread, this, scheduler);
    }
    
    return true;
}

//Add a get task to queue
void HttpClient::send(HttpRequest* request)
{    
    if (!request || false == lazyInitThreadSemphore())
    {
        return;
    }
    
    if (!request)
    {
        return;
    }
        
    request->retain();
    
    if (nullptr != s_requestQueue) {
        s_requestQueueMutex.lock();
        s_requestQueue->pushBack(request);
        s_requestQueueMutex.unlock();
        
        // Notify thread start to work
        s_SleepCondition.notify_one();
    }
}

// Poll and notify main thread if responses exists in queue
void HttpClient::dispatchResponseCallbacks()
{
    // log("CCHttpClient::dispatchResponseCallbacks is running");
    //occurs when cocos thread fires but the network thread has already quited
    if (nullptr == s_responseQueue) {
        return;
    }
    HttpResponse* response = nullptr;
    
    s_responseQueueMutex.lock();

    if (!s_responseQueue->empty())
    {
        response = s_responseQueue->at(0);
        s_responseQueue->erase(0);
    }
    
    s_responseQueueMutex.unlock();
    
    if (response)
    {
        HttpRequest *request = response->getHttpRequest();
        Ref* pTarget = request->getTarget();
        SEL_HttpResponse pSelector = request->getSelector();

        if (pTarget && pSelector) 
        {
            (pTarget->*pSelector)(this, response);
        }
        
        response->release();
    }
}

}

NS_CC_END


