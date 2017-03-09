//
//  LRStreamPlayer.h
//  AudioQueueCheck
//
//  Created by CIA on 2017/3/8.
//  Copyright © 2017年 CIA. All rights reserved.
//



#import <Foundation/Foundation.h>

@interface LRStreamPlayer : NSObject

-(instancetype) initWithFrequency:(int) frequency bitsForSingleChannel:(int)bitsForSingleChannel channelCount:(int) channnelCount singleBufferDuration:(float)singleBufferDuration;

@property (nonatomic, readonly) BOOL isPlaying;

-(void) inputPCMData:(NSData *)pcmDta;

-(BOOL) play;

-(BOOL) pause;

//No more data,Call this function will cause the player auto pause when all PCM Data is played
-(void) dataFinished;
@end
