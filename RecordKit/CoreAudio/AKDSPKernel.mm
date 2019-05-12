//
//  AKDSPKernel.cpp
//  AudioKit
//
//  Created by Stéphane Peter, revision history on Githbub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#include "AKDSPKernel.hpp"

#import <RecordKit/RecordKit-Swift.h>

AKDSPKernel::AKDSPKernel() : AKDSPKernel(RKSettings.channelCount, RKSettings.sampleRate) { }
