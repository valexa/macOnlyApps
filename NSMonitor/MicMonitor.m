//
//  MicMonitor.m
//  NSMonitor
//
//  Created by Vlad Alexa on 4/5/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "MicMonitor.h"

#define SINT16_MAX ((float)(0x7FFF))

SInt16 computemax(SInt16 b[],int n)
{
    SInt16 max = 0;
    for(int c=0; c<n; c++){
        if(b[c]>max) max=b[c];
    }    
    return max;
}

@implementation MicMonitor

-(void)awakeFromNib
{
    micMonitorSession = [[AVCaptureSession alloc] init];
    [self performSelector:@selector(startMonitoringMic) withObject:nil afterDelay:10];
}

-(void)stopMonitoringMic
{
    for (AVCaptureInput *input in [micMonitorSession inputs]) {
        [micMonitorSession removeInput:input];
    }
    for (AVCaptureOutput *output in [micMonitorSession outputs]) {
        [micMonitorSession removeOutput:output];
    }    
}

-(void)startMonitoringMic
{    
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput    = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"Error %@",error);
    }else {
        AVCaptureAudioDataOutput    *dataOutput = [[AVCaptureAudioDataOutput alloc] init];
        
        dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
        [dataOutput setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);                
        
        if ([micMonitorSession canAddInput:audioInput]) {
            [micMonitorSession addInput:audioInput];
        }else {
            NSLog(@"Can not add audioInput");  
            return;            
        }
        if ([micMonitorSession canAddOutput:dataOutput]) {
            [micMonitorSession addOutput:dataOutput];            
        }else {
            NSLog(@"Can not add dataOutput");  
            return;
        }   
        
        [micMonitorSession startRunning];         
        
        NSLog(@"Started monitoring decibel level of %@ ",[audioCaptureDevice modelID]);
                
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //[self calculateMicLevel:sampleBuffer];
    [self levelFromAVCaptureConnection:connection];
    
}

-(AudioBufferList)CMSampleBufferToAudioBuffer:(CMSampleBufferRef)sampleBuffer
{
    AudioBufferList ret;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &ret, sizeof(ret), NULL, NULL, 0, &blockBuffer);
    CFRelease(blockBuffer);
    blockBuffer = NULL;    
    return ret;      
}

-(NSData*)CMSampleBufferToNSData:(CMSampleBufferRef)sampleBuffer
{
    AudioBufferList bufferList;
    NSMutableData *data = [[NSMutableData alloc] init];
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &bufferList, sizeof(bufferList), NULL, NULL, 0, &blockBuffer);
    for( int y=0; y<bufferList.mNumberBuffers; y++ )  {
        AudioBuffer audioBuffer = bufferList.mBuffers[y];
        Float32 *frame = (Float32*)audioBuffer.mData;
        [data appendBytes:frame length:audioBuffer.mDataByteSize];        
    }    
    CFRelease(blockBuffer);
    blockBuffer = NULL;        
    return data;      
}

- (void)levelFromAVCaptureConnection:(AVCaptureConnection *)connection
{
	NSInteger channelCount = 0;
	float decibels = 0.f;
    float peaks = 0.f;
	
	// Sum all of the average power levels and divide by the number of channels
    for (AVCaptureAudioChannel *audioChannel in [connection audioChannels]) {
        decibels += [audioChannel averagePowerLevel];
        peaks += [audioChannel peakHoldLevel];
        channelCount += 1;
    }
	
	decibels /= channelCount;
  	peaks /= channelCount;
	
	[micLevel setFloatValue:(pow(10.f, 0.05f * decibels) * 20.0f)];    
    
	//[inMeter setProgress:(pow(10.f, 0.05f * decibels) * 20.0f)];    
	//[inPeakMeter setProgress:(pow(10.f, 0.05f * peaks) * 20.0f)];    
    
    //NSLog(@"Current decibels: %f %f %f",(pow(10.f, 0.05f * decibels) * 20.0f),decibels,peaks);
    
}

- (void)levelFromCMSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    
    //NSLog(@"%@",CMSampleBufferGetFormatDescription(sampleBuffer));
	
	CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
	NSUInteger channelIndex = 0;
	
	CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
	size_t audioBlockBufferOffset = (channelIndex * numSamples * sizeof(SInt16));
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	SInt16 *samples = NULL;
	CMBlockBufferGetDataPointer(audioBlockBuffer, audioBlockBufferOffset, &lengthAtOffset, &totalLength, (char **)(&samples));
	
	int numSamplesToRead = 1;
    
	for (int i = 0; i < numSamplesToRead; i++) {
		
		SInt16 subSet[numSamples / numSamplesToRead];
		for (int j = 0; j < numSamples / numSamplesToRead; j++)
			subSet[j] = samples[(i * (numSamples / numSamplesToRead)) + j];
		
		SInt16 lastMicSample = computemax(subSet,numSamples/numSamplesToRead);		
		float currentMicLevel = (float) ((lastMicSample / SINT16_MAX));
		
		NSLog(@"Current audio level: %f", currentMicLevel);
		
	}
	
}

@end
