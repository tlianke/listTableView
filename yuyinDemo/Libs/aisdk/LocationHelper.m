//
//  LocationHelper.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "LocationHelper.h"

@interface LocationHelper()<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    BOOL isLocating;//是否正在定位
}
@end

static LocationHelper *lhInstance;

@implementation LocationHelper
@synthesize location;

+(LocationHelper *)sharedHelper
{
    @synchronized (self)
    {
        if (lhInstance == nil) {
            lhInstance =  [[self alloc] init];
        }
    }
    return lhInstance;
}

-(id)init
{
    self = [super init];
    if (self) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = 100;
        [self startLocation];
    }
    return self;
}

-(void)startLocation
{
    if (isLocating ||
        [CLLocationManager locationServicesEnabled] == NO ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        //未获得授权使用位置或正在定位或没有定位信息
        //NSLog(@"isLocating=%d, locationServicesEnabled=%d, authorizationStatus=%d", isLocating, [CLLocationManager locationServicesEnabled], [CLLocationManager authorizationStatus]);
        return;
    }
    [locationManager startUpdatingLocation];
    isLocating = YES;
}

-(void)resetState
{
    [locationManager stopUpdatingLocation];
    isLocating = NO;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
    [self resetState];
    location = newLocation;
}

@end
