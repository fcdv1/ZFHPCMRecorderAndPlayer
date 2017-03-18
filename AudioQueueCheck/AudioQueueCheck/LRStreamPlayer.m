//
//  LRStreamPlayer.m
//  AudioQueueCheck
//
//  Created by CIA on 2017/3/8.
//  Copyright © 2017年 CIA. All rights reserved.
//

#import "LRStreamPlayer.h"
@import AudioToolbox;

static const int kNumberBuffers = 3;                              // 1
struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       //
    UInt32                        bufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
};

@interface LRStreamPlayer()

@property (nonatomic, strong) NSMutableArray *decodedPCMDatas;

@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isDataFinished;

-(void) needPCMDataForQueue:(AudioQueueRef)queueRef buffer:(AudioQueueBufferRef)buffer;

@end


static void HandleOutputBuffer (
                                void                *aqData,
                                AudioQueueRef       inAQ,
                                AudioQueueBufferRef inBuffer
                                ) {
    LRStreamPlayer *player = (__bridge LRStreamPlayer *)aqData;    
    [player needPCMDataForQueue:inAQ buffer:inBuffer];
}



@implementation LRStreamPlayer{
    struct AQPlayerState playerState;
    NSData *emptyData;
}


-(instancetype) initWithFrequency:(int) frequency bitsForSingleChannel:(int)bitsForSingleChannel channelCount:(int) channnelCount singleBufferDuration:(float)singleBufferDuration
{
    self = [super init];
    if (self) {
        self.decodedPCMDatas = [NSMutableArray new];
        
        
        playerState.mDataFormat.mSampleRate = frequency;
        playerState.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        playerState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        playerState.mDataFormat.mChannelsPerFrame = channnelCount;
        playerState.mDataFormat.mFramesPerPacket = 1;
        playerState.mDataFormat.mBitsPerChannel = bitsForSingleChannel;
        playerState.mDataFormat.mBytesPerFrame = (playerState.mDataFormat.mBitsPerChannel/8) * playerState.mDataFormat.mChannelsPerFrame;
        playerState.mDataFormat.mBytesPerPacket = playerState.mDataFormat.mBytesPerFrame;
        

        int status =  AudioQueueNewOutput(&playerState.mDataFormat, HandleOutputBuffer, (__bridge void *)self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &playerState.mQueue);
        if (status != 0) {
            NSLog(@"Create Audio Queue failed");
        }
        
        int bufferSize = singleBufferDuration * playerState.mDataFormat.mBytesPerFrame * frequency;
        for (int i = 0; i < kNumberBuffers; i += 1) {
            AudioQueueAllocateBuffer(playerState.mQueue, bufferSize,&playerState.mBuffers[i]);
        }
        
        void *emptyDatas = malloc(bufferSize);
        memset(emptyDatas, 0, bufferSize);
        emptyData = [NSData dataWithBytes:emptyDatas length:bufferSize];
        free(emptyDatas);
    }
    return self;
}

-(BOOL) play{
    self.isDataFinished = NO;
    
    if (self.isPaused == NO) {
        //need input data
        for (int i = 0; i < kNumberBuffers; i += 1) {
            HandleOutputBuffer((__bridge void *)self,playerState.mQueue,playerState.mBuffers[i]);
        }
    }
    
    OSStatus status = AudioQueueStart(playerState.mQueue, NULL);
    if (status != 0) {
        NSLog(@"Begin play failed");
        return NO;
    } else {
        self.isPlaying = YES;
        self.isPaused = NO;
        return YES;
    }
}

-(void) needPCMDataForQueue:(AudioQueueRef)queueRef buffer:(AudioQueueBufferRef)buffer{
    if (_decodedPCMDatas.count > 0) {
        NSData *pcmData = [_decodedPCMDatas firstObject];
        [_decodedPCMDatas removeObjectAtIndex:0];
        
        [self enQueueBufferData:pcmData inBuffer:buffer];
    } else {
        if (self.isDataFinished) {
            // must enqueue this buffer, if not after play three time,it will no longer play again
            [self enQueueBufferData:emptyData inBuffer:buffer];
            [self pause];
        } else {
            // If no pcm data avaliable, return a buffer with silent sound
            [self enQueueBufferData:emptyData inBuffer:buffer];
        }
    }
}

-(void) inputPCMData:(NSData *)bufferData{
    [self.decodedPCMDatas addObject:bufferData];
}

-(void) enQueueBufferData:(NSData *)pcmData inBuffer:(AudioQueueBufferRef)buffer{
    memcpy(buffer->mAudioData, pcmData.bytes, pcmData.length);
    buffer->mAudioDataByteSize = (int)pcmData.length;
    AudioQueueEnqueueBuffer(playerState.mQueue, buffer, 0, NULL);
}

-(void)dataFinished{
    self.isDataFinished = YES;
}

-(int)checkUsedQueueBuffer:(AudioQueueBufferRef) qbuf {
    int index = 0;
    for (int i = 0; i < kNumberBuffers; i += 1) {
        if (qbuf == playerState.mBuffers[i]) {
            index = i;
            break;
        }
    }
    return index;
}

-(BOOL) pause{
    if (self.isPlaying == NO) {
        return NO;
    } else {
        OSStatus status = AudioQueuePause(playerState.mQueue);
        if (status != 0) {
            NSLog(@"Pause failed");
            return NO;
        } else {
            self.isPlaying = NO;
            self.isPaused = YES;
            return YES;
        }
    }
}


-(void) dealloc{
    AudioQueueStop(playerState.mQueue, YES);
    for (int i = 0; i < kNumberBuffers; i += 1) {
        AudioQueueFreeBuffer(playerState.mQueue, playerState.mBuffers[i]);
    }
    AudioQueueDispose(playerState.mQueue, YES);
    
    
    [self.decodedPCMDatas removeAllObjects];
    self.isDataFinished = YES;
}


@end
