// Real Cocos dispatcher/Lua/GL regression. No game scene or player save is loaded.
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
static int drain(lua_State*) { PoolManager::getInstance()->getCurrentPool()->clear(); return 0; }
static int enter(lua_State* L) { static_cast<Node*>(tolua_tousertype(L,1,nullptr))->onEnter(); return 0; }
static int leave(lua_State* L) { static_cast<Node*>(tolua_tousertype(L,1,nullptr))->onExit(); return 0; }
extern "C" void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause();
static int background(lua_State*) { Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause(); return 0; }
static int restore(lua_State*) {
    assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT));
    assert(eglDestroyContext(display, context));
    createContext();
    GL::invalidateStateCache();
    // Same ordering as Android nativeInit, without pretending to be an Android device.
    ShaderCache::getInstance()->reloadDefaultShaders();
    VolatileTextureMgr::reloadAllTextures();
    EventCustom e(EVENT_COME_TO_FOREGROUND);
    Director::getInstance()->getEventDispatcher()->dispatchEvent(&e);
    return 0;
}
static int linked(lua_State* L) {
    auto p = static_cast<GLProgram*>(tolua_tousertype(L,1,nullptr));
    GLint result=0; glGetProgramiv(p->getProgram(),GL_LINK_STATUS,&result);
    lua_pushboolean(L,result==GL_TRUE); return 1;
}
// Render the production grid program using its actual engine-uploaded PNG,
// texture alpha metadata, and installed native blend factors.
static int gridComposite(lua_State* L) {
    auto layer=static_cast<SpriteBatchNode*>(tolua_tousertype(L,1,nullptr));
    auto program=layer->getShaderProgram();program->use();
    const GLfloat identity[]={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
    glUniformMatrix4fv(program->getUniformLocation("CC_MVPMatrix"),1,GL_FALSE,identity);
    glUniform1i(program->getUniformLocation("CC_Texture0"),0);
    GL::bindTexture2D(layer->getTexture()->getName());
    const GLfloat position[]={-1,-1,1,-1,1,1,-1,-1,1,1,-1,1};
    const GLfloat uv[]={2.0f/64,1.5f/64,0,1.5f/64,0,1.5f/64,2.0f/64,1.5f/64,0,1.5f/64,2.0f/64,1.5f/64};
    glBindBuffer(GL_ARRAY_BUFFER,0);
    glEnableVertexAttribArray(0);glEnableVertexAttribArray(2);glDisableVertexAttribArray(1);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,position);
    glVertexAttribPointer(2,2,GL_FLOAT,GL_FALSE,0,uv);
    glVertexAttrib4f(1,1,1,1,1);
    glBindFramebuffer(GL_FRAMEBUFFER,0);glViewport(0,0,2,2);
    glDisable(GL_DEPTH_TEST);glDisable(GL_STENCIL_TEST);glEnable(GL_BLEND);
    const auto blend=layer->getBlendFunc();glBlendFunc(blend.src,blend.dst);
    glClearColor(20.0f/255,80.0f/255,130.0f/255,1);glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLES,0,6);
    unsigned char pixels[16];glReadPixels(0,0,2,2,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
    const int expected[]={20,80,130,255,29,83,127,255,20,80,130,255,29,83,127,255};
    bool same=true;for(int i=0;i<16;i++)same=same && std::abs(int(pixels[i])-expected[i])<=1;
    if(!same) { for(int i=0;i<16;i++)std::fprintf(stderr,"%u ",pixels[i]);std::fprintf(stderr,"\n"); }
    lua_pushboolean(L,same);return 1;
}
static int premultiplied(lua_State* L) {
    auto node=static_cast<Node*>(tolua_tousertype(L,1,nullptr));
    auto blend=dynamic_cast<BlendProtocol*>(node); assert(blend);
    lua_pushboolean(L,blend->getBlendFunc().src==GL_ONE && blend->getBlendFunc().dst==GL_ONE_MINUS_SRC_ALPHA);return 1;
}
static int fillMask(lua_State* L) {
    auto target=static_cast<RenderTexture*>(tolua_tousertype(L,1,nullptr));
    auto texture=target->getSprite()->getTexture();
    unsigned char pixels[16*16*4];
    for(int i=0;i<16*16;i++) { pixels[i*4]=37;pixels[i*4+1]=91;pixels[i*4+2]=141;pixels[i*4+3]=203; }
    GL::bindTexture2D(texture->getName());
    glTexSubImage2D(GL_TEXTURE_2D,0,0,0,16,16,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
    return 0;
}
static int checkMask(lua_State* L) {
    auto target=static_cast<RenderTexture*>(tolua_tousertype(L,1,nullptr));
    Image* image=target->newImage(false); assert(image);
    auto data=image->getData(); bool same=true;
    for(int i=0;i<16*16;i++) same=same && data[i*4]==37 && data[i*4+1]==91 && data[i*4+2]==141 && data[i*4+3]==203;
    delete image;
    GL::bindTexture2D(target->getSprite()->getTexture()->getName());
    GLint min=0,mag=0;glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&min);glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,&mag);
    lua_pushboolean(L,same && min==GL_LINEAR && mag==GL_LINEAR);return 1;
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
    lua_register(L,"nativeDrain",drain);
    lua_register(L,"nativeEnter",enter); lua_register(L,"nativeExit",leave);
    lua_register(L,"nativeBackground",background); lua_register(L,"nativeRestore",restore);
    lua_register(L,"nativeGridComposite",gridComposite);
    lua_register(L,"nativeLinked",linked);lua_register(L,"nativePremultiplied",premultiplied);
    lua_register(L,"nativeFillMask",fillMask);lua_register(L,"nativeCheckMask",checkMask);
    if(luaL_dofile(L,argv[1])) { std::fprintf(stderr,"%s\n",lua_tostring(L,-1)); return 1; }
    // Force autorelease disposal and a final event to expose dangling callbacks.
    PoolManager::getInstance()->getCurrentPool()->clear();
    EventCustom event(EVENT_COME_TO_FOREGROUND); director->getEventDispatcher()->dispatchEvent(&event);
    std::puts("PASS native Cocos chart lifecycle: real mask pixels/filtering, fog/grid/coast shaders, active/paused context loss, repeat restores, listener cleanup, disposed map/target silence");
    return 0;
}
