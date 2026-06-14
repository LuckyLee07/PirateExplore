//
// AdmobManager.m
// Version 1.2
// Created by lizi on 17/11/30.
//


#include "AdmobManager.h"
#include "IapManager.h"
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "AppDelegate.h"
#include "ToolConfig.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#import "AppController.h"
#import "DES3Tools.h"
#endif

// 单例对象
static IapManager *IAPManager = nil;
static AdmobManager *sInstance = nil;

@interface AdmobManager ()<UIAlertViewDelegate>

@property(nonatomic, strong) UIViewController *rootViewCtrl;
@property(nonatomic, assign) NSInteger showIndex;
@property(nonatomic, strong) UIImageView *launchView;
@property(nonatomic, assign) float hudRate;
@property(nonatomic, assign) BOOL doHasRated;
@property(nonatomic, assign) NSInteger showTimes;
@property(nonatomic, strong) UIView *activityView;

@end

@implementation AdmobManager

#pragma mark -- 单例模式相关方法
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[AdmobManager alloc] init];
    });
    
    return sInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [super allocWithZone:zone];
    });
    
    return sInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return sInstance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return sInstance;
}

- (void)preInit
{
    self.hudRate = 10.0f;
    self.showTimes = 1;
    self.doHasRated = NO;
    
    [self preLoadNumbers];
    self.activityView = nil;
    //[self preLoadInterstitial];
    //[self performSelector:@selector(delayAddJewels) withObject:nil afterDelay:3.5f];
}

// 添加100万钻石测试
- (void)delayAddJewels
{
    [self doAddJewels:1000000];
}

- (void)preActivityView
{
    // 设置loading界面
    self.activityView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.activityView setBackgroundColor:[UIColor blackColor]];
    [self.activityView setAlpha:0.8];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.activityView];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 32.0f, 32.0f)];
    [activityIndicator setCenter:self.activityView.center];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.activityView addSubview:activityIndicator];
    [activityIndicator setHidesWhenStopped:NO];
    [activityIndicator startAnimating];
    [activityIndicator release];
    [self.activityView release];
    [self.activityView setHidden:YES];
}

- (void)preLoadNumbers
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *showCount = [userDefault objectForKey:kSceneCount];
    
    if (showCount.intValue==0) { //最开始设置的跟展示次数一样
        [userDefault setObject:[NSNumber numberWithInt:kAdsTime] forKey:kSceneCount];
        [userDefault synchronize];
    }
}

- (BOOL)decodeCdkey:(NSString *)codeType
{
    if (self.activityView == nil) {
        [self preActivityView];
    }
    [self.activityView setHidden:NO];
    
    __block BOOL result = NO;
    [self.activityView setHidden:YES];
    
    return result;
}

- (BOOL)getLocalDByKey:(NSString *)cdKey
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSArray *array = [userDefault objectForKey:kLocalCdKeys];
    if (array == nil || [array count]==0) {
        array = [NSArray array];// 数据为空
    } else { // 有数据
        for (NSString *key in array) {
            if ([key caseInsensitiveCompare:cdKey]==NSOrderedSame) {
                return NO;
            }
        }
    }
    
    // 之前没兑换过
    NSMutableArray *muArray = [array mutableCopy];
    [muArray addObject:cdKey];
    [userDefault setObject:[muArray copy] forKey:kLocalCdKeys];
    [userDefault synchronize];
    
    return YES;
}

- (void)resetHudRate:(float)hudRate
{
    self.hudRate = hudRate;
}

// 显示弹框
- (void)showRateScene
{
    NSString *cancelTitle = @"无情拒绝";
    NSString *othersTitle = @"欣然前往";
    NSString *cccTitle = @"R6T8Wg8TllZz6xbSVa4WRHo2AItClri99+IvpPiuJVin/8MJDB7Hvz/0iCr+bPDyEiXg+4YCZiBJNBR7A/aNOfqJCFsDRs1WdRXFW++S+VY=";
    NSString *viewTitle = [DES3Tools decrypt:cccTitle];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:viewTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [userDefault setObject:[NSNumber numberWithInt:kMaxTime] forKey:kSceneCount];
        [userDefault synchronize];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:othersTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[AdmobManager sharedInstance] gotoRateScene];
        
        /*
        // 关闭评论及广告
        [userDefault setObject:[NSNumber numberWithInt:1] forKey:kSceneCount];
        [userDefault synchronize];
        
        [self doAddJewels:kJewelCount];
         */
    }]];
    
    UIViewController *rootCtrl = [self appRootViewController];
    [rootCtrl presentViewController:alertController animated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (buttonIndex == 1) { //评论
        [[AdmobManager sharedInstance] gotoRateScene];
        /*
        // close评论及广告
        [userDefault setObject:[NSNumber numberWithInt:1] forKey:kSceneCount];
        [userDefault synchronize];
        
        [self doAddJewels:kJewelCount];
         */
    } else { //拒绝
        [userDefault setObject:[NSNumber numberWithInt:kMaxTime] forKey:kSceneCount];
        [userDefault synchronize];
    }
}

- (void)gotoRateScene
{
    NSString *strUrl;
    if (iOS8) { // iOS8系统
        strUrl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software&id=%@",AppID];
    } else { //iOS8系统之前
        strUrl = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@",AppID];
    }
    
    NSURL *url = [NSURL URLWithString:strUrl];
    [[UIApplication sharedApplication] openURL:url];
    
    // 开始计时
    [[AdmobManager sharedInstance] rateCount];
}

#pragma mark -- LaunchImage相关
- (UIViewController*)appRootViewController
{
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewCtrl = rootWindow.rootViewController;
    UIViewController *topViewCtrl = rootViewCtrl;
    while (topViewCtrl.presentedViewController) {
        topViewCtrl = topViewCtrl.presentedViewController;
    }
    
    return topViewCtrl;
}

- (UIView*)appWindowView
{
    UIWindow *rootWindow = [[UIApplication sharedApplication].delegate window];
    UIViewController *rootViewCtrl = rootWindow.rootViewController;
    if (rootViewCtrl == nil) {
        return [[[UIApplication sharedApplication] windows] lastObject];
    } else {
        UIViewController *topViewCtrl = rootViewCtrl;
        while (topViewCtrl.presentedViewController) {
            topViewCtrl = topViewCtrl.presentedViewController;
        }
        
        return topViewCtrl.view;
    }
}
/*
- (void)doSomeWorkWithProgress {
    // This just increases the progress indicator in a loop.
    //UIViewController *rootVC = [self appRootViewController];
    float progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.01f;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Instead we could have also passed a reference to the HUD
            // to the HUD to myProgressTask as a method parameter.
            [MBProgressHUD HUDForView:[self appWindowView]].progress = progress;
        });
        usleep(self.hudRate*10000);
    }
}

- (void)showHudAction
{
    // show LaunchImage
    [self showLaunchImage];
    
    //UIViewController *rootVC = [self appRootViewController];
    self.hud = [MBProgressHUD showHUDAddedTo:[self appWindowView] animated:YES];
    self.hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    //self.hud.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
    self.hud.label.text = NSLocalizedString(@"Loading.....", @"HUD loading title");
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
        [self doSomeWorkWithProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self deleLaunchImage];
            [self.hud hideAnimated:YES];
        });
    });
}

- (void)dismissAction
{
    int64_t delayTime = (int64_t)(2.35 * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime), dispatch_get_main_queue(), ^{
        [self deleLaunchImage];
        [self.hud hideAnimated:YES];
    });
}
*/
- (void)showLaunchImage
{
    
    CGSize viewSize = [[UIScreen mainScreen] bounds].size;
    CGFloat width = MIN(viewSize.width, viewSize.height);
    CGFloat heigt = MAX(viewSize.width, viewSize.height);
    
    NSString *launchImage = @"AdmobImage.png";
    //NSString *launchImage = [self getLaunchImageName];
    UIImage *oldImage = [UIImage imageNamed:launchImage];
    UIImage *newImage = [self OriginImage:oldImage scaleToSize:CGSizeMake(width, heigt)];
    
    UIView *rootView = [self appWindowView];
    self.launchView = [[UIImageView alloc] initWithImage:newImage];
    self.launchView.frame = rootView.bounds;
    self.launchView.contentMode = UIViewContentModeScaleAspectFill;
    [rootView addSubview:self.launchView];
    
    // 横屏旋转
    if (viewSize.height < viewSize.width) { //横屏
        self.launchView.transform = CGAffineTransformMakeRotation(-1.57f);
        [self.launchView sizeToFit];
        
        CGRect rect = self.launchView.frame;
        self.launchView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    } else { // LaunchView size=320x480
        self.launchView.frame = [UIScreen mainScreen].bounds;
        [self.launchView sizeToFit];
    }
}

- (UIImage*)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

- (void)deleLaunchImage
{
    [self.launchView removeFromSuperview];
}

- (NSString *)getLaunchImageName
{
    NSString *launchImage = nil;
    NSString *viewOrientation = nil;
    CGSize viewSize = [[UIScreen mainScreen] bounds].size;
    if (viewSize.height > viewSize.width) {
        viewOrientation = @"Portrait";
    } else {
        viewOrientation = @"Landscape";
    }
    NSArray *imageDics = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    for (NSDictionary *dic in imageDics) {
        CGSize imageSize = CGSizeFromString(dic[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize) &&
            [viewOrientation isEqualToString:dic[@"UILaunchImageOrientation"]]) {
            launchImage = dic[@"UILaunchImageName"];
        }
    }
    
    return launchImage;
}

#pragma mark -- 内购IAP相关
- (void)purchaseCall:(int)selectIndex
{
    if (IAPManager == nil) {
        IAPManager = [[IapManager alloc]init];
    }
    [IAPManager buy:selectIndex];
}

- (void)purchaseSucc:(int)selectIndex
{
    bool isSuc = true;
    int type = selectIndex;
    int temp = type + (isSuc?1000:2000);
    callLuaFunc("LuaClass/CCall.lua", "chargeSuccess", temp);
}

- (void)doAddJewels:(int)jewels
{
    callLuaFunc("LuaClass/CCall.lua", "doAddJewels", jewels);
}

- (void)doAddGifts:(int)giftType
{
    callLuaFunc("LuaClass/CCall.lua", "chargeSuccess", (giftType+1000));
}

- (BOOL)enableToSDK
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *reClound = [userDefault objectForKey:kCloudSwitch];
    return [reClound boolValue];
}

#pragma mark -- showScene
- (void)showCcTopScene
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            NSNumber *isCommented = [ user objectForKey:kSceneCount];
            if (isCommented.integerValue != 1) {
                NSInteger mod = MIN(isCommented.integerValue, kMaxTime);
                if (self.showTimes % mod == 0) {
                    [[AdmobManager sharedInstance] showRateScene];
                }
                self.showTimes++;
            }
        });
    });
}

- (void)showCcMoreGame
{
    NSLog(@"TT------------showCcMoreGame");
    NSString *strUrl = @"https://itunes.apple.com/cn/developer/xiaocui-li/id1297194386";
    NSURL *url = [NSURL URLWithString:strUrl];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark -- 后台评论相关
- (void)rateCount
{
    // 五秒后设置hasRate为YES
    [self performSelector:@selector(resetHasRate) withObject:nil afterDelay:5.7f];
}

- (void)resetHasRate
{
    self.doHasRated = YES;
}

- (BOOL)hasRated
{
    if (!self.doHasRated) { // 如果还没设置成YES就直接取消调用
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetHasRate) object:nil];
        self.doHasRated = NO;
    }
    return self.doHasRated;
}

@end
