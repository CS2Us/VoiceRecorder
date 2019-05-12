//
//  RKAudioPlot.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AudioToolbox
//import DSPKit

@objc protocol AURenderCallbackDelegate {
	func performRender(_ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
					   inTimeStamp: UnsafePointer<AudioTimeStamp>,
					   inBufNumber: UInt32,
					   inNumberFrames: UInt32,
					   ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus
}

@objc
public protocol RKMicrophoneHandle {
	@objc(microphoneWorking:bufferList:numberOfFrames:)
	optional func microphoneWorking(_ microphone: RKMicrophone, bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32)
	@objc(microphoneStop:)
	optional func microphoneStop(_ microphone: RKMicrophone)
	@objc(microphoneClose:)
	optional func microphoneEndup(_ microphone: RKMicrophone)
	@objc(microphoneStart:)
	optional func microphoneStart(_ microphone: RKMicrophone)
}

public class RKMicrophone: RKObject {
	private var _rioUnit: AudioUnit? = nil
//	private var _ns: DSPKit_Ns? = nil
	
	public var inputFormat: RKSettings.IOFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
	
	public static func microphone() -> RKMicrophone {
		let microphone = RKMicrophone()
		return microphone
	}
	
	deinit {
		RKLogBrisk("麦克风销毁")
	}
}

extension RKMicrophone {
	var RecordKit_RenderCallback: AURenderCallback { return {(inRefCon,
		ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
		inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
		inBufNumber/*: UInt32*/,
		inNumberFrames/*: UInt32*/,
		ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
		-> OSStatus
		in
		
		RKLogBrisk("麦克风首先收到系统数据")
		
		var bufferList = AudioBufferList()
		let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
		let result = delegate.performRender(ioActionFlags,
											inTimeStamp: inTimeStamp,
											inBufNumber: inBufNumber,
											inNumberFrames: inNumberFrames,
											ioData: &bufferList)
		return result
		}
	}
}

extension RKMicrophone: AURenderCallbackDelegate {
	func performRender(_ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBufNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
		// Make sure the size of each buffer in the stored buffer array
		// is properly set using the actual number of frames coming in!
		var bufferList = AudioBufferList(
			mNumberBuffers: 1,
			mBuffers: AudioBuffer(
				mNumberChannels: inputFormat.channelCount,
				mDataByteSize: inNumberFrames * inputFormat.asbd.mBytesPerFrame,
				mData: nil))
		
		let error = AudioUnitRender(_rioUnit!,
									 ioActionFlags,
									 inTimeStamp,
									 1,
									 inNumberFrames,
									 &bufferList)
		
		RKLogBrisk("麦克风收到数据回调: \(error)")

//		if _ns == nil {
//			_ns = DSPKit_Ns.init(asbd: inputFormat.asbd, mode: aggressive15dB)
//		}
//		_ns!.dspFrameProcesss(&bufferList)
//
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneWorking?(self, bufferList: &bufferList, numberOfFrames: bufferList.mBuffers.mDataByteSize / inputFormat.asbd.mBytesPerFrame);
//		})
//
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneWorking?(self, bufferList: &bufferList, numberOfFrames: inNumberFrames);
//		})
		
		RecordKit.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneWorking?(self, bufferList: &bufferList, numberOfFrames: inNumberFrames)
		}
		
		return error
	}
}

extension RKMicrophone {
	 internal func setupIOUnit() throws {
		do {
			var desc = AudioComponentDescription(
				componentType: OSType(kAudioUnitType_Output),
				componentSubType: OSType(kAudioUnitSubType_RemoteIO),
				componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
				componentFlags: 0,
				componentFlagsMask: 0)
			
			var error: OSStatus = noErr
			
			let comp = AudioComponentFindNext(nil, &desc)
			
			try RKTry({
				error = AudioComponentInstanceNew(comp!, &self._rioUnit)
			}, "couldn't create a new instance of AURemoteIO")
			
			RKLogBrisk("麦克风实例化: \(error)")
			
			var one: UInt32 = 1
			try RKTry({
				error = AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), 1, &one, SizeOf32(one))
			}, "kAudioOutputUnitProperty_EnableIO failed")
			
			RKLogBrisk("麦克风io: \(error)")
			
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), 0, &one, SizeOf32(one))
//			}, "could not enable output on AURemoteIO")
			
//			var zero: UInt32 = 0
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!,
//									 kAUVoiceIOProperty_BypassVoiceProcessing,
//									 kAudioUnitScope_Global,
//									 0,
//									 &zero,
//									 SizeOf32(zero))
//			}, "kAUVoiceIOProperty_BypassVoiceProcessing failed")
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, kAUVoiceIOProperty_VoiceProcessingEnableAGC, kAudioUnitScope_Global,
//									 0,
//									 &zero,
//									 SizeOf32(zero))
//			}, "kAUVoiceIOProperty_VoiceProcessingEnableAGC failed")
			
			var ioFormat = inputFormat.asbd
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat))
//			}, "couldn't set the input client format on AURemoteIO")
			try RKTry({
				error = AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
			}, "couldn't set the output client format on AURemoteIO")
			
			RKLogBrisk("麦克风asbd: \(error)")
			
			var maxFramesPerSlice: UInt32 = UInt32(inputFormat.sampleRate / 100)
			try RKTry({
				error = AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_MaximumFramesPerSlice), AudioUnitScope(kAudioUnitScope_Global), 0, &maxFramesPerSlice, SizeOf32(UInt32.self))
			}, "couldn't set max frames per slice on AURemoteIO")
			
			RKLogBrisk("麦克风maxframes: \(error)")
			
			// Set the render callback on AURemoteIO
			var renderCallback = AURenderCallbackStruct(
				inputProc: RecordKit_RenderCallback,
				inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
			)
			try RKTry({
				error = AudioUnitSetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, SizeOf32(AURenderCallbackStruct.self))
			}, "couldn't set render callback on AURemoteIO")
			
			RKLogBrisk("麦克风callback: \(error)")
			
//			propSize = SizeOf32(AURenderCallbackStruct.self)
//			try RKTry({
//				error = AudioUnitGetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, &propSize)
//			}, "couldn't get render callback on AURemoteIO")
//
//			RKLogBrisk("麦克风callback get: \(error)")
			
			// Initialize the AURemoteIO instance
			try RKTry({
				error = AudioUnitInitialize(self._rioUnit!)
			}, "couldn't initialize AURemoteIO instance")
			
			RKLogBrisk("麦克风初始化: \(error)")
		} catch let ex as NSException {
			RKLog("Error returned from setupIOUnit: %d: %@", ex.name)
		} catch _ {
			RKLog("Unknown error returned from setupIOUnit")
		}
		
	}
	
	internal func startIOUnit() throws {
		var error: OSStatus = noErr
		
		try RKTry({
			error = AudioOutputUnitStart(self._rioUnit!)
		}, "couldn't start AURemoteIO")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneStart?(self)
//		})
		
		RKLogBrisk("麦克风开始录音: \(error)")
		
		RecordKit.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneStart?(self)
		}
	}
	
	internal func stopIOUnit() throws {
		var error: OSStatus = noErr
		
		try RKTry({
			error = AudioOutputUnitStop(self._rioUnit!)
		}, "couldn't stop AURemoteIO")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneStop?(self)
//		})
		
		RKLogBrisk("麦克风停止录音: \(error)")
		
		RecordKit.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneStop?(self)
		}
	}
	
	internal func endUpIOUnit() throws {
		var error: OSStatus = noErr

		try RKTry({
			error = AudioComponentInstanceDispose(self._rioUnit!)
		}, "couldn't deinit component")
		_rioUnit = nil
		
		RKLogBrisk("麦克风终止录音: \(error)")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneEndup?(self)
//		})
		
		RecordKit.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneEndup?(self)
		}
	}
}
