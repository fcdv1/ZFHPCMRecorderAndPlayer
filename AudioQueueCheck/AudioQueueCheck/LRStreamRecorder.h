//
//  LRStreamRecorder.h
//  Intercom
//
//  Created by CIA on 2016/11/17.
//  Copyright © 2016年 CIA. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PCMDataCallBackBlock)(NSData *pcmData, int numberOfPacket);

@interface LRStreamRecorder : NSObject

-(instancetype) initWithFrequency:(int) frequency bitsForSingleChannel:(int)bitsForSingleChannel channelCount:(int) channnelCount callBackDuration:(float)callBackDuration;

@property (nonatomic, readonly) BOOL isRecording;

@property (nonatomic, strong) PCMDataCallBackBlock pcmDataCallBack;

-(BOOL) startRecord;

-(BOOL) pause;

@end
