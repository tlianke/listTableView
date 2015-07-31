//
//  AiHttpAuth.h
//  AiEngineLib
//
//  Created by Midfar Sun on 8/13/14.
//  Copyright (c) 2014 Midfar Sun. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

typedef void (^AiHttpAuthSuccessBlock)(NSString *serialNumber);
typedef void (^AiHttpAuthFailureBlock)(NSString *errorString);

/**
 API授权
 */
@interface AiHttpAuth : NSObject

- (void)start:(NSString *)appKey
    secreyKey:(NSString *)secretKey
      success:(AiHttpAuthSuccessBlock)success
      failure:(AiHttpAuthFailureBlock)failure;

@end
