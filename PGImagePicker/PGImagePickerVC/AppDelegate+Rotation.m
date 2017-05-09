//
//  AppDelegate+Rotation.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/8.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "AppDelegate+Rotation.h"
#import "PGImageBrowserViewController.h"

@implementation AppDelegate (Rotation)

static BOOL rotation = false;
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    if (rotation) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

+ (void)updateRotationStatus:(BOOL)flag{
    rotation = flag;
}

@end
