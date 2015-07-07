//
//  ImageViewController.m
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/08.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "ImageViewController.h"
#import "IDPStorageManager.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface ImageViewController ()

@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[IDPStorageManager defaultManager] loadImageWithPhotoImage:self.photoImage startBlock:^(AFHTTPRequestOperation *operation) {
        
    } completion:^(UIImage *image, NSError *error) {
        self.imageView.image = image;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
