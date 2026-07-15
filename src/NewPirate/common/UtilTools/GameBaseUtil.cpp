#include "GameBaseUtil.h"
#include "MD5.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "CppOCBridge.h"
#endif

//导入Android平台下所用的头文件
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#include <android/log.h>
#endif

std::string getonlyID()
{
    std::string strMac="";
    //利用预编译区分不同平台
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS //ios平台下
    
    //调用OpenUrl类中的方法,完成ios访问url
    strMac = OpenUrl::sharedOpenUrl()->getIDFA();
    
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID  //Android平台下,别忘导入Android平台下所用的头文件。
    
    JniMethodInfo methodInfo; //用于获取函数体
    bool isHave = JniHelper::getStaticMethodInfo(methodInfo,"org/cocos2dx/lib/Cocos2dxActivity", "getMacID", "()Ljava/lang/String;");
    
    if (isHave)
    {
        jstring jstr;
        CCLog("java层getMacID 函数存在;");
        jstr = (jstring)methodInfo.env->CallStaticObjectMethod(methodInfo.classID,methodInfo.methodID);
        strMac = JniHelper::jstring2string(jstr);
//        CCMessageBox("Mac", strMac.c_str());
    }
    else
    {
        CCLog("java层getMacID 函数不存在;");
    }
    
#endif
    return strMac;
}


void openUrlFunc(const char* url)
{
//    openUrlBase();
    //利用预编译区分不同平台
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS //ios平台下
    if (url == NULL) {
        CppOCBridge::showCcRateScene();
    } else {
        //调用OpenUrl类中的方法,完成ios访问url
        OpenUrl::sharedOpenUrl()->openUrl(url);
    }
    
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID  //Android平台下,别忘导入Android平台下所用的头文件。
    
    //定义Jni函数信息结构体
    JniMethodInfo minfo;
    //JniHelper类主要用于Jni与Java层之间的相互访问的作用。 getStaticMethodInfo函数返回一个bool值表示是否找到此函数
    bool isHave = JniHelper::getStaticMethodInfo(minfo,"org/cocos2dx/lib/Cocos2dxActivity","openUrl", "(Ljava/lang/String;)V");
    if (isHave) {
        jstring stringArg1;
        if (!url) {
            stringArg1 = minfo.env->NewStringUTF("");
        } else {
            stringArg1 = minfo.env->NewStringUTF(url);
        }
        //调用此函数
        minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID, stringArg1);
    }
    
#endif
}

void addSpriteToFrameCache(const char* fileName, int startNumber, int endNumber)
{
    SpriteFrameCache *cache = SpriteFrameCache::getInstance();
    for (int i = startNumber; i <= endNumber; i++) {
        std::string sprName = StringUtils::format(fileName, i);
        Sprite* spr = Sprite::create(sprName.c_str());
        if (spr) {
            cache->addSpriteFrame(spr->displayFrame(), sprName.c_str());
        }
    }
}

Animate* getAnimate(const char* fileName, int startNumber, int endNumber, float duration)
{
    //缓存动画
    Animation* upgradeAnimation = Animation::create();
    upgradeAnimation->setDelayPerUnit(duration);
    for (int i = startNumber; i < endNumber; i++)
    {
        char szName[40] = {0};
        sprintf(szName, fileName,i+1);
        upgradeAnimation->addSpriteFrame(SpriteFrameCache::getInstance()->getSpriteFrameByName(szName));
    }
    
    //创建动画
    auto _Animate = Animate::create(upgradeAnimation);
    return _Animate;
}

// 获取文件md5
const char* getFileMD5(const char* fileName)
{
    Data data = FileUtils::getInstance()->getDataFromFile(fileName);
    static std::string md5;
    md5 = MD5((const char*)data.getBytes(), (int)data.getSize()).hexdigest();
    return md5.c_str();
}

//	计费
void purchase(const char* parm)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    int type = atoi(parm);
    CppOCBridge::purchaseCall(type);
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

    CCLOG("发起计费请求");
//    ZQJNIHelper::get_ParamChar_ReturnVoid_StaticMethod(parm);
    JniMethodInfo t;
    if (JniHelper::getStaticMethodInfo(t, "org/cocos2dx/cpp/gamesdk", "initorder",
                                       "(Ljava/lang/String;)V")) {
        jstring stringArg1;
        if (!parm) {
            stringArg1 = t.env->NewStringUTF("");
        } else {
            stringArg1 = t.env->NewStringUTF(parm);
        }
        t.env->CallStaticVoidMethod(t.classID, t.methodID, stringArg1);
        t.env->DeleteLocalRef(t.classID);
    }
#endif
    
}

// 获得SDK返回的开启和关闭的参数
std::string getEnableInterface()
{
	std::string returnStr = "{\"UserCenter\":\"Disabled\"}";
	CCLOG("获得SDK返回的开启与关闭的参数");
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    bool result = CppOCBridge::enableToSDK();
    if (result) { // 已开启
        returnStr = "{\"UserCenter\":\"Enabled\"}";
    }
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	JniMethodInfo methodInfo; //用于获取函数体
	bool isHave = JniHelper::getStaticMethodInfo(methodInfo,"org/cocos2dx/cpp/gamesdk", "getEnableInterface", "()Ljava/lang/String;");
	
	if (isHave)
	{
		jstring jstr;
		CCLog("java层getEnableInterface 函数存在;");
		jstr = (jstring)methodInfo.env->CallStaticObjectMethod(methodInfo.classID,methodInfo.methodID);
		returnStr = JniHelper::jstring2string(jstr);
		//        CCMessageBox("Mac", strMac.c_str());
	}
#endif
	return returnStr;
}

// 点击更多游戏之后的回调
void showMoreGameCallback()
{
	CCLOG("点开更多游戏之后的回调");
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    CppOCBridge::showCcMoreScene();
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	JniMethodInfo methodInfo; //用于获取函数体
	bool isHave = JniHelper::getStaticMethodInfo(methodInfo,"org/cocos2dx/cpp/gamesdk", "showMoreGameCallback", "()V");
	
	if (isHave)
	{
		CCLog("java层showMoreGameCallback 函数存在;");
		methodInfo.env->CallStaticObjectMethod(methodInfo.classID,methodInfo.methodID);
		//CCMessageBox("Mac", strMac.c_str());
	}
#endif
}

void showRateOrAdScene()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    // 显示评论
    CppOCBridge::showCcRateScene();
#endif
}

void rateIniTunes()
{
    // 暂时用不上
}

// 兑换码功能
bool decodeExKey(const char* codeKey)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    bool result = CppOCBridge::decodeCdkey(codeKey);
    return result;
#else
    return false;
#endif
}

bool playV2Sound(const char* relativePath, float volume, int loop)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    return CppOCBridge::playV2Sound(relativePath, volume, loop != 0);
#else
    return false;
#endif
}
