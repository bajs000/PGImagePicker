//
//  PGImagePickerCell.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "PGImagePickerCell.h"

@interface PGImagePickerCell()

@property (nonatomic, assign) BOOL beSelect;

@end

@implementation PGImagePickerCell

- (void)setSelectMode:(BOOL)bSelect
{
    if (bSelect != _beSelect) {
        _beSelect = bSelect;
        _animatiomView.alpha = 0.8;
        [UIView animateWithDuration:0.8 animations:^{
            _animatiomView.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    }
    if (bSelect)
        _selectedImage.hidden = false;
    else
        _selectedImage.hidden = true;
}

@end
