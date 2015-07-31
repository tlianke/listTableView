//
//  airecorder.c
//
//  Created by Midfar Sun on 2/6/12.
//  Copyright 2012 midfar.com. All rights reserved.
//

#include "airecorder.h"

static FILE * airecorder_fopen(const char * file_path, uint32_t sample_rate);
static size_t airecorder_fwrite(FILE * file, const void * data, size_t size);
static int airecorder_fclose(FILE * file);
void setupAudioFormat(AudioStreamBasicDescription *audio_format, uint32_t sample_rate);
int computeRecordBufferSize(AudioQueueRef queue, const AudioStreamBasicDescription *format, float seconds);
char * MYCFStringCopyUTF8String(CFStringRef aString);

void setupAudioFormat(
    AudioStreamBasicDescription *audio_format,
    uint32_t sample_rate)
{
    audio_format->mFormatID = kAudioFormatLinearPCM;
    audio_format->mSampleRate = sample_rate;
    audio_format->mBitsPerChannel = 16;
    audio_format->mChannelsPerFrame = 1;
    audio_format->mFramesPerPacket = 1;
    audio_format->mBytesPerFrame = (audio_format->mBitsPerChannel / 8) * audio_format->mChannelsPerFrame;
    audio_format->mBytesPerPacket = audio_format->mBytesPerFrame * audio_format->mFramesPerPacket;
    audio_format->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

// ____________________________________________________________________________________
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
int computeRecordBufferSize(AudioQueueRef queue, const AudioStreamBasicDescription *format, float seconds)
{
	int packets, frames, bytes = 0;
	//try {
    frames = (int)ceil(seconds * format->mSampleRate);
    
    if (format->mBytesPerFrame > 0)
        bytes = frames * format->mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0)
            maxPacketSize = format->mBytesPerPacket;	// constant packet size
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            int rv = AudioQueueGetProperty(
                queue, 
                kAudioQueueProperty_MaximumOutputPacketSize, 
                &maxPacketSize,
                &propertySize);
            if(rv != noErr){
                printf("couldn't get queue's maximum output packet size\n");
                return 0;
            }
        }
        if (format->mFramesPerPacket > 0)
            packets = frames / format->mFramesPerPacket;
        else
            packets = frames;	// worst-case scenario: 1 frame in a packet
        if (packets == 0)		// sanity check
            packets = 1;
        bytes = packets * maxPacketSize;
    }
	//} catch (CAXException e) {
	//	char buf[256];
	//	fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	//	return 0;
	//}	
	return bytes;
}

// ____________________________________________________________________________________
// Copy a queue's encoder's magic cookie to an audio file.
//void copyEncoderCookieToFile(airecorder_t *recorder)
//{
//    UInt32 cookieSize;
//    
//	// get the magic cookie, if any, from the converter
//    OSStatus err = AudioQueueGetPropertySize(
//        recorder->queue, 
//        kAudioQueueProperty_MagicCookie, 
//        &cookieSize
//    );
//
//	// we can get a noErr result and also a propertySize == 0
//	// -- if the file format does support magic cookies, but this file doesn't have one.
//	if (err == noErr && cookieSize > 0) {
//        char* magicCookie = (char *) malloc (cookieSize);
//		UInt32 magicCookieSize;
//		if((AudioQueueGetProperty(
//            recorder->queue, 
//            kAudioQueueProperty_MagicCookie, 
//            magicCookie, 
//            &cookieSize)
//        ) != noErr){
//            printf("get audio converter's magic cookie error\n");
//            return;
//        }
//		
//		// now set the magic cookie on the output file
//		UInt32 willEatTheCookie = false;
//		// the converter wants to give us one; will the file take it?
//		OSStatus err = AudioFileGetPropertyInfo(
//            recorder->record_file, 
//            kAudioFilePropertyMagicCookieData, 
//            NULL, 
//            &willEatTheCookie
//        );
//		if (err == noErr && willEatTheCookie) {
//			err = AudioFileSetProperty(
//               recorder->record_file, 
//               kAudioFilePropertyMagicCookieData, 
//               magicCookieSize, 
//               magicCookie
//            );
//            if(err != noErr){
//                printf("set audio file's magic cookie error\n");
//            }
//		}
//		free(magicCookie);
//	}
//}

// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
static void airecorder_input_callback(void *				in_user_data,
                              AudioQueueRef					in_aq,
                              AudioQueueBufferRef			in_buffer,
                              const AudioTimeStamp *		in_start_time,
                              UInt32						in_num_packets,
                              const AudioStreamPacketDescription*	in_packet_desc)
{
	airecorder *recorder = (airecorder *)in_user_data;
    
    int rv = noErr;
    
    if(in_buffer->mAudioDataByteSize > 0){
        if(recorder->callback_func){ 
            recorder->callback_func(recorder->user_data,
                                    in_buffer->mAudioData,
                                    in_buffer->mAudioDataByteSize);
        }
        if(recorder->audio_file){
            airecorder_fwrite(recorder->audio_file, in_buffer->mAudioData, in_buffer->mAudioDataByteSize);
        }
    }
    
    //if (in_num_packets > 0) {
    // write packets to file
    //rv = AudioFileWritePackets(
    //                      recorder->record_file, 
    //                      FALSE, 
    //                      in_buffer->mAudioDataByteSize,
    //                      in_packet_desc, 
    //                      recorder->record_packet, 
    //                      &in_num_packets, 
    //                      in_buffer->mAudioData);
    //if(rv != noErr){
    //    printf("AudioFileWritePackets failed\n");
    //    return;
    //}
    //
    //recorder->record_packet += in_num_packets;
    //}
    
    // if we're not stopping, re-enqueue the buffe so that it gets filled again
    if (recorder->is_recording){
        rv = AudioQueueEnqueueBuffer(in_aq, in_buffer, 0, NULL);
        if(rv != noErr){
            printf("airecorder_input_callback AudioQueueEnqueueBuffer failed, err=%d\n", rv);
            return;
        }
        
    }else{
        if(recorder->audio_file)
        {
            airecorder_fclose(recorder->audio_file);
            recorder->audio_file = NULL;
        }
        AudioQueueFreeBuffer(recorder->queue, in_buffer);
    }
}

airecorder * airecorder_new()
{
    airecorder *recorder = calloc(1, sizeof(airecorder));
    recorder->is_recording = false;
    //recorder->record_packet = 0;
    recorder->player = aiplayer_new();
    return recorder;
}

OSStatus airecorder_delete(airecorder *recorder)
{
    AudioQueueDispose(recorder->queue, true);
    //AudioFileClose(recorder->record_file);
    if(recorder->audio_file){
        airecorder_fclose(recorder->audio_file);
    }
    if(recorder->file_path) CFRelease(recorder->file_path);
    
    recorder->callback_func = NULL;
    recorder->user_data = NULL;
    aiplayer_delete(recorder->player);
    
    free(recorder);
    
    return noErr;
}

char * MYCFStringCopyUTF8String(CFStringRef aString){
    if(aString == NULL){
        return NULL;
    }
    CFIndex length = CFStringGetLength(aString);
    CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    
    char *buffer = (char *)malloc(maxSize);
    if(CFStringGetCString(aString, buffer, maxSize, kCFStringEncodingUTF8)){
        return buffer;
    }
    return NULL;
}

OSStatus airecorder_start_record(
    airecorder *recorder,
    const char *file_path,
    uint32_t sample_rate,
    airecorder_callback_func callback_func,
    const void *user_data, 
    uint32_t callback_interval
)
{
    int rv = noErr;
    int i, bufferByteSize;
	UInt32 size;
	//CFURLRef url;
    
    if (recorder->file_path) CFRelease(recorder->file_path);
    recorder->file_path = CFStringCreateWithCString(kCFAllocatorDefault, file_path, kCFStringEncodingUTF8);
    recorder->callback_func = callback_func;
    recorder->user_data = user_data;   
    
    // specify the recording format
    AudioStreamBasicDescription audio_format;
    setupAudioFormat(&audio_format, sample_rate);
    
    rv = AudioQueueNewInput(
        &audio_format,
        airecorder_input_callback,
        recorder /* userData */,
        NULL /* run loop */, 
        kCFRunLoopCommonModes /* run loop mode */,
        0 /* flags */, 
        &recorder->queue);
    if(rv != noErr)
    {
        printf("AudioQueueNewInput failed\n");
        goto end;
    };
    
    // get the record format back from the queue's audio converter --
    // the file may require a more specific stream description than was necessary to create the encoder.
    //recorder->record_packet = 0;
    
    size = sizeof(audio_format);
    
    if(( rv = AudioQueueGetProperty(
        recorder->queue, 
        kAudioQueueProperty_StreamDescription,	
        &audio_format, 
        &size)) != noErr){
        printf("couldn't get queue's format");
        goto end;
    };
    //url = CFURLCreateWithString(kCFAllocatorDefault, recorder->file_path, NULL);
    // create the audio file
    //if((rv = AudioFileCreateWithURL(
    //    url, 
    //    kAudioFileWAVEType, 
    //    &audio_format, 
    //    kAudioFileFlags_EraseFile,
    //    &recorder->record_file)) != noErr){
    //    printf("AudioFileCreateWithURL failed");
    //    goto end;
    //}
    //CFRelease(url);
    char *path = MYCFStringCopyUTF8String(recorder->file_path);
    recorder->audio_file = airecorder_fopen(path, sample_rate);
    free(path);
    
    // copy the cookie first to give the file object as much info as we can about the data going in
    // not necessary for pcm, but required for some compressed audio
    //copyEncoderCookieToFile(recorder);
    
    int bufferTime = callback_interval;
    if(bufferTime > kCallbackIntervalMax)
        bufferTime = kCallbackIntervalMax;
    if(bufferTime < kCallbackIntervalMin)
        bufferTime = kCallbackIntervalMin;
    // allocate and enqueue buffers
    bufferByteSize = computeRecordBufferSize(recorder->queue, &audio_format, bufferTime/1000.0);
    //printf("bufferByteSize=%d\n\n\n", bufferByteSize);
    for (i = 0; i < kNumberRecordBuffers; ++i) {
        rv = AudioQueueAllocateBuffer(recorder->queue, bufferByteSize, &recorder->buffers[i]);
        if(rv != noErr){
            printf("AudioQueueAllocateBuffer failed\n");
            goto end;
        }
        rv = AudioQueueEnqueueBuffer(recorder->queue, recorder->buffers[i], 0, NULL);
        if(rv != noErr){
            printf("AudioQueueEnqueueBuffer failed\n");
            goto end;
        }
    }

    recorder->is_recording = true;
    rv = AudioQueueStart(recorder->queue, NULL);
    if(rv != noErr){
        printf("AudioQueueStart failed\n");
    }
    
end:
    return rv;
}

OSStatus airecorder_stop_record(airecorder *recorder)
{
	// end recording
	recorder->is_recording = false;
    
    int rv = noErr;
	if((rv = AudioQueueStop(recorder->queue, true)) != noErr){
        printf("AudioQueueStop failed\n");
        goto end;
    }
	// a codec may update its cookie at the end of an encoding session, so reapply it to the file now
	//copyEncoderCookieToFile(recorder);
	//AudioQueueDispose(recorder->queue, true);
	//AudioFileClose(recorder->record_file);
    if(recorder->queue){
        AudioQueueDispose(recorder->queue, true);
        recorder->queue = NULL;
    }
    if(recorder->audio_file){
        airecorder_fclose(recorder->audio_file);
        recorder->audio_file = NULL;
    }
    
    recorder->callback_func = NULL;
    recorder->user_data = NULL;
    
	// dispose the previous playback queue
    aiplayer_dispose_queue(recorder->player, true);
    
    // now create a new queue for the recorded file
    aiplayer_create_queue(recorder->player, recorder->file_path);

end:
    return rv;
}

OSStatus airecorder_start_replay(airecorder *recorder, Boolean inResume, aiplayer_stopped_callback_func fn, const void *user_data)
{
    return aiplayer_start_queue(recorder->player, inResume, fn, user_data);
}

OSStatus airecorder_stop_replay(airecorder *recorder)
{
    return aiplayer_stop_queue(recorder->player);
}
OSStatus airecorder_pause_replay(airecorder *recorder)
{
    return aiplayer_pause_queue(recorder->player);
}

static FILE * airecorder_fopen(const char * file_path, uint32_t sample_rate)
{
    FILE * file = NULL;
    
    WaveHeader header;
    
    //uint32_t sample_rate = 8000;
    uint32_t bits_per_sample = 16;
    uint32_t channels = 1;
    
    file = fopen(file_path, "w");
    if(file == NULL)
        goto end;
    
    strncpy(header.riff_id, "RIFF", 4);
    header.riff_datasize = 0;                   // placehoder
    
    strncpy(header.riff_type, "WAVE", 4);
    
    strncpy(header.fmt_id, "fmt ", 4);
    header.fmt_datasize = 16;
    header.fmt_compression_code = 1;
    header.fmt_channels = channels;
    header.fmt_sample_rate = sample_rate;
    header.fmt_avg_bytes_per_sec = sample_rate * bits_per_sample * channels / 8;
    header.fmt_block_align = bits_per_sample * channels / 8;
    header.fmt_bit_per_sample = bits_per_sample;
    
    strncpy(header.data_id, "data", 4);
    header.data_datasize = 0;                    // place hoder
    
    fwrite(&header, 1, sizeof(WaveHeader), file);
    
end:
    return file;
}

static size_t airecorder_fwrite(FILE *file, const void * data, size_t size)
{
    return fwrite(data, 1, size, file);
}

static int airecorder_fclose(FILE *file)
{
    int ret = -1;
    
    long file_size = 0;
    long riff_datasize = 0;
    long data_datasize = 0;
    
    if(!file)
        goto end;
    
    fseek(file, 0L, SEEK_END);
    file_size = ftell(file);
    riff_datasize = file_size - 4;
    data_datasize = file_size - 44;
    
    fseek(file, 4L, SEEK_SET);
    fwrite(&riff_datasize, 1, 4, file);
    
    fseek(file, 40L, SEEK_SET);
    fwrite(&data_datasize, 1, 4, file);
    
    ret = fclose(file);
    
end:
    return ret;
}
