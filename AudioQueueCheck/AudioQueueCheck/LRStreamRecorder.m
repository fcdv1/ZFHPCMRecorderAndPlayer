//
//  LRStreamRecorder.m
//  Intercom
//
//  Created by CIA on 2016/11/17.
//  Copyright © 2016年 CIA. All rights reserved.
//

#import "LRStreamRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>

#define kNumberRecordBuffers 3


@interface LRStreamRecorder ()

@property (nonatomic, assign) BOOL isRecording;

-(void) inputData:(NSData *)data numberOfPacket:(int)numberOfPacket;


@end

void MyInputBufferHandler(	void *								inUserData,
                                      AudioQueueRef						inAQ,
                                      AudioQueueBufferRef					inBuffer,
                                      const AudioTimeStamp *				inStartTime,
                                      UInt32								inNumPackets,
                                      const AudioStreamPacketDescription*	inPacketDesc)
{
    LRStreamRecorder *recorder = (__bridge LRStreamRecorder *)inUserData;
    int dataLenth = (int)inBuffer->mAudioDataByteSize;
    if (dataLenth > 0) {
        NSData *newPCMData = [NSData dataWithBytes:inBuffer->mAudioData length:dataLenth];
        [recorder inputData:newPCMData numberOfPacket:dataLenth/2];
    }
    
    OSStatus errorStatus = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    if (errorStatus) {
        NSLog(@"MyInputBufferHandler error:%d", (int)errorStatus);
        return;
    }
}

@implementation LRStreamRecorder{
    AudioQueueRef				mQueue;
    AudioQueueBufferRef			mBuffers[kNumberRecordBuffers];
    int						mRecordPacket; // current packet number in record file
    AudioStreamBasicDescription	mRecordFormat;
}

-(instancetype) initWithFrequency:(int) frequency bitsForSingleChannel:(int)bitsForSingleChannel channelCount:(int) channnelCount callBackDuration:(float)callBackDuration{
    self = [super init];
    
    mRecordFormat.mSampleRate = frequency;
    mRecordFormat.mFormatID = kAudioFormatLinearPCM;
    mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mRecordFormat.mChannelsPerFrame = channnelCount;
    mRecordFormat.mFramesPerPacket = 1;
    mRecordFormat.mBitsPerChannel = bitsForSingleChannel;
    mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel/8) * mRecordFormat.mChannelsPerFrame;
    mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame;
    
    OSStatus errorStatus;
    errorStatus = AudioQueueNewInput(
                                     &mRecordFormat,
                                     MyInputBufferHandler,
                                     (__bridge void *)self /* userData */,
                                     NULL /* run loop */, NULL /* run loop mode */,
                                     0 /* flags */, &mQueue);
    
    int bufferSize = callBackDuration * mRecordFormat.mBytesPerFrame * frequency;
    
    for (int i = 0; i < kNumberRecordBuffers; ++i) {
        errorStatus = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
        errorStatus = AudioQueueEnqueueBuffer(mQueue, mBuffers[i], 0, NULL);
        if (errorStatus) {
            NSLog(@"StartRecord error:%d alloc and enqueue buffer", (int)errorStatus);
        }
    }
    return self;
}

-(BOOL) startRecord{
    if (self.isRecording) {
        return NO;
    }
    // start the queue
    OSStatus errorStatus;
    errorStatus = AudioQueueStart(mQueue, nil);
    if (errorStatus) {
        NSLog(@"StartRecord error:%d", (int)errorStatus);
        return NO;
    }
    self.isRecording = YES;
    return YES;
}

-(void) inputData:(NSData *)data numberOfPacket:(int)numberOfPacket{
    if (self.pcmDataCallBack) {
        self.pcmDataCallBack(data,numberOfPacket);
    }
}

-(BOOL) pause{
    if (self.isRecording == NO) {
        return NO;
    } else {
        AudioQueueFlush(mQueue);
        OSStatus status = AudioQueuePause(mQueue);
        if (status != 0) {
            NSLog(@"Pause failed");
            return NO;
        } else {
            self.isRecording = NO;
            return YES;
        }
    }
}

-(void) dealloc{
    AudioQueueDispose(mQueue, TRUE);
}

@end
