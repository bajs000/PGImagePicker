//
//  PGImagePickerCell.h
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGImagePickerCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *animatiomView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;

- (void)setSelectMode:(BOOL)bSelect;

@end
