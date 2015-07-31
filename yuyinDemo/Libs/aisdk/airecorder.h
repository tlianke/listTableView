//
//  airecorder.h
//
//  Created by Midfar Sun on 2/6/12.
//  Copyright 2012 midfar.com. All rights reserved.
//
#include "stdlib.h"
#include "AudioToolbox/AudioToolbox.h"
#include "aiplayer.h"

#define kNumberRecordBuffers	5
#define kCallbackIntervalMin    50      //50ms
#define kCallbackIntervalMax    1000    //1000ms

typedef void (*airecorder_callback_func)(
    const void * user_data,
    const void * audio_data, 
    int size
);

typedef struct
{
    char riff_id[4];                //"RIFF"
    uint32_t riff_datasize;         // RIFF chunk data size
    
    char riff_type[4];              // "WAVE"
    char fmt_id[4];                 // "fmt "
    uint32_t fmt_datasize;          // fmt chunk data size
    short fmt_compression_code;     // 1 for PCM
    short fmt_channels;             // 1 or 2
    uint32_t fmt_sample_rate;       // samples per second
    uint32_t fmt_avg_bytes_per_sec; // sample_rate*block_align
    short fmt_block_align;          // number bytes per sample bit_per_sample*channels/8
    short fmt_bit_per_sample;       // bits of each sample.
    
    char data_id[4];                // "data"
    uint32_t data_datasize;         // data chunk size.
} WaveHeader;

typedef struct
{
    CFStringRef					file_path;
    FILE *                      audio_file;
    AudioQueueRef				queue;
    AudioQueueBufferRef			buffers[kNumberRecordBuffers];
    //AudioFileID				record_file;
    //SInt64					record_packet; // current packet number in record file
    Boolean						is_recording;
    //Boolean                     is_replaying;
    aiplayer                  *player;
    
    airecorder_callback_func    callback_func;
    const void *                user_data;
} airecorder;

/*
 * create a new recorder
 */
airecorder * airecorder_new(void);

/*
 * delete an existed recorder
 */
OSStatus airecorder_delete(airecorder *recorder);

/*
 * start recorder
 */
OSStatus airecorder_start_record(
    airecorder *recorder,
    const char *file_path,
    uint32_t sample_rate,
    airecorder_callback_func callback_func,
    const void *user_data, 
    uint32_t callback_interval
);

/*
 * stop recorder
 */
OSStatus airecorder_stop_record(airecorder *recorder);

/*
 * start replay
 */
OSStatus airecorder_start_replay(airecorder *recorder, Boolean inResume, aiplayer_stopped_callback_func fn, const void *user_data);

/*
 * stop replay
 */
OSStatus airecorder_stop_replay(airecorder *recorder);

/*
 * pause replay
 */
OSStatus airecorder_pause_replay(airecorder *recorder);
