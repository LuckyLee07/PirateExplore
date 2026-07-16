#ifndef NEWPIRATE_RECORD_CODEC_H
#define NEWPIRATE_RECORD_CODEC_H

#include <cstddef>
#include <string>
#include <vector>

// Bounds-checked codec for the historical Record container. The on-disk
// layout remains compatible with existing saves, while malformed headers and
// compressed payloads are rejected before they can reach Lua.
class RecordCodec
{
public:
    static bool encode(const std::string& plainText, std::vector<unsigned char>& encoded);
    static bool decode(const unsigned char* encoded, std::size_t encodedSize, std::string& plainText);

    static bool readFile(const std::string& path, std::vector<unsigned char>& data);
    static bool writeFileAtomically(const std::string& path, const std::vector<unsigned char>& data);

    // Preserves the exact legacy obfuscation cycle for backward compatibility.
    static void xorLegacyBuffer(unsigned char* data, std::size_t size);

    static std::size_t maximumDecodedSize();
    static std::size_t maximumEncodedSize();

private:
    static std::size_t compressionBound(std::size_t inputSize);
};

#endif
