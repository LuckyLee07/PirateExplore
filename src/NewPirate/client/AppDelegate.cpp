#include "AppDelegate.h"
#include "CCLuaEngine.h"
#include "ToLua/TOLUA_LuaRecord.h"
#include "ToLua/LuaSDMD5.h"
#include "ToLua/TOLUA_GameBaseUtil.h"
#include "SimpleAudioEngine.h"
#include "cocos2d.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>
#endif

USING_NS_CC;

extern"C"{
    
    size_t fwrite$UNIX2003( const void *a, size_t b, size_t c, FILE *d )
    {
        return fwrite(a, b, c, d);
    }
    
    char* strerror$UNIX2003( int errnum )
    {
        return strerror(errnum);
        
    }
    
}

void callLuaFunc(const char* luaFileName, const char* functionName, int val)
{
    LuaEngine* pEngine = LuaEngine::getInstance();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    std::string resPrefix("");
#else
    std::string resPrefix("res/");
#endif
    pEngine->executeScriptFile(luaFileName);
    pEngine->executeGlobalFunction(functionName,val);
}

AppDelegate::AppDelegate()
{
    music_isplay = 0;
}

AppDelegate::~AppDelegate() 
{
}

bool AppDelegate::applicationDidFinishLaunching() {
    // initialize director
    auto director = Director::getInstance();
    auto glview = director->getOpenGLView();
    if(!glview) {
        glview = GLView::create("My Game");
        director->setOpenGLView(glview);
    }

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    // Legacy art was authored around a 640-point canvas. Cap 3x devices at a
    // 2x framebuffer so the deprecated OpenGL renderer does not redraw 125%
    // extra pixels with no meaningful gain in source detail.
    if (glview->getContentScaleFactor() > 2.0f) {
        glview->setContentScaleFactor(2.0f);
    }
#endif

    Size frameSize = director->getWinSize();
    
    Size lsSize = Size(640, frameSize.height * (640/frameSize.width));
	float persent = frameSize.width / frameSize.height;
	if (persent == 0.75) {
		lsSize = Size(640, 960);
	}
    // ipad retina 设置 （非retina的ipad设置了也没事，因为本身就是这个分辨率）
    glview->setDesignResolutionSize(lsSize.width, lsSize.height, ResolutionPolicy::SHOW_ALL);
    
    // turn on display FPS
    //director->setDisplayStats(true);

    // The V2 sample is a decision-focused 2D game. A stable 30 FPS target is
    // sufficient for its lightweight motion and materially reduces sustained
    // CPU/GPU work on current full-screen devices.
    director->setAnimationInterval(1.0 / 30);

    // register lua engine
    LuaEngine* pEngine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);

    auto fileUtils = FileUtils::getInstance();
    auto searchPaths = fileUtils->getSearchPaths();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    searchPaths.insert(searchPaths.begin(), "res/assets");
    searchPaths.insert(searchPaths.begin(), "res/scripts");
#endif
    searchPaths.insert(searchPaths.begin(), "assets");
    searchPaths.insert(searchPaths.begin(), "scripts");
    fileUtils->setSearchPaths(searchPaths);
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32 || CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID ||CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    LuaStack* stack = pEngine->getLuaStack();
    tolua_TOLUA_LuaRecord_open(stack->getLuaState());
    tolua_TOLUA_MD5_open(stack->getLuaState());
    tolua_TOLUA_GameBaseUtil_open(stack->getLuaState());
#endif
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    std::string resPrefix("");
#else
    std::string resPrefix("res/");
#endif
	
	// 如果是老端的用户，在它进入游戏之前要加密一下之前的存档，否则无法正常运行
	bool bIsChangeSaveData = UserDefault::getInstance()->getBoolForKey("kItWasChangeData");
	if (!bIsChangeSaveData) {
		// 优先先处理用户存档
		std::string sourceStr = FileUtils::getInstance()->getStringFromFile(FileUtils::getInstance()->getWritablePath() + "gameRole");
		if (sourceStr != "" && sourceStr.c_str() != NULL) {
			Record::GetInstance()->saveData((char*)sourceStr.c_str(), (char*)"gameRole");
		}
		// 然后处理地图数据
		char* fileName = NULL;
		for (int i = 0; i < 16; ++i) {
			fileName = new char[32];
			sprintf(fileName, "gameMap%d", i);
			sourceStr = FileUtils::getInstance()->getStringFromFile(FileUtils::getInstance()->getWritablePath() + fileName);
			if (sourceStr != "" && sourceStr.c_str() != NULL) {
				Record::GetInstance()->saveData((char*)sourceStr.c_str(), fileName);
			}
			delete []fileName;
			fileName = NULL;
		}
		// 最后写入userdata数据
		UserDefault::getInstance()->setBoolForKey("kItWasChangeData", true);
		UserDefault::getInstance()->flush();
	}
	
	// 生成加密数据文件(0是csv,1是lua)
//	this->runEncipherment(0);
//	this->runEncipherment(1);
    /*
    Sprite *sprite = Sprite::create("spx.png");
    Scene *scene = Scene::create();
    scene->addChild(sprite);
	*/
	// 进入游戏
    pEngine->executeScriptFile("LuaClass/main.lua");
	
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground() {
    Director::getInstance()->stopAnimation();

    
    Director::getInstance()->pause();
    
    if (CocosDenshion::SimpleAudioEngine::getInstance()->isBackgroundMusicPlaying())
    {
        music_isplay = 1;
    }
    else
    {
        music_isplay = 0;
    }
    CocosDenshion::SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
//    SimpleAudioEngine::getInstance()->resumeAllEffects();
//    CCNotificationCenter::sharedNotificationCenter()->postNotification("APP_ENTER_FOREGROUND_EVENT");
    
    // if you use SimpleAudioEngine, it must be pause
    // SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground() {
    Director::getInstance()->startAnimation();

    Director::getInstance()->resume();
    if (1 == music_isplay)
    {
        CocosDenshion::SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
    }
    
//    EventCustom event("chargeSuccess");
//    int temp = 1003;
//    callLuaFunc("LuaClass/CCall.lua", "chargeSuccess", temp);
    
    
    EventCustom event("backtobefor");
    auto  temp = Director::getInstance()->getNotificationNode()->getEventDispatcher();
    temp->dispatchEvent(&event);
	
	
//	EventCustom event("chargeSuccess");
//	int temp = 103;
//	event.setUserData(&temp);
//	auto dispatch = Director::getInstance()->getNotificationNode()->getEventDispatcher();
//	dispatch->dispatchEvent(&event);
	
//	callLuaFunc("LuaClass/DataManager.lua", "chargeSuccess", temp);
	
// if you use SimpleAudioEngine, it must resume here
// SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
}


#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

extern "C"
{
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_IAPListener_purchaseCallBack(JNIEnv *env, jobject thiz, int type, bool isSuc)
    {
        CCLOG("回调了计费");
        EventCustom event("chargeSuccess");
        int temp = type + (isSuc?1000:2000);
		
        callLuaFunc("LuaClass/CCall.lua", "chargeSuccess", temp);
        //m_instance->loginCallBack(isSuc, value_);
    }
}
#endif

#pragma mark - 文件加密工具函数

void AppDelegate::runEncipherment(int type)
{
	Record* rec = Record::GetInstance();
	if (type == 0) {
		CCLOG("开始写入csv数据||||||||||||||||||||||||||||||||||||||||||||||||||");
		char* csvFiles[23] = {(char*)"achievement.csv", (char*)"buff.csv", (char*)"build.csv", (char*)"eternalArena.csv", (char*)"fightboxes.csv", (char*)"gift.csv", (char*)"giftPush.csv", (char*)"loadingTips.csv", (char*)"plot.csv", (char*)"produce.csv", (char*)"randomEvent.csv", (char*)"resourceInfo.csv", (char*)"shopgift.csv", (char*)"shopitem.csv", (char*)"skillAttribute.csv", (char*)"soilderAttribute.csv", (char*)"store.csv", (char*)"strongholdDistribution.csv", (char*)"talent.csv", (char*)"worker.csv", (char*)"WorldMapCoordinates.csv", (char*)"strongholdAttribute.csv"};
		std::string sourceStr = "";
		std::string fileName = "";
		for (int i = 0; i < 23; ++i) {
			if (csvFiles[i] != NULL) {
				fileName = "data/";
				fileName += csvFiles[i];
				sourceStr = FileUtils::getInstance()->getStringFromFile(fileName);
				if (sourceStr.c_str() != NULL) {
					printf("写入%s数据\n", csvFiles[i]);
					rec->saveData((char*)sourceStr.c_str(), csvFiles[i]);
				}
			}
		}
		CCLOG("写入csv数据结束||||||||||||||||||||||||||||||||||||||||||||||||||");
	} else if (type == 1) {
		CCLOG("开始写入lua数据||||||||||||||||||||||||||||||||||||||||||||||||||");
		char* luaFiles[66] = {(char*)"Achievement.lua", (char*)"AlertView.lua", (char*)"BaseView.lua", (char*)"BuildMode.lua", (char*)"CCall.lua", (char*)"CDKView.lua", (char*)"ChargeMode.lua", (char*)"ChargingView.lua", (char*)"controller.lua", (char*)"CSVParser.lua", (char*)"DataController.lua", (char*)"DataManager.lua", (char*)"DialogueView.lua", (char*)"DiamondStore.lua", (char*)"Dispatch.lua", (char*)"DynamicData.lua", (char*)"EffectUtil.lua", (char*)"EternalArenaController.lua", (char*)"EventBaseView.lua", (char*)"EventDetailsLayer.lua", (char*)"EventLayer.lua", (char*)"EventManger.lua", (char*)"EventRewardLayer.lua", (char*)"Expedition.lua", (char*)"Explore.lua", (char*)"ExploreBagController.lua", (char*)"ExploreDataManager.lua", (char*)"FightDataManager.lua", (char*)"FightMode.lua", (char*)"FogManager.lua", (char*)"GuideController.lua", (char*)"Header.lua", (char*)"HttpSingleton.lua", (char*)"Jointed.lua", (char*)"Lackmaterial.lua", (char*)"LoadingScene.lua", (char*)"MainMenu.lua", (char*)"MakeMode.lua", (char*)"MapData.lua", (char*)"MapLayoutManagers.lua", (char*)"NotificationNode.lua", (char*)"PlotLayer.lua", (char*)"PlotMode.lua", (char*)"RandomEventMode.lua", (char*)"Ranking.lua", (char*)"Repository.lua", (char*)"Resource.lua", (char*)"rewardLayer.lua", (char*)"SaveDataManager.lua", (char*)"SDButton.lua", (char*)"SDResourceManager.lua", (char*)"Setting.lua", (char*)"simplejson.lua", (char*)"StaticData.lua", (char*)"StoreMode.lua", (char*)"Talent.lua",(char*)"ToastUtil.lua", (char*)"TrainMode.lua", (char*)"TransformLayer.lua", (char*)"UIKit.lua", (char*)"Update.lua", (char*)"UserData.lua", (char*)"Utils.lua", (char*)"WorldMapLayer.lua", (char*)"WoWUtils.lua"};
		std::string sourceStr = "";
		std::string fileName = "";
		for (int i = 0; i < 66; ++i) {
			if (luaFiles[i] != NULL) {
				fileName = "LuaClass/";
				fileName += luaFiles[i];
				sourceStr = FileUtils::getInstance()->getStringFromFile(fileName);
				if (sourceStr.c_str() != NULL) {
					printf("写入%s数据\n", luaFiles[i]);
					rec->saveData((char*)sourceStr.c_str(), luaFiles[i]);
				}
			}
		}
		CCLOG("写入lua数据结束||||||||||||||||||||||||||||||||||||||||||||||||||");
	}
}
