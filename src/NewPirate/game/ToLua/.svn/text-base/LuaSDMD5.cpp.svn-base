/*
** Lua binding: TOLUA_MD5
** Generated automatically by tolua++-1.0.92 on Fri Mar 27 12:19:00 2015.
*/

/****************************************************************************
 Copyright (c) 2011 cocos2d-x.org

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

extern "C" {
#include "tolua_fix.h"
}

#include "cocos2d.h"
#include "tolua_fix.h"
#include "LuaBasicConversions.h"



/* Exported function */
TOLUA_API int  tolua_TOLUA_MD5_open (lua_State* tolua_S);

#include "MD5.h"

/* function to release collected object via destructor */
#ifdef __cplusplus

static int tolua_collect_MD5 (lua_State* tolua_S)
{
 MD5* self = (MD5*) tolua_tousertype(tolua_S,1,0);
    Mtolua_delete(self);
    return 0;
}
#endif


/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"MD5");
}

/* method: new of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new00
static int tolua_TOLUA_MD5_MD5_new00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)());
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'new'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: new_local of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new00_local
static int tolua_TOLUA_MD5_MD5_new00_local(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)());
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
    tolua_register_gc(tolua_S,lua_gettop(tolua_S));
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'new'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: new of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new01
static int tolua_TOLUA_MD5_MD5_new01(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const std::string text = ((const std::string)  tolua_tocppstring(tolua_S,2,0));
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)(text));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
   tolua_pushcppstring(tolua_S,(const char*)text);
  }
 }
 return 2;
tolua_lerror:
 return tolua_TOLUA_MD5_MD5_new00(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: new_local of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new01_local
static int tolua_TOLUA_MD5_MD5_new01_local(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const std::string text = ((const std::string)  tolua_tocppstring(tolua_S,2,0));
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)(text));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
    tolua_register_gc(tolua_S,lua_gettop(tolua_S));
   tolua_pushcppstring(tolua_S,(const char*)text);
  }
 }
 return 2;
tolua_lerror:
 return tolua_TOLUA_MD5_MD5_new00_local(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: new of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new02
static int tolua_TOLUA_MD5_MD5_new02(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const char* buf = ((const char*)  tolua_tostring(tolua_S,2,0));
  int length = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)(buf,length));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
  }
 }
 return 1;
tolua_lerror:
 return tolua_TOLUA_MD5_MD5_new01(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: new_local of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_new02_local
static int tolua_TOLUA_MD5_MD5_new02_local(lua_State* tolua_S)
{
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
 {
  const char* buf = ((const char*)  tolua_tostring(tolua_S,2,0));
  int length = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   MD5* tolua_ret = (MD5*)  Mtolua_new((MD5)(buf,length));
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"MD5");
    tolua_register_gc(tolua_S,lua_gettop(tolua_S));
  }
 }
 return 1;
tolua_lerror:
 return tolua_TOLUA_MD5_MD5_new01_local(tolua_S);
}
#endif //#ifndef TOLUA_DISABLE

/* method: finalize of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_finalize00
static int tolua_TOLUA_MD5_MD5_finalize00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"MD5",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  MD5* self = (MD5*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'finalize'", NULL);
#endif
  {
   MD5& tolua_ret = (MD5&)  self->finalize();
    tolua_pushusertype(tolua_S,(void*)&tolua_ret,"MD5");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'finalize'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: hexdigest of class  MD5 */
#ifndef TOLUA_DISABLE_tolua_TOLUA_MD5_MD5_hexdigest00
static int tolua_TOLUA_MD5_MD5_hexdigest00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"const MD5",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const MD5* self = (const MD5*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'hexdigest'", NULL);
#endif
  {
   std::string tolua_ret = (std::string)  self->hexdigest();
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'hexdigest'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_TOLUA_MD5_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  #ifdef __cplusplus
  tolua_cclass(tolua_S,"MD5","MD5","",tolua_collect_MD5);
  #else
  tolua_cclass(tolua_S,"MD5","MD5","",NULL);
  #endif
  tolua_beginmodule(tolua_S,"MD5");
   tolua_function(tolua_S,"new",tolua_TOLUA_MD5_MD5_new00);
   tolua_function(tolua_S,"new_local",tolua_TOLUA_MD5_MD5_new00_local);
   tolua_function(tolua_S,".call",tolua_TOLUA_MD5_MD5_new00_local);
   tolua_function(tolua_S,"new",tolua_TOLUA_MD5_MD5_new01);
   tolua_function(tolua_S,"new_local",tolua_TOLUA_MD5_MD5_new01_local);
   tolua_function(tolua_S,".call",tolua_TOLUA_MD5_MD5_new01_local);
   tolua_function(tolua_S,"new",tolua_TOLUA_MD5_MD5_new02);
   tolua_function(tolua_S,"new_local",tolua_TOLUA_MD5_MD5_new02_local);
   tolua_function(tolua_S,".call",tolua_TOLUA_MD5_MD5_new02_local);
   tolua_function(tolua_S,"finalize",tolua_TOLUA_MD5_MD5_finalize00);
   tolua_function(tolua_S,"hexdigest",tolua_TOLUA_MD5_MD5_hexdigest00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_TOLUA_MD5 (lua_State* tolua_S) {
 return tolua_TOLUA_MD5_open(tolua_S);
};
#endif

