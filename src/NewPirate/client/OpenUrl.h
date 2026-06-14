//
//  OpenUrl.h
//  NewPirate
//
//  Created by songding on 15-1-22.
//
//

#ifndef __NewPirate__OpenUrl__
#define __NewPirate__OpenUrl__

#include "cocos2d.h"
USING_NS_CC;
using namespace std;

class OpenUrl
{
public:
    static OpenUrl* sharedOpenUrl();
    void openUrl(const char* url);
    char* getIDFA();
};
#endif /* defined(__OpenUrl__OpenUrl__) */
