//
//  ExceptionCatcher.m
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

void RKTryOperation(void (^ _Nonnull tryBlock)(void),
					void (^ _Nullable catchBlock)(NSException * _Nonnull))
{
	@try {
		tryBlock();
	}
	@catch (NSException *exception) {
		if (catchBlock)
			catchBlock(exception);
	}
}
