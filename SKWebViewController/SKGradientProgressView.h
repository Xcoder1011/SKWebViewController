//
//  SKGradientProgressView.h
//  SKWebViewControllerDemo
//
//  Created by KUN on 2017/12/26.
//  Copyright © 2017年 KUN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKGradientProgressView : UIView

- (instancetype)initWithFrame:(CGRect)frame ;
- (instancetype)initWithCoder:(NSCoder *)aDecoder ;

- (instancetype)initWithProgressViewStyle:(UIProgressViewStyle)style;

@property(nonatomic) UIProgressViewStyle progressViewStyle;
@property(nonatomic) float progress;                        // 0.0 .. 1.0, default is 0.0. values outside are pinned.

@property(nonatomic, strong) UIColor* progressTintColor;
@property(nonatomic, strong) UIColor* trackTintColor ;

- (void)setProgress:(float)progress animated:(BOOL)animated;


@end
