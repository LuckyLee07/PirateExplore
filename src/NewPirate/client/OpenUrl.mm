//
//  OpenUrl.cpp
//  NewPirate
//
//  Created by songding on 15-1-22.
//
//

#include "OpenUrl.h"
#import <AdSupport/ASIdentifierManager.h>

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#endif

static OpenUrl* sharedStatic;
OpenUrl* OpenUrl::sharedOpenUrl()
{
    if(!sharedStatic){
        sharedStatic = new OpenUrl();
    }
    return sharedStatic;
}


const char* getMacAddress()
{
    std::string m_sString;
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    char                mac_addr[60] = {0};
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = (char*)malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    //    sprintf(mac_addr, "%02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
    //按照服务器端需求，去掉":"
    sprintf(mac_addr, "%02X%02X%02X%02X%02X%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
    free(buf);
    
    m_sString = mac_addr;
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

#endif
    
    return m_sString.c_str();
}


void OpenUrl::openUrl(const char* url)
{
    //大家可能会问：为什么要创建.mm文件，原因就在这
    NSString *str = [NSString stringWithUTF8String:url];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}

char* OpenUrl::getIDFA()
{
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    if (adId == nil) {
        adId = [NSString stringWithUTF8String:getMacAddress()];
    }
    return (char*)[adId UTF8String];
}