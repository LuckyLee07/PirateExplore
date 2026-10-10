#ifndef PIRATE_ATOMIC_SAVE_H
#define PIRATE_ATOMIC_SAVE_H
#include <cstdio>
#include <string>
#if defined(_WIN32)
#include <windows.h>
#include <io.h>
#else
#include <unistd.h>
#endif

// Same-directory replacement preserves the old snapshot on every failed step.
// A single game thread owns saves; leftover temporary files are never loaded.
inline bool pirateAtomicSave(const std::string& path, const void* bytes, size_t size)
{
    const std::string temporary = path + ".tmp";
    FILE* file = std::fopen(temporary.c_str(), "wb");
    if (!file) return false;
    bool ok = std::fwrite(bytes, 1, size, file) == size;
    if (ok) ok = std::fflush(file) == 0;
#if defined(_WIN32)
    if (ok) ok = _commit(_fileno(file)) == 0;
#else
    if (ok) ok = fsync(fileno(file)) == 0;
#endif
    if (std::fclose(file) != 0) ok = false;
    if (ok) {
#if defined(_WIN32)
        ok = MoveFileExA(temporary.c_str(), path.c_str(),
                        MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
#else
        ok = std::rename(temporary.c_str(), path.c_str()) == 0;
#endif
    }
    if (!ok) std::remove(temporary.c_str());
    return ok;
}
#endif
