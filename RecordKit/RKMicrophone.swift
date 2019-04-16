//
//  RKAudioPlot.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AudioToolbox
import DSPKit

@objc protocol AURenderCallbackDelegate {
	func performRender(_ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
					   inTimeStamp: UnsafePointer<AudioTimeStamp>,
					   inBufNumber: UInt32,
					   inNumberFrames: UInt32,
					   ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus
}

private let RecordKit_RenderCallback: AURenderCallback = {(inRefCon,
	ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
	inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
	inBufNumber/*: UInt32*/,
	inNumberFrames/*: UInt32*/,
	ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
	-> OSStatus
	in
	var bufferList = AudioBufferList()
	let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
	let result = delegate.performRender(ioActionFlags,
										inTimeStamp: inTimeStamp,
										inBufNumber: inBufNumber,
										inNumberFrames: inNumberFrames,
										ioData: &bufferList)
	return result
}

@objc
public protocol RKMicrophoneHandle {
	@objc(microphoneWorking:bufferList:numberOfFrames:)
	optional func microphoneWorking(_ microphone: RKMicrophone, bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32)
	@objc(microphoneStop:)
	optional func microphoneStop(_ microphone: RKMicrophone)
}

public class RKMicrophone: RKNode {
	private var _rioUnit: AudioUnit? = nil
	
	public var inputFormat: RKSettings.IOFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
	
	public static func microphone() -> RKMicrophone {
		let microphone = RKMicrophone()
		return microphone
	}
	
	public override init() {
		super.init()
		setupIOUnit()
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
		/** noise_suppression
		guard let floatBuffers: UnsafeMutablePointer<UnsafeMutablePointer<Float>?> = {
			let floatConverter = EZAudioFloatConverter(inputFormat: inputFormat.asbd)
			let floatBuffers = EZAudioUtilities.floatBuffers(withNumberOfFrames: inNumberFrames, numberOfChannels: inputFormat.channelCount)
			floatConverter?.convertData(from: &bufferList, withNumberOfFrames: inNumberFrames, toFloatBuffers: floatBuffers)
			return floatBuffers
			}(), let floatData: UnsafePointer<Float> = UnsafePointer(floatBuffers[0]) else { return OSStatus(100000) }
		
		let nsIntData = UnsafeMutablePointer<Float>.init(mutating: floatData)
		let nsOutData = nsIntData
		let nsOutDataPointer = EZAudioUtilities.floatBuffers(withNumberOfFrames: inNumberFrames, numberOfChannels: inputFormat.channelCount)
		nsOutDataPointer?.pointee = nsOutData
		
		let ns: DSPKit_Ns = DSPKit_Ns.init(sampleRate: UInt32(inputFormat.sampleRate), mode: aggressive15dB)
		ns.dspFrameProcess(nsIntData, out: nsOutData, frames: Int32(inNumberFrames))

		guard let floatConverter = AEFloatConverter.init(sourceFormat: inputFormat.asbd) else { return OSStatus(10000) }
		AEFloatConverterFromFloat(floatConverter, unsafeBitCast(nsOutDataPointer, to: UnsafePointer<UnsafeMutablePointer<Float>?>.self), &bufferList, inNumberFrames)
		**/
		
		Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
			observer.microphoneWorking?(self, bufferList: &bufferList, numberOfFrames: inNumberFrames)
		})
		
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
			
			var one: UInt32 = 1
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), 1, &one, SizeOf32(one))
			}, "could not enable input on AURemoteIO")
			
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), 0, &one, SizeOf32(one))
//			}, "could not enable output on AURemoteIO")
			
			var ioFormat = inputFormat.asbd
//			try RKTry({
//				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat))
//			}, "couldn't set the input client format on AURemoteIO")
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
			}, "couldn't set the output client format on AURemoteIO")
			
			var maxFramesPerSlice: UInt32 = UInt32(inputFormat.sampleRate / 100)
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_MaximumFramesPerSlice), AudioUnitScope(kAudioUnitScope_Global), 0, &maxFramesPerSlice, SizeOf32(UInt32.self))
			}, "couldn't set max frames per slice on AURemoteIO")
//
			var propSize = SizeOf32(UInt32.self)
			try RKTry({
				AudioUnitGetProperty(self._rioUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize)
			}, "couldn't get max frames per slice on AURemoteIO")
			
			// Set the render callback on AURemoteIO
			var renderCallback = AURenderCallbackStruct(
				inputProc: RecordKit_RenderCallback,
				inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
			)
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, SizeOf32(AURenderCallbackStruct.self))
			}, "couldn't set render callback on AURemoteIO")
			
			// Initialize the AURemoteIO instance
			try RKTry({
				AudioUnitInitialize(self._rioUnit!)
			}, "couldn't initialize AURemoteIO instance")
		} catch let ex as NSException {
			RKLog("Error returned from setupIOUnit: %d: %@", ex.name)
		} catch _ {
			RKLog("Unknown error returned from setupIOUnit")
		}
		
	}
	
	internal func startIOUnit() throws {
		do {
			try RKTry({
				AudioOutputUnitStart(self._rioUnit!)
			}, "couldn't start AURemoteIO")
		} catch let ex {
			throw ex
		}
	}
	
	internal func stopIOUnit() throws {
		do {
			try RKTry({
				AudioOutputUnitStop(self._rioUnit!)
			}, "couldn't stop AURemoteIO")
			Broadcaster.notify(RKMicrophoneHandle.self, block: { observer in
				observer.microphoneStop?(self)
			})
		} catch let ex {
			throw ex
		}
	}
}
