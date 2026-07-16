#include "LZSS.h"
#include "RecordCodec.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

namespace
{
void expect(bool condition, const char* message)
{
    if (!condition)
    {
        std::fprintf(stderr, "record codec test failed: %s\n", message);
        std::exit(1);
    }
}

std::vector<unsigned char> decodedContainer(const std::vector<unsigned char>& encoded)
{
    std::vector<unsigned char> result = encoded;
    RecordCodec::xorLegacyBuffer(&result[0], result.size());
    return result;
}

std::vector<unsigned char> encodedContainer(const std::vector<unsigned char>& decoded)
{
    std::vector<unsigned char> result = decoded;
    RecordCodec::xorLegacyBuffer(&result[0], result.size());
    return result;
}

std::vector<unsigned char> convertToLegacy32(const std::vector<unsigned char>& encoded)
{
    const std::vector<unsigned char> current = decodedContainer(encoded);
    const std::size_t width = current[0];
    unsigned long decodedLength = 0;
    unsigned long compressedLength = 0;
    std::memcpy(&decodedLength, &current[1], width);
    std::memcpy(&compressedLength, &current[1 + width], width);
    expect(decodedLength <= UINT32_MAX && compressedLength <= UINT32_MAX, "fixture exceeds 32-bit legacy range");

    const std::size_t oldHeaderSize = 1u + width * 2u;
    const std::size_t newHeaderSize = 1u + sizeof(std::uint32_t) * 2u;
    std::vector<unsigned char> legacy(newHeaderSize + compressedLength, 0u);
    legacy[0] = static_cast<unsigned char>(sizeof(std::uint32_t));
    const std::uint32_t decoded32 = static_cast<std::uint32_t>(decodedLength);
    const std::uint32_t compressed32 = static_cast<std::uint32_t>(compressedLength);
    std::memcpy(&legacy[1], &decoded32, sizeof(decoded32));
    std::memcpy(&legacy[1 + sizeof(decoded32)], &compressed32, sizeof(compressed32));
    std::memcpy(&legacy[newHeaderSize], &current[oldHeaderSize], compressedLength);
    return encodedContainer(legacy);
}

std::string deterministicPayload(std::size_t size)
{
    std::string value;
    value.reserve(size);
    std::uint32_t state = 0x5a17c9e3u;
    for (std::size_t index = 0; index < size; ++index)
    {
        state = state * 1664525u + 1013904223u;
        value.push_back(static_cast<char>(33u + state % 90u));
    }
    return value;
}
}

int main(int argc, char** argv)
{
    const std::string save =
        "{\"schema_version\":4,\"chapter_id\":\"chapter_01\","
        "\"stage\":\"naval\",\"resources\":{\"gold\":35,\"timber\":10}}";
    std::vector<unsigned char> encoded;
    std::string decoded;
    expect(RecordCodec::encode(save, encoded), "normal save should encode");
    expect(RecordCodec::decode(&encoded[0], encoded.size(), decoded), "normal save should decode");
    expect(decoded == save, "round trip must preserve JSON exactly");

    const std::string noisy = deterministicPayload(256u * 1024u);
    std::vector<unsigned char> noisyEncoded;
    expect(RecordCodec::encode(noisy, noisyEncoded), "large low-repetition payload should encode within the bound");
    expect(RecordCodec::decode(&noisyEncoded[0], noisyEncoded.size(), decoded), "large payload should decode");
    expect(decoded == noisy, "large payload round trip must match");

    expect(!RecordCodec::encode(std::string(), noisyEncoded), "empty saves must be rejected");
    expect(!RecordCodec::encode(std::string("a\0b", 3), noisyEncoded), "embedded NUL must be rejected");

    for (std::size_t size = 0; size < encoded.size(); ++size)
    {
        const unsigned char* bytes = size == 0u ? NULL : &encoded[0];
        expect(!RecordCodec::decode(bytes, size, decoded), "every truncated prefix must be rejected");
    }

    std::vector<unsigned char> malformed = decodedContainer(encoded);
    malformed[0] = 1u;
    malformed = encodedContainer(malformed);
    expect(!RecordCodec::decode(&malformed[0], malformed.size(), decoded), "unknown length width must be rejected");

    malformed = decodedContainer(encoded);
    const std::size_t width = malformed[0];
    const unsigned long oversized = static_cast<unsigned long>(RecordCodec::maximumDecodedSize() + 1u);
    std::memcpy(&malformed[1], &oversized, width);
    malformed = encodedContainer(malformed);
    expect(!RecordCodec::decode(&malformed[0], malformed.size(), decoded), "oversized decoded length must be rejected");

    malformed = decodedContainer(encoded);
    unsigned long compressedLength = 0;
    std::memcpy(&compressedLength, &malformed[1 + width], width);
    ++compressedLength;
    std::memcpy(&malformed[1 + width], &compressedLength, width);
    malformed = encodedContainer(malformed);
    expect(!RecordCodec::decode(&malformed[0], malformed.size(), decoded), "payload length mismatch must be rejected");

    const std::size_t headerSize = 1u + sizeof(unsigned long) * 2u;
    std::vector<unsigned char> overflowContainer(headerSize + 3u, 0u);
    overflowContainer[0] = static_cast<unsigned char>(sizeof(unsigned long));
    const unsigned long claimedOutput = 1u;
    const unsigned long overflowPayloadSize = 3u;
    std::memcpy(&overflowContainer[1], &claimedOutput, sizeof(claimedOutput));
    std::memcpy(&overflowContainer[1 + sizeof(unsigned long)], &overflowPayloadSize, sizeof(overflowPayloadSize));
    // flags=0 plus a two-byte back-reference expands to three bytes, which
    // must stop at the one-byte output capacity rather than write past it.
    overflowContainer = encodedContainer(overflowContainer);
    expect(!RecordCodec::decode(&overflowContainer[0], overflowContainer.size(), decoded), "decompression overflow must be rejected");

    const std::vector<unsigned char> legacy32 = convertToLegacy32(encoded);
    expect(RecordCodec::decode(&legacy32[0], legacy32.size(), decoded), "32-bit legacy header should remain readable");
    expect(decoded == save, "32-bit legacy round trip must match");

    std::uint32_t mutationState = 0x91b4d2c7u;
    for (int iteration = 0; iteration < 1500; ++iteration)
    {
        std::vector<unsigned char> mutation = encoded;
        mutationState = mutationState * 1103515245u + 12345u;
        const int changes = 1 + static_cast<int>(mutationState % 3u);
        for (int change = 0; change < changes; ++change)
        {
            mutationState = mutationState * 1103515245u + 12345u;
            const std::size_t offset = mutationState % mutation.size();
            mutationState = mutationState * 1103515245u + 12345u;
            mutation[offset] ^= static_cast<unsigned char>(1u + mutationState % 255u);
        }
        if (RecordCodec::decode(&mutation[0], mutation.size(), decoded))
        {
            expect(!decoded.empty() && decoded.size() <= RecordCodec::maximumDecodedSize(), "accepted mutation must remain bounded");
        }
    }

    const std::string path = "/tmp/newpirate-record-codec-" + std::to_string(static_cast<long long>(getpid())) + ".save";
    const std::string temporaryPath = path + ".tmp";
    std::remove(path.c_str());
    std::remove(temporaryPath.c_str());
    expect(RecordCodec::writeFileAtomically(path, encoded), "atomic first write should pass");
    std::vector<unsigned char> fromDisk;
    expect(RecordCodec::readFile(path, fromDisk) && fromDisk == encoded, "atomic file should read back exactly");

    expect(RecordCodec::writeFileAtomically(path, legacy32), "atomic replacement should pass");
    expect(RecordCodec::readFile(path, fromDisk) && fromDisk == legacy32, "replacement should be complete");

    expect(::mkdir(temporaryPath.c_str(), 0700) == 0, "temporary-path failure fixture should be created");
    expect(!RecordCodec::writeFileAtomically(path, encoded), "failed temp creation must report failure");
    expect(RecordCodec::readFile(path, fromDisk) && fromDisk == legacy32, "failed replacement must preserve the previous save");
    expect(::rmdir(temporaryPath.c_str()) == 0, "temporary fixture should be removed");
    expect(std::remove(path.c_str()) == 0, "test save should be removed");

    for (int index = 1; index < argc; ++index)
    {
        std::vector<unsigned char> external;
        expect(RecordCodec::readFile(argv[index], external), "external legacy fixture should be readable");
        expect(RecordCodec::decode(&external[0], external.size(), decoded), "external legacy fixture should decode");
        expect(decoded.find("\"chapter_id\":\"chapter_01\"") != std::string::npos, "external fixture should contain the V2 chapter id");
        std::printf("Validated external legacy fixture: %s (%zu decoded bytes)\n", argv[index], decoded.size());
    }

    std::puts("Record codec durability OK: round-trip, legacy32, 1500 mutations, truncation, bounds and atomic replacement");
    return 0;
}
