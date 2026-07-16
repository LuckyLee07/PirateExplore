/****************************************************************************
 Copyright (c) 2026 NewPirate contributors

 Bounded allocation for TextureAtlas CPU-side buffers.
 ****************************************************************************/

#ifndef __CC_TEXTURE_ATLAS_ALLOCATION_H__
#define __CC_TEXTURE_ATLAS_ALLOCATION_H__

#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <limits>

namespace cocos2d
{
namespace textureatlas_detail
{

using AtlasAllocator = void* (*)(std::size_t);

inline bool checkedMultiply(std::size_t left, std::size_t right, std::size_t* result)
{
    if (result == nullptr || (right != 0 && left > std::numeric_limits<std::size_t>::max() / right))
    {
        return false;
    }
    *result = left * right;
    return true;
}

template <typename Quad, typename Index>
bool allocateAtlasBuffers(std::ptrdiff_t capacity,
                          Quad** quads,
                          Index** indices,
                          AtlasAllocator allocator = std::malloc)
{
    if (quads == nullptr || indices == nullptr || allocator == nullptr)
    {
        return false;
    }

    *quads = nullptr;
    *indices = nullptr;

    if (capacity < 0)
    {
        return false;
    }

    const std::size_t count = static_cast<std::size_t>(capacity);
    if (count == 0)
    {
        return true;
    }

    // setupIndices stores four vertices per quad in the Index type.
    static_assert(std::numeric_limits<Index>::is_integer && !std::numeric_limits<Index>::is_signed,
                  "TextureAtlas indices must use an unsigned integer type");
    const std::size_t maximumIndex =
        static_cast<std::size_t>(std::numeric_limits<Index>::max());
    const std::size_t maximumQuads =
        maximumIndex / 4u + (maximumIndex % 4u == 3u ? 1u : 0u);
    if (count > maximumQuads)
    {
        return false;
    }

    std::size_t quadBytes = 0;
    std::size_t indexCount = 0;
    std::size_t indexBytes = 0;
    if (!checkedMultiply(count, sizeof(Quad), &quadBytes)
        || !checkedMultiply(count, 6u, &indexCount)
        || !checkedMultiply(indexCount, sizeof(Index), &indexBytes))
    {
        return false;
    }

    Quad* allocatedQuads = static_cast<Quad*>(allocator(quadBytes));
    if (allocatedQuads == nullptr)
    {
        return false;
    }

    Index* allocatedIndices = static_cast<Index*>(allocator(indexBytes));
    if (allocatedIndices == nullptr)
    {
        std::free(allocatedQuads);
        return false;
    }

    std::memset(allocatedQuads, 0, quadBytes);
    std::memset(allocatedIndices, 0, indexBytes);
    *quads = allocatedQuads;
    *indices = allocatedIndices;
    return true;
}

} // namespace textureatlas_detail
} // namespace cocos2d

#endif // __CC_TEXTURE_ATLAS_ALLOCATION_H__
