//
//  PGImageBrowserViewController.h
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef void(^FinishBrowse)(NSDictionary *);

@interface PGImageBrowserViewController : UIViewController

@property (nonatomic, copy) NSArray<PHAsset *> *assets;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, copy) NSDictionary *dSelected;
@property (nonatomic, assign) NSInteger nMaxCount;
@property (nonatomic, copy) FinishBrowse finish;

@end
