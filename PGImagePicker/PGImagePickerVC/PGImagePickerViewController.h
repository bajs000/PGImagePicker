//
//  PGImagePickerViewController.h
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class PGImagePickerViewController;

@protocol PGImagePickerViewDelegate <NSObject>

@required
- (void)imagePicker:(PGImagePickerViewController *)imagePicker assetsPicked:(NSArray *)assets;
- (void)imagePicker:(PGImagePickerViewController *)imagePicker numberOfAssetsDidSelected:(NSInteger)number;

@optional
- (NSInteger)numberOfItemCanSelected;

@end

@interface PGImagePickerViewController : UIViewController

@property (nonatomic, assign) id<PGImagePickerViewDelegate> delegate;
+ (UINavigationController *)getInstance;

@end
