//
//  RKRecorder.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/10.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AudioToolbox

@objc
public protocol RKAudioConverterHandle {
	@objc(audioConvertCompleted:)
	optional func audioConvertCompleted(_ converter: RKAudioConverter)
	@objc(audioConvertError)
	optional func audioConvertError()
}

public class RKAudioConverter: RKObject {
	private var _sourceFile: ExtAudioFileRef?
	private var _destinationFile: ExtAudioFileRef!
	private var _queue: DispatchQueue
	private var _semaphore: DispatchSemaphore
	private var _audioConvertInfo: AudioConvertInfo!
	private var _inRealtime: Bool!
	
	public var inputUrl: Destination = .none
	public var outputUrl: Destination = .none
	public var outputFormat: RKSettings.IOFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
	public var outputFileType: AudioFileTypeID = kAudioFileAIFFType
	
	public static func converter() -> RKAudioConverter {
		let converter = RKAudioConverter()
		return converter
	}
	
	override init() {
		_queue = DispatchQueue(label: "com.matrixmiaou.recordkit.audioConverter.queue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
		_semaphore = DispatchSemaphore(value: 0)
		super.init()
	}
	
	public func prepare(inRealtime: Bool) throws {
		_inRealtime = inRealtime
		if _inRealtime {
			RKLog("Converting In Realtime...\n")
		} else {
			RKLog("Converting Not In Realtime...\n")
		}
		
		do {
			try RKTry({
				self._audioConvertInfo = try AudioConvertInfo(parent: self)
			}, "failed for audioConvertInfo")
			
			try RKTry({
				if self._audioConvertInfo?._crt != nil {
					var canResumeFromInterruption = true
					var canResume: UInt32 = 0
					var canResumeSize = SizeOf32(canResume)
					var error = AudioConverterGetProperty(self._audioConvertInfo._crt, kAudioConverterPropertyCanResumeFromInterruption, &canResumeSize, &canResume)
					if error == noErr {
						if canResume == 0 {
							canResumeFromInterruption = false
						}
						RKLog("AudioConverter \((!canResumeFromInterruption ? "CANNOT" : "CAN")) continue after interruption!\n")
					} else {
						if error == kAudioConverterErr_PropertyNotSupported {
							RKLog("kAudioConverterPropertyCanResumeFromInterruption property not supported\n")
						} else {
							RKLog("AudioConverterGetProperty kAudioConverterPropertyCanResumeFromInterruption result \(error), paramErr is OK if PCM\n")
						}
						error = noErr
					}
				}
			}, "failed for canResumeFromInterruption")
		} catch let ex {
			RKLog("failed to prepare")
			throw ex
		}
	}
	
	public func convert(inputStream: RKAudioInputStream) throws {
		do {
			if _inRealtime {
				try RKTry({
					ExtAudioFileWrite(self._destinationFile, inputStream.audioData.mDataFrames.1, inputStream.audioData.mDataFrames.0!)
				}, "ExtAudioFileRead failed")
			} else {
				let bufferByteSize : UInt32 = RKSettings.bufferLength.samplesCount
				var srcBuffer = [UInt8](repeating: 0, count: Int(bufferByteSize))
				/*
				keep track of the source file offset so we know where to reset the source for
				reading if interrupted and input was not consumed by the audio converter
				*/
				var sourceFrameOffset : UInt32 = 0
				
				var error: OSStatus = noErr
				
				while true {
					// Set up output buffer list
					var fillBufferList = AudioBufferList()
					fillBufferList.mNumberBuffers = 1
					fillBufferList.mBuffers = AudioBuffer(mNumberChannels: _audioConvertInfo._cltASBD.mChannelsPerFrame, mDataByteSize: bufferByteSize, mData: &srcBuffer)
					
					var numberOfFrames: UInt32 = 0
					if _audioConvertInfo._cltASBD.mBytesPerFrame > 0 {
						numberOfFrames = bufferByteSize / _audioConvertInfo._cltASBD.mBytesPerFrame
					}
					
					try RKTry({
						ExtAudioFileRead(self._sourceFile!, &numberOfFrames, &fillBufferList)
					}, "ExtAudioFileRead failed")
					
					if numberOfFrames == 0 {
						error = noErr
						break
					}
					
					sourceFrameOffset += numberOfFrames
					
					try RKTry({
						error = ExtAudioFileWrite(self._destinationFile, numberOfFrames, &fillBufferList)
					}, "ExtAudioFileWrite failed")
					// If we were interrupted in the process of the write call, we must handle the errors appropriately.
					if error != noErr {
						if error == kExtAudioFileError_CodecUnavailableInputConsumed {
							RKLog("ExtAudioFileWrite kExtAudioFileError_CodecUnavailableInputConsumed error \(error)\n")
						} else if error == kExtAudioFileError_CodecUnavailableInputNotConsumed {
							RKLog("ExtAudioFileWrite kExtAudioFileError_CodecUnavailableInputNotConsumed error \(error)\n")
							sourceFrameOffset -= numberOfFrames
							try RKTry({
								ExtAudioFileSeek(self._sourceFile!, Int64(sourceFrameOffset))
							}, "ExtAudioFileSeek failed")
						} else {
							RKLog("ExtAudioFileWrite Unknown Error")
							break
						}
					}
				}
				
				try disposeConvert()
				if error == noErr {
					RKLog("RKAudioConverter Done")
				}
			}
		} catch let ex {
			RKLog("RKAudioConverter failed in progress")
			throw ex
		}
	}
	
	internal func disposeConvert() throws {
		try RKTry({
			if self._sourceFile != nil {
				ExtAudioFileDispose(self._sourceFile!)
			}
		}, "_sourceFile dispose error")
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
		
		_sourceFile = nil
		_destinationFile = nil
		_audioConvertInfo = nil
		
//		Broadcaster.notify(RKAudioConverterHandle.self, block: { observer in
//			observer.audioConvertCompleted?(self)
//		})
		
		RecordKit.microphoneObservers.allObjects
			.map{$0 as? RKAudioConverterHandle}.filter{$0 != nil}.forEach { observer in
			observer?.audioConvertCompleted?(self)
		}
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
				
				if !parent._inRealtime {
					try RKTry({
						ExtAudioFileOpenURL(parent.inputUrl.url as CFURL, &parent._sourceFile)
					}, "failed for sourceFile with URL: %@")
				}
				
				var sorASBD = AudioStreamBasicDescription()
				var sorSize = SizeOf32(sorASBD)
				if !parent._inRealtime {
					try RKTry({
						ExtAudioFileGetProperty(parent._sourceFile!, kExtAudioFileProperty_FileDataFormat, &sorSize, &sorASBD)
					}, "couldn't get the source data format")
				}
				
				var dstASBD = AudioStreamBasicDescription()
				try RKTry({
					switch parent.outputFormat.formatID {
					case kAudioFormatLinearPCM:
						dstASBD = parent.outputFormat.asbd
					default:
						dstASBD.mFormatID = parent.outputFormat.formatID
						dstASBD.mSampleRate = parent.outputFormat.sampleRate
						dstASBD.mChannelsPerFrame = parent._inRealtime ? parent.outputFormat.channelCount : sorASBD.mChannelsPerFrame
						var dstSize = SizeOf32(dstASBD)
						AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &dstSize, &dstASBD)
					}
				}, "couldn't fill out the destination data format")
				
				try RKTry({
					ExtAudioFileCreateWithURL(parent.outputUrl.url as CFURL, parent.outputFileType, &dstASBD, nil, AudioFileFlags.eraseFile.rawValue, &parent._destinationFile)
				}, "failed to create the destination audio file")
				
				var cltASBD = AudioStreamBasicDescription()
				try RKTry({
					switch parent.outputFormat.formatID {
					case kAudioFormatLinearPCM:
//						cltASBD = dstASBD
						cltASBD = RKSettings.IOFormat.lpcm32
					default:
						cltASBD = RKSettings.IOFormat.lpcm32
					}
				}, "")
				
				let cltSize = SizeOf32(cltASBD)
				if !parent._inRealtime {
					try RKTry({
						ExtAudioFileSetProperty(parent._sourceFile!, kExtAudioFileProperty_ClientDataFormat, cltSize, &cltASBD)
					}, "couldn't set the client format on the source file")
				}
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
				
//				RKLog("Source file format:\n")
//				printAudioStreamBasicDescription(sorASBD)
//				RKLog("Destination file format:\n")
//				printAudioStreamBasicDescription(dstASBD)
//				RKLog("Client file format:\n")
//				printAudioStreamBasicDescription(cltASBD)
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
