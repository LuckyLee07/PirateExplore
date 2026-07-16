/****************************************************************************
 Copyright (c) 2026 NewPirate contributors

 RAII ownership for the legacy UserDefault.xml migration path.
 ****************************************************************************/

#ifndef __CC_USERDEFAULT_XML_H__
#define __CC_USERDEFAULT_XML_H__

#include "tinyxml2.h"

#include <cstring>
#include <memory>
#include <string>
#include <utility>

namespace cocos2d
{
namespace userdefault_detail
{

enum class LegacyXMLStatus
{
    Invalid,
    EmptyRoot,
    KeyNotFound,
    Found
};

class LegacyXMLLookup
{
public:
    LegacyXMLLookup()
    : _document()
    , _node(nullptr)
    , _status(LegacyXMLStatus::Invalid)
    {
    }

    LegacyXMLLookup(LegacyXMLLookup&& other) noexcept = default;
    LegacyXMLLookup& operator=(LegacyXMLLookup&& other) noexcept = default;

    LegacyXMLLookup(const LegacyXMLLookup&) = delete;
    LegacyXMLLookup& operator=(const LegacyXMLLookup&) = delete;

    static LegacyXMLLookup parse(const std::string& xml, const char* key)
    {
        LegacyXMLLookup result;
        if (xml.empty() || key == nullptr)
        {
            return result;
        }

        std::unique_ptr<tinyxml2::XMLDocument> document(new tinyxml2::XMLDocument());
        if (document->Parse(xml.c_str(), xml.size()) != tinyxml2::XML_SUCCESS)
        {
            return result;
        }

        tinyxml2::XMLElement* root = document->RootElement();
        if (root == nullptr)
        {
            return result;
        }

        tinyxml2::XMLElement* node = root->FirstChildElement();
        if (node == nullptr)
        {
            result._status = LegacyXMLStatus::EmptyRoot;
            return result;
        }

        while (node != nullptr && std::strcmp(node->Value(), key) != 0)
        {
            node = node->NextSiblingElement();
        }

        if (node == nullptr)
        {
            result._status = LegacyXMLStatus::KeyNotFound;
            return result;
        }

        result._document = std::move(document);
        result._node = node;
        result._status = LegacyXMLStatus::Found;
        return result;
    }

    LegacyXMLStatus status() const
    {
        return _status;
    }

    tinyxml2::XMLElement* node() const
    {
        return _node;
    }

    bool removeNodeAndSave(const std::string& path)
    {
        if (_document == nullptr || _node == nullptr || path.empty())
        {
            return false;
        }

        _document->DeleteNode(_node);
        _node = nullptr;
        _status = LegacyXMLStatus::KeyNotFound;
        return _document->SaveFile(path.c_str()) == tinyxml2::XML_SUCCESS;
    }

private:
    std::unique_ptr<tinyxml2::XMLDocument> _document;
    tinyxml2::XMLElement* _node;
    LegacyXMLStatus _status;
};

} // namespace userdefault_detail
} // namespace cocos2d

#endif // __CC_USERDEFAULT_XML_H__
