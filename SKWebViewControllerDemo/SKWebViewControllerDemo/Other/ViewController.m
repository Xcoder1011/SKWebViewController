//
//  ViewController.m
//  SKWebViewControllerDemo
//
//  Created by KUN on 2017/12/25.
//  Copyright © 2017年 KUN. All rights reserved.
//

#import "ViewController.h"
#import "SKWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:0 target:nil action:nil];
}

// 百度一下
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id webControl = segue.destinationViewController;
    [webControl setValue:[NSURL URLWithString:@"https://www.baidu.com/"] forKey:@"url"];
}


@end
