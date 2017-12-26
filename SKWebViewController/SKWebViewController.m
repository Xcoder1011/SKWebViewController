//
//  SKWebViewController.m
//  SKWebViewControllerDemo
//
//  Created by KUN on 2017/12/25.
//  Copyright © 2017年 KUN. All rights reserved.
//

#import "SKWebViewController.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

@interface SKWebViewController () <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) WKWebViewConfiguration *webConfig;

@property (nonatomic, strong) WKNavigation *navigation;
@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, strong) UIBarButtonItem *customBackBarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneItem;

@end


@implementation SKWebViewController

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height);
    [self updateNavigationItems];
    if (@available(iOS 11.0, *)) {} else {
        id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
        id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;

        UIEdgeInsets contentInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0.0, bottomLayoutGuide.length, 0.0);
        if (!UIEdgeInsetsEqualToEdgeInsets(contentInsets, self.webView.scrollView.contentInset)) {
            [self.webView.scrollView setContentInset:contentInsets];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateNavigationItems];
    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonClicked:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
        _doneItem = doneButton;
    }
}


#pragma mark - update nav items

-(void)updateNavigationItems{
    
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    if (self.webView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        if (self.navigationController.viewControllers.count == 1) {
            NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray:@[spaceButtonItem,self.customBackBarItem]];
            if ( self.navigationController.topViewController != self){
                [leftBarButtonItems addObject:self.closeButtonItem];
            }
            [self.navigationItem setLeftBarButtonItems:leftBarButtonItems animated:NO];
        } else {
            [self.navigationItem setLeftBarButtonItems:@[self.closeButtonItem] animated:NO];
        }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    }
}


-(UIBarButtonItem*)customBackBarItem{
    if (!_customBackBarItem) {
        UIImage* backItemImage = [[UIImage imageNamed:@"goBack"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* backItemHlImage = [[UIImage imageNamed:@"goBack"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIButton* backButton = [[UIButton alloc] init];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [backButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [backButton setImage:backItemImage forState:UIControlStateNormal];
        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

-(UIBarButtonItem*)closeButtonItem{
    if (!_closeButtonItem) {
        
        if (self.navigationItem.rightBarButtonItem == _doneItem && self.navigationItem.rightBarButtonItem != nil) {
            _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:0 target:self action:@selector(doneButtonClicked:)];
        } else {
            _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:0 target:self action:@selector(closeItemClicked)];
        }
      
    }
    return _closeButtonItem;
}

-(void)customBackItemClicked{
    
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];

}

-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)_updateTitle {
    NSString *title = self.title;
    title = title.length>0 ? title: [_webView title];
    if (title.length > _maxTitleLength) {
        title = [[title substringToIndex:_maxTitleLength-1] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title ;
}

- (void)didFinishLoad{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
    [self _updateTitle];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

    if ([self.navigationController.topViewController isKindOfClass:[SKWebViewController class]]) {
        SKWebViewController* webVC = (SKWebViewController*)self.navigationController.topViewController;
        if (webVC.webView.canGoBack) {
            if (webVC.webView.isLoading) {
                [webVC.webView stopLoading];
            }
            [webVC.webView goBack];
            return NO;
        } else {
            if ([webVC.navigationItem.leftBarButtonItems containsObject:webVC.closeButtonItem]) {
                [webVC updateNavigationItems];
                return NO;
            }
            return YES;
        }
    }else{
        return YES;
    }
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        float progress =[[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        NSLog(@"progress = %f",progress);
        
    } else if ([keyPath isEqualToString:@"scrollView.contentOffset"]) {
        //CGPoint contnetOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        
    } else if ([keyPath isEqualToString:@"title"]) {
        
        NSString *title = [_webView title];
        NSLog(@"title = %@",title);
        [self updateNavigationItems];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - WKNavigationDelegate

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.navigationItem.title = @"加载中...";
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateNavigationItems];
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self didFinishLoad];
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(nonnull NSError *)error{
    
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateNavigationItems];

}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateNavigationItems];}

// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}


// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
    if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {
        
        if (@available(iOS 8.0, *)) {
            if (!self.checkUrlCanOpen || [[UIApplication sharedApplication] canOpenURL:components.URL]) {
                if (@available(iOS 10.0, *)) {
                    [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
                }else{
                    [[UIApplication sharedApplication] openURL:components.URL];
                }
            }
        }else{
            if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    [self updateNavigationItems];
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

// 创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    
    /*
     *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Returned WKWebView was not created with the given configuration.'
     
     
     原因呢：
     每次点击H5中的line会跳转一个新网页，"_black" 是开一个新的页面 打开网页,和Safari中点加号一样！
     当然在应用中如果不实现和Safari一样的效果 那就只能让其在当前页面中 重新加载一次新link
     
     还有一种解决方法:
     
     -(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
     //如果是跳转一个新页面
     if (navigationAction.targetFrame == nil) {
     [webView loadRequest:navigationAction.request];
     }
     decisionHandler(WKNavigationActionPolicyAllow);
     }
     
     */
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}


// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{
    
    NSString *host = webView.URL.host;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:prompt message:host preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText;
        textField.font = [UIFont systemFontOfSize:12];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    NSLog(@"%@",message);
    
    NSString *host = webView.URL.host;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host message:message preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    NSLog(@"%@",message);
    
    NSString *host = webView.URL.host;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host message:message preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}



#pragma mark - Life cycle

- (instancetype)init {
    if (self = [super init]) {
        [self commonInitial];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInitial];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInitial];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL {
    
    if (self = [super init]) {
        _url = URL;
    }
    return self;
}

- (void)commonInitial {
    
    _checkUrlCanOpen = YES;
    _maxTitleLength = 10;

    if (@available(iOS 8.0, *)) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = NO;
    } else {
        _timeoutInternal = 30.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    }
    self.navigationItem.leftItemsSupplementBackButton = YES;
}


- (void)setupSubViews {

    [self.view addSubview:self.webView];
    
    if (_url) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
        request.timeoutInterval = _timeoutInternal;
        request.cachePolicy = _cachePolicy;
        [self.webView loadRequest:request];
    }
    
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
}

- (void)setEnabledWebViewUIDelegate:(BOOL)enabledWebViewUIDelegate {
    _enabledWebViewUIDelegate = enabledWebViewUIDelegate;
    if (@available(iOS 8.0, *)) {
        if (_enabledWebViewUIDelegate) {
            _webView.UIDelegate = self;
        } else {
            _webView.UIDelegate = nil;
        }
    }
}

- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal {
    _timeoutInternal = timeoutInternal;
//    NSMutableURLRequest *request = [_request mutableCopy];
//    request.timeoutInterval = _timeoutInternal;
//    _navigation = [_webView loadRequest:request];
//    _request = [request copy];
}

- (WKWebView *)webView {
    
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.webConfig];
        _webView.navigationDelegate = self;
        if (_enabledWebViewUIDelegate) _webView.UIDelegate = self;
        _webView.multipleTouchEnabled = YES;
        _webView.autoresizesSubviews = YES;
        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.scrollView.backgroundColor = [UIColor clearColor];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_webView addObserver:self forKeyPath:@"scrollView.contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];

    }
    return _webView;
}


- (WKWebViewConfiguration *)webConfig
{
    if (!_webConfig) {
        
        // 创建并配置WKWebView的相关参数
        _webConfig = [[WKWebViewConfiguration alloc] init];
        
        if ([_webConfig respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [_webConfig setAllowsInlineMediaPlayback:YES];
        }
        
        if (@available(iOS 9.0, *)) {
            if ([_webConfig respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                [_webConfig setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        } else {
            
        }
        
        if (@available(iOS 10.0, *)) {
            if ([_webConfig respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]){
                [_webConfig setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
            }
        } else if (@available(iOS 9.0, *)) {
            if ( [_webConfig respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
                [_webConfig setRequiresUserActionForMediaPlayback:NO];
            }
        } else {
            if ( [_webConfig respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
                [_webConfig setMediaPlaybackRequiresUserAction:NO];
            }
        }
        
        // 通过 JS 与 webView 内容交互
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        // 创建设置对象
        WKPreferences *preference = [[WKPreferences alloc]init];
        // 设置字体大小(最小的字体大小)
        preference.minimumFontSize = 9.0;
        // 设置偏好设置对象
        _webConfig.preferences = preference;
        // 自适应屏幕宽度js
        NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:wkUScript];
        _webConfig.userContentController = userContentController;
        // 是否支持 JavaScript
        _webConfig.preferences.javaScriptEnabled = YES;
        // 不通过用户交互，是否可以打开窗口
        _webConfig.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    }
    return _webConfig;
}

- (void)dealloc {
    [_webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [_webView removeObserver:self forKeyPath:@"scrollView.contentOffset"];
    [_webView removeObserver:self forKeyPath:@"title"];
    NSLog(@"One of SKWebViewController's instances was destroyed.");
}


@end
