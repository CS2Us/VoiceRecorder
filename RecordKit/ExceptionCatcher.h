//
//  ExceptionCatcher.h
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

void RKTryOperation(void (^ _Nonnull tryBlock)(void),
					void (^ _Nullable catchBlock)(NSException * _Nonnull));

#endif /* ExceptionCatcher_h */
