//
//  MUPhotoPreviewView.m
//  MUKit_Example
//
//  Created by Jekity on 2017/11/10.
//  Copyright © 2017年 Jeykit. All rights reserved.
//

#import "MUPhotoPreviewView.h"
#import "MUZoomingScrollView.h"
#import "MUPhotoPreviewController.h"


#define  kWidth  self.scrollView.bounds.size.width
#define  kHeight self.scrollView.bounds.size.height
#define kPageControlMargin 10.0f
@interface MUPhotoPreviewView()<UIScrollViewDelegate,MUZoomingScrollViewDelegate>
@property (nonatomic, strong) PHImageManager *cacheImageManager;
@property(strong, nonatomic) UIScrollView *scrollView;
// kImageCount = array.count,图片数组个数
@property(assign, nonatomic) NSInteger kImageCount;
// 记录nextImageView的下标 默认从1开始
@property(assign, nonatomic) NSInteger nextPhotoIndex;
// 记录lastImageView的下标 默认从 _kImageCount - 1 开始
@property(assign, nonatomic) NSInteger lastPhotoIndex;
@property(strong, nonatomic) MUZoomingScrollView *lastScrollView;
@property(strong, nonatomic) MUZoomingScrollView *currentScrollView;
@property(strong, nonatomic) MUZoomingScrollView *nextScrollView;
@end

@implementation MUPhotoPreviewView

#pragma mark - 初始化方法
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.currentIndex = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.currentIndex = 0;
    }
    return self;
}


#pragma mark - lazy loading
-(UIScrollView *)scrollView{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.clipsToBounds = YES;
        _scrollView.layer.masksToBounds = YES;
    }
    return _scrollView;
}

-(MUZoomingScrollView *)lastScrollView{
    
    if (!_lastScrollView) {
        _lastScrollView = [[MUZoomingScrollView alloc]init];
        _lastScrollView.backgroundColor = [UIColor blackColor];
        _lastScrollView.tapDelegate = self;
    }
    return _lastScrollView;
}
-(MUZoomingScrollView *)nextScrollView{
    if (!_nextScrollView) {
        _nextScrollView = [[MUZoomingScrollView alloc]init];
        _nextScrollView.backgroundColor = [UIColor blackColor];
        _nextScrollView.tapDelegate = self;
    }
    return _nextScrollView;
}
-(MUZoomingScrollView *)currentScrollView{
    if (!_currentScrollView) {
        _currentScrollView = [[MUZoomingScrollView alloc]init];
        _currentScrollView.backgroundColor = [UIColor blackColor];
        _currentScrollView.tapDelegate = self;
    }
    return _currentScrollView;
}
-(PHImageManager *)cacheImageManager{
    if (!_cacheImageManager) {
        _cacheImageManager = [PHCachingImageManager defaultManager];
    }
    return _cacheImageManager;
}

#pragma mark -configured
-(void)configure{
    
    self.scrollView.frame = [self frameForScorllView];
    [self addSubview:self.scrollView];
    // 添加最初的三张imageView
    [self.scrollView addSubview:self.lastScrollView];
    [self.scrollView addSubview:self.nextScrollView];
    [self.scrollView addSubview:self.currentScrollView];
    
    if (self.currentIndex > _kImageCount - 1 || self.currentIndex == 0) {
        // 将上一张图片设置为数组中最后一张图片
        [self setImageView:_lastScrollView withSubscript:(_kImageCount-1)];
        // 将当前图片设置为数组中第一张图片
        [self setImageView:_currentScrollView withSubscript:0];
        
        // 将下一张图片设置为数组中第二张图片,如果数组只有一张图片，则上、中、下图片全部是数组中的第一张图片
        [self setImageView:_nextScrollView withSubscript:_kImageCount == 1 ? 0 : 1];
        self.nextPhotoIndex = 1;
        self.lastPhotoIndex = _kImageCount - 1;
    }else if(self.currentIndex == _kImageCount - 1){
        // 将上一张图片设置为数组中最后一张图片
        [self setImageView:_lastScrollView withSubscript:_currentIndex - 1];
        // 将当前图片设置为数组中第一张图片
        [self setImageView:_currentScrollView withSubscript:_currentIndex];
        // 将下一张图片设置为数组中第二张图片,如果数组只有一张图片，则上、中、下图片全部是数组中的第一张图片
        [self setImageView:_nextScrollView withSubscript:0];
        
        self.nextPhotoIndex = 0;
        self.lastPhotoIndex = _currentIndex - 1;
    }else{
        // 将上一张图片设置为数组中最后一张图片
        [self setImageView:_lastScrollView withSubscript:_currentIndex - 1];
        // 将当前图片设置为数组中第一张图片
        [self setImageView:_currentScrollView withSubscript:_currentIndex];
        // 将下一张图片设置为数组中第二张图片,如果数组只有一张图片，则上、中、下图片全部是数组中的第一张图片
        [self setImageView:_nextScrollView withSubscript:_currentIndex + 1];
        
        self.nextPhotoIndex = _currentIndex + 1;
        self.lastPhotoIndex = _currentIndex - 1;
    }
    _scrollView.contentSize = CGSizeMake(kWidth * 3, kHeight);
    //显示中间的图片
    _scrollView.contentOffset = CGPointMake(kWidth, 0);
    [self layoutIfNeeded];
}

#pragma mark - scrollView
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    // 到第一张图片时   (一上来，当前图片的x值是kWidth)
    if (ceil(scrollView.contentOffset.x) <= 0) {  // 右滑
        _nextScrollView.image = _currentScrollView.image;
        _currentScrollView.image = _lastScrollView.image;
        if (self.doneUpdateCurrentIndex) {
            self.doneUpdateCurrentIndex(_lastPhotoIndex);
        }
        // 将轮播图的偏移量设回中间位置
        //        [scrollView setContentOffset:CGPointMake(kWidth, 0) animated:YES];
        scrollView.contentOffset = CGPointMake(kWidth, 0);
        _lastScrollView.image = nil;
        // 一定要是小于等于，否则数组中只有一张图片时会出错
        if (_lastPhotoIndex <= 0) {
            _lastPhotoIndex = _kImageCount - 1;
            _nextPhotoIndex = _lastPhotoIndex - (_kImageCount - 2);
        } else {
            _lastPhotoIndex--;
            if (_nextPhotoIndex == 0) {
                _nextPhotoIndex = _kImageCount - 1;
            } else {
                _nextPhotoIndex--;
            }
        }
        
        [self setImageView:_lastScrollView withSubscript:_lastPhotoIndex];
    }
    // 到最后一张图片时（最后一张就是轮播图的第三张）
    if (ceil(scrollView.contentOffset.x)  >= kWidth*2) {  // 左滑
        _lastScrollView.image = _currentScrollView.image;
        _currentScrollView.image = _nextScrollView.image;
        if (self.doneUpdateCurrentIndex) {
            self.doneUpdateCurrentIndex(_nextPhotoIndex);
        }
        // 将轮播图的偏移量设回中间位置
        //        [scrollView setContentOffset:CGPointMake(kWidth, 0) animated:YES];
        scrollView.contentOffset = CGPointMake(kWidth, 0);
        _nextScrollView.image = nil;
        // 一定要是大于等于，否则数组中只有一张图片时会出错
        if (_nextPhotoIndex >= _kImageCount - 1 ) {
            _nextPhotoIndex = 0;
            _lastPhotoIndex = _nextPhotoIndex + (_kImageCount - 2);
        } else{
            _nextPhotoIndex++;
            if (_lastPhotoIndex == _kImageCount - 1) {
                _lastPhotoIndex = 0;
            } else {
                _lastPhotoIndex++;
            }
        }
        
        [self setImageView:_nextScrollView withSubscript:_nextPhotoIndex];
    }
}
static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}
//根据下标设置imgView的image
-(void)setImageView:(MUZoomingScrollView *)imgView withSubscript:(NSInteger)subcript{
    
    
    if (self.fetchResult.count > 0) {
        
        PHAsset *asset = self.fetchResult[subcript];
        CGSize itemSize = CGSizeMake(kWidth, kHeight);
        CGSize targetSize = CGSizeScale(itemSize, [UIScreen mainScreen].scale);
        [self.cacheImageManager requestImageForAsset:asset
                                          targetSize:targetSize
                                         contentMode:PHImageContentModeAspectFill
                                             options:nil
                                       resultHandler:^(UIImage *result, NSDictionary *info) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               imgView.hidden = YES;
                                               imgView.image = result;
                                               imgView.mediaType = self.mediaType;
                                               imgView.hidden = NO;
                                           });
                                           
                                       }];
    }
    
    
}



-(void)dealloc {
    NSLog(@"dealloc");
    _scrollView.delegate = nil;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Hide controls when dragging begins
    //    self.previewController
    if (self.hideControls) {
        self.hideControls();
    }
}

#pragma mark -pramters
-(void)setFetchResult:(PHFetchResult *)fetchResult{
    if (fetchResult.count == 0) return;
    _fetchResult = fetchResult;
    self.kImageCount = fetchResult.count;
    [self configure];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    //    self.scrollView.frame = [self frameForScorllView];
    // 重新设置contentOffset和contentSize对于轮播图下拉放大以及里面的图片跟随放大起着关键作用，因为scrollView放大了，如果不手动设置contentOffset和contentSize，则会导致scrollView的容量不够大，从而导致图片越出scrollview边界的问题
    self.scrollView.contentSize = CGSizeMake(kWidth * 3,kHeight);
    // 这里如果采用动画效果设置偏移量将不起任何作用
    self.scrollView.contentOffset = CGPointMake(kWidth, 0);
    
    [self layoutVisiblePages];
    //    self.lastScrollView.frame = CGRectMake(0, 0, kWidth, kHeight);
    //    self.currentScrollView.frame = CGRectMake(kWidth, 0, kWidth, kHeight);
    //    self.nextScrollView.frame = CGRectMake(kWidth * 2, 0, kWidth, kHeight);
    
    NSLog(@"--- %@",NSStringFromCGRect(self.scrollView.frame));
    
}



- (void)layoutVisiblePages {
    
    
    self.lastScrollView.frame    = [self frameForPageAtInde:0];
    self.currentScrollView.frame = [self frameForPageAtInde:1];
    self.nextScrollView.frame    = [self frameForPageAtInde:2];
    
}
//- (CGRect)frameForPagingScrollView {
//    CGRect frame = self.bounds;// [[UIScreen mainScreen] bounds];
//    frame.origin.x -= kPageControlMargin;
//    frame.size.width += (2 * PADDING);
//    return CGRectIntegral(frame);
//}
- (CGRect)frameForPageAtInde:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = self.scrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * kPageControlMargin);
    pageFrame.origin.x = (bounds.size.width * index) + kPageControlMargin;
    return CGRectIntegral(pageFrame);
}
- (CGRect)frameForScorllView {
    CGRect frame = self.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= kPageControlMargin;
    frame.size.width += (2 * kPageControlMargin);
    return CGRectIntegral(frame);
}

#pragma mark-delegate
-(void)muZoomingScrollView:(UIScrollView *)view mediaType:(NSInteger)mediaType{
    if (self.handleSingleTap) {
        self.handleSingleTap(0,self.mediaType);
    }
}
- (void)muPlayVideo:(UIScrollView *)view mediaType:(NSInteger)mediaType;
{
    if (self.handleSingleTapWithPlayVideo) {
        self.handleSingleTapWithPlayVideo(0, self.mediaType);
    }
    
}
-(void)muZoomingScrollViewDragging:(UIScrollView *)view cancle:(BOOL)cancle{
    
    if (self.handleScrollViewDelegate) {
        self.handleScrollViewDelegate(cancle);
    }
}
@end
