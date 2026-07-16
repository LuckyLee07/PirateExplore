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
    if (url == nullptr) {
        return;
    }
    NSString *string = [NSString stringWithUTF8String:url];
    NSURL *target = [NSURL URLWithString:string];
    if (target == nil || ![[target.scheme lowercaseString] isEqualToString:@"https"]) {
        NSLog(@"V2 release refused a non-HTTPS external URL");
        return;
    }
    [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:nil];
}
