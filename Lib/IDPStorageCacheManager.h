//
//  IDPStorageCacheManager.h
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/26.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BFTask;

@interface IDPStorageCacheManager : NSObject

+ (instancetype) defaultManager;

- (NSOperation *) imageLoadWithPath:(NSString *)path completion:(void (^)(UIImage *image,NSError *error))completion;;
- (void) storeImage:(UIImage *)image withPath:(NSString *)path completion:(void (^)(NSError *error))completion;
- (void) storeData:(NSData *)data withPath:(NSString *)path completion:(void (^)(NSError *error))completion;

// for debug methods
- (void) clearAllCaches;

@end
