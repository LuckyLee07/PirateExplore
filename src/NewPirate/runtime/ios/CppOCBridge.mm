//
//  CppOCBridge.mm
//  NewPirate
//
//  Created by lizi on 17/11/16.
//
//

#include "CppOCBridge.h"
#include "AdmobManager.h"
#import <AVFoundation/AVFoundation.h>

static AVAudioPlayer *sV2AudioPlayer = nil;

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

bool CppOCBridge::playV2Sound(const char* relativePath, float volume, bool loop)
{
    if (relativePath == NULL || relativePath[0] == '\0') {
        return false;
    }

    NSString *relative = [NSString stringWithUTF8String:relativePath];
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *fullPath = [[resourcePath stringByAppendingPathComponent:@"assets"]
        stringByAppendingPathComponent:relative];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        NSLog(@"V2 audio cue missing: %@", fullPath);
        return false;
    }

    NSError *sessionError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    if (sessionError == nil) {
        [session setActive:YES error:&sessionError];
    }
    if (sessionError != nil) {
        NSLog(@"V2 audio session failed: %@", sessionError);
        return false;
    }

    [sV2AudioPlayer stop];
    [sV2AudioPlayer release];
    sV2AudioPlayer = nil;

    NSError *playerError = nil;
    sV2AudioPlayer = [[AVAudioPlayer alloc]
        initWithContentsOfURL:[NSURL fileURLWithPath:fullPath]
        error:&playerError];
    if (sV2AudioPlayer == nil || playerError != nil) {
        NSLog(@"V2 audio player failed for %@: %@", relative, playerError);
        [sV2AudioPlayer release];
        sV2AudioPlayer = nil;
        return false;
    }

    sV2AudioPlayer.volume = MAX(0.0f, MIN(1.0f, volume));
    sV2AudioPlayer.numberOfLoops = loop ? -1 : 0;
    [sV2AudioPlayer prepareToPlay];
    return [sV2AudioPlayer play] == YES;
}
