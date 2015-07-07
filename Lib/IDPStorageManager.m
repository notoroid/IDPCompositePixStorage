//
//  IDPStorageManager.m
//  ImageUploadTest
//
//  Created by 能登 要 on 2015/07/07.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPStorageManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <Bolts/Bolts.h>
#import <Parse/Parse.h>
#import <AFNetworking/AFNetworking.h>

static IDPStorageManager *s_storageManager = nil;


@interface IDPStorageManager ()
{
    AFHTTPRequestOperationManager *_operationManager;
    AFHTTPRequestOperationManager *_imageOperationManager;
}
@property(readonly,nonatomic) AFHTTPRequestOperationManager *operationManager;
@property(readonly,nonatomic) AFHTTPRequestOperationManager *imageOperationManager;
@end

@implementation IDPStorageManager

- (AFHTTPRequestOperationManager *)operationManager
{
    if( _operationManager == nil ){
        _operationManager = [AFHTTPRequestOperationManager manager];
    }
    return _operationManager;
}
- (AFHTTPRequestOperationManager *)imageOperationManager
{
    if( _imageOperationManager == nil ){
        _imageOperationManager = [AFHTTPRequestOperationManager manager];
        _imageOperationManager.responseSerializer = [AFImageResponseSerializer serializer];
    }
    return _imageOperationManager;
}

+ (IDPStorageManager *) defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_storageManager = [[IDPStorageManager alloc] init];
    });
    return s_storageManager;
}

- (void) cancelAllStore
{
    [self.operationManager.operationQueue cancelAllOperations];
}

- (void) storeWithImage:(UIImage *)image filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion
{
    [self storeWithImage:image filename:filename completion:completion progress:nil];
}

- (NSString*)encryptToMD5WithData:(NSData *)data {
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes,(CC_LONG)data.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    
    return output;
}

- (void) storeWithImage:(UIImage *)image filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
{
    __block BFTask *taskStore = [BFTask taskWithResult:nil];
    
    
    taskStore = [taskStore continueWithExecutor:[BFExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)] withBlock:^id(BFTask *task) {
        NSData *data = nil;
        @autoreleasepool {
            data = UIImageJPEGRepresentation(image, 0.9);
        }
        return data;
    }];
    
    
    taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

        NSData *data = task.result;
        NSString *hash = [self encryptToMD5WithData:data];
            // Uploadチケット発行

        PFConfig *config = [PFConfig getConfig];
            // config の取得

        NSString *prefix = config[@"UploadTicketPrefix"];
        NSLog(@"prefix=%@",prefix );

        NSString *name = [NSString stringWithFormat:@"%@_%@",prefix,hash];

        [[PFObject objectWithClassName:@"UploadTicket" dictionary:@{@"name":name}] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error)
        {
            if( error == nil ){
                [taskCompletion setResult:@{@"data":data,@"name":name,@"MINE":@"image/jpeg",@"filename":filename}];
            }else{
                [taskCompletion setError:error];

            }
        }];

        return taskCompletion.task;
    }];

    taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task)
    {
        BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

        NSDictionary *dict = task.result;

        PFConfig *config = [PFConfig getConfig];
            // config の取得
        NSString *uploadURL = config[@"UploadURL"];

        AFHTTPRequestOperation *operation = [self.operationManager POST:uploadURL parameters:@{@"name":dict[@"name"]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {

            NSString *filename = dict[@"filename"];
            filename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:[[filename pathExtension] lowercaseString]];
            NSString *MINE = dict[@"MINE"];
            NSData *data = dict[@"data"];

            // イメージデータを追加
            [formData appendPartWithFileData:data name:@"file" fileName:filename mimeType:MINE];
        }
            success:^(AFHTTPRequestOperation *operation, id responseObject) {

                NSLog(@"responseObject=%@",responseObject);

                [taskCompletion setResult:responseObject];

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [taskCompletion setError:error];
            }
        ];
        
        if( progress != nil ){
            [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                progress(bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
            }];
        }
        return taskCompletion.task;
    }];


    taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        id result = task.result;
//        NSLog(@"task.result=%@",task.result);

        NSDictionary *dict = [result isKindOfClass:[NSDictionary class]] ? result : nil;
        NSString *objectID = dict[@"objectID"];

        if( objectID.length > 0 ){
            BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

            PFQuery *query = [PFQuery queryWithClassName:@"PhotoImage"];
            [query getObjectInBackgroundWithId:objectID block:^(PFObject *PF_NULLABLE_S object,  NSError *PF_NULLABLE_S error){
                if( error == nil ){
                    [taskCompletion setResult:object];
                }else{
                    [taskCompletion setError:error];
                }
            }];
            return taskCompletion.task;
        }

        return nil;
    }];
    
    taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if( completion != nil ){
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(task.result,task.error);
            });
        }
        return nil;
    }];
}

- (void) loadImageWithPhotoImage:(PFObject *)photoImage startBlock:(void (^)(AFHTTPRequestOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion;

{
    NSString *path = [photoImage objectForKey:@"path"];
    if( path.length > 0 ){
        
        PFConfig *config = [PFConfig getConfig];
        // config の取得
        NSString *loadURL = config[@"LoadURL"];

        __block BFTask *taskStore = [BFTask taskWithResult:photoImage];
     
        if( [photoImage isDataAvailable] != YES ){
            taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
                
                [photoImage fetchIfNeededInBackgroundWithBlock:^(PFObject *PF_NULLABLE_S object,  NSError *PF_NULLABLE_S error){
                    if( error == nil ){
                        [taskCompletion setResult:photoImage];
                    }else{
                        [taskCompletion setError:error];
                    }
                }];
                
                return taskCompletion.task;
            }];
        }
        
        taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
            
            PFObject *photoImage = task.result;
            NSString *path = photoImage[@"path"];

            
            AFHTTPRequestOperation *operation = [self.imageOperationManager POST:loadURL parameters:@{@"path":path} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [taskCompletion setResult:responseObject];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [taskCompletion setError:error];
            }];
            
            if( startBlock != nil ){
                startBlock(operation);
            }
            
            return taskCompletion.task;
        }];
        
        taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            id result = task.result;
            UIImage *image = [result isKindOfClass:[UIImage class]] ? result : nil;

            if( completion != nil ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image,task.error);
                });
            }
            
            return nil;
        }];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil,nil);
        });
    }
}

- (void) loadImageWithObjectID:(NSString *)objectID startBlock:(void (^)(AFHTTPRequestOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion
{
    PFQuery *query = [PFQuery queryWithClassName:@"PhotoImage"];
    [query getObjectInBackgroundWithId:objectID block:^(PFObject *PF_NULLABLE_S object,  NSError *PF_NULLABLE_S error){
        [self loadImageWithPhotoImage:object startBlock:startBlock completion:completion];
    }];

}

- (void) cancelAllLoad
{
    [self.imageOperationManager.operationQueue cancelAllOperations];
}

@end
