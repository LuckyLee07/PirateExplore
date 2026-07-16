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
    // V2 uses AVAudioPlayer for short cues because the legacy OpenAL backend
    // terminates on current iOS simulator runtimes.
    static bool playV2Sound(const char* relativePath, float volume, bool loop);
};

#endif /* defined(__NewPirate__CppOCBridge__) */
