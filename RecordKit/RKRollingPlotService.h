//
//  RKRollingPlotService.h
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/9.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRollingPlotSetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface RKRollingPlotService : NSObject

@property (nonatomic, strong)RKRollingPlotSetting *setting;

- (void)update:(const float *)buffer with:(UInt32)bufferSize;

@end

NS_ASSUME_NONNULL_END
