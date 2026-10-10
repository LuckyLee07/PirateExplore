// Native tutorial layout regression. No GUI, game scene or player save.
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "tolua++.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <cassert>
#include <cstdio>
#include <unistd.h>
using namespace cocos2d;
class TestApplication : public Application {
    bool applicationDidFinishLaunching() override { return true; }
    void applicationDidEnterBackground() override {}
    void applicationWillEnterForeground() override {}
};
static EGLDisplay display;
static EGLConfig config;
static EGLSurface surface;
static EGLContext context;
static void createContext() {
    context = eglCreateContext(display, config, EGL_NO_CONTEXT, nullptr);
    assert(context != EGL_NO_CONTEXT);
    assert(eglMakeCurrent(display, surface, surface, context));
    // GLEW can report no GLX display for EGL while loading the GL entrypoints.
    glewInit();
    assert(glCreateShader && glCreateProgram);
}
int main(int argc,char**argv) {
    assert(argc==2);
    TestApplication app;
    auto getDisplay = reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));
    assert(getDisplay);
    display=getDisplay(EGL_PLATFORM_SURFACELESS_MESA,EGL_DEFAULT_DISPLAY,nullptr);
    assert(eglInitialize(display,nullptr,nullptr));
    assert(eglBindAPI(EGL_OPENGL_API));
    EGLint attrs[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_BIT,EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};
    EGLint count=0; assert(eglChooseConfig(display,attrs,&config,1,&count)&&count);
    EGLint size[]={EGL_WIDTH,16,EGL_HEIGHT,16,EGL_NONE};
    surface=eglCreatePbufferSurface(display,config,size); assert(surface!=EGL_NO_SURFACE);
    createContext();
    Configuration::getInstance()->gatherGPUInfo();
    char cwd[4096]; assert(getcwd(cwd,sizeof(cwd)));
    FileUtils::getInstance()->addSearchPath(std::string(cwd)+"/src/engine/cocos2d-x/cocos/scripting/lua-bindings/script");
    FileUtils::getInstance()->addSearchPath(std::string(cwd)+"/bin/res/scripts");
    FileUtils::getInstance()->addSearchPath(std::string(cwd)+"/bin/res/assets");
    auto director=Director::getInstance();
    director->getEventDispatcher()->setEnabled(true);
    auto engine=LuaEngine::getInstance(); ScriptEngineManager::getInstance()->setScriptEngine(engine);
    auto L=engine->getLuaStack()->getLuaState();
    if(luaL_dofile(L,argv[1])) { std::fprintf(stderr,"%s\n",lua_tostring(L,-1)); return 1; }
    std::puts("PASS native tutorial LabelTTF and ScrollView layout");
    return 0;
}
