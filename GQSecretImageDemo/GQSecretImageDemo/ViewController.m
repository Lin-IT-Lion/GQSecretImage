//
//  ViewController.m
//  GQSecretImageDemo
//
//  Created by 林国强 on 16/6/6.
//  Copyright © 2016年 林国强. All rights reserved.
//

#import "ViewController.h"
#import "GQSecretImageHandler.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    [[GQSecretImageHandler sharedInstance] activeWtihSetting:^(GQSecretImageModel *model) {
        model.secretImageText = @"123456789";
        model.noAlbumAuthorizedBlock = ^() {
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_0) {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:@"请允许app访问相册" preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请允许app访问相册" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                [alert show];
            }
        };
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
