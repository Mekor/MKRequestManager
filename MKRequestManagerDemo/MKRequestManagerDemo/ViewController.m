//
//  ViewController.m
//  MKRequestManagerDemo
//
//  Created by 微指 on 16/5/16.
//  Copyright © 2016年 Mekor. All rights reserved.
//

#import "ViewController.h"
#import "MKRequestManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // post
    [self makePOSTRequest];
}

- (void)makePOSTRequest {
    
    [[MKRequestManager sharedInstance] POST:@"http://httpbin.org/post" params:@{@"foo": @"bar"} success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"responseObject-->\n%@",responseObject);
    } fail:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error%@",error);
    }];
}

@end
