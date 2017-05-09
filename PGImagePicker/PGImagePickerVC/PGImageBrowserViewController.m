//
//  PGImageBrowserViewController.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "PGImageBrowserViewController.h"
#import "PGImageBrowserCell.h"
#import "AppDelegate+Rotation.h"

#define ANIMATION_TIME 0.2
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height

@interface PGImageBrowserViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CAAnimationDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;

@end

@implementation PGImageBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.hidden = true;
    [AppDelegate updateRotationStatus:true];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.collectionView.hidden = false;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_currentCount inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:false];
    });
    _selectBtn.selected = (_dSelected[@(_currentCount)] != nil);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc{
    NSLog(@"dealloc");
}

#pragma mark- UICollectionView delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _assets.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [UIScreen mainScreen].bounds.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PGImageBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    PHAsset *asset = _assets[indexPath.row];
    [cell setModel:asset];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    int row = scrollView.contentOffset.x / [UIScreen mainScreen].bounds.size.width;
    _selectBtn.selected = (_dSelected[@(row)] != nil);
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    _currentCount = scrollView.contentOffset.x / [UIScreen mainScreen].bounds.size.width;
}

#pragma mark- Action
- (IBAction)goBack:(id)sender {
    [AppDelegate updateRotationStatus:false];
    if (_finish) {
        _finish(_dSelected);
    }
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)imageSelect:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _selectBtn.selected = !_selectBtn.selected;
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithDictionary:_dSelected];
        UICollectionViewCell *cell = self.collectionView.visibleCells[0];
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (_selectBtn.selected) {
            [tempDic setObject:@(_dSelected.count) forKey:@(indexPath.row)];
        }else{
            [tempDic removeObjectForKey:@(indexPath.row)];
        }
        _dSelected = tempDic;
    });
    CABasicAnimation *smaller = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    smaller.fromValue = [NSNumber numberWithFloat:1];
    smaller.toValue = [NSNumber numberWithFloat:0.1];
    smaller.duration = ANIMATION_TIME;
    CABasicAnimation *bigger = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    bigger.fromValue = [NSNumber numberWithFloat:0.1];
    bigger.toValue = [NSNumber numberWithFloat:1];
    bigger.duration = ANIMATION_TIME;
    bigger.beginTime = ANIMATION_TIME;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = ANIMATION_TIME * 2;
    group.repeatCount = 1;
    group.animations = @[smaller,bigger];
    [sender.layer addAnimation:group forKey:@""];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
