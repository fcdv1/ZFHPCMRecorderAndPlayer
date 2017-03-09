//
//  ViewController.m
//  AudioQueueCheck
//
//  Created by CIA on 2017/3/8.
//  Copyright © 2017年 CIA. All rights reserved.
//

#import "ViewController.h"
#import "LRStreamRecorder.h"
#import "LRStreamPlayer.h"
@import AVFoundation;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) LRStreamRecorder *recorder;

@property (nonatomic, strong) LRStreamPlayer *player;

@property (nonatomic, strong) NSMutableArray *allRecordData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:&error];
    if (error) {
        NSLog(@"Set session failed");
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Set session failed");
    }

    self.allRecordData = [NSMutableArray new];
    
    __weak ViewController *weakSelf = self;
    self.recorder = [[LRStreamRecorder alloc] initWithFrequency:8000 bitsForSingleChannel:8 channelCount:1 callBackDuration:.5];
    self.recorder.pcmDataCallBack = ^(NSData *pcmData, int numberOfPacket){
        [weakSelf.allRecordData addObject:pcmData];
    };
    
    self.player = [[LRStreamPlayer alloc] initWithFrequency:8000 bitsForSingleChannel:8 channelCount:1 singleBufferDuration:.5];
}
- (IBAction)recordButtonPressed:(id)sender {
    if (self.recorder.isRecording) {        
        [self.recorder pause];
        [self.recordButton setTitle:@"Begin Record" forState:UIControlStateNormal];
    } else {
        [self.recorder startRecord];
        [self.recordButton setTitle:@"Pause Record" forState:UIControlStateNormal];
    }
}
- (IBAction)playButtonPressed:(id)sender {
    if (self.player.isPlaying) {
        [self.player pause];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        if (self.allRecordData.count > 0) {
            for (NSData *pcmData in self.allRecordData) {
                [self.player inputPCMData:pcmData];
            }
            [self.allRecordData removeAllObjects];
        }
        [self.player play];
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}




@end
