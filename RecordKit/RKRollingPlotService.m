//
//  RKRollingPloat.m
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/9.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

const UInt32 kMaxFrames = 2048;
const Float32 kAdjust0DB = 1.5849e-13;
const NSInteger kFrameInterval = 1; // Alter this to draw more or less often
const NSInteger kFramesPerSecond = 20; // Alter this to draw more or less often

#import "RKRollingPlotService.h"

@interface RKRollingPlotService()

@property (strong, nonatomic) CADisplayLink *displaylink;
@property (strong, nonatomic) NSMutableArray *heightsByTime;

@end

@implementation RKRollingPlotService {
	FFTSetup fftSetup;
	float sampleRate;
	COMPLEX_SPLIT complexSplit;
	size_t bufferCapacity, index;
	float *speeds, *times, *tSqrts, *vts, *deltaHeights, *dataBuffer, *heightsByFrequency;
	int log2n, n, nOver2;
}

- (void)setSetting:(RKRollingPlotSetting *)setting {
	_setting = setting;
	_displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateHeightsByTime)];
	[_displaylink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
	[self prepare];
}

- (void)prepare {
	NSUInteger numOfBins = _setting.numOfBins;
	
	//Configure Data buffer and setup FFT
	dataBuffer = (float *)malloc(kMaxFrames * sizeof(float));
	
	log2n = log2f(kMaxFrames);
	n = 1 << log2n;
	assert(n == kMaxFrames);
	
	nOver2 = kMaxFrames / 2;
	bufferCapacity = kMaxFrames;
	index = 0;
	
	complexSplit.realp = (float *)malloc(nOver2 * sizeof(float));
	complexSplit.imagp = (float *)malloc(nOver2 * sizeof(float));
	
	[self freeBuffers];
	
	//Create buffers
	heightsByFrequency = (float *)calloc(sizeof(float), numOfBins);
	speeds = (float *)calloc(sizeof(float), numOfBins);
	times = (float *)calloc(sizeof(float), numOfBins);
	tSqrts = (float *)calloc(sizeof(float), numOfBins);
	vts = (float *)calloc(sizeof(float), numOfBins);
	deltaHeights = (float *)calloc(sizeof(float), numOfBins);
	
	//Create Heights by time array
	self.heightsByTime = [NSMutableArray arrayWithCapacity: numOfBins];
	for (int i = 0; i < numOfBins; i++) {
		self.heightsByTime[i] = [NSNumber numberWithFloat:0];
	}
}

- (void)updateHeightsByTime {
	NSUInteger numOfBins = _setting.numOfBins;
	float gravity = _setting.gravity;
	
	//Delay from last frame
	float delay;
	if (@available(iOS 11.0, *)) {
		delay = self.displaylink.duration * self.displaylink.preferredFramesPerSecond;
	} else {
		delay = self.displaylink.duration * self.displaylink.frameInterval;
	}
	
	// increment time
	vDSP_vsadd(times, 1, &delay, times, 1, numOfBins);
	
	// clamp time
	static const float timeMin = 1.5, timeMax = 10;
	vDSP_vclip(times, 1, &timeMin, &timeMax, times, 1, numOfBins);
	
	// increment speed
	float g = gravity * delay;
	vDSP_vsma(times, 1, &g, speeds, 1, speeds, 1, numOfBins);
	
	// increment height
	vDSP_vsq(times, 1, tSqrts, 1, numOfBins);
	vDSP_vmul(speeds, 1, times, 1, vts, 1, numOfBins);
	float aOver2 = g / 2;
	vDSP_vsma(tSqrts, 1, &aOver2, vts, 1, deltaHeights, 1, numOfBins);
	vDSP_vneg(
			  
			  deltaHeights, 1, deltaHeights, 1, numOfBins);
	vDSP_vadd(heightsByFrequency, 1, deltaHeights, 1, heightsByFrequency, 1, numOfBins);
}

#pragma mark - Update Buffers
- (void)setSampleData:(float *)data length:(int)length {
	NSUInteger numOfBins = _setting.numOfBins;
	// fill the buffer with our sampled data. If we fill our buffer, run the FFT
	int inNumberFrames = length;
	int read = (int)(bufferCapacity - index);
	
	if (read > inNumberFrames) {
		memcpy((float *)dataBuffer + index, data, inNumberFrames * sizeof(float));
		index += inNumberFrames;
	} else {
		// if we enter this conditional, our buffer will be filled and we should perform the FFT
		memcpy((float *)dataBuffer + index, data, read * sizeof(float));
		
		// reset the index.
		index = 0;
		
		vDSP_ctoz((COMPLEX *)dataBuffer, 2, &complexSplit, 1, nOver2);
		vDSP_fft_zrip(fftSetup, &complexSplit, 1, log2n, FFT_FORWARD);
		vDSP_ztoc(&complexSplit, 1, (COMPLEX *)dataBuffer, 2, nOver2);
		
		// convert to dB
		Float32 one = 1, zero = 0;
		vDSP_vsq(dataBuffer, 1, dataBuffer, 1, inNumberFrames);
		vDSP_vsadd(dataBuffer, 1, &kAdjust0DB, dataBuffer, 1, inNumberFrames);
		vDSP_vdbcon(dataBuffer, 1, &one, dataBuffer, 1, inNumberFrames, 0);
		vDSP_vthr(dataBuffer, 1, &zero, dataBuffer, 1, inNumberFrames);
		
		// aux
		float mul = (sampleRate / bufferCapacity) / 2;
		int minFrequencyIndex = self.setting.minFrequency / mul;
		int maxFrequencyIndex = self.setting.maxFrequency / mul;
		int numDataPointsPerColumn =
		(maxFrequencyIndex - minFrequencyIndex) / numOfBins;
		float maxHeight = 0;
		
		for (NSUInteger i = 0; i < numOfBins; i++) {
			// calculate new column height
			float avg = 0;
			vDSP_meanv(dataBuffer + minFrequencyIndex +
					   i * numDataPointsPerColumn,
					   1, &avg, numDataPointsPerColumn);
			
			CGFloat columnHeight = MIN(avg * self.setting.gain, self.setting.maxBinHeight);
			
			maxHeight = MAX(maxHeight, columnHeight);
			// set column height, speed and time if needed
			if (columnHeight > heightsByFrequency[i]) {
				heightsByFrequency[i] = columnHeight;
				speeds[i] = 0;
				times[i] = 0;
			}
		}
		
		[self.heightsByTime addObject: [NSNumber numberWithFloat:maxHeight]];
		
		if (self.heightsByTime.count > numOfBins) {
			[self.heightsByTime removeObjectAtIndex:0];
		}
	}
}

- (void)update:(float *)buffer with:(UInt32)bufferSize {
	[self setSampleData:buffer length:bufferSize];
}

- (void)freeBuffers {
	if (heightsByFrequency) {
		free(heightsByFrequency);
	}
	if (speeds) {
		free(speeds);
	}
	if (times) {
		free(times);
	}
	if (tSqrts) {
		free(tSqrts);
	}
	if (vts) {
		free(vts);
	}
	if (deltaHeights) {
		free(deltaHeights);
	}
}

- (void)dealloc {
	[_displaylink invalidate];
	_displaylink = nil;
	[self freeBuffers];
}

@end
