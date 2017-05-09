//
//  ViewController.m
//  PGImagePicker
//
//  Created by 果儿 on 2017/5/7.
//  Copyright © 2017年 果儿. All rights reserved.
//

#import "ViewController.h"
#import "PGImagePickerViewController.h"
#import <Photos/Photos.h>

@interface ViewController ()<PGImagePickerViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray<PHAsset *> *imageArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _imageArr = [NSMutableArray array];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushToImgPicker:(id)sender {
    UINavigationController *imgPikcerNav = [PGImagePickerViewController getInstance];
    ((PGImagePickerViewController *)imgPikcerNav.topViewController).delegate = self;
    [self presentViewController:imgPikcerNav animated:true completion:nil];
}

- (NSInteger)numberOfItemCanSelected{
    return 30;
}

- (void)imagePicker:(PGImagePickerViewController *)imagePicker numberOfAssetsDidSelected:(NSInteger)number{
    
}

- (void)imagePicker:(PGImagePickerViewController *)imagePicker assetsPicked:(NSArray *)assets{
    _imageArr = assets;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    PHAsset *asset = _imageArr[indexPath.row];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeZero contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        cell.imageView.image = result;
    }];
    return cell;
}

@end
