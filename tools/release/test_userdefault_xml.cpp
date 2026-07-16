#include "CCUserDefaultXML.h"

#include <cstdio>
#include <cstdlib>
#include <string>
#include <unistd.h>

namespace
{
void expect(bool condition, const char* message)
{
    if (!condition)
    {
        std::fprintf(stderr, "UserDefault XML test failed: %s\n", message);
        std::exit(1);
    }
}
}

int main()
{
    using cocos2d::userdefault_detail::LegacyXMLLookup;
    using cocos2d::userdefault_detail::LegacyXMLStatus;

    expect(LegacyXMLLookup::parse("", "key").status() == LegacyXMLStatus::Invalid,
           "empty XML must be invalid without retaining a document");
    expect(LegacyXMLLookup::parse("<", "key").status() == LegacyXMLStatus::Invalid,
           "malformed XML must be rejected");
    expect(LegacyXMLLookup::parse("<userDefaultRoot/>", "key").status() == LegacyXMLStatus::EmptyRoot,
           "empty legacy root must be distinguished");
    expect(LegacyXMLLookup::parse("<userDefaultRoot><other>1</other></userDefaultRoot>", "key").status()
               == LegacyXMLStatus::KeyNotFound,
           "missing key must not retain the parsed document");

    LegacyXMLLookup found = LegacyXMLLookup::parse(
        "<userDefaultRoot><music>true</music><count>3</count></userDefaultRoot>",
        "music");
    expect(found.status() == LegacyXMLStatus::Found, "existing key must be found");
    expect(found.node() != nullptr, "found lookup must expose its owned node");
    expect(found.node()->FirstChild() != nullptr, "found key must retain its value node");
    expect(std::string(found.node()->FirstChild()->Value()) == "true",
           "found value must remain valid while lookup owns the document");

    char pathTemplate[] = "/tmp/newpirate-userdefault-xml.XXXXXX";
    const int descriptor = mkstemp(pathTemplate);
    expect(descriptor >= 0, "temporary XML path must be created");
    expect(close(descriptor) == 0, "temporary XML descriptor must close");
    expect(found.removeNodeAndSave(pathTemplate), "migrated node must be removed and saved");
    expect(found.node() == nullptr, "removed node must not remain exposed");

    std::FILE* saved = std::fopen(pathTemplate, "rb");
    expect(saved != nullptr, "saved migration XML must be readable");
    expect(std::fseek(saved, 0, SEEK_END) == 0, "saved XML size must be measurable");
    const long savedSize = std::ftell(saved);
    expect(savedSize > 0 && std::fseek(saved, 0, SEEK_SET) == 0,
           "saved XML must contain the remaining document");
    std::string savedXML(static_cast<std::size_t>(savedSize), '\0');
    expect(std::fread(&savedXML[0], 1, savedXML.size(), saved) == savedXML.size(),
           "saved XML must be read completely");
    expect(std::fclose(saved) == 0, "saved XML file must close");
    expect(savedXML.find("<music>") == std::string::npos,
           "migrated key must be removed from legacy XML");
    expect(savedXML.find("<count>3</count>") != std::string::npos,
           "unrelated legacy keys must remain");
    expect(std::remove(pathTemplate) == 0, "temporary XML file must be removed");

    for (int index = 0; index < 20000; ++index)
    {
        LegacyXMLLookup missing = LegacyXMLLookup::parse(
            "<userDefaultRoot><other>1</other></userDefaultRoot>",
            "missing");
        expect(missing.status() == LegacyXMLStatus::KeyNotFound,
               "repeated missing-key lookup must remain bounded");

        LegacyXMLLookup malformed = LegacyXMLLookup::parse("<broken", "missing");
        expect(malformed.status() == LegacyXMLStatus::Invalid,
               "repeated malformed lookup must remain bounded");
    }

    std::puts("UserDefault XML ownership OK: invalid, empty, missing, found, migration and stress");
    return 0;
}
