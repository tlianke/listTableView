//
//  AiQPlayer.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiQPlayer.h"
#import "aiplayer.h"

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

@interface AiQPlayer ()
{
    aiplayer *player;
}
@property(nonatomic, assign)BOOL stopByFunc;
@end

@implementation AiQPlayer
@synthesize delegate, tag;
@synthesize stopByFunc;

- (id)init
{
    //NSLog(@"AiQPlayer init");
    self = [super init];
    if (self) {
        delegate = nil;
        player = aiplayer_new();
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"AiQPlayer dealloc");
    if (player != NULL) {
        aiplayer_delete(player);
    }
    //[super dealloc];
}

- (OSStatus)loadWithPath:(NSString *)path
{
    if (path == nil) {
        NSLog(@"AiQPlayer loadWithPath: path can not be nil");
        return -1;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"AiQPlayer loadWithPath: file not exist at %@", path);
        return -1;
    }
    aiplayer_dispose_queue(player, true);
    CFStringRef cfPath = CFStringCreateWithCString(kCFAllocatorDefault, [path UTF8String], kCFStringEncodingUTF8);
    aiplayer_create_queue(player, cfPath);
    return 0;
}

- (OSStatus)play
{
    stopByFunc = NO;
    OSStatus rv = aiplayer_start_queue(player, false, aiplayer_play_stopped, (__bridge const void *)(self));
    return rv;
}

- (OSStatus)stop
{
    return [self stopByStopType:AIENGINE_STOPTYPE_MANUAL];
}

- (OSStatus)stopByStopType:(AIENGINE_STOPTYPE)stopType
{
    stopByFunc = YES;
    OSStatus rv = aiplayer_stop_queue(player);
    if (rv == noErr) {
        AiQPlayer *THIS = self;
        if (THIS.delegate &&
            [THIS.delegate respondsToSelector:@selector(aiQPlayerDidFinishPlaying:stopType:)]) {
            [THIS.delegate aiQPlayerDidFinishPlaying:THIS stopType:stopType];
        }
    }
    return rv;
}

- (void)reset
{
    if (player->is_playing) {
        [self stopByStopType:AIENGINE_STOPTYPE_RESET];
    }
}

- (BOOL)isPlaying
{
    return player->is_playing;
}

#pragma mark - callbacks
void aiplayer_play_stopped(const void *user_data)
{
    AiQPlayer *THIS = (__bridge AiQPlayer *)(user_data);
    if (THIS.stopByFunc == YES) {
        return;
    }
    if (THIS.delegate &&
        [THIS.delegate respondsToSelector:@selector(aiQPlayerDidFinishPlaying:stopType:)]) {
        [THIS.delegate aiQPlayerDidFinishPlaying:THIS stopType:AIENGINE_STOPTYPE_AUTO];
    }
}

@end
