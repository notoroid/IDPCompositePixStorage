//
//  ViewController.m
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/07.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "ViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <Bolts/Bolts.h>
#import <Parse/Parse.h>
#import "IDPCompositePixStorage.h"
#import "ImageViewController.h"
@import CoreImage;

@interface ViewController ()

@property NSArray *photoImages;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    PFQuery *query = [PFQuery queryWithClassName:@"PhotoImage"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S objects, NSError *PF_NULLABLE_S error){
        self.photoImages = objects;
        [self.tableView reloadData];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PFObject *photoImage = self.photoImages[self.tableView.indexPathForSelectedRow.row];
    [segue.destinationViewController setPhotoImage:photoImage];
    
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.photoImages.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *photoImage = self.photoImages[indexPath.row];
    NSString *path = [photoImage objectForKey:@"path"];
    cell.textLabel.text = path;

    return cell;
}

- (IBAction)onUploadImage:(id)sender
{
    UIImagePickerController *viewController = [[UIImagePickerController alloc] init];
    viewController.delegate = self;
    viewController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:viewController animated:YES completion:^{

     
    }];
}

- (void) onCancelUpload:(id)sender
{
    [[IDPStorageManager defaultManager] cancelAllStore];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        
        UIView *boardView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero,self.view.frame.size}];
        boardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.5f];
        boardView.opaque = NO;
        boardView.autoresizingMask = self.view.autoresizingMask;
        [self.view addSubview:boardView];

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.labelText = @"Uploading";

        BFTask *task = task = [BFTask taskWithResult:info[UIImagePickerControllerOriginalImage]];
        NSURL *URL = info[UIImagePickerControllerReferenceURL];
        NSString *filename = URL.lastPathComponent;

        task = [task continueWithExecutor:[BFExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)] withBlock:^id(BFTask *task) {
            UIImage *image = task.result;
           
            CGFloat edge = MIN(image.size.width,image.size.height);
            CGFloat ratio = 1024 / edge; // アイコンのサイズを決定
            
//            CGSize resizedSize = CGSizeMake(ceil(image.size.width * ratio),ceil(image.size.height * ratio));
            
            CIImage *ciImage = [[CIImage alloc] initWithImage:image];
            CIImage *filteredImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(ratio,ratio)];
            
//            CGSize croppingSize = CGSizeMake(88.0,88.0);
//            filteredImage = [filteredImage imageByCroppingToRect:CGRectMake(resizedSize.width * 0.5 - croppingSize.width * 0.5,
//                                                                            resizedSize.height * 0.5 - croppingSize.height * 0.5,
//                                                                            croppingSize.width,
//                                                                            croppingSize.height)];
            
            CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@NO}];
            CGImageRef imgRef = [ciContext createCGImage:filteredImage fromRect:[filteredImage extent]];
            UIImage *resizedImage  = [UIImage imageWithCGImage:imgRef];
            CGImageRelease(imgRef);
            
            return resizedImage;
        }];
        
        task = [task continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
            
            UIImage *resizedImage = task.result;
            
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelUpload:)];
            self.navigationItem.rightBarButtonItem.enabled = NO;
            
            [[IDPStorageManager defaultManager] storeWithImage:resizedImage filename:filename
                completion:^(PFObject *photoImage, NSError *error) {
                    [boardView removeFromSuperview];
                    [hud hide:YES];
                    
                    self.navigationItem.leftBarButtonItem = nil;
                    self.navigationItem.rightBarButtonItem.enabled = YES;

                    
                    if( error == nil ){
                        NSAssert(photoImage != nil , @"photoImage is nil.");
                        
                        [taskCompletionSource setResult:@{}];
                    }else{
                        [taskCompletionSource setError:error];
                    }
                }
                  progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                      hud.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
                  }
             ];
            
            return taskCompletionSource.task;
        }];
        
        task = [task continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            PFQuery *query = [PFQuery queryWithClassName:@"PhotoImage"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S objects, NSError *PF_NULLABLE_S error){
                self.photoImages = objects;
                [self.tableView reloadData];
            }];
            
            return nil;
        }];
    }];
    
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
}



@end
