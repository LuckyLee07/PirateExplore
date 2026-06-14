/*
 ** Lua binding: TOLUA_LuaRecord
 ** Generated automatically by tolua++-1.0.92 on 01/20/15 15:42:39.
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


#include "TOLUA_LuaRecord.h"
#include "cocos2d.h"
#include "SimpleAudioEngine.h"
#include "tolua_fix.h"
#include "LuaBasicConversions.h"



/* function to release collected object via destructor */
#ifdef __cplusplus

static int tolua_collect_Record (lua_State* tolua_S)
{
    Record* self = (Record*) tolua_tousertype(tolua_S,1,0);
    Mtolua_delete(self);
    return 0;
}
#endif


/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"Record");
    tolua_usertype(tolua_S,"Ref");
}

/* method: new of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_new00
static int tolua_TOLUA_LuaRecord_Record_new00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertable(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        {
            Record* tolua_ret = (Record*)  Mtolua_new((Record)());
            int nID = (tolua_ret) ? (int)tolua_ret->_ID : -1;
            int* pLuaID = (tolua_ret) ? &tolua_ret->_luaID : NULL;
            toluafix_pushusertype_ccobject(tolua_S, nID, pLuaID, (void*)tolua_ret,"Record");
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

/* method: new_local of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_new00_local
static int tolua_TOLUA_LuaRecord_Record_new00_local(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertable(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        {
            Record* tolua_ret = (Record*)  Mtolua_new((Record)());
            int nID = (tolua_ret) ? (int)tolua_ret->_ID : -1;
            int* pLuaID = (tolua_ret) ? &tolua_ret->_luaID : NULL;
            toluafix_pushusertype_ccobject(tolua_S, nID, pLuaID, (void*)tolua_ret,"Record");
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

/* method: delete of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_delete00
static int tolua_TOLUA_LuaRecord_Record_delete00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'delete'", NULL);
#endif
        Mtolua_delete(self);
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'delete'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: GetInstance of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_GetInstance00
static int tolua_TOLUA_LuaRecord_Record_GetInstance00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertable(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        {
            Record* tolua_ret = (Record*)  Record::GetInstance();
            int nID = (tolua_ret) ? (int)tolua_ret->_ID : -1;
            int* pLuaID = (tolua_ret) ? &tolua_ret->_luaID : NULL;
            toluafix_pushusertype_ccobject(tolua_S, nID, pLuaID, (void*)tolua_ret,"Record");
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'GetInstance'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: saveData of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_saveData00
static int tolua_TOLUA_LuaRecord_Record_saveData00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isstring(tolua_S,2,0,&tolua_err) ||
        !tolua_isstring(tolua_S,3,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,4,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
        char* buff = ((char*)  tolua_tostring(tolua_S,2,0));
        char* fileName = ((char*)  tolua_tostring(tolua_S,3,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'saveData'", NULL);
#endif
        {
            self->saveData(buff,fileName);
        }
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'saveData'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: loadData of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_loadData00
static int tolua_TOLUA_LuaRecord_Record_loadData00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isstring(tolua_S,2,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,3,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
        const char* fileName = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'loadData'", NULL);
#endif
        {
            const char* tolua_ret = (const char*)  self->loadData(fileName);
            tolua_pushstring(tolua_S,(const char*)tolua_ret);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'loadData'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: loadDataFromPackage of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_loadDataFromPackage00
static int tolua_TOLUA_LuaRecord_Record_loadDataFromPackage00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
	tolua_Error tolua_err;
	if (
		!tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
		!tolua_isstring(tolua_S,2,0,&tolua_err) ||
		!tolua_isnoobj(tolua_S,3,&tolua_err)
		)
		goto tolua_lerror;
	else
#endif
	{
		Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
		const char* fileName = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
		if (!self) tolua_error(tolua_S,"invalid 'self' in function 'loadDataFromPackage'", NULL);
#endif
		{
			const char* tolua_ret = (const char*)  self->loadDataFromPackage(fileName);
			tolua_pushstring(tolua_S,(const char*)tolua_ret);
		}
	}
	return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
	tolua_error(tolua_S,"#ferror in function 'loadDataFromPackage'.",&tolua_err);
	return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: deleteBuf of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_deleteBuf00
static int tolua_TOLUA_LuaRecord_Record_deleteBuf00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isstring(tolua_S,2,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,3,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
        const char* key = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'deleteBuf'", NULL);
#endif
        {
            bool tolua_ret = (bool)  self->deleteBuf(key);
            tolua_pushboolean(tolua_S,(bool)tolua_ret);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'deleteBuf'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: writeData of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_writeData00
static int tolua_TOLUA_LuaRecord_Record_writeData00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isstring(tolua_S,2,0,&tolua_err) ||
        !tolua_isstring(tolua_S,3,0,&tolua_err) ||
        !tolua_isstring(tolua_S,4,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,5,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
        const char* path = ((const char*)  tolua_tostring(tolua_S,2,0));
        const char* fileName = ((const char*)  tolua_tostring(tolua_S,3,0));
        const char* buf = ((const char*)  tolua_tostring(tolua_S,4,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'writeData'", NULL);
#endif
        {
            bool tolua_ret = (bool)  self->writeData(path,fileName,buf);
            tolua_pushboolean(tolua_S,(bool)tolua_ret);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'writeData'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: loadRecourcesCSV of class  Record */
#ifndef TOLUA_DISABLE_tolua_TOLUA_LuaRecord_Record_loadRecourcesCSV00
static int tolua_TOLUA_LuaRecord_Record_loadRecourcesCSV00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S,1,"Record",0,&tolua_err) ||
        !tolua_isstring(tolua_S,2,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,3,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        Record* self = (Record*)  tolua_tousertype(tolua_S,1,0);
        const char* fileName = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'loadRecourcesCSV'", NULL);
#endif
        {
            self->loadRecourcesCSV(fileName);
        }
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'loadRecourcesCSV'.",&tolua_err);
    return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE
/* Open function */
TOLUA_API int tolua_TOLUA_LuaRecord_open (lua_State* tolua_S)
{
    tolua_open(tolua_S);
    tolua_reg_types(tolua_S);
    tolua_module(tolua_S,NULL,0);
    tolua_beginmodule(tolua_S,NULL);
#ifdef __cplusplus
    tolua_cclass(tolua_S,"Record","Record","Ref",tolua_collect_Record);
#else
    tolua_cclass(tolua_S,"Record","Record","Ref",NULL);
#endif
    tolua_beginmodule(tolua_S,"Record");
    tolua_function(tolua_S,"new",tolua_TOLUA_LuaRecord_Record_new00);
    tolua_function(tolua_S,"new_local",tolua_TOLUA_LuaRecord_Record_new00_local);
    tolua_function(tolua_S,".call",tolua_TOLUA_LuaRecord_Record_new00_local);
    tolua_function(tolua_S,"delete",tolua_TOLUA_LuaRecord_Record_delete00);
    tolua_function(tolua_S,"GetInstance",tolua_TOLUA_LuaRecord_Record_GetInstance00);
    tolua_function(tolua_S,"saveData",tolua_TOLUA_LuaRecord_Record_saveData00);
    tolua_function(tolua_S,"loadData",tolua_TOLUA_LuaRecord_Record_loadData00);
	tolua_function(tolua_S,"loadDataFromPackage", tolua_TOLUA_LuaRecord_Record_loadDataFromPackage00);
    tolua_function(tolua_S,"deleteBuf",tolua_TOLUA_LuaRecord_Record_deleteBuf00);
    tolua_function(tolua_S,"writeData",tolua_TOLUA_LuaRecord_Record_writeData00);
    tolua_function(tolua_S,"loadRecourcesCSV",tolua_TOLUA_LuaRecord_Record_loadRecourcesCSV00);
    tolua_endmodule(tolua_S);
    tolua_endmodule(tolua_S);
    return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
TOLUA_API int luaopen_TOLUA_LuaRecord (lua_State* tolua_S) {
    return tolua_TOLUA_LuaRecord_open(tolua_S);
};
#endif

