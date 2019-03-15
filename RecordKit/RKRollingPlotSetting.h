//
//  RKRollingPlotSetting.h
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/3/10.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef RKRollingSetting_h
#define RKRollingSetting_h

@interface RKRollingPlotSetting : NSObject

/// The highest bound of the frequency. Default: 7000Hz
@property (nonatomic) float maxFrequency;

/// The lowest bound of the frequency. Default: 400Hz
@property (nonatomic) float minFrequency;

/// The number of bins in the audio plot. Default: 40
@property (nonatomic) NSUInteger numOfBins;

/// The padding of each bin in percent width. Default: 0.2
@property (nonatomic) CGFloat padding;

/// The gain applied to the height of each bin. Default: 10
@property (nonatomic) CGFloat gain;

/// A float that specifies the vertical gravitational acceleration applied to each bin.
/// Default: 10 pixel/sec^2
@property (nonatomic) float gravity;

/// The number of max bin height. Default: Screen height.
@property (assign, nonatomic) CGFloat maxBinHeight;

@end

#endif /* RKRollingSetting_h */
