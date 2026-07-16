#include "base/CCData.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sanitizer/asan_interface.h>
#include <utility>

namespace
{
void expect(bool condition, const char* message)
{
    if (!condition)
    {
        std::fprintf(stderr, "CCData ownership test failed: %s\n", message);
        std::exit(1);
    }
}

void expectBytes(const cocos2d::Data& data, const unsigned char* expected, ssize_t size, const char* message)
{
    expect(data.getSize() == size, message);
    expect(data.getBytes() != nullptr, message);
    expect(std::memcmp(data.getBytes(), expected, static_cast<std::size_t>(size)) == 0, message);
}
}

int main()
{
    const unsigned char original[] = {1u, 3u, 5u, 7u, 9u};
    cocos2d::Data data;
    data.copy(const_cast<unsigned char*>(original), sizeof(original));
    expectBytes(data, original, sizeof(original), "initial copy must preserve bytes");

    data = data;
    expectBytes(data, original, sizeof(original), "copy self-assignment must remain valid");

    unsigned char* firstAllocation = data.getBytes();
    data.copy(data.getBytes(), data.getSize());
    expectBytes(data, original, sizeof(original), "aliased copy must not read freed memory");
    expect(data.getBytes() != firstAllocation, "aliased copy must own a distinct allocation");
    expect(__asan_address_is_poisoned(firstAllocation) != 0, "aliased copy must release its old allocation");

    unsigned char* aliasCopyAllocation = data.getBytes();
    unsigned char* replacement = static_cast<unsigned char*>(std::malloc(3u));
    expect(replacement != nullptr, "replacement allocation must succeed");
    replacement[0] = 2u;
    replacement[1] = 4u;
    replacement[2] = 6u;
    data.fastSet(replacement, 3);
    expect(__asan_address_is_poisoned(aliasCopyAllocation) != 0, "fastSet replacement must release the old allocation");
    const unsigned char expectedReplacement[] = {2u, 4u, 6u};
    expectBytes(data, expectedReplacement, 3, "fastSet replacement must take ownership");

    data.fastSet(data.getBytes(), data.getSize());
    expectBytes(data, expectedReplacement, 3, "fastSet self-alias must remain valid");

    cocos2d::Data target;
    const unsigned char targetBefore[] = {8u, 8u, 8u, 8u};
    target.copy(const_cast<unsigned char*>(targetBefore), sizeof(targetBefore));
    unsigned char* targetAllocation = target.getBytes();
    target = std::move(data);
    expect(__asan_address_is_poisoned(targetAllocation) != 0, "move assignment must release the target allocation");
    expectBytes(target, expectedReplacement, 3, "move assignment must transfer source bytes");
    expect(data.isNull(), "move assignment must empty the source");

    target = std::move(target);
    expectBytes(target, expectedReplacement, 3, "move self-assignment must preserve bytes");

    cocos2d::Data copied(target);
    expectBytes(copied, expectedReplacement, 3, "copy constructor must remain independent");
    target.clear();
    expectBytes(copied, expectedReplacement, 3, "copy must outlive cleared source");

    std::puts("CCData ownership OK: copy aliasing, self-assignment, fastSet and move replacement");
    return 0;
}
