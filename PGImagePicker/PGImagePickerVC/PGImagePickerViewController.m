//
//  PGImagePickerViewController.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "PGImagePickerViewController.h"
#import "PGImagePickerCell.h"
#import "PGImageBrowserViewController.h"

#define ITEM_COLUMN_COUNT 4
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define EDGEOFFSET 20
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

@interface PGImagePickerViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>{
    BOOL nStartSelected;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (readwrite)   NSInteger           nMaxCount;// -1 : 无限制

@property (nonatomic, strong) NSMutableArray *thumbnailArray;

@property (strong, nonatomic)   NSMutableDictionary     *dSelected;
@property (strong, nonatomic)	NSIndexPath				*lastAccessed;
@property (strong, nonatomic)   NSIndexPath             *nStartIndexPath;
@property (strong, nonatomic)   NSTimer                 *timer;
@property (strong, nonatomic)   UIPanGestureRecognizer  *panSelection;
@property (assign, nonatomic)   NSInteger               contentSizeHeight;

@end

@implementation PGImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpUI];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self getThumbnailImages];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.contentSizeHeight = self.collectionView.contentSize.height;
            });
        });
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)dealloc{
    NSLog(@"dealloc");
}

+ (UINavigationController *)getInstance {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PGImagePicker" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"PGImagePickerNav"];

}

#pragma mark- init
- (void)setUpUI{
    _thumbnailArray = [NSMutableArray array];
    _dSelected = [[NSMutableDictionary alloc] init];
    _nMaxCount = -1;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    int width = ((int)screenBounds.size.width - 3 * _flowLayout.minimumLineSpacing) / ITEM_COLUMN_COUNT;
    _flowLayout.itemSize = CGSizeMake(width, width);
    if ([_delegate respondsToSelector:@selector(numberOfItemCanSelected)]) {
        _nMaxCount = [_delegate numberOfItemCanSelected];
    }
    
    _panSelection = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanForSelection:)];
    [self.view addGestureRecognizer:_panSelection];
    
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapForPreview:)];
    longTap.minimumPressDuration = 0.3;
    [self.view addGestureRecognizer:longTap];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishSelectImage)];
    
}

//获取所有图片
- (void)getThumbnailImages {
    
    // 获得所有的自定义相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    // 遍历所有的自定义相簿
    for (PHAssetCollection *assetCollection in assetCollections) {
        [self enumerateAssetsInAssetCollection:assetCollection original:NO];
    }
    // 获得相机胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    [self enumerateAssetsInAssetCollection:cameraRoll original:NO];
}

/**
 *  遍历相簿中的所有图片
 *  @param assetCollection 相簿
 *  @param original        是否要原图
 */
- (void)enumerateAssetsInAssetCollection:(PHAssetCollection *)assetCollection original:(BOOL)original
{
    NSLog(@"相簿名:%@", assetCollection.localizedTitle);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = YES;
    
    WS(ws)
    // 获得某个相簿中的所有PHAsset对象
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    for (PHAsset *asset in assets) {
        // 是否要原图
        CGSize size = original ? CGSizeMake(asset.pixelWidth, asset.pixelHeight) : CGSizeZero;
        // 从asset中获得图片
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                [ws.thumbnailArray addObject:asset];
            }
        }];
    }
}

//-(void)getAllPictures{
//    NSString *tipTextWhenNoPhotosAuthorization; // 提示语
//    // 获取当前应用对照片的访问授权状态
//    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
//    // 如果没有获取访问授权，或者访问授权状态已经被明确禁止，则显示提示语，引导用户开启授权
//    if (authorizationStatus == ALAuthorizationStatusRestricted || authorizationStatus == ALAuthorizationStatusDenied) {
//        NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
//        NSString *appName = [mainInfoDictionary objectForKey:@"CFBundleDisplayName"];
//        tipTextWhenNoPhotosAuthorization = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问你的手机相册", appName];
//        // 展示提示语
//    }else{
//        _imageArray = [[NSArray alloc] init];
//        _mutableArray = [[NSMutableArray alloc] init];
//        NSMutableArray* assetURLDictionaries = [[NSMutableArray alloc] init];
//        _library = [[ALAssetsLibrary alloc] init];
//        void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
//            if(result != nil) {
//                if([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
//                    [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
//                    NSURL *url= (NSURL*) [[result defaultRepresentation]url];
//                    
//                    [_library assetForURL:url
//                              resultBlock:^(ALAsset *asset) {
//                                  [_mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]]];
//                                  if ([_mutableArray count] == count){
//                                      _imageArray=[[NSArray alloc] initWithArray:_mutableArray];
//                                      [self.collectionView reloadData];
//                                  }
//                              }
//                             failureBlock:^(NSError *error){ NSLog(@"operation was not successfull!"); } ];
//                }
//                
//            }
//            
//        };
//        
//        NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
//        void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
//            
//            if(group != nil) {
//                
//                [group enumerateAssetsUsingBlock:assetEnumerator];
//                
//                [assetGroups addObject:group];
//                
//                count = [group numberOfAssets];
//                
//            }
//            
//        };
//        assetGroups = [[NSMutableArray alloc] init];
//        [_library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:assetGroupEnumerator failureBlock:^(NSError *error) {
//            NSLog(@"There is an error");
//        }];
//    }
//    
//}


#pragma mark- UIColloctionView delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _thumbnailArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PGImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    PHAsset *asset = _thumbnailArray[indexPath.row];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = YES;
    __weak PGImagePickerCell *tempCell = cell;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(_flowLayout.itemSize.width * 3, _flowLayout.itemSize.height * 3) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        tempCell.imageView.image = result;
    }];
    if (_dSelected[@(indexPath.row)] == nil){
        cell.selectedImage.hidden = true;
    }else{
        cell.selectedImage.hidden = false;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ((_dSelected[@(indexPath.row)] == nil) && (_nMaxCount > _dSelected.count)){
        [self setIndexPath:indexPath SelectStatus:true];
    }else{
        [self setIndexPath:indexPath SelectStatus:false];
    }
}

#pragma mark- GestureRecognizer Action
- (void)onPanForSelection:(UIPanGestureRecognizer *)gestureRecognizer
{
    double fX = [gestureRecognizer locationInView:_collectionView].x;
    double fY = [gestureRecognizer locationInView:_collectionView].y;
    
    double edgeY = [gestureRecognizer locationInView:self.view].y;
    if (fY >= _contentSizeHeight || fY <= -64) {
        [_timer invalidate];
        _timer = nil;
    }else{
        if (edgeY > SCREENHEIGHT - EDGEOFFSET - 64) {
            if (SCREENHEIGHT - 64 - edgeY < EDGEOFFSET) {
                if (_timer == nil) {
                    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerSchedule:) userInfo:@((int)SCREENHEIGHT - edgeY) repeats:true];
                }
            }
        }else if (edgeY < EDGEOFFSET){
            if (_timer == nil) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerSchedule:) userInfo:@((int)edgeY - EDGEOFFSET) repeats:true];
            }
        }else{
            [_timer invalidate];
            _timer = nil;
        }
    }
    for (UICollectionViewCell *cell in _collectionView.visibleCells)
    {
        float fSX = cell.frame.origin.x;
        float fEX = cell.frame.origin.x + cell.frame.size.width;
        float fSY = cell.frame.origin.y;
        float fEY = cell.frame.origin.y + cell.frame.size.height;
        
        if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
        {
            NSIndexPath *indexPath = [_collectionView indexPathForCell:cell];
            
            if (_nStartIndexPath == nil) {
                _nStartIndexPath = indexPath;
                if (_dSelected[@(_nStartIndexPath.row)]) {
                    nStartSelected = true;
                }
            }
            if (_lastAccessed == nil) {
                [self collectionView:_collectionView didSelectItemAtIndexPath:indexPath];
            }else if (_lastAccessed != indexPath)
            {
                NSInteger startI = 0;
                NSInteger endI = 0;
                /*FIXME: 该注释是模仿iOS自带相册手势选择，即pan经过的都选，不会出现反选 */
//                NSInteger tempI = 0;
//                
//                startI = _nStartIndexPath.row;
//                endI = _lastAccessed.row;
//                if (startI > endI) {
//                    tempI = startI;
//                    startI = endI;
//                    endI = tempI;
//                }
////                NSLog(@"clean: start: %ld end: %ld",startI,endI);
//                for (NSInteger i = startI; i <= endI; i++) {
//                    [self setIndexPath:[NSIndexPath indexPathForRow:i inSection:0] SelectStatus:false];
//                }
//                
//                startI = _nStartIndexPath.row;
//                endI = indexPath.row;
//                if (startI > endI) {
//                    tempI = startI;
//                    startI = endI;
//                    endI = tempI;
//                    if (endI - startI > _nMaxCount) {
//                        startI = endI - _nMaxCount + 1;
//                    }
//                }else{
//                    if (endI - startI > _nMaxCount) {
//                        endI = startI + _nMaxCount - 1;
//                    }
//                }
////                NSLog(@"fill: start: %ld end: %ld",startI,endI);
//                for (NSInteger i = startI; i <= endI; i++) {
//                    [self setIndexPath:[NSIndexPath indexPathForRow:i inSection:0] SelectStatus:true];
//                }
                /*FIXME: 以下是在手势选择时，如遇到被选的相片，会被反选 */
                [_delegate imagePicker:self numberOfAssetsDidSelected:_dSelected.count];
                if (indexPath.row >= _nStartIndexPath.row) {
                    if (_lastAccessed.row < indexPath.row) {
                        startI = _lastAccessed.row + 1;
                        endI = indexPath.row;
                    }else{
                        startI = indexPath.row;
                        endI = _lastAccessed.row - 1;
                    }
                    if (indexPath.row - _nStartIndexPath.row < _lastAccessed.row - _nStartIndexPath.row) {
                        startI++;
                        endI++;
                    }
                    if (_lastAccessed.row < _nStartIndexPath.row) {
                        startI--;
                    }
                }else{
                    if (_lastAccessed.row < indexPath.row) {
                        startI = _lastAccessed.row;
                        endI = indexPath.row;
                    }else{
                        startI = indexPath.row;
                        endI = _lastAccessed.row;
                    }
                    if (_lastAccessed.row >= _nStartIndexPath.row) {
                        
                    }else{
                        endI--;
                    }
                }
                for (NSInteger i = startI; i <= endI; i++) {
                    [self collectionView:_collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                }
            }
            
            if (!_dSelected[@(_nStartIndexPath.row)]) {
                [_dSelected setObject:@(_dSelected.count) forKey:@(_nStartIndexPath.row)];
                PGImagePickerCell *cell = (PGImagePickerCell *)[_collectionView cellForItemAtIndexPath:_nStartIndexPath];
                [cell setSelectMode:true];
                if (_nMaxCount == -1)
                    self.title = [NSString stringWithFormat:@"(%d)", (int)_dSelected.count];
                else
                    self.title = [NSString stringWithFormat:@"(%d/%d)", (int)_dSelected.count, (int)_nMaxCount];
            }
            
            if (nStartSelected && _dSelected[@(_nStartIndexPath.row)]) {
                [_dSelected setObject:@(_dSelected.count) forKey:@(_nStartIndexPath.row)];
                PGImagePickerCell *cell = (PGImagePickerCell *)[_collectionView cellForItemAtIndexPath:_nStartIndexPath];
                [cell setSelectMode:false];
                if (_nMaxCount == -1)
                    self.title = [NSString stringWithFormat:@"(%d)", (int)_dSelected.count];
                else
                    self.title = [NSString stringWithFormat:@"(%d/%d)", (int)_dSelected.count, (int)_nMaxCount];
            }
            
            if (_dSelected.count == 30) {
                NSArray *key =  _dSelected.allKeys;
                NSNumber *num;
                if (indexPath.row > _nStartIndexPath.row) {
                    num = [key sortedArrayUsingSelector:@selector(compare:)].lastObject;
                }else{
                    num = [key sortedArrayUsingSelector:@selector(compare:)].firstObject;
                }
                _lastAccessed = [NSIndexPath indexPathForRow:num.integerValue inSection:0];
            }else{
                _lastAccessed = indexPath;
            }
            
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastAccessed = nil;
        _nStartIndexPath = nil;
        nStartSelected = false;
        _collectionView.scrollEnabled = YES;
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)timerSchedule:(NSTimer *)timer{
    NSNumber *edgeY = timer.userInfo;
    int offsetY = 0;
    if (edgeY.intValue > 0) {
        offsetY = MIN(EDGEOFFSET, edgeY.intValue);
    }else{
        offsetY = MAX(-EDGEOFFSET, edgeY.intValue) > -1 ? -8:-16;
    }
    self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentOffset.y + offsetY);
    [self onPanForSelection:_panSelection];
    if (self.collectionView.contentOffset.y >= _contentSizeHeight || self.collectionView.contentOffset.y <= 0) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)setIndexPath:(NSIndexPath *)indexPath SelectStatus:(BOOL)flag{
    PGImagePickerCell *cell = (PGImagePickerCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    if (flag){
        if (_dSelected.count < _nMaxCount){
            _dSelected[@(indexPath.row)] = @(_dSelected.count);
            [cell setSelectMode:true];
        }
    }else{
        [_dSelected removeObjectForKey:@(indexPath.row)];
        [cell setSelectMode:false];
    }
    if (_nMaxCount == -1)
        self.title = [NSString stringWithFormat:@"(%d)", (int)_dSelected.count];
    else
        self.title = [NSString stringWithFormat:@"(%d/%d)", (int)_dSelected.count, (int)_nMaxCount];
}

- (void)onLongTapForPreview:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        double fX = [gestureRecognizer locationInView:_collectionView].x;
        double fY = [gestureRecognizer locationInView:_collectionView].y;
        
        NSIndexPath *indexPath = nil;
        for (UICollectionViewCell *cell in _collectionView.visibleCells)
        {
            float fSX = cell.frame.origin.x;
            float fEX = cell.frame.origin.x + cell.frame.size.width;
            float fSY = cell.frame.origin.y;
            float fEY = cell.frame.origin.y + cell.frame.size.height;
            
            if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
            {
                indexPath = [_collectionView indexPathForCell:cell];
                [self performSegueWithIdentifier:@"imageShow" sender:indexPath];
                break;
            }
        }
    }
}

#pragma mark- UINavigationItem Action
- (void)goBack{
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void)finishSelectImage {
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSNumber *num in _dSelected) {
        [tempArr addObject:_thumbnailArray[num.integerValue]];
    }
    
    [_delegate imagePicker:self assetsPicked:tempArr];
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PGImageBrowserViewController *browser = (PGImageBrowserViewController *)segue.destinationViewController;
    browser.currentCount = ((NSIndexPath *)sender).row;
    browser.assets = _thumbnailArray;
    browser.dSelected = _dSelected;
    browser.nMaxCount = _nMaxCount;
    WS(ws)
    browser.finish = ^(NSDictionary *dSelected){
        ws.dSelected = [NSMutableDictionary dictionaryWithDictionary:dSelected];
        [ws.collectionView reloadData];
    };
}


@end
