/*
 ** Lua binding: TOLUA_GameBaseUtil
 ** Generated automatically by tolua++-1.0.92 on Tue Apr 28 15:48:55 2015.
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
#include "TOLUA_GameBaseUtil.h"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"Animate");
}

/* function: getonlyID */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_getonlyID00
static int tolua_TOLUA_GameBaseUtil_getonlyID00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isnoobj(tolua_S,1,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  {
   std::string tolua_ret = (std::string)  getonlyID();
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getonlyID'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: openUrlFunc */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_openUrlFunc00
static int tolua_TOLUA_GameBaseUtil_openUrlFunc00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isstring(tolua_S,1,0,&tolua_err) ||
	 !tolua_isnoobj(tolua_S,2,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  const char* url = ((const char*)  tolua_tostring(tolua_S,1,0));
  {
   openUrlFunc(url);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'openUrlFunc'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: addSpriteToFrameCache */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_addSpriteToFrameCache00
static int tolua_TOLUA_GameBaseUtil_addSpriteToFrameCache00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isstring(tolua_S,1,0,&tolua_err) ||
	 !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
	 !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
	 !tolua_isnoobj(tolua_S,4,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  const char* fileName = ((const char*)  tolua_tostring(tolua_S,1,0));
  int startNumber = ((int)  tolua_tonumber(tolua_S,2,0));
  int endNumber = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   addSpriteToFrameCache(fileName,startNumber,endNumber);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'addSpriteToFrameCache'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: getAnimate */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_getAnimate00
static int tolua_TOLUA_GameBaseUtil_getAnimate00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isstring(tolua_S,1,0,&tolua_err) ||
	 !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
	 !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
	 !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
	 !tolua_isnoobj(tolua_S,5,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  const char* fileName = ((const char*)  tolua_tostring(tolua_S,1,0));
  int startNumber = ((int)  tolua_tonumber(tolua_S,2,0));
  int endNumber = ((int)  tolua_tonumber(tolua_S,3,0));
  float duration = ((float)  tolua_tonumber(tolua_S,4,0));
  {
   Animate* tolua_ret = (Animate*)  getAnimate(fileName,startNumber,endNumber,duration);
	  tolua_pushusertype(tolua_S,(void*)tolua_ret,"Animate");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getAnimate'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: purchase */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_purchase00
static int tolua_TOLUA_GameBaseUtil_purchase00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isstring(tolua_S,1,0,&tolua_err) ||
	 !tolua_isnoobj(tolua_S,2,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  const char* parm = ((const char*)  tolua_tostring(tolua_S,1,0));
  {
   purchase(parm);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'purchase'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: decodeExKey */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_decodeExKey00
static int tolua_TOLUA_GameBaseUtil_decodeExKey00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        const char* parm = ((const char*)  tolua_tostring(tolua_S,1,0));
        {
            bool tolua_ret = decodeExKey(parm);
            tolua_pushboolean(tolua_S, (bool)tolua_ret);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'decodeExKey'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: getEnableInterface */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_getEnableInterface00
static int tolua_TOLUA_GameBaseUtil_getEnableInterface00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isnoobj(tolua_S,1,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  {
   std::string tolua_ret = (std::string)  getEnableInterface();
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getEnableInterface'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: showMoreGameCallback */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_showMoreGameCallback00
static int tolua_TOLUA_GameBaseUtil_showMoreGameCallback00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
	 !tolua_isnoobj(tolua_S,1,&tolua_err)
	 )
  goto tolua_lerror;
 else
#endif
 {
  {
   showMoreGameCallback();
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'showMoreGameCallback'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: rateIniTunes */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_rateIniTunes00
static int tolua_TOLUA_GameBaseUtil_rateIniTunes00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        {
            rateIniTunes();
        }
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'rateIniTunes'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: showRateOrAdScene */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_showRateOrAdScene00
static int tolua_TOLUA_GameBaseUtil_showRateOrAdScene00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        {
            showRateOrAdScene();
        }
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'showRateOrAdScene'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: playV2Sound */
#ifndef TOLUA_DISABLE_tolua_TOLUA_GameBaseUtil_playV2Sound00
static int tolua_TOLUA_GameBaseUtil_playV2Sound00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
     )
  goto tolua_lerror;
 else
#endif
 {
  const char* relativePath = ((const char*) tolua_tostring(tolua_S,1,0));
  float volume = ((float) tolua_tonumber(tolua_S,2,1.0));
  int loop = ((int) tolua_tonumber(tolua_S,3,0));
  {
   bool tolua_ret = playV2Sound(relativePath, volume, loop);
   tolua_pushboolean(tolua_S, (bool) tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'playV2Sound'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_TOLUA_GameBaseUtil_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
	tolua_function(tolua_S,"getonlyID",tolua_TOLUA_GameBaseUtil_getonlyID00);
	tolua_function(tolua_S,"openUrlFunc",tolua_TOLUA_GameBaseUtil_openUrlFunc00);
	tolua_function(tolua_S,"addSpriteToFrameCache",tolua_TOLUA_GameBaseUtil_addSpriteToFrameCache00);
	tolua_function(tolua_S,"getAnimate",tolua_TOLUA_GameBaseUtil_getAnimate00);
	tolua_function(tolua_S,"purchase",tolua_TOLUA_GameBaseUtil_purchase00);
    tolua_function(tolua_S,"decodeExKey",tolua_TOLUA_GameBaseUtil_decodeExKey00);
	tolua_function(tolua_S,"getEnableInterface",tolua_TOLUA_GameBaseUtil_getEnableInterface00);
	tolua_function(tolua_S,"showMoreGameCallback",tolua_TOLUA_GameBaseUtil_showMoreGameCallback00);
    tolua_function(tolua_S,"rateIniTunes",tolua_TOLUA_GameBaseUtil_rateIniTunes00);
    tolua_function(tolua_S,"showRateOrAdScene",tolua_TOLUA_GameBaseUtil_showRateOrAdScene00);
    tolua_function(tolua_S,"playV2Sound",tolua_TOLUA_GameBaseUtil_playV2Sound00);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
TOLUA_API int luaopen_TOLUA_GameBaseUtil (lua_State* tolua_S) {
 return tolua_TOLUA_GameBaseUtil_open(tolua_S);
};
#endif
