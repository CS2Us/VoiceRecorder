//
//  RollingOutputView.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/3/9.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit
import RecordKit

class RollingOutputView: UIView {
	private var _rollingEqualizerView: DPRollingEqualizerView? = nil
	private var _floatData: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>? = nil
	private var _audioFloatConverter: EZAudioFloatConverter? = nil

	func beginRolling() {
		_rollingEqualizerView = DPRollingEqualizerView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 100)), andSettings: DPEqualizerSettings.create(by: .rolling))
		addSubview(_rollingEqualizerView!)
	}
	
	func endUpRolling() {
		_rollingEqualizerView?.removeFromSuperview()
		_floatData = nil
		_audioFloatConverter = nil
	}
}

extension RollingOutputView: RKMicrophoneHandle {
	func microphoneWorking(_ microphone: RKMicrophone, bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32) {
		if _audioFloatConverter == nil {
			_audioFloatConverter = EZAudioFloatConverter(inputFormat: microphone.inputFormat.asbd)
			_floatData = EZAudioUtilities.floatBuffers(withNumberOfFrames: RKSettings.bufferLength.samplesCount, numberOfChannels: microphone.inputFormat.channelCount)
		}
		_audioFloatConverter?.convertData(from: UnsafeMutablePointer<AudioBufferList>(mutating: bufferList), withNumberOfFrames: numberOfFrames, toFloatBuffers: _floatData)
		if let monoFloatData = _floatData?.pointee {
			_rollingEqualizerView?.updateBuffer(monoFloatData, withBufferSize: numberOfFrames)
		}
	}
}

extension RollingOutputView: RKAudioConverterHandle {
	func audioConvertCompleted(_ converter: RKAudioConverter) {
//		print("录音录制完成 fileExt: \(converter.outputUrl.fileExt)")
//		print("录音录制完成 fileName: \(converter.outputUrl.fileName)")
//		print("录音录制完成 mimeType: \(converter.outputUrl.mimeType!)")
//		print("录音录制完成 directoryPath: \(converter.outputUrl.directoryPath)")
//		print("录音录制完成 fileID: \(converter.outputUrl.fileId) \n")
//		print("录音录制完成 fileNamePlusExtension: \(converter.outputUrl.fileNamePlusExtension)")
	}
}
