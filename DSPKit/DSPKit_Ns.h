//
//  DSPKit_Ns.h
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/4/13.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

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

- (instancetype)initWithASBD:(AudioStreamBasicDescription)asbd mode:(DSPKit_NsMode)mode;

- (void)dspFrameProcesss:(AudioBufferList *)bufferList;

@end
