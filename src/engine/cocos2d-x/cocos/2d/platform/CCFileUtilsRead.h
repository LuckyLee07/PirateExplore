/****************************************************************************
 Copyright (c) 2026 NewPirate contributors

 Small, dependency-free file reader used by CCFileUtils and its sanitizer
 regression. It intentionally lives in the platform layer so the production
 read path and the test exercise the same implementation.
 ****************************************************************************/

#ifndef __CC_FILEUTILS_READ_H__
#define __CC_FILEUTILS_READ_H__

#include <cstdio>
#include <cstdlib>
#include <limits>
#include <string>

namespace cocos2d
{
namespace fileutils_detail
{

typedef void* (*FileAllocator)(std::size_t);

inline bool readFile(const std::string& path,
                     const char* mode,
                     bool nullTerminate,
                     std::size_t maximumSize,
                     unsigned char** output,
                     std::size_t* outputSize,
                     FileAllocator allocator = std::malloc)
{
    if (output == nullptr || outputSize == nullptr)
    {
        return false;
    }

    *output = nullptr;
    *outputSize = 0;

    if (path.empty() || mode == nullptr || allocator == nullptr)
    {
        return false;
    }

    std::FILE* file = std::fopen(path.c_str(), mode);
    if (file == nullptr)
    {
        return false;
    }

    bool succeeded = false;
    unsigned char* buffer = nullptr;

    do
    {
        if (std::fseek(file, 0, SEEK_END) != 0)
        {
            break;
        }

        const long endPosition = std::ftell(file);
        if (endPosition < 0 || std::fseek(file, 0, SEEK_SET) != 0)
        {
            break;
        }

        const std::size_t fileSize = static_cast<std::size_t>(endPosition);
        const std::size_t terminatorSize = nullTerminate ? 1u : 0u;
        if (fileSize > maximumSize ||
            fileSize > std::numeric_limits<std::size_t>::max() - terminatorSize)
        {
            break;
        }

        // An empty file is a valid empty result. Avoid malloc(0), and leave
        // output as nullptr so callers cannot accidentally leak its result.
        if (fileSize == 0)
        {
            succeeded = true;
            break;
        }

        buffer = static_cast<unsigned char*>(allocator(fileSize + terminatorSize));
        if (buffer == nullptr)
        {
            break;
        }

        // A seekable regular file must still contain the measured byte count.
        // A short read means the file changed or the stream failed; never hand
        // a partially initialized allocation to the caller.
        if (std::fread(buffer, 1, fileSize, file) != fileSize)
        {
            break;
        }

        if (nullTerminate)
        {
            buffer[fileSize] = '\0';
        }

        *output = buffer;
        *outputSize = fileSize;
        buffer = nullptr;
        succeeded = true;
    } while (false);

    std::free(buffer);
    std::fclose(file);
    return succeeded;
}

} // namespace fileutils_detail
} // namespace cocos2d

#endif // __CC_FILEUTILS_READ_H__
