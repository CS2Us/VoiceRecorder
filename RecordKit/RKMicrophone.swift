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

public class RKMicrophone: RKNode {
	private var _rioUnit: AudioUnit? = nil
//	private var _ns: DSPKit_Ns? = nil
	
	public var inputFormat: RKSettings.IOFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
	
	public static func microphone() -> RKMicrophone {
		let microphone = RKMicrophone()
		return microphone
	}
	
	public override init() {
		super.init()
		setupIOUnit()
	}
	
	deinit {
		print("麦克风销毁")
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
		
		print("麦克风首先收到系统数据")
		
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
		
		let result = AudioUnitRender(_rioUnit!,
									 ioActionFlags,
									 inTimeStamp,
									 1,
									 inNumberFrames,
									 &bufferList)
		
		print("麦克风收到数据回调")
		
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
		
		RecordKit.default.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneWorking?(self, bufferList: &bufferList, numberOfFrames: inNumberFrames)
		}
		
		return result
	}
}

extension RKMicrophone {
	private func setupIOUnit() {
		do {
			var desc = AudioComponentDescription(
				componentType: OSType(kAudioUnitType_Output),
				componentSubType: OSType(kAudioUnitSubType_RemoteIO),
				componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
				componentFlags: 0,
				componentFlagsMask: 0)
			
			let comp = AudioComponentFindNext(nil, &desc)
			
			try RKTry({
				AudioComponentInstanceNew(comp!, &self._rioUnit)
			}, "couldn't create a new instance of AURemoteIO")
			
			print("麦克风实例化")
			
			var one: UInt32 = 1
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), 1, &one, SizeOf32(one))
			}, "kAudioOutputUnitProperty_EnableIO failed")
			
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
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
			}, "couldn't set the output client format on AURemoteIO")
			
//			var maxFramesPerSlice: UInt32 = UInt32(inputFormat.sampleRate / 100)
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_MaximumFramesPerSlice), AudioUnitScope(kAudioUnitScope_Global), 0, &maxFramesPerSlice, SizeOf32(UInt32.self))
//			}, "couldn't set max frames per slice on AURemoteIO")
//
//			var propSize = SizeOf32(UInt32.self)
//			try RKTry({
//				AudioUnitGetProperty(self._rioUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize)
//			}, "couldn't get max frames per slice on AURemoteIO")
			
			// Set the render callback on AURemoteIO
			var renderCallback = AURenderCallbackStruct(
				inputProc: RecordKit_RenderCallback,
				inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
			)
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, SizeOf32(AURenderCallbackStruct.self))
			}, "couldn't set render callback on AURemoteIO")
			
			do {
				try AudioUnitSetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, SizeOf32(AURenderCallbackStruct.self))
			} catch let ex {
				print("这到底是怎么回事: \(ex)")
			}
			
			// Initialize the AURemoteIO instance
			try RKTry({
				AudioUnitInitialize(self._rioUnit!)
			}, "couldn't initialize AURemoteIO instance")
			
			print("麦克风初始化完成")
		} catch let ex as NSException {
			RKLog("Error returned from setupIOUnit: %d: %@", ex.name)
		} catch _ {
			RKLog("Unknown error returned from setupIOUnit")
		}
		
	}
	
	internal func startIOUnit() throws {
		try RKTry({
			AudioOutputUnitStart(self._rioUnit!)
		}, "couldn't start AURemoteIO")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneStart?(self)
//		})
		
		print("麦克风开始录音")
		
		RecordKit.default.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneStart?(self)
		}
	}
	
	internal func stopIOUnit() throws {
		try RKTry({
			AudioOutputUnitStop(self._rioUnit!)
		}, "couldn't stop AURemoteIO")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneStop?(self)
//		})
		
		RecordKit.default.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneStop?(self)
		}
	}
	
	internal func endUpIOUnit() throws {
		print("取消麦克风before")
		try RKTry({
			AudioOutputUnitStop(self._rioUnit!)
		}, "couldn't stop AURemoteIO")
		print("麦克风暂停")
		try RKTry({
			AudioComponentInstanceDispose(self._rioUnit!)
		}, "couldn't deinit component")
		_rioUnit = nil
		print("取消麦克风after")
		
//		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
//			observer.microphoneEndup?(self)
//		})
		
		RecordKit.default.microphoneObservers.allObjects
			.map{$0 as? RKMicrophoneHandle}.filter{$0 != nil}.forEach { observer in
			observer?.microphoneEndup?(self)
		}
	}
}
