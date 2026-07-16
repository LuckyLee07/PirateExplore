#include "CCFileUtilsRead.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unistd.h>

namespace
{
void expect(bool condition, const char* message)
{
    if (!condition)
    {
        std::fprintf(stderr, "FileUtils read test failed: %s\n", message);
        std::exit(1);
    }
}

void* failAllocation(std::size_t)
{
    return nullptr;
}

void writeFixture(const std::string& path, const unsigned char* bytes, std::size_t size)
{
    std::FILE* file = std::fopen(path.c_str(), "wb");
    expect(file != nullptr, "fixture must open for writing");
    expect(size == 0 || std::fwrite(bytes, 1, size, file) == size,
           "fixture bytes must be written");
    expect(std::fclose(file) == 0, "fixture must close");
}
}

int main()
{
    char directoryTemplate[] = "/tmp/newpirate-fileutils.XXXXXX";
    char* directory = mkdtemp(directoryTemplate);
    expect(directory != nullptr, "temporary directory must be created");

    const std::string root(directory);
    const std::string emptyPath = root + "/empty";
    const std::string textPath = root + "/text";
    const std::string binaryPath = root + "/binary";
    const std::string missingPath = root + "/missing";

    writeFixture(emptyPath, nullptr, 0);
    const unsigned char text[] = {'p', 'i', 'r', 'a', 't', 'e', '\n'};
    writeFixture(textPath, text, sizeof(text));
    const unsigned char binary[] = {0u, 1u, 0xffu, 42u};
    writeFixture(binaryPath, binary, sizeof(binary));

    unsigned char sentinel = 0;
    unsigned char* output = &sentinel;
    std::size_t outputSize = 99;
    expect(cocos2d::fileutils_detail::readFile(emptyPath,
                                               "rb",
                                               false,
                                               1024,
                                               &output,
                                               &outputSize),
           "empty file must be a valid empty result");
    expect(output == nullptr && outputSize == 0,
           "empty file must not create a malloc(0) ownership ambiguity");

    expect(cocos2d::fileutils_detail::readFile(textPath,
                                               "rb",
                                               true,
                                               1024,
                                               &output,
                                               &outputSize),
           "text file must be readable");
    expect(outputSize == sizeof(text), "text size must be exact");
    expect(std::memcmp(output, text, sizeof(text)) == 0, "text bytes must match");
    expect(output[outputSize] == '\0', "text result must be null terminated");
    std::free(output);

    expect(cocos2d::fileutils_detail::readFile(binaryPath,
                                               "rb",
                                               false,
                                               1024,
                                               &output,
                                               &outputSize),
           "binary file must be readable");
    expect(outputSize == sizeof(binary), "binary size must be exact");
    expect(std::memcmp(output, binary, sizeof(binary)) == 0, "binary bytes must match");
    std::free(output);

    output = &sentinel;
    outputSize = 99;
    expect(!cocos2d::fileutils_detail::readFile(binaryPath,
                                                "rb",
                                                false,
                                                3,
                                                &output,
                                                &outputSize),
           "maximum size must reject oversized input before allocation");
    expect(output == nullptr && outputSize == 0,
           "size rejection must reset outputs");

    output = &sentinel;
    outputSize = 99;
    expect(!cocos2d::fileutils_detail::readFile(binaryPath,
                                                "rb",
                                                false,
                                                1024,
                                                &output,
                                                &outputSize,
                                                failAllocation),
           "allocation failure must be reported safely");
    expect(output == nullptr && outputSize == 0,
           "allocation failure must not expose partial ownership");

    output = &sentinel;
    outputSize = 99;
    expect(!cocos2d::fileutils_detail::readFile(missingPath,
                                                "rb",
                                                false,
                                                1024,
                                                &output,
                                                &outputSize),
           "missing input must fail");
    expect(output == nullptr && outputSize == 0,
           "open failure must reset outputs");

    output = &sentinel;
    outputSize = 99;
    expect(!cocos2d::fileutils_detail::readFile(root,
                                                "rb",
                                                false,
                                                1024,
                                                &output,
                                                &outputSize),
           "directory input must not be treated as an empty regular file");
    expect(output == nullptr && outputSize == 0,
           "non-file input must reset outputs");

    expect(std::remove(emptyPath.c_str()) == 0, "empty fixture must be removed");
    expect(std::remove(textPath.c_str()) == 0, "text fixture must be removed");
    expect(std::remove(binaryPath.c_str()) == 0, "binary fixture must be removed");
    expect(rmdir(root.c_str()) == 0, "temporary directory must be removed");

    std::puts("FileUtils read safety OK: empty, text, binary, bounds, allocation, missing and non-file input");
    return 0;
}
