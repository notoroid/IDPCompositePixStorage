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
    NSOperationQueue *_loadOperationQueue;
    NSOperationQueue *_saveOperationQueue;
    NSManagedObjectContext *_writerContext;
}
// for CoreData
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly,nonatomic) NSOperationQueue *loadOperationQueue;
@property (readonly,nonatomic) NSOperationQueue *saveOperationQueue;
@end

@implementation IDPStorageCacheManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSOperationQueue *)loadOperationQueue
{
    if( _loadOperationQueue == nil ){
        _loadOperationQueue = [[NSOperationQueue alloc] init];
        _loadOperationQueue.maxConcurrentOperationCount = 3;
    }
    return _loadOperationQueue;
}

- (NSOperationQueue *)saveOperationQueue
{
    if( _saveOperationQueue == nil ){
        _saveOperationQueue = [[NSOperationQueue alloc] init];
        _saveOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _saveOperationQueue;
}

+ (instancetype) defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_StorageCacheManager = [[IDPStorageCacheManager alloc] init];
    });
    return s_StorageCacheManager;
}

- (NSOperation *) imageLoadWithPath:(NSString *)path completion:(void (^)(UIImage *image,NSError *error))completion
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
        
        NSData *data = nil;
        if( results.count > 0 ){
            @autoreleasepool {
                IDPStorageCacheImage *storageCacheImage = results[0];
                IDPStorageCacheImageData *storageCacheImageData = storageCacheImage.storageCacheImageData;
                data = storageCacheImageData.data;
                [temporaryContext refreshObject:storageCacheImage mergeChanges:NO];
            }
        }
        
        if( completion != nil ){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = image = [UIImage imageWithData:data scale:1.0];
                completion( image , error);
            });
        }
    }];
    
    [self.loadOperationQueue addOperation:operation];
    return operation;
}

- (void) storeData:(NSData *)data withPath:(NSString *)path completion:(void (^)(NSError *error))completion
{
    [self storeObject:data withPath:path completion:completion];
}

- (void) storeImage:(UIImage *)image withPath:(NSString *)path completion:(void (^)(NSError *error))completion
{
    [self storeObject:image withPath:path completion:completion];
}

- (void) storeObject:(id)object withPath:(NSString *)path completion:(void (^)(NSError *error))completion
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
        
        if( results.count > 0 ){

        }else{
            NSData *data = nil;
            
            if( [object isKindOfClass:[NSData class]] ){
                data = object;
            }else{
                @autoreleasepool {
                    data = UIImageJPEGRepresentation(object, 0.9);
                }
            }
            
            IDPStorageCacheImageData *temporaryImageData = [NSEntityDescription insertNewObjectForEntityForName:@"IDPStorageCacheImageData" inManagedObjectContext:temporaryContext];
            temporaryImageData.data = data;
            
            IDPStorageCacheImage *temporaryImage = [NSEntityDescription insertNewObjectForEntityForName:@"IDPStorageCacheImage" inManagedObjectContext:temporaryContext];
            temporaryImage.cacheName = path;
            temporaryImage.storageCacheImageData = temporaryImageData;

            __weak NSManagedObjectContext *weakTemporaryContext = temporaryContext;
            __weak NSManagedObjectContext *weakManagedObjectContext = self.managedObjectContext;
            __weak NSManagedObjectContext *weakWriterContext = _writerContext;
            
            [weakTemporaryContext performBlock:^{
                if( [weakTemporaryContext hasChanges] == YES){
                    NSError *error = nil;
                    if( [weakTemporaryContext save:&error] != YES ){
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                        abort();
                    }else{
                        [weakManagedObjectContext performBlock:^{
                            if( [weakManagedObjectContext hasChanges] == YES){
                                NSError *error = nil;
                                if( [weakManagedObjectContext save:&error] != YES ){
                                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                    abort();
                                }else{
                                    // データを書き込み
                                    [weakWriterContext performBlock:^{
                                        if( [weakWriterContext hasChanges] == YES){
                                            NSError *error = nil;
                                            if( [weakWriterContext save:&error] != YES ){
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
    
    [self.saveOperationQueue addOperation:operation ];
    
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

- (void) clearAllCaches
{
    NSArray *storageCacheImages = nil;
    @autoreleasepool {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IDPStorageCacheImage" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSError *error = nil;
        storageCacheImages = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }

    NSArray *storageCacheImageDataCollection = nil;
    @autoreleasepool {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IDPStorageCacheImageData" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSError *error = nil;
        storageCacheImageDataCollection = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }
 
    [storageCacheImages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.managedObjectContext deleteObject:obj];
    }];
    
    [storageCacheImageDataCollection enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.managedObjectContext deleteObject:obj];
    }];
 
    [self saveContext];
        // オブジェクトを保存
    
}
@end
