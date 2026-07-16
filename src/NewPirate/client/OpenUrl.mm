//
//  OpenUrl.cpp
//  NewPirate
//
//  Created by songding on 15-1-22.
//
//

#include "OpenUrl.h"

static OpenUrl* sharedStatic;
OpenUrl* OpenUrl::sharedOpenUrl()
{
    if(!sharedStatic){
        sharedStatic = new OpenUrl();
    }
    return sharedStatic;
}


void OpenUrl::openUrl(const char* url)
{
    //大家可能会问：为什么要创建.mm文件，原因就在这
    NSString *str = [NSString stringWithUTF8String:url];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}
