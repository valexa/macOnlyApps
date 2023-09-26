//
//  MicMonitor.h
//  NSMonitor
//
//  Created by Vlad Alexa on 4/5/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>

@interface MicMonitor : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate>{
    AVCaptureSession  *micMonitorSession;
    IBOutlet NSLevelIndicator *micLevel;  
}

-(void)startMonitoringMic;
-(void)stopMonitoringMic;

@end
