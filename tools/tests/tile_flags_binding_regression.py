#!/usr/bin/env python3
"""Compile the real read-only binding body against a tiny Lua/TMX boundary stub."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'src/engine/cocos2d-x/cocos/scripting/lua-bindings/auto/lua_cocos2dx_auto.cpp').read_text()
start=source.index('int lua_cocos2dx_TMXLayer_getTileFlagsAt(');end=source.index('\nint lua_cocos2dx_TMXLayer_getPositionAt(',start)
body=source[start:end]
assert '"getTileFlagsAt",lua_cocos2dx_TMXLayer_getTileFlagsAt' in source
stub=r'''
#include <cassert>
#include <cstdint>
struct lua_State {};struct tolua_Error {};typedef double lua_Number;
namespace cocos2d {struct Point {float x,y;};enum TMXTileFlags:unsigned {ZERO=0};
struct TMXLayer {unsigned calls=0, expected=0;unsigned getTileGIDAt(Point p,TMXTileFlags* flags){assert(p.x==3&&p.y==7);assert(*flags==0);++calls;*flags=static_cast<TMXTileFlags>(expected);return 94;}};}
cocos2d::TMXLayer tile;bool typeOK=true,pointOK=true;int count=2;double result=-1;
bool tolua_isusertype(lua_State*,int,const char*,int,tolua_Error*){return typeOK;}
void tolua_error(lua_State*,const char*,tolua_Error*){}
void* tolua_tousertype(lua_State*,int,void*){return &tile;}
int lua_gettop(lua_State*){return count;}
bool luaval_to_point(lua_State*,int,cocos2d::Point* p){p->x=3;p->y=7;return pointOK;}
void tolua_pushnumber(lua_State*,lua_Number n){result=n;}
'''
main=r'''
int main(){lua_State state;for(unsigned i=0;i<8;++i){tile.expected=i<<29;assert(lua_cocos2dx_TMXLayer_getTileFlagsAt(&state)==1);assert(result==double(tile.expected));}assert(tile.calls==8);count=3;assert(lua_cocos2dx_TMXLayer_getTileFlagsAt(&state)==0);count=2;pointOK=false;assert(lua_cocos2dx_TMXLayer_getTileFlagsAt(&state)==0);pointOK=true;typeOK=false;assert(lua_cocos2dx_TMXLayer_getTileFlagsAt(&state)==0);assert(tile.calls==8);}
'''
with tempfile.TemporaryDirectory() as d:
 cpp=Path(d)/'flags.cpp';exe=Path(d)/'flags';cpp.write_text(stub+body+main)
 subprocess.run(['c++','-std=c++11',str(cpp),'-o',str(exe)],check=True);subprocess.run([str(exe)],check=True)
print('PASS real TMX flags binding: all 8 flag combinations, initialized output, invalid input no read')
