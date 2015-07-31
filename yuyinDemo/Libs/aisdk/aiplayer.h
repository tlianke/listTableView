//
//  aiplayer.h
//
//  Created by Midfar Sun on 2/7/12.
//  Copyright 2012 midfar.com. All rights reserved.
//
#include "stdlib.h"
#include "AudioToolbox/AudioToolbox.h"

#define kNumberPlayBuffers	5
#define kBufferDurationSeconds 0.5

typedef void (*aiplayer_stopped_callback_func)(
    const void *fn_stopped_user_data
);

typedef struct
{
    CFStringRef					file_path;
    AudioQueueRef				queue;
    AudioQueueBufferRef			buffers[kNumberPlayBuffers];
    AudioStreamBasicDescription audio_format;
    AudioFileID					audio_file;
    UInt32						num_packets_to_read;
    SInt64						current_packet; // current packet number in audio file
    Boolean						is_playing;
    Boolean                     is_done;
    Boolean                     is_looping;
    
    aiplayer_stopped_callback_func fn_stopped;
    const void *                fn_stopped_user_data;
} aiplayer;

/*
 * create a new player
 */
aiplayer * aiplayer_new(void);

/*
 * delete an existed player
 */
OSStatus aiplayer_delete(aiplayer *player);

/*
 * start queue
 */
OSStatus aiplayer_start_queue(aiplayer *player, Boolean inResume, aiplayer_stopped_callback_func fn_stopped, const void *fn_stopped_user_data);

/*
 * stop queue
 */
OSStatus aiplayer_stop_queue(aiplayer *player);

/*
 * pause queue
 */
OSStatus aiplayer_pause_queue(aiplayer *player);

/*
 * create queue for file before start the queue
 */
void aiplayer_create_queue(aiplayer *player, CFStringRef inFilePath);

/*
 * dispose the queue.
 */
void aiplayer_dispose_queue(aiplayer *player, Boolean inDisposeFile);	


