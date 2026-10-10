// Synthetic files in a fresh temporary directory only; no game profile access.
#include "AtomicSave.h"
#include <cassert>
#include <fstream>
#include <iterator>
#include <sys/stat.h>
#include <cstdlib>
static std::string read(const std::string& p) {
    std::ifstream f(p.c_str(), std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
}
int main() {
    char pattern[] = "/tmp/pirate-atomic-test-XXXXXX";
    const char* dir = mkdtemp(pattern); assert(dir);
    std::string p = std::string(dir) + "/snapshot";
    assert(pirateAtomicSave(p, "old", 3));
    assert(read(p) == "old");
    assert(pirateAtomicSave(p, "new", 3));
    assert(read(p) == "new");
    assert(access((p+".tmp").c_str(), F_OK) != 0);
    // Temp-open failure: target remains untouched.
    assert(mkdir((p+".tmp").c_str(), 0700) == 0);
    assert(!pirateAtomicSave(p, "lost", 4)); assert(read(p) == "new");
    assert(rmdir((p+".tmp").c_str()) == 0);
    // Write/flush failure with a full synthetic sink; old snapshot survives.
    assert(symlink("/dev/full", (p+".tmp").c_str()) == 0);
    assert(!pirateAtomicSave(p, "lost", 4)); assert(read(p) == "new");
    assert(access((p+".tmp").c_str(), F_OK) != 0);
    // Replacement failure must never remove the destination.
    std::string d = std::string(dir)+"/destination-directory";
    assert(mkdir(d.c_str(),0700)==0);
    assert(!pirateAtomicSave(d,"lost",4));
    struct stat info; assert(stat(d.c_str(),&info)==0 && S_ISDIR(info.st_mode));
    assert(access((d+".tmp").c_str(), F_OK) != 0);
    // Simulate a process stopping after temp write and before rename. A new
    // process still reads the old path; retry safely replaces the stale temp.
    {std::ofstream f((p+".tmp").c_str()); f << "interrupted";}
    assert(read(p)=="new");
    assert(pirateAtomicSave(p,"final",5));assert(read(p)=="final");
    std::remove(p.c_str());rmdir(d.c_str());rmdir(dir);
    std::puts("PASS native atomic replacement, open/write/flush/rename failures, stale-temp restart and retry preserve original snapshot");
}
