//
//  RKAudioPlot.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AudioToolbox

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
	let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
	let result = delegate.performRender(ioActionFlags,
										inTimeStamp: inTimeStamp,
										inBufNumber: inBufNumber,
										inNumberFrames: inNumberFrames,
										ioData: ioData!)
	return result
}

protocol RKMicrophoneDelegate {
	func microphone(_ microphone: RKMicrophone, audioReceived buffer: UnsafePointer<Float>, bufferSize: UInt32)
	
	func microphone(_ microphone: RKMicrophone, audioReceived bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32)
}

class RKMicrophone: RKNode {
	private var _rioUnit: AudioUnit? = nil
	private var _delegate: RKMicrophoneDelegate? = nil
	private var _audioFloatConverter: EZAudioFloatConverter? = nil
	private var _floatData: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>? = nil
	
	var inputFormat: RKSettings.IOFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
	
	static func microphone(_ delegate: RKMicrophoneDelegate) -> RKMicrophone {
		let microphone = RKMicrophone()
		microphone._delegate = delegate
		return microphone
	}
	
	public override init() {
		super.init()
		_audioFloatConverter = EZAudioFloatConverter(inputFormat: inputFormat.asbd)
		_floatData = EZAudioUtilities.floatBuffers(withNumberOfFrames: RKSettings.bufferLength.samplesCount, numberOfChannels: inputFormat.channelCount)
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
				mNumberChannels:1,
				mDataByteSize: inNumberFrames * inputFormat.asbd.mBytesPerFrame,
				mData: nil))
		
		let result = AudioUnitRender(_rioUnit!,
							   ioActionFlags,
							   inTimeStamp,
							   1,
							   inNumberFrames,
							   &bufferList)
		
		
		_audioFloatConverter?.convertData(from: &bufferList, withNumberOfFrames: inNumberFrames, toFloatBuffers: _floatData)
		if let monoFloatData = _floatData?.pointee {
			_delegate?.microphone(self, audioReceived: monoFloatData, bufferSize: inNumberFrames)
		}

		_delegate?.microphone(self, audioReceived: &bufferList, numberOfFrames: inNumberFrames)
		

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
			
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), 0, &one, SizeOf32(one))
			}, "could not enable output on AURemoteIO")
			
			var ioFormat = inputFormat.asbd
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat))
			}, "couldn't set the input client format on AURemoteIO")
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
			}, "couldn't set the output client format on AURemoteIO")
			
			var maxFramesPerSlice: UInt32 = RKSettings.bufferLength.samplesCount
			try RKTry({
				AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_MaximumFramesPerSlice), AudioUnitScope(kAudioUnitScope_Global), 0, &maxFramesPerSlice, SizeOf32(UInt32.self))
			}, "couldn't set max frames per slice on AURemoteIO")

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
				AudioUnitSetProperty(self._rioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, SizeOf32(AURenderCallbackStruct.self))
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
		} catch let ex {
			throw ex
		}
	}
}
