//
//  PGImageBrowserCell.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "PGImageBrowserCell.h"
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define kScreenWidth  SCREENWIDTH
#define kScreenHeight  SCREENHEIGHT
#define kMaxZoom 3.0

@interface PGImageBrowserCell()<UIScrollViewDelegate>{
    PHAsset *currentAsset;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *artimage;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@property (nonatomic) CGFloat touchX;
@property (nonatomic) CGFloat touchY;
@property (nonatomic) BOOL isTwiceTaping;
@property (nonatomic) BOOL isDoubleTapingForZoom;
@property (nonatomic) CGFloat offsetY;
@property (nonatomic) CGFloat currentScale;

@end

@implementation PGImageBrowserCell

- (void)setModel:(PHAsset *)asset{
    currentAsset = asset;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = NO;
    WS(ws)
    CGFloat width = asset.pixelWidth;
    CGFloat height = asset.pixelHeight;
    if (width >= height) {
        if (asset.pixelWidth > SCREENWIDTH) {
            width = SCREENWIDTH * [UIScreen mainScreen].scale;
            height = SCREENWIDTH * asset.pixelHeight / asset.pixelWidth;
        }
    }else{
        if (asset.pixelHeight > SCREENHEIGHT) {
            height = SCREENHEIGHT * [UIScreen mainScreen].scale;
            width = SCREENWIDTH * asset.pixelWidth / asset.pixelHeight;
        }
    }
    CGSize size = CGSizeMake(width, height);
    size = CGSizeMake(width * 3, height * 3);
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        UIImageView *textimage = [[UIImageView alloc] initWithImage:image];
        
        //移除上一个artimage
        [ws.artimage removeFromSuperview];
        [ws.tap removeTarget:self action:@selector(doubleGesture:)];
        
        ws.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleGesture:)];
        ws.tap.numberOfTapsRequired = 2;
        ws.artimage = [[UIImageView alloc] init];
        ws.artimage.userInteractionEnabled = true;
        ws.artimage.contentMode = UIViewContentModeScaleAspectFit;
        ws.artimage.frame = [self setImage:textimage];
        ws.artimage.image = image;
        [ws.artimage addGestureRecognizer:ws.tap];
        [ws.scrollView addSubview:ws.artimage];
        
        //设置scroll的contentsize的frame
        ws.scrollView.contentSize = ws.artimage.frame.size;
    }];
    
}

//这个方法的返回值决定了要缩放的内容(只能是UISCrollView的子控件)
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.artimage;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    _currentScale = scale;
}

//控制缩放是在中心
- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    //    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    //
    //    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    //
    //    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    //
    //    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    //
    //    self.artimage.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
    //
    //                                       scrollView.contentSize.height * 0.5 + offsetY);
    //当捏或移动时，需要对center重新定义以达到正确显示未知
    //    CGFloat xcenter = scrollView.center.x,ycenter = scrollView.center.y;
    //    xcenter = scrollView.contentSize.width > scrollView.frame.size.width?scrollView.contentSize.width/2 :xcenter;
    //    ycenter = scrollView.contentSize.height > scrollView.frame.size.height ?scrollView.contentSize.height/2 : ycenter;
    //    //双击放大时，图片不能越界，否则会出现空白。因此需要对边界值进行限制。
    //    if(_isDoubleTapingForZoom){
    //        xcenter = kMaxZoom*(kScreenWidth - _touchX);
    //        ycenter = kMaxZoom*(kScreenHeight - _touchY);
    //        if(xcenter > (kMaxZoom - 0.5)*kScreenWidth){//放大后左边超界
    //            xcenter = (kMaxZoom - 0.5)*kScreenWidth;
    //        }else if(xcenter <0.5*kScreenWidth){//放大后右边超界
    //            xcenter = 0.5*kScreenWidth;
    //        }
    //        if(ycenter > (kMaxZoom - 0.5)*kScreenHeight){//放大后左边超界
    //            ycenter = (kMaxZoom - 0.5)*kScreenHeight +_offsetY*kMaxZoom;
    //        }else if(ycenter <0.5*kScreenHeight){//放大后右边超界
    //            ycenter = 0.5*kScreenHeight +_offsetY*kMaxZoom;
    //        }
    //    }
    //    [self.artimage setCenter:CGPointMake(xcenter, ycenter)];
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

//根据不同的比例设置尺寸
-(CGRect) setImage:(UIImageView *)imageView
{
    
    CGFloat imageX = imageView.frame.size.width;
    
    CGFloat imageY = imageView.frame.size.height;
    
    CGRect imgfram;
    
    CGFloat CGscale;
    
    BOOL flx =  (SCREENWIDTH / SCREENHEIGHT) > (imageX / imageY);
    
    if(flx)
    {
        CGscale = SCREENHEIGHT / imageY;
        
        imageX = imageX * CGscale;
        
        imgfram = CGRectMake((SCREENWIDTH - imageX) / 2, 0, imageX, SCREENHEIGHT);
        
        return imgfram;
    }
    else
    {
        CGscale = SCREENWIDTH / imageX;
        
        imageY = imageY * CGscale;
        
        imgfram = CGRectMake(0, (SCREENHEIGHT - imageY) / 2, SCREENWIDTH, imageY);
        
        return imgfram;
    }
    
}

- (void)doubleGesture:(UIGestureRecognizer *)sender{
    //    //当前倍数等于最大放大倍数
    //    //双击默认为缩小到原图
    //    if (currentScale == 3) {
    //        currentScale = 1;
    //        [_scrollView setZoomScale:currentScale animated:YES];
    //        return;
    //    }
    //    //当前等于最小放大倍数
    //    //双击默认为放大到最大倍数
    //    if (currentScale == 1) {
    //        currentScale = 3;
    //        [_scrollView setZoomScale:currentScale animated:YES];
    //        return;
    //    }
    //
    //    CGFloat aveScale = 1 + (3 - 1)/2.0;//中间倍数
    //
    //    //当前倍数大于平均倍数
    //    //双击默认为放大最大倍数
    //    if (currentScale >= aveScale) {
    //        currentScale = 3;
    //        [_scrollView setZoomScale:currentScale animated:YES];
    //        return;
    //    }
    //
    //    //当前倍数小于平均倍数
    //    //双击默认为放大到最小倍数
    //    if (currentScale < aveScale) {
    //        currentScale = 1;
    //        [_scrollView setZoomScale:currentScale animated:YES];
    //        return;
    //    }
    
    _touchX = [sender locationInView:sender.view].x;
    _touchY = [sender locationInView:sender.view].y;
    //    if(_isTwiceTaping){
    //        return;
    //    }
    //    _isTwiceTaping = YES;
    //
    //
    //    if(_currentScale > 1.0){
    //        _currentScale = 1.0;
    //        [_scrollView setZoomScale:1.0 animated:YES];
    //    }else{
    //        _isDoubleTapingForZoom = YES;
    //        _currentScale = kMaxZoom;
    //        [_scrollView setZoomScale:kMaxZoom animated:YES];
    //    }
    //    _isDoubleTapingForZoom = NO;
    //    //延时做标记判断，使用户点击3次时的单击效果不生效。
    //    [self performSelector:@selector(twiceTaping) withObject:nil afterDelay:0.65];
    if (_currentScale > 1.0) {
        _currentScale = 1.0;
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    }else{
        CGFloat newZoomScale = ((_scrollView.maximumZoomScale + _scrollView.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [_scrollView zoomToRect:CGRectMake(_touchX - xsize/2, _touchY - ysize/2, xsize, ysize) animated:YES];
    }
}

-(void)twiceTaping{
    _isTwiceTaping = NO;
}

@end
