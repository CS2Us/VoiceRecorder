//
//  RKAudioInputStream.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/14.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

open class RKAudioInputStream: InputStream {
	var microphone: RKMicrophone!
	var audioConverter: RKAudioConverter!
	var asrerConverter: RKAudioConverter!
	var asrer: RKASRer!
	
	var audioData: AudioDataQueue = AudioDataQueue(bufferCapacity: RKSettings.bufferLength.samplesCount)
	struct AudioDataQueue {
		var mDataLength: Int
		var mBufferCapacity: Int
		var mData: UnsafeMutablePointer<UInt8>
		var mLoopStart: UnsafeMutablePointer<UInt8>
		var mLoopEnd: UnsafeMutablePointer<UInt8>
		var mDataEnd: UnsafeMutablePointer<UInt8>
		var mDataFrames: (UnsafePointer<AudioBufferList>?, UInt32)
		var mTotalFrames: UInt32
		
		init(bufferCapacity: UInt32) {
			mDataLength = 0
			mBufferCapacity = Int(bufferCapacity)
			mData = UnsafeMutablePointer<UInt8>.allocate(capacity: mBufferCapacity)
			mDataEnd = mData + mBufferCapacity
			mLoopStart = mData
			mLoopEnd = mData
			mDataFrames = (nil, 0)
			mTotalFrames = 0
		}
	}
	
	public static func inputStream() -> RKAudioInputStream {
		let inputStream = RKAudioInputStream()
//		inputStream.microphone = RKMicrophone.microphone()
//		inputStream.audioConverter = RKAudioConverter.converter()
//		inputStream.asrerConverter = RKAudioConverter.converter()
		inputStream.asrer = RKASRer.asrer()
		return inputStream
	}
	
	public func initObserver() {
//		Broadcaster.register(RKMicrophoneHandle.self, observer: self)
		
		{ [weak self] in
			RecordKit.microphoneObservers.addObject(self)
		}()
	}
	
	public func initInputStream() {
		do {
			try microphone.setupIOUnit()
//			try audioConverter.prepare(inRealtime: true)
//			try asrerConverter.prepare(inRealtime: true)
//			try asrer.longSpeechRecognition(audioConverter.outputUrl)
		} catch let ex {
			RKLog("initInputStream error: \(ex)")
		}
	}
	
	public func openInputStream() {
		do {
			try microphone.startIOUnit()
		} catch let ex {
			RKLog("openInputStream error: \(ex)")
		}
	}
	
	public func stopInputStream() {
		do {
			try microphone.stopIOUnit()
		} catch let ex {
			RKLog("stopInputStream error: \(ex)")
		}
	}
	
	public func closeInputStream() {
		do {
			try microphone.endUpIOUnit()
			try audioConverter.disposeConvert()
			try asrerConverter.disposeConvert()
			try asrer.endRecognition()
		} catch let ex {
			RKLog("closeInputStream error: \(ex)")
		}
		
		microphone = nil
		audioConverter = nil
		asrerConverter = nil
		asrer = nil
		audioData.reset()
	}
	
	override open func open() {}
	override open func close() {}
	override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
		objc_sync_enter(self)
		defer {
			objc_sync_exit(self)
		}
		return audioData.dequeSamples(buffer, bufferSize: len, dequeRemaining: true)
		
	}
	
	override open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
		return false
	}
	
	deinit {
		RKLogBrisk("流销毁")
	}
}

extension RKAudioInputStream.AudioDataQueue {
	mutating func queueAudio(_ audioData: inout UnsafePointer<UInt8>, dataLength: inout Int) -> Int {
		if dataLength == 0 { return mDataLength }
		if dataLength > mBufferCapacity {
			audioData += (dataLength - mBufferCapacity)
			dataLength = mBufferCapacity
		}
		let remainingLen = mDataEnd - mLoopEnd
		let rightLen = remainingLen >= dataLength ? dataLength : remainingLen
		memcpy(mLoopEnd, audioData, rightLen)
		mLoopEnd += rightLen
		if mLoopEnd == mDataEnd {
			mLoopEnd = mData
		}
		let leftLen = dataLength > rightLen ? dataLength - rightLen : 0
		if leftLen > 0 {
			memcpy(mLoopEnd, audioData + rightLen, leftLen)
			mLoopEnd += leftLen
		}
		mDataLength += dataLength
		if mDataLength >= mBufferCapacity {
			mDataLength = mBufferCapacity
			mLoopStart = mLoopEnd
		}
		return mDataLength
	}
	
	mutating func dequeSamples(_ dataBuffer: UnsafeMutablePointer<UInt8>, bufferSize: Int, dequeRemaining: Bool) -> Int {
		if mDataLength >= bufferSize || dequeRemaining {
			let tmp = mDataEnd - mLoopStart
			let dataRightLen = tmp >= mDataLength ? mDataLength : tmp
			let rightLen = dataRightLen >= bufferSize ? bufferSize : dataRightLen
			memcpy(dataBuffer, mLoopStart, rightLen)
			mLoopStart += rightLen
			if mLoopStart == mDataEnd {
				mLoopStart = mData
			}
			var leftLen = 0
			let left = bufferSize - rightLen
			if left > 0 {
				let dataLeftLen = mDataLength > dataRightLen ? mDataLength - dataRightLen : 0
				leftLen = dataLeftLen >= left ? left : dataLeftLen
				memcpy(dataBuffer + rightLen, mLoopStart, leftLen)
				mLoopStart += leftLen
			}
			mDataLength -= bufferSize
			if mDataLength <= 0 {
				mDataLength = 0
				mLoopStart = mData
				mLoopEnd = mData
			}
			return rightLen + leftLen
		}
		return 0
	}
	
	mutating func reset() {
		mDataLength = 0
		mDataEnd = mData + mBufferCapacity
		mLoopStart = mData
		mLoopEnd = mData
		mDataFrames = (nil, 0)
		mTotalFrames = 0
	}
}

extension RKAudioInputStream: RKMicrophoneHandle {
	public func microphoneWorking(_ microphone: RKMicrophone, bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32) {
		var intByteSize: Int = Int(bufferList.pointee.mBuffers.mDataByteSize)
		var uInt8Buffer: UnsafePointer<UInt8> = UnsafePointer(bufferList.pointee.mBuffers.mData!.bindMemory(to: UInt8.self, capacity: intByteSize))
		RKLogBrisk("流准备写入")
		audioData.mDataLength = audioData.queueAudio(&uInt8Buffer, dataLength: &intByteSize)
		audioData.mDataFrames = (bufferList, numberOfFrames)
		audioData.mTotalFrames += numberOfFrames
		
		guard UInt32(RKSettings.maxDuration * RKSettings.sampleRate)
			> audioData.mTotalFrames else {
				RKLogBrisk("时间到，流停止: \(audioData.mTotalFrames)")
				DispatchQueue.main.async {
					RecordKit.recordCancle()
				}
				return }
		
		if RKSettings.timeStamp >= RKSettings.maxDuration {
			RKSettings.timeStamp = 0
			RKLogBrisk("清除录音时长")
		} else {
			RKSettings.timeStamp = Double(audioData.mTotalFrames) / RKSettings.sampleRate
			RKLogBrisk("录音时长: \(RKSettings.timeStamp)")
		}
		
		do {
			try audioConverter.convert(inputStream: self)
			try asrerConverter.convert(inputStream: self)
		} catch let ex {
			print("converter convert error: \(ex)")
		}
		RKLogBrisk("流已经写入")
		
	}
}
