// Real original main -> Update -> controller startup, observed after each frame.
// No window, no injected game state, no custom Lua bootstrap or timer changes.
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "AppDelegate.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <cassert>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include <vector>
#include <chrono>
using namespace cocos2d;
class OpeningView : public GLView {
 public:
  OpeningView(int w,int h){GLViewProtocol::setFrameSize(w,h);}
  bool isOpenGLReady() override{return true;}
  void end() override{}
  void swapBuffers() override{glFinish();}
  void pollInputEvents() override{}
  void setIMEKeyboardState(bool) override{}
  void setFrameSize(float w,float h) override{GLViewProtocol::setFrameSize(w,h);}
  void setViewPortInPoints(float x,float y,float w,float h) override{GLViewProtocol::setViewPortInPoints(x,y,w,h);}
  void setScissorInPoints(float x,float y,float w,float h) override{GLViewProtocol::setScissorInPoints(x,y,w,h);}
};
static MenuItem* nextButton(Node* node){
 if(auto item=dynamic_cast<MenuItem*>(node))return item;
 for(auto child:node->getChildren())if(auto item=nextButton(child))return item;
 return nullptr;
}
static void capture(int w,int h,const std::string& path){
 std::vector<unsigned char> raw(w*h*4),flipped(w*h*4);glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,raw.data());
 for(int y=0;y<h;++y)std::memcpy(flipped.data()+y*w*4,raw.data()+(h-y-1)*w*4,w*4);
 Image image;assert(image.initWithRawData(flipped.data(),flipped.size(),w,h,8));assert(image.saveToFile(path));
 printf("CAPTURE %s\n",path.c_str());fflush(nullptr);
}
int main(int argc,char**argv){
 assert(argc==5);int w=atoi(argv[1]),h=atoi(argv[2]);std::string output=argv[3];AppDelegate app;
 auto getDisplay=reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));assert(getDisplay);
 auto display=getDisplay(EGL_PLATFORM_SURFACELESS_MESA,EGL_DEFAULT_DISPLAY,nullptr);assert(eglInitialize(display,nullptr,nullptr));assert(eglBindAPI(EGL_OPENGL_API));
 EGLint attrs[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_BIT,EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};EGLConfig config;EGLint count=0;assert(eglChooseConfig(display,attrs,&config,1,&count)&&count);
 EGLint size[]={EGL_WIDTH,w,EGL_HEIGHT,h,EGL_NONE};auto surface=eglCreatePbufferSurface(display,config,size);assert(surface!=EGL_NO_SURFACE);auto context=eglCreateContext(display,config,EGL_NO_CONTEXT,nullptr);assert(context!=EGL_NO_CONTEXT);assert(eglMakeCurrent(display,surface,surface,context));glewInit();assert(glCreateShader&&glCreateProgram);
 Configuration::getInstance()->gatherGPUInfo();auto director=Director::getInstance();director->setOpenGLView(new OpeningView(w,h));
 FileUtils::getInstance()->addSearchPath(argv[4]);app.applicationDidFinishLaunching();
 auto state=LuaEngine::getInstance()->getLuaStack()->getLuaState();int previous=0,captured=0,seen=0,completeTextFrame=-1;bool skipRequested=getenv("OPENING_STORY_SKIP")!=nullptr,skipped=false;auto entered=std::chrono::steady_clock::now();
 for(int frame=0;frame<4800;++frame){
  usleep(16667);director->mainLoop();
  int top=lua_gettop(state);assert(luaL_dostring(state,
   "local s=cc.Director:getInstance():getRunningScene(); local id=s and s.plotArray and s.plotArray[1] or 0; "
   "local expected,seen={},{};local total=0; if id>0 then for _,r in ipairs(s.plots[1].story)do expected[r[1]]=true;total=total+1 end end; "
   "local function visit(n) if n.getString and expected[n:getString()]then seen[n:getString()]=true end;for _,c in ipairs(n:getChildren())do visit(c)end end; "
   "if id>0 then visit(s)end;local count=0;for _ in pairs(seen)do count=count+1 end;return id,total,count")==0);
  int id=lua_tointeger(state,-3),expected=lua_tointeger(state,-2),visible=lua_tointeger(state,-1);lua_settop(state,top);
  if(id!=previous){printf("SCENE %d frame %d\n",id,frame);fflush(nullptr);if(id>0){assert(id==seen+1);seen=id;}previous=id;completeTextFrame=-1;entered=std::chrono::steady_clock::now();}
  double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-entered).count();
  if(id==1&&skipRequested&&!skipped&&seconds>1.1){
   capture(w,h,output+"/scene-1.png");captured=1;auto item=nextButton(director->getRunningScene());assert(item);
   item->activate();item->activate();skipped=true;puts("INPUT native Next twice; expect one scene advance");fflush(nullptr);
  }
  if(id>0&&visible==expected&&expected>0&&completeTextFrame<0)completeTextFrame=frame;
  if(id>0&&captured<id&&completeTextFrame>=0&&frame>completeTextFrame){capture(w,h,output+"/scene-"+std::to_string(id)+".png");captured=id;printf("SUBTITLES %d/%d scene %d\n",visible,expected,id);fflush(nullptr);}
  if(id==0&&seen==7&&seconds>2){capture(w,h,output+"/home.png");assert(captured==7);printf("PASS original startup all seven story frames -> Home; physical %dx%d, logical %.0fx%.0f\n",w,h,director->getVisibleSize().width,director->getVisibleSize().height);fflush(nullptr);_exit(0);}
 }
 fprintf(stderr,"FAIL opening did not reach Home; seen %d captured %d\n",seen,captured);return 1;
}
