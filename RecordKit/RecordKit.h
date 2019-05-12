//
//  RecordKit.h
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for RecordKit.
FOUNDATION_EXPORT double RecordKitVersionNumber;

//! Project version string for RecordKit.
FOUNDATION_EXPORT const unsigned char RecordKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RecordKit/PublicHeader.h>
#import "ExceptionCatcher.h"
#import "EZAudio.h"

// 百度语音识别
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"

// AudioKit
#import "AKInterop.h"
#import "AKAudioUnit.h"
#import "AKAudioUnitBase.h"
#import "AKBoosterDSP.hpp"
#import "AKParameterRamp.hpp"
#import "AKParameterRampBase.hpp"
#import "AKLinearParameterRamp.hpp"
#import "AKExponentialParameterRamp.hpp"
#import "AKGeneratorAudioUnitBase.h"
#import "AKDSPKernel.hpp"
#import "AKDSPBase.hpp"
#import "BufferedAudioUnit.h"
#import "ParameterRamper.hpp"
#import "DSPKernel.hpp"
#import "BufferedAudioBus.hpp"
#import "AudioEngineUnit.h"
#import "AKStereoFieldLimiterDSP.hpp"
#import "AKMoogLadderDSP.hpp"
#import "AKSoundpipeDSPBase.hpp"
