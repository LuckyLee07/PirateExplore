// World selector native pixels and real GLView dispatch, without a desktop.
#define main coherent_loot_harness_main
#include "coherent_loot_pages_render.cpp"
#undef main
static void frames() {for(int i=0;i<4;++i){usleep(4000);Director::getInstance()->mainLoop();}}
static int enter(lua_State* L) {
 auto scene=static_cast<Scene*>(tolua_tousertype(L,1,nullptr));
 auto director=Director::getInstance();auto view=new OffscreenView(lua_tonumber(L,2),lua_tonumber(L,3));
 director->setOpenGLView(view);view->release();director->setProjection(Director::Projection::_2D);
 if(director->getRunningScene()!=scene) {
  if(director->getRunningScene())director->replaceScene(scene);else director->runWithScene(scene);
 }
 frames();assert(scene->isRunning());return 0;
}
static int step(lua_State* L){ int count=lua_tointeger(L,1); for(int i=0;i<count;++i){usleep(10000); Director::getInstance()->mainLoop();} return 0;}
static int tap(lua_State* L) {
 auto director=Director::getInstance();auto p=director->convertToUI(Point(lua_tonumber(L,1),lua_tonumber(L,2)));
 auto view=director->getOpenGLView();intptr_t id=7421;float x=p.x,y=p.y;
 view->handleTouchesBegin(1,&id,&x,&y);view->handleTouchesEnd(1,&id,&x,&y);frames();return 0;
}
static int eventGesture(lua_State* L) {
 auto director=Director::getInstance();auto p=director->convertToUI(Point(lua_tonumber(L,2),lua_tonumber(L,3)));
 auto view=director->getOpenGLView();intptr_t id=8241;float x=p.x,y=p.y;
 int phase=lua_tointeger(L,1);
 if(phase==0)view->handleTouchesBegin(1,&id,&x,&y);
 else if(phase==1)view->handleTouchesMove(1,&id,&x,&y);
 else if(phase==2)view->handleTouchesEnd(1,&id,&x,&y);
 else view->handleTouchesCancel(1,&id,&x,&y);
 return 0;
}
int main(int argc,char**argv) {
 assert(argc==2);TestApplication app;
 auto getDisplay=reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));assert(getDisplay);
 display=getDisplay(EGL_PLATFORM_SURFACELESS_MESA,EGL_DEFAULT_DISPLAY,nullptr);assert(eglInitialize(display,nullptr,nullptr));assert(eglBindAPI(EGL_OPENGL_API));
 EGLint attrs[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_BIT,EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};EGLint count;
 assert(eglChooseConfig(display,attrs,&config,1,&count)&&count);EGLint size[]={EGL_WIDTH,720,EGL_HEIGHT,1280,EGL_NONE};surface=eglCreatePbufferSurface(display,config,size);assert(surface!=EGL_NO_SURFACE);createContext();
 Configuration::getInstance()->gatherGPUInfo();char cwd[4096];assert(getcwd(cwd,sizeof(cwd)));
 for(auto path:{"/src/engine/cocos2d-x/cocos/scripting/lua-bindings/script","/bin/res/scripts","/bin/res/assets"})FileUtils::getInstance()->addSearchPath(std::string(cwd)+path);
 auto engine=LuaEngine::getInstance();ScriptEngineManager::getInstance()->setScriptEngine(engine);auto L=engine->getLuaStack()->getLuaState();
 lua_register(L,"coherentWorldStep",step);lua_register(L,"coherentEventEnter",enter);lua_register(L,"coherentEventGesture",eventGesture);
 lua_register(L,"coherentCapture",capture);lua_register(L,"coherentDescriptionDrag",dispatchDescriptionDrag);
 if(luaL_dofile(L,argv[1])){fprintf(stderr,"%s\n",lua_tostring(L,-1));return 1;}return 0;
}
