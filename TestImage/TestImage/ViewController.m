//
//  ViewController.m
//  TestImage
//
//  Created by LL on 2019/1/17.
//  Copyright © 2019年 LL. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Scale.h"
#import <AFNetworking/AFNetworking.h>

@interface LLFile : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIImage *previewImage;

@end

@implementation LLFile


@end

@interface LLCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImgV;
@property (weak, nonatomic) IBOutlet UIImageView *imageV;
@property (weak, nonatomic) IBOutlet UILabel *labTitle;
@property (nonatomic, assign) NSInteger index;




@end

@implementation LLCollectionCell

/**
 自定义文件视图
 
 @param file 文件信息
 @param row 行数
 @param collectionView 视图
 */
- (void)customCellWithFile:(LLFile *)file indexRow:(NSInteger)row loading:(BOOL)loading collectionView:(UICollectionView *)collectionView {
    NSLog(@"cell row:%@",@(row));
    self.index = row;
    self.labTitle.text = file.name;
    if (file.previewImage != nil) {
        self.imageV.image = file.previewImage;
        self.iconImgV.image = nil;
    }else {
        self.imageV.image = nil;
        self.iconImgV.image = [UIImage imageNamed:@"list_image"];
        if (loading) {
            __weak typeof(self) weakSelf = self;
            [self loadImage:row block:^(UIImage *image, NSInteger index) {
                file.previewImage = image;
                if (weakSelf.index == index) {
                    weakSelf.imageV.image = file.previewImage;
                    weakSelf.iconImgV.image = nil;
                }else {
                    NSLog(@"==not equal==:%@==%@",@(weakSelf.index),@(index));
                }
            }];
        }else {
            NSLog(@"==not loading==:%@",@(row));
        }
    }
}

- (void)loadImage:(NSInteger)row block:(void (^)(UIImage *image, NSInteger index))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *result = [UIImage ws_imageWithIndex:row];
            if (block) {
                block(result, row);
            }
        });
    });
}

@end

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *listCV;
@property (nonatomic, strong) NSMutableArray *listArray;
@property (nonatomic, assign) BOOL isBegin;
@property (nonatomic, assign) BOOL readyLoad;
@property (nonatomic, assign) CGFloat yOffset;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.yOffset = -9999.0;
    self.listArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i=0; i<100; i++) {
        LLFile *file = [[LLFile alloc] init];
        file.index = i;
        file.name = [NSString stringWithFormat:@"title%02d",i];
        file.previewImage = nil;
        [self.listArray addObject:file];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.yOffset != -9999.0) {
        CGFloat offset = fabs(scrollView.contentOffset.y - self.yOffset);
        if (offset < 5.0) {
            self.readyLoad = YES;
        }else {
            self.readyLoad = NO;
        }
    }else {
        self.readyLoad = YES;
    }
    self.yOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.isBegin) {
        if (!decelerate) {
            NSLog(@"==1==ready load:%@",@(self.readyLoad));
            NSArray<NSIndexPath *> *array = [self.listCV indexPathsForVisibleItems];
            for (NSIndexPath *indexPath in array) {
                LLFile *file = self.listArray[indexPath.row];
                if (file.previewImage == nil) {
                    [self.listCV reloadItemsAtIndexPaths:@[indexPath]];
                }
            }
        }else {
            NSLog(@"==2==");
        }
    }else {
        NSLog(@"==5==");
        self.readyLoad = YES;
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    NSLog(@"==3==");
    self.isBegin = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"==4==ready load:%@",@(self.readyLoad));
    self.isBegin = NO;
    NSArray<NSIndexPath *> *array = [self.listCV indexPathsForVisibleItems];
    for (NSIndexPath *indexPath in array) {
        LLFile *file = self.listArray[indexPath.row];
        if (file.previewImage == nil) {
            [self.listCV reloadItemsAtIndexPaths:@[indexPath]];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.listArray.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const ListIdentifier = @"Cell";
    LLCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ListIdentifier forIndexPath:indexPath];
    
    LLFile *file = self.listArray[indexPath.row];
    [cell customCellWithFile:file indexRow:indexPath.row loading:self.readyLoad collectionView:collectionView];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(320.0, 50.0);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.5;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

@end
