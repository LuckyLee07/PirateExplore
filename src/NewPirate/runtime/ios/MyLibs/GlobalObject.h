//
//  GlobalObject.h
//  BulletAdventure
//
//  Created by lizi on 17/9/5.
//  Copyright © 2017年 PalmGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalObject : NSObject

@property (nonatomic,assign) float globleWidth;
@property (nonatomic,assign) float globleHeight;
@property (nonatomic,assign) float globleAllHeight;

+ (GlobalObject *)shareInstance;
+ (UIColor *)colorFromHexRGB:(NSString *)inColorString;

@end
