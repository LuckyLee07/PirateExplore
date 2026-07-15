//
//  CppOCBridge.h
//  NewPirate
//
//  Created by lizi on 17/11/16.
//
//

#ifndef __NewPirate__CppOCBridge__
#define __NewPirate__CppOCBridge__

class CppOCBridge
{
public:
    // 弹框/更多游戏
    static void showCcRateScene();
    static void showCcMoreScene();
    
    // 是否已开启兑换码功能
    static bool enableToSDK();
    
    // iOS内购接口
    static void purchaseCall(int selIndex);
    // 获取兑换码
    static bool decodeCdkey(const char* codeKey);

    // V2 uses AVAudioPlayer for short cues because the legacy OpenAL backend
    // terminates on current iOS simulator runtimes.
    static bool playV2Sound(const char* relativePath, float volume, bool loop);
};

#endif /* defined(__NewPirate__CppOCBridge__) */
