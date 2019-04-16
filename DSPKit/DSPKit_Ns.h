//
//  DSPKit_Ns.h
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/4/13.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

/** |mode| = 0 is mild (6dB),
 |mode| = 1 is medium (10dB) and
 |mode| = 2 is aggressive (15dB).
 **/
typedef enum mode {
	mild6dB,
	medium10dB,
	aggressive15dB,
} DSPKit_NsMode;

@interface DSPKit_Ns: NSObject

- (instancetype)initWithUrl:(NSURL *)url mode:(DSPKit_NsMode)nsMode;

- (instancetype)initWithSampleRate:(unsigned int)sampleRate mode:(DSPKit_NsMode)nsMode;

- (void)dspFrameProcess:(float *)data_in out:(float *)data_out frames:(int)inNumberOfFrames;

@end
