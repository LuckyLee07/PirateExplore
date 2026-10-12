// Native Cocos offscreen loot/chest evidence. No GLFW window or player save.
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "cocos-ext.h"
#include "tolua++.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <cassert>
#include <cstdio>
#include <unistd.h>
using namespace cocos2d;
// The legacy Linux Device::getDPI dereferences XOpenDisplay even in a
// surfaceless test. Supply only this display metric at link time; all native
// event dispatch, ScrollView thresholds and movement logic remain unchanged.
extern "C" int __wrap__ZN7cocos2d6Device6getDPIEv() { return 96; }
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
class OffscreenView : public GLView {
public:
    OffscreenView(float w,float h) { GLViewProtocol::setFrameSize(w,h); }
    bool isOpenGLReady() override { return true; }
    void swapBuffers() override {}
    void end() override {}
    void setIMEKeyboardState(bool) override {}
    void setFrameSize(float w,float h) override { GLViewProtocol::setFrameSize(w,h); }
    void setViewPortInPoints(float x,float y,float w,float h) override { glViewport(x,y,w,h); }
    void setScissorInPoints(float x,float y,float w,float h) override { glScissor(x,y,w,h); }
};
static int capture(lua_State* L) {
    auto node=static_cast<Node*>(tolua_tousertype(L,1,nullptr));
    int w=lua_tointeger(L,2),h=lua_tointeger(L,3);const char* path=lua_tostring(L,4);
    auto director=Director::getInstance();
    auto view=new OffscreenView(w,h);director->setOpenGLView(view);view->release();
    director->setProjection(Director::Projection::_2D);
    auto target=RenderTexture::create(w,h,Texture2D::PixelFormat::RGBA8888,GL_DEPTH24_STENCIL8);
    target->beginWithClear(1,1,1,1);node->visit();target->end();director->getRenderer()->render();
    auto pixels=target->newImage(true);assert(pixels);bool saved=pixels->saveToFile(path);delete pixels;
    lua_pushboolean(L,saved);return 1;
}
static int tableTap(lua_State* L) {
    auto table=static_cast<extension::TableView*>(tolua_tousertype(L,1,nullptr));
    auto point=Director::getInstance()->convertToUI(Point(lua_tonumber(L,2),lua_tonumber(L,3)));
    Touch touch;touch.setTouchInfo(1,point.x,point.y);EventTouch event;
    bool accepted=table->onTouchBegan(&touch,&event);
    if(accepted) table->onTouchEnded(&touch,&event);
    lua_pushboolean(L,accepted);return 1;
}
static int dispatchDescriptionDrag(lua_State* L) {
    auto scroll=static_cast<extension::ScrollView*>(tolua_tousertype(L,1,nullptr));
    auto director=Director::getInstance();
    Node* root=scroll;while(root->getParent())root=root->getParent();
    auto scene=dynamic_cast<Scene*>(root);assert(scene);
    if(director->getRunningScene()!=scene) {
        if(director->getRunningScene())director->replaceScene(scene);
        else director->runWithScene(scene);
        // runWithScene deliberately skips its first zero-delta draw. Advance
        // real frames until onEnter has enabled scene-graph input listeners.
        for(int i=0;i<4 && !scene->isRunning();++i) {
            usleep(2000);director->drawScene();
        }
    }
    assert(scene->isRunning() && scroll->isRunning());
    auto point=scroll->convertToWorldSpace(Point(scroll->getViewSize().width*.5f,4));
    point=director->convertToUI(point);
    intptr_t id=4242;float x=point.x,y=point.y;
    auto view=director->getOpenGLView();
    view->handleTouchesBegin(1,&id,&x,&y);
    const bool visibleAfterBegin=scroll->getParent()->isVisible();
    const float before=scroll->getContentOffset().y;
    y-=14;view->handleTouchesMove(1,&id,&x,&y);
    // ScrollView's first threshold-crossing move starts the drag with zero
    // displacement; a subsequent move performs the actual content scroll.
    y-=14;view->handleTouchesMove(1,&id,&x,&y);
    const float after=scroll->getContentOffset().y;
    view->handleTouchesEnd(1,&id,&x,&y);
    std::fprintf(stderr,"description drag: visible=%d/%d, offset=%g/%g, point=%g/%g, running=%d\n",
        visibleAfterBegin,scroll->getParent()->isVisible(),before,after,x,y,scroll->isRunning());
    lua_pushboolean(L,visibleAfterBegin && scroll->getParent()->isVisible());
    lua_pushboolean(L,before!=after);return 2;
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
    lua_register(L,"coherentCapture",capture);
    lua_register(L,"coherentTableTap",tableTap);
    lua_register(L,"coherentDescriptionDrag",dispatchDescriptionDrag);
    if(luaL_dofile(L,argv[1])) { std::fprintf(stderr,"%s\n",lua_tostring(L,-1)); return 1; }
    std::puts("PASS native loot/chest offscreen rendering");
    return 0;
}
