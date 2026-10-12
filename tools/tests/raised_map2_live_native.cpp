// Actual Cocos TMX / Lua / EGL rendering. No application scene, GUI or save I/O.
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "tolua++.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <cassert>
#include <cstdio>
#include <unistd.h>
#include <execinfo.h>
#include <signal.h>
#include <vector>
#include <cstdint>
#include <map>
#include <set>
#include <string>
using namespace cocos2d;
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
static bool contextReloadPhase=false;
static unsigned liveTextureDeletes=0,allTextureDeletes=0;
static std::set<GLuint> liveTextureNames, liveBufferNames;
static PFNGLGENBUFFERSPROC realGenBuffers;
static PFNGLDELETEBUFFERSPROC realDeleteBuffers;
static void GLAPIENTRY countedGenBuffers(GLsizei n,GLuint* names) {
 realGenBuffers(n,names);for(int i=0;i<n;++i)liveBufferNames.insert(names[i]);
}
static void GLAPIENTRY countedDeleteBuffers(GLsizei n,const GLuint* names) {
 for(int i=0;i<n;++i)liveBufferNames.erase(names[i]);realDeleteBuffers(n,names);
}
extern "C" void __real_glGenTextures(GLsizei n,GLuint* names);
extern "C" void __wrap_glGenTextures(GLsizei n,GLuint* names) {
 __real_glGenTextures(n,names);for(int i=0;i<n;++i)liveTextureNames.insert(names[i]);
}
static std::map<unsigned,std::string> priorTextureNames;
extern "C" void __real_glDeleteTextures(GLsizei n,const GLuint* names);
extern "C" void __wrap_glDeleteTextures(GLsizei n,const GLuint* names) {
    if(contextReloadPhase)for(int i=0;i<n;++i)if(glIsTexture(names[i])) {
        ++liveTextureDeletes;
        std::printf("CONTEXT_LIVE_DELETE\t%u\t%s\n",names[i],priorTextureNames[names[i]].c_str());
    }
    for(int i=0;i<n;++i){liveTextureNames.erase(names[i]);++allTextureDeletes;}
    __real_glDeleteTextures(n,names);
}
static void createContext() {
    liveTextureNames.clear();liveBufferNames.clear();
    context = eglCreateContext(display, config, EGL_NO_CONTEXT, nullptr);
    assert(context != EGL_NO_CONTEXT);
    assert(eglMakeCurrent(display, surface, surface, context));
    glewInit(); // EGL has no GLX display, but GLEW loads its GL entrypoints.
    realGenBuffers=__glewGenBuffers;realDeleteBuffers=__glewDeleteBuffers;
    __glewGenBuffers=countedGenBuffers;__glewDeleteBuffers=countedDeleteBuffers;
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
static void viewport(int w,int h) {
    auto director=Director::getInstance();
    if (director->getOpenGLView()) director->getOpenGLView()->setFrameSize(w,h);
    else { auto view=new OffscreenView(w,h);director->setOpenGLView(view);view->release(); }
    director->setProjection(Director::Projection::_2D);
}
static int capture(lua_State* L) {
    auto node=static_cast<Node*>(tolua_tousertype(L,1,nullptr));
    int w=lua_tointeger(L,2),h=lua_tointeger(L,3);const char* path=lua_tostring(L,4);
    viewport(w,h);
    auto director=Director::getInstance();
    auto target=RenderTexture::create(w,h,Texture2D::PixelFormat::RGBA8888,GL_DEPTH24_STENCIL8);
    assert(target);
    target->setVirtualViewport(Point(0,0),Rect(0,0,w,h),Rect(0,0,w,h));
    target->beginWithClear(0.1f,0.15f,0.2f,1);node->visit();target->end();
    director->getRenderer()->render();
    auto pixels=target->newImage(true);assert(pixels);
    bool saved=pixels->saveToFile(path);delete pixels;
    lua_pushboolean(L,saved);return 1;
}
// TMX opacity is baked into batch quads at load in this Cocos version.
// Adjust ONLY vertex alpha for fog diagnostics, without touching any GID/UV.
static int fogOpacity(lua_State* L) {
    auto layer=static_cast<SpriteBatchNode*>(tolua_tousertype(L,1,nullptr));
    auto atlas=layer->getTextureAtlas();
    const GLubyte opacity=lua_tointeger(L,2);
    for(ssize_t i=0;i<atlas->getTotalQuads();++i) {
        auto quad=atlas->getQuads()[i];
        quad.bl.colors.a=quad.br.colors.a=quad.tl.colors.a=quad.tr.colors.a=opacity;
        atlas->updateQuad(&quad,i);
    }
    return 0;
}
static int enter(lua_State* L) { static_cast<Node*>(tolua_tousertype(L,1,nullptr))->onEnter();return 0; }
static int leave(lua_State* L) { static_cast<Node*>(tolua_tousertype(L,1,nullptr))->onExit();return 0; }
static int drain(lua_State*) { PoolManager::getInstance()->getCurrentPool()->clear();return 0; }
static int sampler(lua_State* L) {
    auto texture=static_cast<Texture2D*>(tolua_tousertype(L,1,nullptr));
    GL::bindTexture2D(texture->getName());
    GLint min=0,mag=0;glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&min);
    glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,&mag);
    lua_pushinteger(L,min);lua_pushinteger(L,mag);return 2;
}
extern "C" void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause();
static int background(lua_State*) { Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause();return 0; }
static int restore(lua_State*) {
    assert(eglMakeCurrent(display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT));
    assert(eglDestroyContext(display,context));createContext();GL::invalidateStateCache();
    ShaderCache::getInstance()->reloadDefaultShaders();DrawPrimitives::init();contextReloadPhase=true;VolatileTextureMgr::reloadAllTextures();contextReloadPhase=false;
    std::printf("CONTEXT_COLLISIONS\t%u\n",liveTextureDeletes);
    EventCustom event(EVENT_COME_TO_FOREGROUND);
    Director::getInstance()->getEventDispatcher()->dispatchEvent(&event);
    Director::getInstance()->setGLDefaultValues();
    return 0;
}
static int textureHash(lua_State* L) {
 auto texture=static_cast<Texture2D*>(tolua_tousertype(L,1,nullptr));
 if(lua_gettop(L)>1)priorTextureNames[texture->getName()]=lua_tostring(L,2);
 GL::bindTexture2D(texture->getName());GLint width=0,height=0;glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,&width);glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,&height);
 assert(width>0 && height>0 && width<=8192 && height<=8192);std::vector<unsigned char> bytes(width*height*4);
 glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,bytes.data());
 uint64_t hash=1469598103934665603ULL;for(auto b:bytes){hash^=b;hash*=1099511628211ULL;}
 char value[32];snprintf(value,sizeof(value),"%016llx",(unsigned long long)hash);lua_pushstring(L,value);return 1;
}
class DispatcherProbe : public EventDispatcher {
public:
 static void drawCounts(unsigned& nodes,unsigned& listeners,unsigned& largest) {
  auto member=&DispatcherProbe::_nodeListenersMap;
  auto& entries=Director::getInstance()->getEventDispatcher()->*member;
  nodes=listeners=largest=0;
  for(auto& item:entries)if(dynamic_cast<DrawNode*>(item.first)) {
   ++nodes;auto size=(unsigned)item.second->size();listeners+=size;largest=std::max(largest,size);
  }
 }
};
static int bufferCounts(lua_State* L) {
 unsigned nodes,listeners,largest;DispatcherProbe::drawCounts(nodes,listeners,largest);
 lua_pushinteger(L,liveBufferNames.size());lua_pushinteger(L,nodes);lua_pushinteger(L,listeners);lua_pushinteger(L,largest);return 4;
}
static int textureCounts(lua_State* L) {
 lua_pushinteger(L,liveTextureNames.size());lua_pushinteger(L,VolatileTextureMgr::_textures.size());lua_pushinteger(L,liveTextureDeletes);return 3;
}
static int ordinaryTextureReplacement(lua_State*) {
 unsigned char bytes[8*8*4];std::fill(bytes,bytes+sizeof(bytes),255);
 auto count=liveTextureNames.size();auto texture=new Texture2D();
 assert(texture->initWithData(bytes,sizeof(bytes),Texture2D::PixelFormat::RGBA8888,8,8,Size(8,8)));
 auto deleted=allTextureDeletes;assert(liveTextureNames.size()==count+1);
 assert(texture->initWithData(bytes,sizeof(bytes),Texture2D::PixelFormat::RGBA8888,8,8,Size(8,8)));
 assert(allTextureDeletes==deleted+1 && liveTextureNames.size()==count+1);
 texture->release();assert(liveTextureNames.size()==count);
 std::puts("PASS same-context texture replacement deletes exactly its old texture and releases the replacement");return 0;
}
static int liveTick(lua_State* L) {
 auto director=Director::getInstance();director->getScheduler()->update((float)luaL_checknumber(L,1));director->getRenderer()->render();PoolManager::getInstance()->getCurrentPool()->clear();return 0;
}
static int liveScene(lua_State* L) {
 auto scene=static_cast<Scene*>(tolua_tousertype(L,1,nullptr));auto director=Director::getInstance();
 director->getRenderer()->render(); // Complete queued native coast FBO draws before the first zero-delta frame drains autorelease.
 if(director->getRunningScene())director->replaceScene(scene);else director->runWithScene(scene);
 for(int i=0;i<3;++i){usleep(3000);director->mainLoop();}assert(scene->isRunning());return 0;
}
static int liveTouch(lua_State* L) {
 auto director=Director::getInstance();auto view=director->getOpenGLView();intptr_t id=9131;
 auto start=director->convertToUI(Point(lua_tonumber(L,1),lua_tonumber(L,2)));
 float x=start.x,y=start.y;view->handleTouchesBegin(1,&id,&x,&y);
 if(lua_gettop(L)>=4){auto finish=director->convertToUI(Point(lua_tonumber(L,3),lua_tonumber(L,4)));x=finish.x;y=finish.y;view->handleTouchesMove(1,&id,&x,&y);}
 view->handleTouchesEnd(1,&id,&x,&y);return 0;
}

// Test-only held/cancelled gestures, using the same native GLView dispatcher.
static int liveGesture(lua_State* L) {
 auto d=Director::getInstance();auto v=d->getOpenGLView();intptr_t id=8241;
 int phase=(int)lua_tointeger(L,1);auto p=d->convertToUI(Point(lua_tonumber(L,2),lua_tonumber(L,3)));float x=p.x,y=p.y;
 if(phase==0)v->handleTouchesBegin(1,&id,&x,&y);
 else if(phase==1)v->handleTouchesMove(1,&id,&x,&y);
 else if(phase==2)v->handleTouchesEnd(1,&id,&x,&y);
 else v->handleTouchesCancel(1,&id,&x,&y);
 return 0;
}

int main(int argc,char**argv) {
    signal(SIGSEGV,[](int){void* frames[60];int n=backtrace(frames,60);backtrace_symbols_fd(frames,n,2);_exit(139);});
    assert(argc==2);TestApplication app;
    auto getDisplay=reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));
    assert(getDisplay);display=getDisplay(EGL_PLATFORM_SURFACELESS_MESA,EGL_DEFAULT_DISPLAY,nullptr);
    assert(eglInitialize(display,nullptr,nullptr));assert(eglBindAPI(EGL_OPENGL_API));
    EGLint attrs[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_BIT,
        EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_DEPTH_SIZE,24,EGL_STENCIL_SIZE,8,EGL_NONE};
    EGLint count=0;assert(eglChooseConfig(display,attrs,&config,1,&count)&&count);
    EGLint size[]={EGL_WIDTH,16,EGL_HEIGHT,16,EGL_NONE};
    surface=eglCreatePbufferSurface(display,config,size);assert(surface!=EGL_NO_SURFACE);createContext();
    Configuration::getInstance()->gatherGPUInfo();
    std::printf("NATIVE_GL\t%s\t%s\t%s\n",glGetString(GL_VENDOR),glGetString(GL_RENDERER),glGetString(GL_VERSION));
    char cwd[4096];assert(getcwd(cwd,sizeof(cwd)));
    auto files=FileUtils::getInstance();
    files->addSearchPath(std::string(cwd)+"/src/engine/cocos2d-x/cocos/scripting/lua-bindings/script");
    files->addSearchPath(std::string(cwd)+"/bin/res/scripts");files->addSearchPath(std::string(cwd)+"/bin/res/assets");
    auto director=Director::getInstance();director->getEventDispatcher()->setEnabled(true);viewport(768,768);
    auto engine=LuaEngine::getInstance();ScriptEngineManager::getInstance()->setScriptEngine(engine);
    auto L=engine->getLuaStack()->getLuaState();
    lua_register(L,"cleanWorldCapture",capture);lua_register(L,"cleanWorldFogOpacity",fogOpacity);lua_register(L,"cleanWorldEnter",enter);
    lua_register(L,"cleanWorldExit",leave);lua_register(L,"cleanWorldDrain",drain);
    lua_register(L,"cleanWorldSampler",sampler);lua_register(L,"cleanWorldBackground",background);
    lua_register(L,"cleanWorldRestore",restore);
    lua_register(L,"liveTextureHash",textureHash);lua_register(L,"liveTextureCounts",textureCounts);lua_register(L,"liveBufferCounts",bufferCounts);lua_register(L,"liveTextureReplace",ordinaryTextureReplacement);lua_register(L,"liveMap2Tick",liveTick);lua_register(L,"liveMap2Scene",liveScene);lua_register(L,"liveMap2Touch",liveTouch);lua_register(L,"liveMap2Gesture",liveGesture);
    if(luaL_dofile(L,argv[1])) { std::fprintf(stderr,"%s\n",lua_tostring(L,-1));return 1; }
    PoolManager::getInstance()->getCurrentPool()->clear();
    std::puts("PASS native clean-world fixture");return 0;
}
