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
#import <AFNetworking/AFHTTPSessionManager.h>
#import "IDPStorageCacheManager.h"

static IDPStorageManager *s_storageManager = nil;
static NSDictionary *s_supportMINE = nil;

@interface IDPStorageManager ()
{
    AFHTTPSessionManager *_storeHTTPSessionManager;
    NSMutableDictionary *_dictUploadURLSessionDataTask;
    NSMutableDictionary *_dictLoadURLSessionDataTask;
    
    AFHTTPSessionManager *_loadHTTPSessionManager;
    
    NSCache *_cahe;
    id _observerApplicationDidReceiveMemoryWarning;
}
@property(readonly,nonatomic) NSCache *cahe;
@property(readonly,nonatomic) NSMutableDictionary *dictUploadURLSessionDataTask;
@property(readonly,nonatomic) NSMutableDictionary *dictLoadURLSessionDataTask;
@end

@implementation IDPStorageManager

- (NSMutableDictionary *)dictUploadURLSessionDataTask
{
    if( _dictUploadURLSessionDataTask == nil ){
        _dictUploadURLSessionDataTask = [NSMutableDictionary dictionary];
    }
    return _dictUploadURLSessionDataTask;
}

- (NSMutableDictionary *)dictLoadURLSessionDataTask
{
    if( _dictLoadURLSessionDataTask == nil ){
        _dictLoadURLSessionDataTask = [NSMutableDictionary dictionary];
    }
    return _dictLoadURLSessionDataTask;
}

- (NSCache *)cahe
{
    if( _cahe == nil ){
        _cahe = [[NSCache alloc] init];
        _cahe.countLimit = 10;
    }
    return _cahe;
}

- (instancetype) init
{
    self = [super init];
    if( self != nil ){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            s_supportMINE = @{ @"gif":@"image/gif"
                              ,@"jpeg":@"image/jpeg"
                              ,@"jpg":@"image/jpeg"
                              ,@"png":@"image/image/png"
                              ,@"pdf":@"application/pdf"
                               };
        });
        
        _observerApplicationDidReceiveMemoryWarning = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self.cahe removeAllObjects];
        }];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observerApplicationDidReceiveMemoryWarning];
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
    [_dictUploadURLSessionDataTask.allValues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = obj;
        NSURLSessionDataTask *sessionDataTask = dict[@"task"];
        [sessionDataTask cancel];
    }];
    _dictLoadURLSessionDataTask = nil;
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

        [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *_Nullable config, NSError *_Nullable error){
            // config の取得
            if( error == nil ){
                NSString *prefix = config[IDP_UPLOAD_TICKET_PREFIX_KEY_NAME];
                NSString *name = [NSString stringWithFormat:@"%@_%@",prefix,hash];
                
                [[PFObject objectWithClassName:IDP_UPLOAD_TICKET_CLASS_NAME dictionary:@{@"name":name}] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *_Nullable error)
                 {
                     if( error == nil ){
                         [taskCompletion setResult:@{@"data":data,@"name":name,@"MINE":@"image/jpeg",@"filename":filename}];
                     }else{
                         [taskCompletion setError:error];
                         
                     }
                 }];
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


        [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *_Nullable config, NSError *_Nullable error){
            if( error == nil ){
                NSString *uploadURL = config[IDP_UPLOAD_URL_KEY_NAME];
                
                if( _storeHTTPSessionManager == nil ){
                    _storeHTTPSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:uploadURL].baseURL];
                    _storeHTTPSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
                    
                    __weak IDPStorageManager *weakSelf = self;
                    [_storeHTTPSessionManager setTaskDidSendBodyDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {

                        void (^progress)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) = weakSelf.dictUploadURLSessionDataTask[@(task.taskIdentifier)][@"progress"];
                        if( progress != nil ){
                            progress(bytesSent, totalBytesSent, totalBytesExpectedToSend);
                        }
                    }];
                }
                
                NSURLSessionDataTask *sessionDataTask = [_storeHTTPSessionManager POST:uploadURL parameters:@{@"name":dict[@"name"]} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    NSString *filename = dict[@"filename"];
                    filename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:[[filename pathExtension] lowercaseString]];
                    NSString *MINE = dict[@"MINE"];
                    NSData *data = dict[@"data"];
                    
                    // イメージデータを追加
                    [formData appendPartWithFileData:data name:@"file" fileName:filename mimeType:MINE];
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    [self.dictUploadURLSessionDataTask removeObjectForKey:@(task.taskIdentifier)];
                    
                    NSLog(@"responseObject=%@",responseObject);
                    
                    [taskCompletion setResult:responseObject];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self.dictUploadURLSessionDataTask removeObjectForKey:@(task.taskIdentifier)];
                    
                    [taskCompletion setError:error];
                }];
                
                if( sessionDataTask != nil ){
                    self.dictUploadURLSessionDataTask[@(sessionDataTask.taskIdentifier)] = progress == nil ? @{@"task":sessionDataTask} : @{@"task":sessionDataTask,@"progress":progress};
                }
            }else{
                [taskCompletion setError:error];
            }
        }];
        return taskCompletion.task;
    }];


    taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if( task.error == nil ){
            id result = task.result;

            NSDictionary *dict = [result isKindOfClass:[NSDictionary class]] ? result : nil;
            NSString *objectID = dict[@"objectID"];

            if( objectID.length > 0 ){
                BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

                PFQuery *query = [PFQuery queryWithClassName:IDP_PHOTO_IMAGE_CLASS_NAME];
                [query getObjectInBackgroundWithId:objectID block:^(PFObject *_Nullable object,  NSError *_Nullable error){
                    if( error == nil ){
                        // ストレージキャッシュに保存
                        [[IDPStorageCacheManager defaultManager] storeImage:image withPath:objectID completion:^(NSError *error) {
                            
                        }];
                        
                        // キャッシュに保存
                        [self.cahe setObject:image forKey:objectID];
                        
                        [taskCompletion setResult:object];
                    }else{
                        [taskCompletion setError:error];
                    }
                }];
                return taskCompletion.task;
            }
        }

        return [BFTask taskWithError:task.error];
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

- (UIImage *) loadImageWithPhotoImage:(PFObject *)photoImage completion:(void (^)(UIImage *image,NSError *error))completion
{
    return [self loadImageWithPhotoImage:photoImage startBlock:nil completion:completion];
}

- (UIImage *) loadImageWithPhotoImage:(PFObject *)photoImage startBlock:(void (^)(NSOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion;
{
    NSString *objectId = photoImage.objectId;
    
    UIImage *cachedImage = [self.cahe objectForKey:objectId];
    if( cachedImage == nil ){
        __block BFTask *taskStore = [BFTask taskWithResult:photoImage];
        taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

            NSOperation *operation = [[IDPStorageCacheManager defaultManager] imageLoadWithPath:objectId completion:^(UIImage *image, NSError *error) {
                if( image != nil ){
                    [taskCompletion setResult:image];
                    [self.cahe setObject:image forKey:objectId];
                }else{
                    dispatch_block_t block = ^{
                        PFObject *photoImage = task.result;
                        NSString *path = photoImage[@"path"];
                        
                        [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *_Nullable config, NSError *_Nullable error){
                            if( error == nil ){
                                NSString *loadURL = config[IDP_LOAD_URL_KEY_NAME];
                                
                                if( _loadHTTPSessionManager == nil ) {
                                    _loadHTTPSessionManager = [AFHTTPSessionManager manager];
                                    _loadHTTPSessionManager.responseSerializer = [AFImageResponseSerializer serializer];
                                }
                                
                                NSURLSessionDataTask *task = [_loadHTTPSessionManager POST:loadURL parameters:@{@"path":path} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                    [self.dictLoadURLSessionDataTask removeObjectForKey:@(task.taskIdentifier)];
                                    
                                    [taskCompletion setResult:responseObject];
                                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                    [self.dictLoadURLSessionDataTask removeObjectForKey:@(task.taskIdentifier)];
                                    
                                    [taskCompletion setError:error];
                                }];
                                
                                if( startBlock != nil ){
                                    startBlock(operation);
                                }
                                
                                if( task != nil ){
                                    self.dictLoadURLSessionDataTask[@(task.taskIdentifier)] = @{@"task":task};
                                }
                            }else{
                                [taskCompletion setError:error];
                            }
                        }];

                    };
                    
                    if( [photoImage isDataAvailable] != YES ){
                        [photoImage fetchIfNeededInBackgroundWithBlock:^(PFObject *_Nullable object,  NSError *_Nullable error){
                            if( error == nil ){
                                block();
                            }else{
                                [taskCompletion setError:error];
                            }
                        }];
                    }else{
                        block();
                    }
                }
            }];
            if( startBlock != nil ){
                startBlock(operation);
            }
            
            return taskCompletion.task;
        }];
        
        taskStore = [taskStore continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            id result = task.result;
            
            UIImage *image = [result isKindOfClass:[UIImage class]] ? result : nil;
            
            if( image != nil ){
                // ストレージキャッシュに保存
                [[IDPStorageCacheManager defaultManager] storeImage:image withPath:objectId completion:^(NSError *error) {

                }];
                
                // キャッシュに保存
                [self.cahe setObject:image forKey:objectId];
            }

            
            if( completion != nil ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image,task.error);
                });
            }
            
            return nil;
        }];
    }
    
    return cachedImage;
}

- (UIImage *) loadImageWithObjectID:(NSString *)objectID completion:(void (^)(UIImage *image,NSError *error))completion
{
    return [self loadImageWithObjectID:objectID startBlock:nil completion:completion];
}

- (UIImage *) loadImageWithObjectID:(NSString *)objectID startBlock:(void (^)(NSOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion
{
    UIImage *cachedImage = [self.cahe objectForKey:objectID];
    if( cachedImage == nil ){
        PFQuery *query = [PFQuery queryWithClassName:IDP_PHOTO_IMAGE_CLASS_NAME];
        [query getObjectInBackgroundWithId:objectID block:^(PFObject *_Nullable object,  NSError *_Nullable error){
            [self loadImageWithPhotoImage:object startBlock:startBlock completion:completion];
        }];
    }
    return cachedImage;
}

- (void) cancelAllLoad
{
    [_dictLoadURLSessionDataTask.allValues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = obj;
        NSURLSessionDataTask *sessionDataTask = dict[@"task"];
        [sessionDataTask cancel];
    }];
    _dictLoadURLSessionDataTask = nil;
}

@end
