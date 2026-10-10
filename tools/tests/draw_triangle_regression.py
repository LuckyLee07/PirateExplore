#!/usr/bin/env python3
"""Compile the actual DrawNode::drawTriangle body with minimal buffer types.

This detects vertex-count/buffer-initialization regressions independently of
Lua mocks. Native GUI acceptance remains necessary for actual GL rendering.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/engine/cocos2d-x/cocos/2d/CCDrawNode.cpp').read_text()
start = source.index('void DrawNode::drawTriangle(')
brace = source.index('{', start)
depth = 1
end = brace + 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
body = source[start:end]
harness = r'''
#include <cassert>
#include <cmath>
struct Point {float x,y;};
struct Color4F {float r,g,b,a;};
struct Color4B {float r,g,b,a; Color4B(Color4F c):r(c.r),g(c.g),b(c.b),a(c.a) {}};
struct Vertex2F {float x,y; Vertex2F(float a,float b):x(a),y(b) {}};
struct Tex2F {float x,y; Tex2F(float a,float b):x(a),y(b) {}};
struct V2F_C4B_T2F {Vertex2F vertices;Color4B colors;Tex2F texCoords;};
struct V2F_C4B_T2F_Triangle {V2F_C4B_T2F a,b,c;};
class DrawNode {
public:
    V2F_C4B_T2F storage[1024]; V2F_C4B_T2F* _buffer=storage;
    unsigned _bufferCount=0; bool _dirty=false;
    DrawNode(): storage{} {}
    void ensureCapacity(unsigned n) {assert(_bufferCount+n<=1024);}
    void drawTriangle(const Point&,const Point&,const Point&,const Color4F&);
};
'''
# Aggregate elements need default constructors for the sentinel backing buffer.
harness = harness.replace('Color4B(Color4F', 'Color4B():r(-99),g(-99),b(-99),a(-99) {} Color4B(Color4F')
harness = harness.replace('Vertex2F(float', 'Vertex2F():x(-99),y(-99) {} Vertex2F(float')
harness = harness.replace('Tex2F(float', 'Tex2F():x(-99),y(-99) {} Tex2F(float')
harness += '\n' + body + r'''
int main() {
    DrawNode d;
    for(int i=0;i<100;i++) {
        const Point a={float(i),1},b={float(i)+.5f,2},c={float(i)+1,1};
        d.drawTriangle(a,b,c,{.9f,.8f,.6f,1});
        assert(d._bufferCount==unsigned((i+1)*3));
        assert(d._buffer[i*3].vertices.x==a.x);
        assert(d._buffer[i*3+1].vertices.x==b.x);
        assert(d._buffer[i*3+2].vertices.x==c.x);
        assert(d._buffer[d._bufferCount].vertices.x==-99);
        assert(d._dirty);
    }
    for(unsigned i=0;i<d._bufferCount;i++) {
        assert(std::isfinite(d._buffer[i].vertices.x));
        assert(d._buffer[i].colors.a==1);
    }
}
'''
with tempfile.TemporaryDirectory(prefix='pirate-draw-triangle-') as temp:
    cpp = Path(temp) / 'check.cpp'
    exe = Path(temp) / 'check'
    cpp.write_text(harness)
    subprocess.run(['c++', '-std=c++11', str(cpp), '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
print('PASS actual DrawNode::drawTriangle: 100 repeated calls submit exactly 300 initialized vertices')
