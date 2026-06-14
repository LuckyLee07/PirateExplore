//
//  CppOCBridge.mm
//  NewPirate
//
//  Created by lizi on 17/11/16.
//
//

#include "CppOCBridge.h"
#include "AdmobManager.h"

void CppOCBridge::purchaseCall(int selIndex)
{
    [[AdmobManager sharedInstance] purchaseCall:selIndex];
}

void CppOCBridge::showCcRateScene()
{
    [[AdmobManager sharedInstance] showCcTopScene];
}

void CppOCBridge::showCcMoreScene()
{
    [[AdmobManager sharedInstance] showCcMoreGame];
}

bool CppOCBridge::decodeCdkey(const char* codeKey)
{
    NSString *nCodeKey = [NSString stringWithUTF8String:codeKey];
    BOOL result = [[AdmobManager sharedInstance] decodeCdkey:nCodeKey];
    return result==YES;
}

bool CppOCBridge::enableToSDK()
{
    BOOL result = [[AdmobManager sharedInstance] enableToSDK];
    return result==YES;
}
