//
//  AppDelegate.m
//  IDPCompositPixStorage
//
//  Created by 能登 要 on 2015/07/07.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSString *applicationID = @"<YOUR_PARSE_APPLICATION_ID>";
    NSString *clientKey = @"<YOUR_PARSE_CLIENT_KEY>";
    
    NSAssert([applicationID isEqualToString:@"<YOUR_PARSE_APPLICATION_ID>"] != YES,@"input your Parse application ID.");
    NSAssert([clientKey isEqualToString:@"<YOUR_PARSE_CLIENT_KEY>"]  != YES,@"input your Parse application master key.");

    
    [Parse setApplicationId:applicationID clientKey:clientKey];

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

    
}

@end
