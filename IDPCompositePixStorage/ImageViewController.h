//
//  ImageViewController.h
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/08.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;

@interface ImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property(strong,nonatomic) PFObject *photoImage;

@end
