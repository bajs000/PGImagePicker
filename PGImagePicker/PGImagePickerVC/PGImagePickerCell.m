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
        if (!bSelect) {
            _animatiomView.alpha = 0.5;
        }
        [UIView animateWithDuration:0.5 animations:^{
            if (bSelect) {
                _animatiomView.alpha = 0.5;
            }else {
                _animatiomView.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                _animatiomView.alpha = 0;
            }];
        }];
    }
    if (bSelect)
        _selectedImage.hidden = false;
    else
        _selectedImage.hidden = true;
}

@end
