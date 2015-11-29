//
//  IDPStorageManager.h
//  ImageUploadTest
//
//  Created by 能登 要 on 2015/07/07.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;
@class AFHTTPRequestOperation;

#define IDP_UPLOAD_URL_KEY_NAME @"IDPUploadURL"
#define IDP_LOAD_URL_KEY_NAME @"IDPLoadURL"
#define IDP_UPLOAD_TICKET_PREFIX_KEY_NAME @"IDPUploadTicketPrefix"

#define IDP_PHOTO_IMAGE_CLASS_NAME @"PhotoImage"
#define IDP_UPLOAD_TICKET_CLASS_NAME @"UploadTicket"
#define IDF_STORE_SUB_FOLDER_CLASS_NAME @"StoreSubFolder"

@interface IDPStorageManager : NSObject

+ (instancetype) defaultManager;

- (void) storeWithImage:(UIImage *)image filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress;

- (void) storeWithImage:(UIImage *)image filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion;

- (void) storeWithURL:(NSURL *)URL filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress;

- (void) storeWithURL:(NSURL *)URL filename:(NSString *)filename completion:(void (^)(PFObject *photoImage,NSError *error))completion;


- (void) cancelAllStore;

- (UIImage *) loadImageWithPhotoImage:(PFObject *)photoImage completion:(void (^)(UIImage *image,NSError *error))completion;
- (UIImage *) loadImageWithPhotoImage:(PFObject *)photoImage startBlock:(void (^)(NSOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion;

- (UIImage *) loadImageWithObjectID:(NSString *)objectID completion:(void (^)(UIImage *image,NSError *error))completion;
- (UIImage *) loadImageWithObjectID:(NSString *)objectID startBlock:(void (^)(NSOperation *operation))startBlock completion:(void (^)(UIImage *image,NSError *error))completion;

- (void) URLWithPhotoImage:(PFObject *)photoImage completion:(void (^)(NSURL *URL,NSError *error))completion;
- (void) URLWithObjectID:(NSString *)objectID completion:(void (^)(NSURL *URL,NSError *error))completion;

- (void) cancelAllLoad;


@end
