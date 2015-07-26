//
//  IDPStorageCacheManager.m
//  IDPCompositePixStorage
//
//  Created by 能登 要 on 2015/07/26.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPStorageCacheManager.h"
@import CoreData;
#import "IDPStorageCacheImage.h"
#import "IDPStorageCacheImageData.h"

static IDPStorageCacheManager *s_StorageCacheManager = nil;

@interface IDPStorageCacheManager ()
{
    NSOperationQueue *_operationQueue;
    NSManagedObjectContext *_writerContext;
}
// for CoreData
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly,nonatomic) NSOperationQueue *operationQueue;
@end

@implementation IDPStorageCacheManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSOperationQueue *)operationQueue
{
    if( _operationQueue == nil ){
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    return _operationQueue;
}

+ (instancetype) defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_StorageCacheManager = [[IDPStorageCacheManager alloc] init];
    });
    return s_StorageCacheManager;
}

- (void) imageLoadWithPath:(NSString *)path completion:(void (^)(UIImage *image,NSError *error))completion
{
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.managedObjectContext;

    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IDPStorageCacheImage" inManagedObjectContext:temporaryContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cacheName == %@",path];
        fetchRequest.predicate = predicate;
        
        NSError *error = nil;
        NSArray *results = [temporaryContext executeFetchRequest:fetchRequest error:&error];
        
        UIImage *image = nil;
        if( results.count > 0 ){
            @autoreleasepool {
                IDPStorageCacheImage *storageCacheImage = results[0];
                IDPStorageCacheImageData *storageCacheImageData = storageCacheImage.storageCacheImageData;
                image = [UIImage imageWithData:storageCacheImageData.data scale:1.0];
                [temporaryContext refreshObject:storageCacheImage mergeChanges:NO];
            }
        }
        
        if( completion != nil ){
            dispatch_async(dispatch_get_main_queue(), ^{
                completion( image , error);
            });
        }
    }];
    [self.operationQueue addOperation:operation ];
}

- (void) storeImage:(UIImage *)image withPath:(NSString *)path completion:(void (^)(NSError *error))completion
{
    NSLog(@"storeData: call.");
    
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.managedObjectContext;
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IDPStorageCacheImage" inManagedObjectContext:temporaryContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cacheName == %@",path];
        fetchRequest.predicate = predicate;
        
        NSError *error = nil;
        NSArray *results = [temporaryContext executeFetchRequest:fetchRequest error:&error];
        
        if( results.count > 0 ){

        }else{
            NSData *data = nil;
            @autoreleasepool {
                data = UIImageJPEGRepresentation(image, 0.9);
            }
            
            IDPStorageCacheImageData *temporaryImageData = [NSEntityDescription insertNewObjectForEntityForName:@"IDPStorageCacheImageData" inManagedObjectContext:temporaryContext];
            temporaryImageData.data = data;
            
            IDPStorageCacheImage *temporaryImage = [NSEntityDescription insertNewObjectForEntityForName:@"IDPStorageCacheImage" inManagedObjectContext:temporaryContext];
            temporaryImage.cacheName = path;
            temporaryImage.storageCacheImageData = temporaryImageData;

            [temporaryContext performBlock:^{
                if( [temporaryContext hasChanges] == YES){
                    NSError *error = nil;
                    if( [temporaryContext save:&error] != YES ){
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                        abort();
                    }else{
                        [self.managedObjectContext performBlock:^{
                            if( [self.managedObjectContext hasChanges] == YES){
                                NSError *error = nil;
                                if( [self.managedObjectContext save:&error] != YES ){
                                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                    abort();
                                }else{
                                    // データを書き込み
                                    [_writerContext performBlock:^{
                                        if( [_writerContext hasChanges] == YES){
                                            NSError *error = nil;
                                            if( [_writerContext save:&error] != YES ){
                                                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                                abort();
                                            }else{
                                                if( completion != nil ){
                                                    completion(nil);
                                                }
                                            }
                                        }else{
                                            if( completion != nil ){
                                                completion(nil);
                                            }
                                        }
                                    }];
                                }
                            }else{
                                if( completion != nil ){
                                    completion(nil);
                                }
                            }
                        }];
                    }
                }else{
                    if( completion != nil ){
                        completion(nil);
                    }
                }
            }];
        }
    }];
    
    NSLog(@"add operaton.");
    [self.operationQueue addOperation:operation ];
    
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"IDPStorageManagerModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSURL *)temporaryImageCacheDirectory
{
    NSString *temporaryPath = NSTemporaryDirectory();
    return [NSURL fileURLWithPath:temporaryPath];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self temporaryImageCacheDirectory] URLByAppendingPathComponent:@"IDPStorageManagerModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        if( [[NSFileManager defaultManager] fileExistsAtPath:storeURL.path] ){
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        }
        
        NSURL *shmURL = [[self temporaryImageCacheDirectory] URLByAppendingPathComponent:@"IDPStorageManagerModel.sqlite-shm"];
        if( [[NSFileManager defaultManager] fileExistsAtPath:shmURL.path] ){
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:shmURL error:&error];
        }
        
        NSURL *walURL = [[self temporaryImageCacheDirectory] URLByAppendingPathComponent:@"IDPStorageManagerModel.sqlite-wal"];
        if( [[NSFileManager defaultManager] fileExistsAtPath:walURL.path] ){
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:walURL error:&error];
        }
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    // 書き込みコンテキスト
    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_writerContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    // メインコンテキスト
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.parentContext = _writerContext;
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
