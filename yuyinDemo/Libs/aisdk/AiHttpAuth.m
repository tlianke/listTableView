//
//  AiHttpAuth.m
//  AiEngineLib
//
//  Created by Midfar Sun on 8/13/14.
//  Copyright (c) 2014 Midfar Sun. All rights reserved.
//

#import "AiHttpAuth.h"
#import "AiUtil.h"
#import "AiQEngine.h"

#define kApiAuthUrl @"http://auth.api.chivox.com/device"
#define kSerialNumberFileName @"aiengine.serial"

@implementation AiHttpAuth

- (void)start:(NSString *)appKey
    secreyKey:(NSString *)secretKey
      success:(AiHttpAuthSuccessBlock)success
      failure:(AiHttpAuthFailureBlock)failure
{
    NSString *s = [self readSerialNumber];
    if (s != nil) {
        if (success!=nil) {
            success(s);
        }
        
    }else{
        NSString *urlString = kApiAuthUrl;
        NSString *now = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]*1000];
        NSString *deviceId = [AiQEngine getDeviceId];
        NSString *sig = [NSString stringWithFormat:@"%@%@%@%@", appKey, now, secretKey, deviceId];
        NSDictionary *parameters = @{@"appKey": appKey,
                                     @"timestamp": now,
                                     @"deviceId": deviceId,
                                     @"sig": [AiUtil sha1:sig],
                                     @"userId": deviceId};
        [self POST:urlString parameters:parameters success:success failure:failure];
    }
}
// /Users/chenzhe/Library/Developer/CoreSimulator/Devices/72F403D0-BCF3-4C17-896E-2EB0BB016F4E/data/Containers/Data/Application/3A84AC5A-065D-43CE-92C2-BB2C5DCB8CFE/Library/Caches/aiengine.serial
// /Users/chenzhe/Library/Developer/CoreSimulator/Devices/72F403D0-BCF3-4C17-896E-2EB0BB016F4E/data/Containers/Data/Application/E565C6E9-99D4-443B-9C11-1E85F30C19CA/Library/Caches/aiengine.serial
-(NSString *)readSerialNumber
{
    NSString *filePath = [[AiUtil cachePath] stringByAppendingPathComponent:kSerialNumberFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        return [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    }
    return nil;
}

-(void)writeSerialNumber:(NSString *)serialNumber
{
    NSString *filePath = [[AiUtil cachePath] stringByAppendingPathComponent:kSerialNumberFileName];
    NSError *err = nil;
    [serialNumber writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err != nil) {
        NSLog(@"saveSerialNumber error:%@", err);
    }
}

- (void)POST:(NSString *)URLString
                     parameters:(id)parameters
                        success:(AiHttpAuthSuccessBlock)success
                        failure:(AiHttpAuthFailureBlock)failure
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager POST:URLString parameters:parameters success:^(AFHTTPRequestOperation *operation, id dict) {
        if (dict!=nil && [dict isKindOfClass:[NSDictionary class]]) {
            if ([dict objectForKey:@"error"] == nil) {
                NSString *serialNumber = [dict objectForKey:@"serialNumber"];
                [self writeSerialNumber:serialNumber];
                if (success!=nil) {
                    success(serialNumber);
                }
                
            }else{
                if (failure!=nil) {
                    failure(operation.responseString);
                }
            }
        }else{
            if (failure!=nil) {
                failure(operation.responseString);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure!=nil) {
            failure(operation.responseString);
        }
    }];
}

@end
