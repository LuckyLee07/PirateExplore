// Real Record encoder/decoder and Lua binding. No scene, GUI, or existing save.
#include "Record.h"
// The runner compiles the checked-in baseline source and pinned header under
// this second class name to prove both directions of the on-disk format contract.
#undef _RECORD_H_
#define Record LegacyRecord
#include "fixtures/legacy_record/Record.h"
#undef Record
#include "ToLua/TOLUA_LuaRecord.h"
#include "tolua_fix.h"
extern "C" {
#include "lauxlib.h"
#include "lualib.h"
}
#include <cassert>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include <iterator>
static std::string bytes(const std::string& p) {
    std::ifstream f(p.c_str(),std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(f),std::istreambuf_iterator<char>());
}
int main() {
    assert(getenv("XDG_CONFIG_HOME")); // Runner supplies a fresh temporary root.
    const std::string path=cocos2d::FileUtils::getInstance()->getWritablePath();
    char name[]="synthetic-record";
    std::string original="{\"fixture\":\""+std::string(300,'A')+"\",\"money\":4,\"wall\":1000}";
    std::string next="{\"fixture\":\""+std::string(300,'B')+"\",\"money\":7,\"wall\":1060}";
    Record* r=Record::GetInstance();
    LegacyRecord legacy;
    char legacyName[]="legacy-native";
    legacy.saveData(const_cast<char*>(original.c_str()),legacyName);
    assert(original==r->loadData(legacyName));
    const std::string legacyBytes=bytes(path+legacyName);
    assert(r->saveDataAtomic(const_cast<char*>(original.c_str()),name));
    assert(legacyBytes==bytes(path+name));
    assert(r->saveDataAtomic(const_cast<char*>(next.c_str()),legacyName));
    LegacyRecord legacyCold;assert(next==legacyCold.loadData(legacyName));
    assert(r->saveDataAtomic(const_cast<char*>(original.c_str()),name));
    assert(original==r->loadData(name));
    const std::string oldBytes=bytes(path+name);
    assert(mkdir((path+name+".tmp").c_str(),0700)==0);
    assert(!r->saveDataAtomic(const_cast<char*>(next.c_str()),name));
    assert(oldBytes==bytes(path+name));assert(original==r->loadData(name));
    assert(rmdir((path+name+".tmp").c_str())==0);
    assert(r->saveDataAtomic(const_cast<char*>(next.c_str()),name));
    assert(next==r->loadData(name));
    // Tiny/incompressible input used to overrun the legacy output allocation.
    char shortName[]="tiny"; char tiny[]="Z";
    assert(r->saveDataAtomic(tiny,shortName));assert(std::string(r->loadData(shortName))=="Z");
    // Simulate a cold decode with a distinct Record object, bypassing its cache.
    Record cold;assert(next==cold.loadData(name));
    lua_State* L=luaL_newstate();luaL_openlibs(L);toluafix_open(L);tolua_TOLUA_LuaRecord_open(L);
    lua_pushlstring(L,original.data(),original.size());lua_setglobal(L,"fixture");
    assert(luaL_dostring(L,"assert(Record:GetInstance():saveDataAtomic(fixture,'lua-record')==true); assert(Record:GetInstance():loadData('lua-record')==fixture)")==0);
    assert(mkdir((path+"lua-record.tmp").c_str(),0700)==0);
    assert(luaL_dostring(L,"assert(Record:GetInstance():saveDataAtomic(fixture,'lua-record')==false); assert(Record:GetInstance():loadData('lua-record')==fixture)")==0);
    rmdir((path+"lua-record.tmp").c_str());
    assert(luaL_dostring(L,"Record:GetInstance():saveData(fixture,'legacy-void'); assert(Record:GetInstance():loadData('legacy-void')==fixture)")==0);
    lua_close(L);
    puts("PASS actual Record encode/atomic/decode/cold-reader, failed save preserves existing bytes, real Lua bool binding, baseline byte equality and both-direction legacy format compatibility");
}
