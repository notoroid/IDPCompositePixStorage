//
//  IDPStorageCacheImageData.h
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/26.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IDPStorageCacheImage;

@interface IDPStorageCacheImageData : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) IDPStorageCacheImage *storageCacheImage;

@end
