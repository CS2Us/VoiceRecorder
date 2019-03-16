//
//  RKSettings.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public class RKSettings {
	public enum BufferLength: Int {
		case shortest = 5
		case veryShort = 6
		case short = 7
		case medium = 8
		case long = 9
		case veryLong = 10
		case huge = 11
		case longest = 12
	}
	
	public struct IOFormat {
		let channelCount: UInt32
		let formatID: AudioFormatID
		let bitDepth: CommonFormat
		let sampleRate: Double
		var asbd: AudioStreamBasicDescription {
			var value = AudioStreamBasicDescription()
			ioFormat(desc: &value, iof: {
				RKSettings.IOFormat(formatID: formatID, bitDepth: bitDepth,
									channelCount: channelCount, sampleRate: sampleRate)
			}(), inIsInterleaved: false)
			return value
		}
		
		init(formatID: AudioFormatID, bitDepth: CommonFormat,
			 channelCount: UInt32 = 1, sampleRate: Double = RKSettings.sampleRate) {
			self.formatID = formatID
			self.bitDepth = bitDepth
			self.channelCount = channelCount
			self.sampleRate = sampleRate
		}
	}
	
	public static var resources: Bundle {
		if let bundlePath = Bundle.main.path(forResource: "Resources", ofType: "bundle"),
			let bundle = Bundle(path: bundlePath) {
			return bundle
		} else {
			fatalError()
		}
	}
	public static var sampleRate: Double = 44_100
	public static var asrFileDst: Destination = .temp(url: "bsd_asr.wav")
	public static var bufferLength: BufferLength = .veryLong
	public static var interleaved: Bool = false
	public static var enableLogging: Bool = true
	public static var maxDuration: TimeInterval = TimeInterval(2 * 60)
	public static var ASRAppID: String = "15731062"
	public static var ASRApiKey: String = "rbKB6zVhL0fAc7fn0lKGYiPn"
	public static var ASRSecretKey: String = "Un2QyGl2HS942MOa2GjCKFN4HOQrHUaX"
}

private func ioFormat(desc: UnsafeMutablePointer<AudioStreamBasicDescription>,
					  iof: RKSettings.IOFormat,
					  inIsInterleaved: Bool) {
	let descBlock: (inout AudioStreamBasicDescription) -> () = {
		var wordsize: UInt32
		$0.mSampleRate = iof.sampleRate
		$0.mFormatID = iof.formatID
		$0.mFormatFlags = AudioFormatFlags(kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked)
		$0.mFramesPerPacket = 1
		$0.mBytesPerFrame = 0
		$0.mBytesPerPacket = 0
		$0.mReserved = 0
		
		switch iof.bitDepth {
		case .float32:
			wordsize = 4
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsFloat)
		case .float64:
			wordsize = 8
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsFloat)
			break;
		case .int16:
			wordsize = 2
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsSignedInteger)
		case .int32:
			wordsize = 4
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsSignedInteger)
			break;
		case .fixed824:
			wordsize = 4
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsSignedInteger | (24 << kLinearPCMFormatFlagsSampleFractionShift))
		}
		$0.mBitsPerChannel = wordsize * 8
		if inIsInterleaved {
			$0.mBytesPerFrame = wordsize * iof.channelCount
			$0.mBytesPerPacket = $0.mBytesPerFrame
		} else {
			$0.mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsNonInterleaved)
			$0.mBytesPerFrame = wordsize
			$0.mBytesPerPacket = $0.mBytesPerFrame
		}
		if case kAudioFormatiLBC = iof.formatID {
			$0.mChannelsPerFrame = 1
		} else {
			$0.mChannelsPerFrame = iof.channelCount
		}
	};descBlock(&desc.pointee)
}

extension RKSettings.IOFormat {
	static var lpcm16: AudioStreamBasicDescription {
		var asbd = AudioStreamBasicDescription()
		ioFormat(desc: &asbd, iof: {
			RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16)
		}(), inIsInterleaved: false)
		return asbd
	}
	
	static var lpcm32: AudioStreamBasicDescription {
		var asbd = AudioStreamBasicDescription()
		ioFormat(desc: &asbd, iof: {
			RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
		}(), inIsInterleaved: false)
		return asbd
	}
	
	enum CommonFormat: UInt32 {
		case float32 = 1
		case int16 = 2
		case fixed824 = 3
		case float64 = 4
		case int32 = 5
	}
}

extension RKSettings.BufferLength {
	public var samplesCount: AVAudioFrameCount {
		return AVAudioFrameCount(pow(2.0, Double(rawValue)))
	}
	
	public var duration: Double {
		return Double(samplesCount) / RKSettings.sampleRate
	}
}
