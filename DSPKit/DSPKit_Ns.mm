//
//  DSPKit.m
//  DSPKit
//
//  Created by guoyiyuan on 2019/4/13.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

#import "DSPKit_Ns.h"
#import <RecordKit/RecordKit-Swift.h>

#import <mobileffmpeg/mobileffmpeg.h>

#include <iostream>

#include "ns/ns_core.h"
#include "ns/noise_suppression.h"
#include "splitting_filter/splitting_filter.h"
#include "audio_util.h"
#include "signal_processing_library.h"

@implementation DSPKit_Ns {
	AudioStreamBasicDescription asbd;
	NsHandle *nsHandle;
	uint32_t numPerFrame;
	webrtc::TwoBandsStates TwoBands;
	webrtc::ThreeBandFilterBank *three_bands_filter_48k;
	char *left_buff;
	char *total_buff;
	uint32_t buff_length;
	uint32_t total_size;
}

- (instancetype)init {
	if (!(self = [super init])) {
		return nil;
	}
	return self;
}

- (instancetype)initWithASBD:(AudioStreamBasicDescription)_asbd mode:(DSPKit_NsMode)_mode {
	if (!(self = [self init]))
		return nil;
	
	uint32_t sampleRate = UInt32(_asbd.mSampleRate);
	if (sampleRate == 8000 || sampleRate == 16000 || sampleRate == 32000 || sampleRate == 48000 || sampleRate == 44100) {
		if (sampleRate == 44100) {
			std::cout << "44100 采样率暂不支持, 请用48000 测试" << std::endl;
			return nil;
		}
		asbd = _asbd;
		numPerFrame = sampleRate / 100;
		left_buff = (char *)malloc(numPerFrame*asbd.mBytesPerFrame);
		total_size = 0;
		buff_length = 0;
		nsHandle = WebRtcNs_Create();
		int status = WebRtcNs_Init(nsHandle, sampleRate);
		if (status != 0) {
			std::cout << "句柄初始化失败" << std::endl;
			return nil;
		}
		status = WebRtcNs_set_policy(nsHandle, _mode);
		if (status != 0) {
			std::cout <<  "降噪模式设置失败" << std::endl;
			return nil;
		}
		three_bands_filter_48k = new webrtc::ThreeBandFilterBank(480);
		return self;
	} else {
		std::cout << "该采样率暂不支持" << std::endl;
		return nil;
	}
}

- (void)dspFrameProcesss:(AudioBufferList *)bufferList {
	uint32_t in_data_length = bufferList->mBuffers[0].mDataByteSize;
	uint32_t threshold_data_length = numPerFrame * asbd.mBytesPerFrame;
	if ((buff_length + in_data_length) < threshold_data_length) {
		memcpy(left_buff + buff_length, bufferList->mBuffers[0].mData, in_data_length);
		buff_length += in_data_length;
	} else {
		total_size = buff_length + in_data_length;
		total_buff = (char *)malloc(total_size);
		memset(total_buff, 0, total_size);
		memcpy(total_buff, left_buff, buff_length);
		memcpy(total_buff + buff_length, bufferList->mBuffers[0].mData, in_data_length);
		uint32_t multiple = (total_size - total_size % threshold_data_length);
		float *data_in = reinterpret_cast<float*>(total_buff);
		float *data_out = (float *)calloc(multiple, sizeof(float));
		for (int i = 0; i < (total_size / threshold_data_length); i++) {
			[self dspFrameProcess:data_in + i * threshold_data_length out:data_out + i * threshold_data_length];
		}
		buff_length = total_size % threshold_data_length;
		memset(left_buff, 0, numPerFrame * asbd.mBytesPerFrame);
		memcpy(left_buff, total_buff + (total_size - buff_length), buff_length);
		
//		memset(bufferList->mBuffers[0].mData, 0, total_size - buff_length);
		memcpy(bufferList->mBuffers[0].mData, data_out, total_size - buff_length);
		bufferList->mBuffers[0].mDataByteSize = total_size - buff_length;
		free(data_in);
		free(data_out);
	}
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
		webrtc::S16ToFloat(data_in_int16, 320, data_out);
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

- (void)dealloc {
	free(left_buff);
	free(total_buff);
	left_buff = NULL;
	total_buff = NULL;
}

@end
