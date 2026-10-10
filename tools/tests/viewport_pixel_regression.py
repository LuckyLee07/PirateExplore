#!/usr/bin/env python3
"""Compile the production viewport conversion without opening a display."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/engine/cocos2d-x/cocos/2d/platform/CCGLViewProtocol.cpp').read_text()
start = source.index('void GLViewProtocol::setViewPortInPoints(')
end = source.index('\nvoid GLViewProtocol::setScissorInPoints(', start)
body = source[start:end]
desktop_source = (root / 'src/engine/cocos2d-x/cocos/2d/platform/desktop/CCGLView.cpp').read_text()
start = desktop_source.index('void GLView::setViewPortInPoints(')
end = desktop_source.index('\nvoid GLView::setScissorInPoints(', start)
desktop_body = desktop_source[start:end]
harness = r'''
#include <algorithm>
#include <cassert>
#include <cmath>
#include <utility>
using GLint = int;
using GLsizei = int;
static int pixels[4];
void glViewport(int x,int y,int w,int h) {
    pixels[0]=x; pixels[1]=y; pixels[2]=w; pixels[3]=h;
}
struct Point {float x=0,y=0;};
struct Rect {Point origin;};
class GLViewProtocol {
public:
    float _scaleX=1,_scaleY=1;
    Rect _viewPortRect;
    void setViewPortInPoints(float,float,float,float);
};
class GLView : public GLViewProtocol {
public:
    float _retinaFactor=1,_frameZoomFactor=1;
    void setViewPortInPoints(float,float,float,float);
};
void expect(int x,int y,int w,int h) {
    assert(pixels[0]==x && pixels[1]==y && pixels[2]==w && pixels[3]==h);
}
'''
harness += body + desktop_body + r'''
template <typename View> void commonCases() {
    View v;
    // The application's real matching-aspect design-height arithmetic. In the
    // old conversion 480x800 becomes 479x800 and 540x960 becomes 539x960.
    for (auto s : {std::pair<int,int>(480,800),{540,960},{480,900},
                   {320,568},{640,1136},{1080,1920},{1920,1080}}) {
        float width=s.first,height=s.second;
        float designW=640,designH=height*(640/width);
        v._scaleX=v._scaleY=std::min(width/designW,height/designH);
        v._viewPortRect.origin.x=(width-designW*v._scaleX)/2;
        v._viewPortRect.origin.y=(height-designH*v._scaleY)/2;
        v.setViewPortInPoints(0,0,designW,designH);
        expect(0,0,s.first,s.second);
    }
    // Preserve whole-pixel dimensions and positive/negative subview origins.
    v._scaleX=v._scaleY=1;
    v._viewPortRect.origin.x=v._viewPortRect.origin.y=0;
    v.setViewPortInPoints(-32,17,640,960);expect(-32,17,640,960);
    v.setViewPortInPoints(-.5f,.5f,10.5f,20.5f);expect(-1,1,11,21);
    v._scaleX=.8f;v._scaleY=.6f;
    v._viewPortRect.origin.x=.1f;v._viewPortRect.origin.y=-.2f;
    v.setViewPortInPoints(-1.25f,1.25f,100.5f,200.5f);expect(-1,1,80,120);
    // Existing SHOW_ALL letterboxing is retained and only pixel-quantized.
    v._scaleX=v._scaleY=1024.f/960.f;
    v._viewPortRect.origin.x=(768-640*v._scaleX)/2;
    v._viewPortRect.origin.y=0;
    v.setViewPortInPoints(0,0,640,960);expect(43,0,683,1024);
}
int main() {
    commonCases<GLViewProtocol>();
    commonCases<GLView>();
    GLView d;
    d._scaleX=d._scaleY=.74999994f;
    d._retinaFactor=2;d._frameZoomFactor=1;
    d.setViewPortInPoints(0,0,640,1066.66675f);expect(0,0,960,1600);
    d._frameZoomFactor=.5f;
    d.setViewPortInPoints(0,0,640,1066.66675f);expect(0,0,480,800);
    d._scaleX=.8f;d._scaleY=.6f;d._frameZoomFactor=1.25f;
    d._viewPortRect.origin.x=.1f;d._viewPortRect.origin.y=-.2f;
    d.setViewPortInPoints(-1.25f,1.25f,100.5f,200.5f);expect(-2,1,201,301);
}
'''
with tempfile.TemporaryDirectory(prefix='pirate-viewport-') as temp:
    cpp, exe = Path(temp) / 'check.cpp', Path(temp) / 'check'
    cpp.write_text(harness)
    subprocess.run(['c++', '-std=c++11', str(cpp), '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
print('PASS actual base and desktop viewport conversion: complete fractional-aspect windows, nearest-pixel subviews, letterboxing, retina and frame zoom')
