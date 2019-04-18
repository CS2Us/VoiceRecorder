//
//  DSPKit.m
//  DSPKit
//
//  Created by guoyiyuan on 2019/4/13.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import "DSPKit_Ns.h"

#import <mobileffmpeg/mobileffmpeg.h>

#include <iostream>

#include "ns/ns_core.h"
#include "ns/noise_suppression.h"
#include "splitting_filter/splitting_filter.h"
#include "audio_util.h"
#include "signal_processing_library.h"

@implementation DSPKit_Ns {
	NsHandle *nsHandle;
	size_t numPerFrame;
	webrtc::TwoBandsStates TwoBands;
	webrtc::ThreeBandFilterBank *three_bands_filter_48k;
	char *pcm_buff;
}

- (instancetype)init {
	if (!(self = [super init])) {
		return nil;
	}
	return self;
}

- (instancetype)initWithSampleRate:(unsigned int)sampleRate mode:(DSPKit_NsMode)nsMode {
	if (!(self = [self init]))
		return nil;
	
	if (sampleRate == 8000 || sampleRate == 16000 || sampleRate == 32000 || sampleRate == 48000 || sampleRate == 44100) {
		if (sampleRate == 44100) {
			std::cout << "44100 采样率暂不支持, 请用48000 测试";
			return nil;
		}
		numPerFrame = sampleRate / 100;
		nsHandle = WebRtcNs_Create();
		int status = WebRtcNs_Init(nsHandle, sampleRate);
		if (status != 0) {
			std::cout << "句柄初始化失败";
			return nil;
		}
		status = WebRtcNs_set_policy(nsHandle, nsMode);
		if (status != 0) {
			std::cout <<  "降噪模式设置失败";
			return nil;
		}
		three_bands_filter_48k = new webrtc::ThreeBandFilterBank(480);
		return self;
	} else {
		std::cout << "该采样率暂不支持";
		return nil;
	}
}

- (void)dspFrameProcess:(float *)data_in out:(float *)data_out frames:(int)inNumberOfFrames {
	for (size_t nFrames = 0; nFrames < inNumberOfFrames / numPerFrame; nFrames ++) {
		[self dspFrameProcess:data_in + nFrames * numPerFrame out:data_out + nFrames * numPerFrame];
	}
}

- (void)dspFrameProcesss:(AudioBufferList *)bufferList {
	
}

- (void)dspFrameProcess:(float *)data_in out:(float *)data_out {
	if (numPerFrame == 80 || numPerFrame == 160) {
		float *input_buffer[1] = { data_in };
		float *output_buffer[1] = { data_out };
		WebRtcNs_Analyze(nsHandle, input_buffer[0]);
		WebRtcNs_Process(nsHandle, (const float *const *)input_buffer, 1, output_buffer);
		return;
	} else if (numPerFrame == 320) {
		int16_t data_twobands_int16[2][160] {{0}, {0}};
		int16_t data_in_int16[320] {};
		webrtc::FloatToS16(data_in, 320, data_in_int16);
		// 滤波
		WebRtcSpl_AnalysisQMF(data_in_int16, 320, data_twobands_int16[0], data_twobands_int16[1], TwoBands.analysis_state1, TwoBands.analysis_state2);
		// 两波操作
		float data_in_twobands_f[2][160] = {{0}, {0}};
		float data_out_twobands_f[2][160] = {{0}, {0}};
		webrtc::S16ToFloat(data_twobands_int16[0], 160, data_in_twobands_f[0]);
		webrtc::S16ToFloat(data_twobands_int16[1], 160, data_out_twobands_f[1]);
		// 噪声分析
		float *input_buffer[2] = { data_in_twobands_f[0], data_in_twobands_f[1] };
		float *output_buffer[2] = { data_out_twobands_f[0], data_out_twobands_f[1] };
		WebRtcNs_Analyze(nsHandle, input_buffer[0]);
		WebRtcNs_Process(nsHandle, input_buffer, 2, output_buffer);
		webrtc::FloatToS16(output_buffer[0], 160, data_twobands_int16[0]);
		webrtc::FloatToS16(output_buffer[1], 160, data_twobands_int16[1]);
		// 合成
		WebRtcSpl_SynthesisQMF(data_twobands_int16[0], data_twobands_int16[1], 160, data_in_int16, TwoBands.synthesis_state1, TwoBands.synthesis_state2);
	} else if (numPerFrame == 480 || numPerFrame == 441) {
		float band_in[3][160] {{}, {}, {}};
		float band_out[3][160] {{}, {}, {}};
		float *three_band_in[3] = { band_in[0], band_in[1], band_in[2] };
		float *three_band_out[3] = { band_out[0], band_out[1], band_out[2] };
		three_bands_filter_48k->Analysis(data_in, 480, three_band_out);
		WebRtcNs_Analyze(nsHandle, three_band_in[0]);
		WebRtcNs_Process(nsHandle, three_band_in, 3, three_band_out);
		three_bands_filter_48k->Synthesis(three_band_out, 160, data_out);
	} else {
		std::cout << "仅仅支持48000khz";
		return;
	}
}

@end
