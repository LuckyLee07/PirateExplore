#include "CCTextureAtlasAllocation.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>

#if defined(__has_feature)
#if __has_feature(address_sanitizer)
#include <sanitizer/asan_interface.h>
#define NEWPIRATE_HAS_ASAN 1
#endif
#endif

namespace
{
struct TestQuad
{
    unsigned char bytes[32];
};

int allocationCalls = 0;
int failOnCall = 0;
void* firstAllocation = nullptr;

void* controlledAllocate(std::size_t size)
{
    ++allocationCalls;
    if (allocationCalls == failOnCall)
    {
        return nullptr;
    }
    void* memory = std::malloc(size);
    if (allocationCalls == 1)
    {
        firstAllocation = memory;
    }
    return memory;
}

void resetAllocator(int failureCall)
{
    allocationCalls = 0;
    failOnCall = failureCall;
    firstAllocation = nullptr;
}

void expect(bool condition, const char* message)
{
    if (!condition)
    {
        std::fprintf(stderr, "TextureAtlas allocation test failed: %s\n", message);
        std::exit(1);
    }
}
}

int main()
{
    using cocos2d::textureatlas_detail::allocateAtlasBuffers;

    TestQuad* quads = reinterpret_cast<TestQuad*>(1);
    unsigned short* indices = reinterpret_cast<unsigned short*>(1);

    resetAllocator(0);
    expect(allocateAtlasBuffers<TestQuad, unsigned short>(0, &quads, &indices, controlledAllocate),
           "zero capacity must be a valid empty atlas");
    expect(quads == nullptr && indices == nullptr, "zero capacity must not fabricate buffers");
    expect(allocationCalls == 0, "zero capacity must not call malloc(0)");

    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(-1, &quads, &indices, controlledAllocate),
           "negative capacity must be rejected in release builds");
    expect(allocationCalls == 0, "invalid capacity must fail before allocation");

    resetAllocator(0);
    expect(allocateAtlasBuffers<TestQuad, unsigned short>(3, &quads, &indices, controlledAllocate),
           "normal atlas buffers must allocate");
    TestQuad emptyQuad = {};
    expect(std::memcmp(&quads[0], &emptyQuad, sizeof(emptyQuad)) == 0,
           "quad storage must be zero initialized");
    for (int index = 0; index < 18; ++index)
    {
        expect(indices[index] == 0, "index storage must be zero initialized");
    }
    std::free(quads);
    std::free(indices);

    resetAllocator(1);
    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(1, &quads, &indices, controlledAllocate),
           "first allocation failure must be reported");
    expect(quads == nullptr && indices == nullptr, "failed first allocation must not escape ownership");

    resetAllocator(2);
    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(1, &quads, &indices, controlledAllocate),
           "second allocation failure must be reported");
    expect(quads == nullptr && indices == nullptr, "partial allocation must not escape ownership");
#if NEWPIRATE_HAS_ASAN
    expect(firstAllocation != nullptr && __asan_address_is_poisoned(firstAllocation),
           "partial allocation must release the first buffer");
#endif

    resetAllocator(0);
    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(16385, &quads, &indices, controlledAllocate),
           "capacity beyond 16-bit vertex indices must be rejected");
    expect(allocationCalls == 0, "index overflow must fail before allocation");

    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(1, nullptr, &indices, controlledAllocate),
           "null output pointer must be rejected");
    expect(!allocateAtlasBuffers<TestQuad, unsigned short>(1, &quads, &indices, nullptr),
           "null allocator must be rejected");

    std::puts("TextureAtlas allocation OK: zero, bounds, initialization and partial failure");
    return 0;
}
