//
//  SKWebViewController.h
//  SKWebViewControllerDemo
//
//  Created by KUN on 2017/12/25.
//  Copyright © 2017年 KUN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKWebView;
@interface SKWebViewController : UIViewController

@property(nonatomic, assign) BOOL enabledWebViewUIDelegate;

@property(nonatomic, assign) NSTimeInterval timeoutInternal;

@property(nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

@property(nonatomic, assign) BOOL checkUrlCanOpen;
// Default is 10.
@property(nonatomic, assign) NSUInteger maxTitleLength;

@property(nonatomic, strong) NSURL *url;

@property(nonatomic, strong, readonly) WKWebView *webView;

@property(nonatomic, strong, readonly) UIBarButtonItem *customBackBarItem;

- (instancetype)initWithURL:(NSURL *)URL;

@end
