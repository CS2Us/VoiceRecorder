//
//  RecordKit+StarUp_Abadoned.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/11.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension RecordKit {
//	public func recordStart(destinationURL: Destination) {
//		sessionShouldBeInit()
//		RecordKit.shouldBeRunning = true
//		inputStream = RKAudioInputStream.inputStream()
//		inputStream.microphone.inputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
//		inputStream.audioConverter.outputFormat = RKSettings.IOFormat(formatID: outputFormat, bitDepth: .float32)
//		inputStream.audioConverter.outputUrl = destinationURL
//		inputStream.audioConverter.outputFileType = outputFileType
//		inputStream.asrerConverter.outputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16, sampleRate: 16000)
//		inputStream.asrerConverter.outputUrl = Destination.temp(url: "ASRTempFile.wav")
//		inputStream.asrerConverter.outputFileType = kAudioFileWAVEType
//		inputStream.initObserver()
//		inputStream.initInputStream()
//		inputStream.openInputStream()
//		RKLog("outputUrl: \(destinationURL.url.absoluteString)")
//
//		startCompletion?()
//	}
//
//	public func recordCancle() {
//		RecordKit.shouldBeRunning = false
//		inputStream.closeInputStream()
//		inputStream = nil
//		sessionShouldBeDeinit()
//		cancleCompletion?()
//	}
//
//	public func recordStop() {
//		RecordKit.shouldBeRunning = false
//		inputStream.stopInputStream()
//		stopCompletion?()
//	}
//
//	public func recordResume() {
//		RecordKit.shouldBeRunning = true
//		inputStream.openInputStream()
//		resumeCompletion?()
//	}
}
