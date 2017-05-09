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

@interface PGLineLayout : UICollectionViewFlowLayout

@end

@implementation PGLineLayout

- (void)prepareLayout
{
    [super prepareLayout];
    
}

// 当布局改变时重新加载layout
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}


// 对layoutAttrute根据需要做调整，也许是frame,alpha,transform等
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // 获取父类原先的(未放大形变的)attrsArray,我们要对其attr的frame属性做下调整
    NSArray *attrsArray = [super layoutAttributesForElementsInRect:rect];
    CGFloat centerX = self.collectionView.frame.size.width*0.5 + self.collectionView.contentOffset.x;
    
    for(UICollectionViewLayoutAttributes *attr in attrsArray)
    {
        CGFloat length = 0.f;
        if(attr.center.x > centerX)
        {
            length = attr.center.x - centerX;
        }
        else
        {
            length = centerX - attr.center.x;
        }
        
        CGFloat scale = 1 - length / self.collectionView.frame.size.width;
        
        attr.transform = CGAffineTransformMakeScale(scale, scale);
    }
    
    return attrsArray;
}


//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
//{
//    // 某cell滑动停止时的最终rect
//    CGRect rect;
//    rect.origin.x = proposedContentOffset.x;
//    rect.origin.y = 0.f;
//    rect.size = self.collectionView.frame.size;
//    
//    // 计算collectionView最中心点的x值
//    CGFloat centerX = proposedContentOffset.x + self.collectionView.frame.size.width * 0.5;
//    
//    // 获得super已经计算好的布局属性
//    CGFloat offset = 0.0f;
//    NSArray *attrsArray = [super layoutAttributesForElementsInRect:rect];
//    for(UICollectionViewLayoutAttributes *attr in attrsArray)
//    {
//        if(attr.center.x - centerX > 100 || centerX - attr.center.x > 100)
//        {
//            offset = attr.center.x - centerX; // 此刻，cell的center的x和此刻CollectionView的中心点的距离
//        }
//    }
//    
//    proposedContentOffset.x += offset;
//    
//    return proposedContentOffset;
//}

@end

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

- (CGPoint)collectionView:(UICollectionView *)collectionView targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset{
    return CGPointMake(_currentCount * [UIScreen mainScreen].bounds.size.width, 0);
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
