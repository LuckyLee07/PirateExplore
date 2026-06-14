//
//  ToolConfig.h
//  NewPirate
//
//  Created by lizi on 17/11/25.
//
//

#ifndef ToolConfig_h
#define ToolConfig_h

//debug模式-->>上线注掉
//#define AppDebug

static int kAdsTime    = 7;
static int kMaxTime    = 7;

static int const kCoundMin  = 3;
static int const kCoundMax  = 3;

// 赠送的钻石数量
static int const kJewelCount  = 100;

// AppId/AdmobId
static NSString* const AppID    = @"1320350921";
static NSString* const AdmobID  = @"ca-app-pub-3670114149704964/5098844338";

// 本地兑换码
static NSString* const kLocalCdKeys = @"kLocalCdKeys";
// LeanCloud开关
static NSString* const kCloudSwitch = @"kCloudSwitch";
// 关闭评论或广告
static NSString* const kSceneCount = @"kRatesAndAdmobs";
// 本地通知Key
static NSString* const kNotesKey = @"kNotificationKeys";
// 商品道具ID前缀
static NSString* const kItemPrefix = @"com.fancyGame.PirateItem";

// 主界面上侧的滑动按钮高度
static const CGFloat kHeightOfTopScrollView = 35.0f;

//判断是否为iOS7
#define iOS7 [[[UIDevice currentDevice]systemVersion] floatValue] >= 7.0

// 判断是否为iOS8
#define iOS8 [[[UIDevice currentDevice]systemVersion] floatValue] >= 8.0

//全屏宽/高
#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#endif /* ToolConfig_h */
