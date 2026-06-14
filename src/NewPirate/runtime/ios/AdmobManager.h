//
// AdmobManager.h
// Version 1.2
// Created by lizi on 17/11/30.
//

#import <UIKit/UIKit.h>

@interface AdmobManager : NSObject
// 单例模式
+ (instancetype)sharedInstance;

// 初始化广告
- (void)preInit;

// 弹框请求
- (void)showCcTopScene;
// More请求
- (void)showCcMoreGame;

// 开启兑换功能
- (BOOL)enableToSDK;

// 内购请求
- (void)purchaseCall:(int)selIndex;
// 内购成功后的回调
- (void)purchaseSucc:(int)selIndex;
// 兑换码功能
- (BOOL)decodeCdkey:(NSString *)codeType;

// 判断是否已评论过
- (void)rateCount;
- (BOOL)hasRated;
// 添加宝石接口
- (void)doAddJewels:(int)jewels;

/*
// 显示广告/评论
- (void)showRateScene;
- (void)showAdmobScene;
- (void)gotoRateScene;

- (void)showHudAction;
- (void)dismissAction;

- (void)showLaunchImage;
- (void)deleLaunchImage;

- (void)resetHudRate:(float)hudRate;
*/

@end
