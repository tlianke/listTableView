//
//  LocationHelper.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationHelper : NSObject

@property(nonatomic, retain, readonly)CLLocation* location;

+(LocationHelper *)sharedHelper;

@end
