//
//  FlyImageTableViewCell.m
//  Demo
//
//  Created by Norris Tong on 4/14/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageTableViewCell.h"
#import "UIImageView+MUImageCache.h"
//#import "ProgressImageView.h"

@implementation FlyImageTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = 10;
    [self addSubview:imageView];
	
    return imageView;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	[imageView setImageURL:url.absoluteString];
}

@end
