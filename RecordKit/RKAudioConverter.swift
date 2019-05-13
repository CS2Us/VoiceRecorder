//
//  RKAudioConverter.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/13.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

public class RKAudioConverter: RKObject {
	private var _destinationFile: ExtAudioFileRef!
	private var _audioConvertInfo: AudioConvertInfo!
	
	public override init() {
		super.init()
		
		do {
			try RKTry({
				self._audioConvertInfo = try AudioConvertInfo(parent: self)
			}, "failed for audioConvertInfo")
		} catch let ex {
			RKLog("failed to prepare: \(ex)")
		}
	}

	public func write(from buffer: AVAudioPCMBuffer) throws {
		do {
			try RKTry({
				ExtAudioFileWrite(self._destinationFile, buffer.frameLength, buffer.audioBufferList)
			}, "ExtAudioFileRead failed")
		} catch let ex {
			RKLog("RKAudioConverter failed in progress")
			throw ex
		}
	}
	
	public func stop() throws {
		try RKTry({
			if self._destinationFile != nil {
				ExtAudioFileDispose(self._destinationFile)
			}
		}, "_destinationFile dispose error")
		try RKTry({
			if self._audioConvertInfo?._crt != nil {
				ExtAudioFileDispose(self._audioConvertInfo._crt)
			}
		}, "_audioConvertInfo?._crt dispose error")
		
		_destinationFile = nil
		_audioConvertInfo = nil
	}
	
	deinit {
		RKLogBrisk("转换器销毁")
	}
}

extension RKAudioConverter {
	struct AudioConvertInfo {
		let _parent: RKAudioConverter
		let _crt: AudioConverterRef
		let _cltASBD: AudioStreamBasicDescription
		
		init(parent: RKAudioConverter) throws {
			do {
				_parent = parent
				
				var dstASBD = AudioStreamBasicDescription()
				try RKTry({
					dstASBD.mFormatID = kAudioFormatMPEG4AAC
					dstASBD.mSampleRate = RKSettings.sampleRate
					dstASBD.mChannelsPerFrame = RKSettings.channelCount
					var dstSize = SizeOf32(dstASBD)
					AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &dstSize, &dstASBD)
				}, "couldn't fill out the destination data format")
				
				try RKTry({
					ExtAudioFileCreateWithURL(Destination.documents(name: "RK_CV", type: "m4a").fileUrl as CFURL, kAudioFileM4AType, &dstASBD, nil, AudioFileFlags.eraseFile.rawValue, &parent._destinationFile)
				}, "failed to create the destination audio file")
				
				var cltASBD = RKSettings.IOFormat.lpcm32
				let cltSize = SizeOf32(cltASBD)
				try RKTry({
					ExtAudioFileSetProperty(parent._destinationFile, kExtAudioFileProperty_ClientDataFormat, cltSize, &cltASBD)
				}, "couldn't set the client format on the destination file")
				
				// Get the audio converter
				var crt: AudioConverterRef?
				var crtSize = SizeOf32(crt)
				try RKTry({
					ExtAudioFileGetProperty(parent._destinationFile, kExtAudioFileProperty_AudioConverter, &crtSize, &crt)
				}, "failed to get the Audio Converter from the destination file")
				
				_crt = crt!
				_cltASBD = cltASBD
				
				RKLog("Destination file format:\n")
				printAudioStreamBasicDescription(dstASBD)
				RKLog("Client file format:\n")
				printAudioStreamBasicDescription(cltASBD)
			} catch let ex {
				RKLog("Prepare AudioConvertInfo Fault")
				throw ex
			}
		}
		
		func printAudioStreamBasicDescription(_ asbd: AudioStreamBasicDescription) {
			print("Sample Rate: \(asbd.mSampleRate)")
			print("Format ID: \(Desc(formatID: asbd.mFormatID))")
			print("Format Flags: \(Desc(formatFlags: asbd.mFormatFlags))")
			print("Bytes PER Packet: \(asbd.mBytesPerPacket)")
			print("Frames PER Packet: \(asbd.mFramesPerPacket)")
			print("Bytes PER Frame: \(asbd.mBytesPerFrame)")
			print("Channels PER Frame: \(asbd.mChannelsPerFrame)")
			print("Bits PER Channel: \(asbd.mBitsPerChannel)")
			print("\n")
		}
	}
}
