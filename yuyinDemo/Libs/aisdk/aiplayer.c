//
//  aiplayer.c
//
//  Created by Midfar Sun on 2/7/12.
//  Copyright 2012 midfar.com. All rights reserved.
//

#include "aiplayer.h"

void aiplayer_setup_new_queue(aiplayer *player);
void aiplayer_buffer_callback(void *					inUserData,
                              AudioQueueRef			inAQ,
                              AudioQueueBufferRef		inCompleteAQBuffer);
void isRunningProc (
                    void *                  inUserData,
                    AudioQueueRef           inAQ,
                    AudioQueuePropertyID    inID
                    );
void calculateBytesForTime (AudioStreamBasicDescription inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets);

void aiplayer_buffer_callback(void *					inUserData,
    AudioQueueRef			inAQ,
    AudioQueueBufferRef		inCompleteAQBuffer) 
{
	aiplayer *THIS = (aiplayer *)inUserData;
    
	if (THIS->is_done) return;
    
	UInt32 numBytes;
	UInt32 nPackets = THIS->num_packets_to_read;
	OSStatus result = AudioFileReadPackets(THIS->audio_file, false, &numBytes, inCompleteAQBuffer->mPacketDescriptions, THIS->current_packet, &nPackets, 
										   inCompleteAQBuffer->mAudioData);
	if (result)
		printf("AudioFileReadPackets failed: %d", (int)result);
	if (nPackets > 0) {
		inCompleteAQBuffer->mAudioDataByteSize = numBytes;		
		inCompleteAQBuffer->mPacketDescriptionCount = nPackets;		
		AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
		THIS->current_packet = (THIS->current_packet + nPackets);
	} 
	
	else 
	{
		if (THIS->is_looping)
		{
			THIS->current_packet = 0;
			aiplayer_buffer_callback(inUserData, inAQ, inCompleteAQBuffer);
		}
		else
		{
			// stop
			THIS->is_done = true;
			AudioQueueStop(inAQ, false);
		}
	}
}

void isRunningProc (
    void *                  inUserData,
    AudioQueueRef           inAQ,
    AudioQueuePropertyID    inID
)
{
	aiplayer *THIS = (aiplayer *)inUserData;
	UInt32 size = sizeof(UInt32);
	OSStatus result = AudioQueueGetProperty (inAQ, kAudioQueueProperty_IsRunning, &THIS->is_playing, &size);
	
	if ((result == noErr) && (!THIS->is_playing)){
        if(THIS->fn_stopped){
            THIS->fn_stopped(THIS->fn_stopped_user_data);
        }
    }
}

void calculateBytesForTime (AudioStreamBasicDescription inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
	// we only use time here as a guideline
	// we're really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
	static const int maxBufferSize = 0x10000; // limit size to 64K
	static const int minBufferSize = 0x4000; // limit size to 16K
	
	if (inDesc.mFramesPerPacket) {
		Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
		*outBufferSize = numPacketsForTime * inMaxPacketSize;
	} else {
		// if frames per packet is zero, then the codec has no predictable packet == time
		// so we can't tailor this (we don't know how many Packets represent a time period
		// we'll just return a default buffer size
		*outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
	}
	
	// we're going to limit our size to our default
	if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize)
		*outBufferSize = maxBufferSize;
	else {
		// also make sure we're not too small - we don't want to go the disk for too small chunks
		if (*outBufferSize < minBufferSize)
			*outBufferSize = minBufferSize;
	}
	*outNumPackets = *outBufferSize / inMaxPacketSize;
}

aiplayer * aiplayer_new()
{
    aiplayer *player = calloc(1, sizeof(aiplayer));
    player->is_playing = false;
    player->is_done = false;
    player->is_looping = false;
    player->num_packets_to_read = 0;
    player->current_packet = 0;
    player->audio_file = 0;
    player->file_path = NULL;
    return player;
}

OSStatus aiplayer_delete(aiplayer *player)
{
    player->fn_stopped = NULL;
    player->fn_stopped_user_data = NULL;
    aiplayer_dispose_queue(player, true);
    
    free(player);
    
    return noErr;
}

/*
 * start queue
 */
OSStatus aiplayer_start_queue(aiplayer *player, Boolean inResume, aiplayer_stopped_callback_func fn_stopped, const void *fn_stopped_user_data)
{
	// if we have a file but no queue, create one now
	if ((player->queue == NULL) && (player->file_path != NULL))
		aiplayer_create_queue(player, player->file_path);
    
    player->fn_stopped = fn_stopped;
    player->fn_stopped_user_data = fn_stopped_user_data;
    player->is_done = false;
	
	// if we are not resuming, we also should restart the file read index
	if (!inResume)
		player->current_packet = 0;	
    
	// prime the queue with some data before starting
    if (player->queue != NULL) {
        for (int i = 0; i < kNumberPlayBuffers; ++i) {
            aiplayer_buffer_callback(player, player->queue, player->buffers[i]);			
        }
    }
	return AudioQueueStart(player->queue, NULL);
}

/*
 * stop queue
 */
OSStatus aiplayer_stop_queue(aiplayer *player)
{
    OSStatus result = AudioQueueStop(player->queue, true);
    aiplayer_dispose_queue(player, false);
    
	if (result) printf("ERROR STOPPING QUEUE!\n");
	return result;
}

/*
 * pause queue
 */
OSStatus aiplayer_pause_queue(aiplayer *player)
{
    OSStatus result = AudioQueuePause(player->queue);
	return result;
}

/*
 * create queue for file before start the queue
 */
void aiplayer_create_queue(aiplayer *player, CFStringRef inFilePath)
{
	CFURLRef sndFile = NULL;
    				
    if (player->file_path == NULL)
    {
        player->is_looping = false;
        
        sndFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, inFilePath, kCFURLPOSIXPathStyle, false);
        if (!sndFile) { printf("can't parse file path\n"); return; }
        
        if(AudioFileOpenURL (sndFile, kAudioFileReadPermission, 0/*inFileTypeHint*/, &player->audio_file) != noErr)
        printf("can't open file");
        
        UInt32 size = sizeof(player->audio_format);
        if(AudioFileGetProperty(
            player->audio_file, 
            kAudioFilePropertyDataFormat, 
            &size, 
            &player->audio_format) != noErr)
        printf("couldn't get file's data format");
        
        player->file_path = CFStringCreateCopy(kCFAllocatorDefault, inFilePath);
    }
    aiplayer_setup_new_queue(player);
	if (sndFile)
		CFRelease(sndFile);
}

/*
 * dispose the queue
 */
void aiplayer_dispose_queue(aiplayer *player, Boolean inDisposeFile)
{
    if(player->queue){
        AudioQueueDispose(player->queue, true);
        player->queue = NULL;
    }
    if(inDisposeFile){
        if (player->audio_file)
		{		
			AudioFileClose(player->audio_file);
			player->audio_file = 0;
		}
		if (player->file_path)
		{
			CFRelease(player->file_path);
			player->file_path = NULL;
		}
    }
}

void aiplayer_setup_new_queue(aiplayer *player)
{
	if(AudioQueueNewOutput(
        &player->audio_format, 
        aiplayer_buffer_callback, 
        player, 
        CFRunLoopGetCurrent(), 
        kCFRunLoopCommonModes, 
        0, 
        &player->queue
    ) != noErr){
        printf("AudioQueueNew failed\n");
        return;
    }
    
	UInt32 bufferByteSize;		
	// we need to calculate how many packets we read at a time, and how big a buffer we need
	// we base this on the size of the packets in the file and an approximate duration for each buffer
	// first check to see what the max size of a packet is - if it is bigger
	// than our allocation default size, that needs to become larger
	UInt32 maxPacketSize;
	UInt32 size = sizeof(maxPacketSize);
	if(AudioFileGetProperty(
        player->audio_file, 
        kAudioFilePropertyPacketSizeUpperBound, 
        &size, 
        &maxPacketSize
    ) != noErr){
        printf("couldn't get file's max packet size");
        return;
    }
	
	// adjust buffer size to represent about a half second of audio based on this format
	calculateBytesForTime (player->audio_format, maxPacketSize, kBufferDurationSeconds, &bufferByteSize, &player->num_packets_to_read);
    
    //printf ("Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)mNumPacketsToRead);
	
	// (2) If the file has a cookie, we should get it and set it on the AQ
	size = sizeof(UInt32);
	OSStatus result = AudioFileGetPropertyInfo (player->audio_file, kAudioFilePropertyMagicCookieData, &size, NULL);
	
	if (!result && size) {
        char* cookie = (char *) malloc (size);
		if (AudioFileGetProperty (player->audio_file, kAudioFilePropertyMagicCookieData, &size, cookie) != noErr){
            printf("get cookie from file");
            return;
        }
		if (AudioQueueSetProperty(player->queue, kAudioQueueProperty_MagicCookie, cookie, size) != noErr){
            printf("set cookie on queue");
            return;
        }
		free(cookie);
	}
	
	// channel layout?
	result = AudioFileGetPropertyInfo(player->audio_file, kAudioFilePropertyChannelLayout, &size, NULL);
	if (result == noErr && size > 0) {
		AudioChannelLayout *acl = (AudioChannelLayout *)malloc(size);
		if(AudioFileGetProperty(player->audio_file, kAudioFilePropertyChannelLayout, &size, acl) != noErr)
            printf("ERROR: get audio file's channel layout");
		if(AudioQueueSetProperty(player->queue, kAudioQueueProperty_ChannelLayout, acl, size) != noErr)
            printf("ERROR: set channel layout on queue");
		free(acl);
	}
	
	if(AudioQueueAddPropertyListener(player->queue, kAudioQueueProperty_IsRunning, isRunningProc, player) != noErr)
        printf("ERROR: adding property listener");
	
	bool isFormatVBR = (player->audio_format.mBytesPerPacket == 0 || player->audio_format.mFramesPerPacket == 0);
	for (int i = 0; i < kNumberPlayBuffers; ++i) {
		if(AudioQueueAllocateBufferWithPacketDescriptions(
            player->queue, 
            bufferByteSize, 
            (isFormatVBR ? player->num_packets_to_read : 0), 
            &player->buffers[i]
        ) != noErr)
            printf("ERROR: AudioQueueAllocateBuffer failed");
	}	
    
	// set the volume of the queue
	if (AudioQueueSetParameter(player->queue, kAudioQueueParam_Volume, 1.0) != noErr)
        printf("ERROR: set queue volume");
}
