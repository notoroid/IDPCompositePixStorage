//
//  IDPStorageCacheImage.h
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/26.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IDPStorageCacheImageData;

@interface IDPStorageCacheImage : NSManagedObject

@property (nonatomic, retain) NSString * cacheName;
@property (nonatomic, retain) IDPStorageCacheImageData *storageCacheImageData;

@end
