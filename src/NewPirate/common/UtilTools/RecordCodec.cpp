#include "RecordCodec.h"

#include "LZSS.h"

#include <cerrno>
#include <climits>
#include <cstdio>
#include <cstring>
#include <limits>

#if defined(__APPLE__) || defined(__linux__) || defined(__unix__)
#include <unistd.h>
#endif

namespace
{
const char* const kLegacyKey = "jhG8i8ekb23sd438";
const std::size_t kMaxDecodedBytes = 16u * 1024u * 1024u;

bool readLegacyLength(const unsigned char* source, std::size_t width, unsigned long& value)
{
    if (source == NULL || (width != 4u && width != 8u) || width > sizeof(value))
    {
        return false;
    }
    value = 0;
    std::memcpy(&value, source, width);
    return true;
}
}

std::size_t RecordCodec::compressionBound(std::size_t inputSize)
{
    // LZSS emits one flag byte for each group of up to eight literals. The
    // extra 17 bytes cover the encoder's final code buffer conservatively.
    const std::size_t overhead = (inputSize + 7u) / 8u + 17u;
    if (inputSize > std::numeric_limits<std::size_t>::max() - overhead)
    {
        return 0;
    }
    return inputSize + overhead;
}

std::size_t RecordCodec::maximumDecodedSize()
{
    return kMaxDecodedBytes;
}

std::size_t RecordCodec::maximumEncodedSize()
{
    return 1u + sizeof(unsigned long) * 2u + compressionBound(kMaxDecodedBytes);
}

void RecordCodec::xorLegacyBuffer(unsigned char* data, std::size_t size)
{
    if (data == NULL || size == 0u)
    {
        return;
    }

    const std::size_t keyLength = std::strlen(kLegacyKey);
    const unsigned char* key = reinterpret_cast<const unsigned char*>(kLegacyKey);
    const unsigned char* cursor = key;
    for (std::size_t index = 0; index < size; ++index)
    {
        data[index] ^= *cursor;
        if (index % keyLength == 0u)
        {
            cursor = key;
        }
        ++cursor;
    }
}

bool RecordCodec::encode(const std::string& plainText, std::vector<unsigned char>& encoded)
{
    encoded.clear();
    const std::size_t inputSize = plainText.size();
    if (inputSize == 0u || inputSize > kMaxDecodedBytes ||
        plainText.find('\0') != std::string::npos || inputSize > ULONG_MAX)
    {
        return false;
    }

    const std::size_t bound = compressionBound(inputSize);
    if (bound == 0u || bound > ULONG_MAX)
    {
        return false;
    }

    std::vector<unsigned char> compressed(bound, 0u);
    unsigned long compressedSize = 0;
    LZSS codec;
    if (!codec.Compress(
            reinterpret_cast<unsigned char*>(const_cast<char*>(plainText.data())),
            static_cast<unsigned long>(inputSize),
            &compressed[0],
            static_cast<unsigned long>(compressed.size()),
            &compressedSize) ||
        compressedSize == 0u || compressedSize > compressed.size())
    {
        return false;
    }

    const std::size_t lengthWidth = sizeof(unsigned long);
    const std::size_t headerSize = 1u + lengthWidth * 2u;
    if (compressedSize > std::numeric_limits<std::size_t>::max() - headerSize)
    {
        return false;
    }

    encoded.assign(headerSize + compressedSize, 0u);
    encoded[0] = static_cast<unsigned char>(lengthWidth);
    const unsigned long decodedLength = static_cast<unsigned long>(inputSize);
    std::memcpy(&encoded[1], &decodedLength, lengthWidth);
    std::memcpy(&encoded[1 + lengthWidth], &compressedSize, lengthWidth);
    std::memcpy(&encoded[headerSize], &compressed[0], compressedSize);
    xorLegacyBuffer(&encoded[0], encoded.size());
    return true;
}

bool RecordCodec::decode(
    const unsigned char* encoded,
    std::size_t encodedSize,
    std::string& plainText)
{
    plainText.clear();
    if (encoded == NULL || encodedSize < 1u || encodedSize > maximumEncodedSize())
    {
        return false;
    }

    std::vector<unsigned char> container(encoded, encoded + encodedSize);
    xorLegacyBuffer(&container[0], container.size());

    const std::size_t lengthWidth = container[0];
    if ((lengthWidth != 4u && lengthWidth != 8u) || lengthWidth > sizeof(unsigned long))
    {
        return false;
    }
    const std::size_t headerSize = 1u + lengthWidth * 2u;
    if (headerSize > container.size())
    {
        return false;
    }

    unsigned long decodedLength = 0;
    unsigned long compressedLength = 0;
    if (!readLegacyLength(&container[1], lengthWidth, decodedLength) ||
        !readLegacyLength(&container[1 + lengthWidth], lengthWidth, compressedLength))
    {
        return false;
    }
    if (decodedLength == 0u || decodedLength > kMaxDecodedBytes ||
        compressedLength == 0u || compressedLength > maximumEncodedSize() ||
        compressedLength != container.size() - headerSize)
    {
        return false;
    }

    std::vector<unsigned char> decoded(static_cast<std::size_t>(decodedLength) + 1u, 0u);
    unsigned long outputSize = 0;
    LZSS codec;
    if (!codec.UnCompress(
            &container[headerSize],
            compressedLength,
            &decoded[0],
            decodedLength,
            &outputSize) ||
        outputSize != decodedLength ||
        std::memchr(&decoded[0], '\0', decodedLength) != NULL)
    {
        return false;
    }

    plainText.assign(reinterpret_cast<const char*>(&decoded[0]), decodedLength);
    return true;
}

bool RecordCodec::readFile(const std::string& path, std::vector<unsigned char>& data)
{
    data.clear();
    FILE* file = std::fopen(path.c_str(), "rb");
    if (file == NULL)
    {
        return false;
    }
    if (std::fseek(file, 0, SEEK_END) != 0)
    {
        std::fclose(file);
        return false;
    }
    const long end = std::ftell(file);
    if (end <= 0 || static_cast<unsigned long>(end) > maximumEncodedSize() ||
        std::fseek(file, 0, SEEK_SET) != 0)
    {
        std::fclose(file);
        return false;
    }

    data.resize(static_cast<std::size_t>(end));
    const std::size_t read = std::fread(&data[0], 1u, data.size(), file);
    const bool success = read == data.size() && std::ferror(file) == 0;
    std::fclose(file);
    if (!success)
    {
        data.clear();
    }
    return success;
}

bool RecordCodec::writeFileAtomically(
    const std::string& path,
    const std::vector<unsigned char>& data)
{
    if (path.empty() || data.empty() || data.size() > maximumEncodedSize())
    {
        return false;
    }

    const std::string temporaryPath = path + ".tmp";
    FILE* file = std::fopen(temporaryPath.c_str(), "wb");
    if (file == NULL)
    {
        return false;
    }

    bool success = std::fwrite(&data[0], 1u, data.size(), file) == data.size();
    if (success)
    {
        success = std::fflush(file) == 0;
    }
#if defined(__APPLE__) || defined(__linux__) || defined(__unix__)
    if (success)
    {
        success = ::fsync(fileno(file)) == 0;
    }
#endif
    if (std::fclose(file) != 0)
    {
        success = false;
    }

    if (success)
    {
        success = std::rename(temporaryPath.c_str(), path.c_str()) == 0;
    }
    if (!success)
    {
        std::remove(temporaryPath.c_str());
    }
    return success;
}
