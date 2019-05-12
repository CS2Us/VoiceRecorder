//
//  RKSettings.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public class RKSettings: RKObject {
	@objc public enum BufferLength: Int {
		case shortest = 5
		case veryShort = 6
		case short = 7
		case medium = 8
		case long = 9
		case veryLong = 10
		case huge = 11
		case longest = 12
	}
	
	/// Constants for ramps used in RKParameterRamp.hpp, RKBooster, and others
	@objc public enum RampType: Int {
		case linear = 0
		case exponential = 1
		case logarithmic = 2
		case sCurve = 3
	}
	
	public struct IOFormat {
		public let channelCount: UInt32
		public let formatID: AudioFormatID
		public let bitDepth: CommonFormat
		public let sampleRate: Double
		public let interleaved: Bool
		public var asbd: AudioStreamBasicDescription {
			var value = AudioStreamBasicDescription()
			ioFormat(desc: &value, iof: {
				RKSettings.IOFormat(formatID: formatID, bitDepth: bitDepth,
									channelCount: channelCount, sampleRate: sampleRate)
			}(), inIsInterleaved: interleaved)
			return value
		}
		
		public init(formatID: AudioFormatID, bitDepth: CommonFormat,
					channelCount: UInt32 = 2, sampleRate: Double = RKSettings.sampleRate, isInterleaved: Bool = false) {
			self.formatID = formatID
			self.bitDepth = bitDepth
			self.channelCount = channelCount
			self.sampleRate = sampleRate
			self.interleaved = isInterleaved
		}
	}
	
	@objc public static var resources: Bundle {
		if let bundlePath = Bundle.main.path(forResource: "Frameworks/RecordKit.framework/Resources", ofType: "bundle"),
			let bundle = Bundle(path: bundlePath) {
			return bundle
		} else {
			return Bundle.main
		}
	}
	@objc public static var channelCount: UInt32 = 2
	@objc public static var audioFormat: AVAudioFormat {
		return AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)!
	}
	/// If set to true, Recording will stop after some delay to compensate
	/// latency between time recording is stopped and time it is written to file
	/// If set to false (the default value) , stopping record will be immediate,
	/// even if the last audio frames haven't been recorded to file yet.
	@objc public static var fixTruncatedRecordings = false
	
	/// Whether we should be listening to audio input (microphone)
	@objc public static var audioInputEnabled: Bool = false
	
	/// Whether to allow audio playback to override the mute setting
	@objc public static var playbackWhileMuted: Bool = false
	
	/// Whether to output to the speaker (rather than receiver) when audio input is enabled
	@objc public static var defaultToSpeaker: Bool = false
	
	/// Whether to use bluetooth when audio input is enabled
	@objc public static var useBluetooth: Bool = false
	
	/// Additional control over the options to use for bluetooth
	@objc public static var bluetoothOptions: AVAudioSession.CategoryOptions = []
	
	/// Whether AirPlay is enabled when audio input is enabled
	@objc public static var allowAirPlay: Bool = false
	
	/// Enable AudioKit AVAudioSession Category Management
	@objc public static var disableAVAudioSessionCategoryManagement: Bool = false
	
	/// If set to true, AudioKit will not deactivate the AVAudioSession when stopping
	@objc public static var disableAudioSessionDeactivationOnStop: Bool = false
	
	/// If set to false, AudioKit will not handle the AVAudioSession route change
	/// notification (AVAudioSessionRouteChange) and will not restart the AVAudioEngine
	/// instance when such notifications are posted. The developer can instead subscribe
	/// to these notifications and restart AudioKit after rebuiling their audio chain.
	@objc public static var enableRouteChangeHandling: Bool = true
	
	/// If set to false, AudioKit will not handle the AVAudioSession category change
	/// notification (AVAudioEngineConfigurationChange) and will not restart the AVAudioEngine
	/// instance when such notifications are posted. The developer can instead subscribe
	/// to these notifications and restart AudioKit after rebuiling their audio chain.
	@objc public static var enableCategoryChangeHandling: Bool = true
	
	/// Allows AudioKit to send Notifications
	@objc public static var notificationsEnabled: Bool = false
	
	/// Global default rampDuration value
	@objc public static var rampDuration: Double = 0.000_2
	
	#if os(macOS)
	/// The hardware ioBufferDuration. Setting this will request the new value, getting
	/// will query the hardware.
	@objc public static var ioBufferDuration: Double {
		set {
			let node = RecordKit.engine.outputNode
			guard let audioUnit = node.audioUnit else { return }
			let samplerate = node.outputFormat(forBus: 0).sampleRate
			var frames = UInt32(round(newValue * samplerate))
			
			let status = AudioUnitSetProperty(audioUnit,
											  kAudioDevicePropertyBufferFrameSize,
											  kAudioUnitScope_Global,
											  0,
											  &frames,
											  UInt32(MemoryLayout<UInt32>.size))
			if status != 0 {
				RKLog("error in set ioBufferDuration status \(status)")
			}
		}
		get {
			let node = RecordKit.engine.outputNode
			guard let audioUnit = node.audioUnit else { return 0 }
			let sampleRate = node.outputFormat(forBus: 0).sampleRate
			var frames = UInt32()
			var propSize = UInt32(MemoryLayout<UInt32>.size)
			let status = AudioUnitGetProperty(audioUnit,
											  kAudioDevicePropertyBufferFrameSize,
											  kAudioUnitScope_Global,
											  0,
											  &frames,
											  &propSize)
			if status != 0 {
				RKLog("error in get ioBufferDuration status \(status)")
			}
			return Double(frames) / sampleRate
		}
	}
	#else
	
	/// The hardware ioBufferDuration. Setting this will request the new value, getting
	/// will query the hardware.
	@objc public static var ioBufferDuration: Double {
		set {
			do {
				try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
			} catch {
				RKLog(error)
			}
		}
		get {
			return AVAudioSession.sharedInstance().ioBufferDuration
		}
	}
	#endif
	
	#if !os(macOS)
	/// Checks the application's info.plist to see if UIBackgroundModes includes "audio".
	/// If background audio is supported then the system will allow the AVAudioEngine to start even if the app is in,
	/// or entering, a background state. This can help prevent a potential crash
	/// (AVAudioSessionErrorCodeCannotStartPlaying aka error code 561015905) when a route/category change causes
	/// AudioEngine to attempt to start while the app is not active and background audio is not supported.
	@objc public static let appSupportsBackgroundAudio = (Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String])?.contains("audio") ?? false
	#endif
	@objc public static var sampleRate: Double = 44100
	@objc public static var bufferLength: BufferLength = .medium
	@objc public static var interleaved: Bool = false
	@objc public static var enableLogging: Bool = true
	@objc public static var maxDuration: TimeInterval = TimeInterval(2 * 60)
	@objc public static var timeStamp: TimeInterval = 0
	@objc public static var ASRLimitDuration: TimeInterval = TimeInterval(60)
	@objc public static var ASRAppID: String = /** "15731062" **/ "15807927"
	@objc public static var ASRApiKey: String = /** "rbKB6zVhL0fAc7fn0lKGYiPn" **/ "DavSgp7gxiBbbqxdWFQpvGO0"
	@objc public static var ASRSecretKey: String = /** "Un2QyGl2HS942MOa2GjCKFN4HOQrHUaX" **/ "GAXG2t82pT7UWzIXiB4kIkbbD6fwWlK8"
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
	public static var lpcm16: AudioStreamBasicDescription {
		var asbd = AudioStreamBasicDescription()
		ioFormat(desc: &asbd, iof: {
			RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16)
		}(), inIsInterleaved: true)
		return asbd
	}
	
	public static var lpcm32: AudioStreamBasicDescription {
		var asbd = AudioStreamBasicDescription()
		ioFormat(desc: &asbd, iof: {
			RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .float32)
		}(), inIsInterleaved: true)
		return asbd
	}
	
	public enum CommonFormat: UInt32 {
		case float32, fixed824, int32 = 4
		case int16 = 2
		case float64 = 8
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

extension RKSettings {
	
	/// Shortcut for AVAudioSession.sharedInstance()
	@objc public static let session = AVAudioSession.sharedInstance()
	
	/// Convenience method accessible from Objective-C
	@objc public static func setSession(category: SessionCategory, options: UInt) throws {
		try setSession(category: category, with: AVAudioSession.CategoryOptions(rawValue: options))
	}
	
	/// Set the audio session type
	@objc public static func setSession(category: SessionCategory,
										with options: AVAudioSession.CategoryOptions = []) throws {
		
		if !RKSettings.disableAVAudioSessionCategoryManagement {
			do {
				if #available(iOS 10.0, *) {
					try session.setCategory(category.avCategory, mode: .default, options: options)
				} else {
					session.perform(NSSelectorFromString("setCategory:error:"), with: category.avCategory)
				}
			} catch let error as NSError {
				RKLog("Error: \(error) Cannot set AVAudioSession Category to \(category) with options: \(options)")
				throw error
			}
		}
		
		// Preferred IO Buffer Duration
		do {
			try session.setPreferredIOBufferDuration(bufferLength.duration)
		} catch let error as NSError {
			RKLog("RKSettings Error: Cannot set Preferred IOBufferDuration to " +
				"\(bufferLength.duration) ( = \(bufferLength.samplesCount) samples)")
			RKLog("RKSettings Error: \(error))")
			throw error
		}
		
		// Activate session
		do {
			try session.setActive(true)
		} catch let error as NSError {
			RKLog("RKSettings Error: Cannot set AVAudioSession.setActive to true", error)
			throw error
		}
	}
	
	@objc public static func computedSessionCategory() -> SessionCategory {
		if RKSettings.audioInputEnabled {
			return .playAndRecord
		} else if RKSettings.playbackWhileMuted {
			return .playback
		} else {
			return .ambient
		}
	}
	
	@objc public static func computedSessionOptions() -> AVAudioSession.CategoryOptions {
		
		var options: AVAudioSession.CategoryOptions = [.mixWithOthers]
		
		if RKSettings.audioInputEnabled {
			
			options = options.union(.mixWithOthers)
			
			#if !os(tvOS)
			if #available(iOS 10.0, *) {
				// Blueooth Options
				// .allowBluetooth can only be set with the categories .playAndRecord and .record
				// .allowBluetoothA2DP comes for free if the category is .ambient, .soloAmbient, or
				// .playback. This option is cleared if the category is .record, or .multiRoute. If this
				// option and .allowBluetooth are set and a device supports Hands-Free Profile (HFP) and the
				// Advanced Audio Distribution Profile (A2DP), the Hands-Free ports will be given a higher
				// priority for routing.
				if !RKSettings.bluetoothOptions.isEmpty {
					options = options.union(RKSettings.bluetoothOptions)
				} else if RKSettings.useBluetooth {
					// If bluetoothOptions aren't specified
					// but useBluetooth is then we will use these defaults
					options = options.union([.allowBluetooth,
											 .allowBluetoothA2DP])
				}
				
				// AirPlay
				if RKSettings.allowAirPlay {
					options = options.union(.allowAirPlay)
				}
			} else if !RKSettings.bluetoothOptions.isEmpty ||
				RKSettings.useBluetooth ||
				RKSettings.allowAirPlay {
				RKLog("Some of the specified RKSettings are not supported by iOS 9 and were ignored.")
			}
			
			// Default to Speaker
			if RKSettings.defaultToSpeaker {
				options = options.union(.defaultToSpeaker)
			}
			#endif
		}
		
		return options
	}
	
	/// Checks if headphones are connected
	/// Returns true if headPhones are connected, otherwise return false
	@objc public static var headPhonesPlugged: Bool {
		let headphonePortTypes: [AVAudioSession.Port] =
			[.headphones, .bluetoothHFP, .bluetoothA2DP]
		return session.currentRoute.outputs.contains {
			return headphonePortTypes.contains($0.portType)
		}
	}
	
	/// Enum of available AVAudioSession Categories
	@objc public enum SessionCategory: Int, CustomStringConvertible {
		/// Audio silenced by silent switch and screen lock - audio is mixable
		case ambient
		/// Audio is silenced by silent switch and screen lock - audio is non mixable
		case soloAmbient
		/// Audio is not silenced by silent switch and screen lock - audio is non mixable
		case playback
		/// Silences playback audio
		case record
		/// Audio is not silenced by silent switch and screen lock - audio is non mixable.
		/// To allow mixing see AVAudioSessionCategoryOptionMixWithOthers.
		case playAndRecord
		#if !os(tvOS)
		/// Disables playback and recording; deprecated in iOS 10, unavailable on tvOS
		case audioProcessing
		#endif
		/// Use to multi-route audio. May be used on input, output, or both.
		case multiRoute
		
		public var description: String {
			switch self {
			case .ambient:
				return AVAudioSession.Category.ambient.rawValue
			case .soloAmbient:
				return AVAudioSession.Category.soloAmbient.rawValue
			case .playback:
				return AVAudioSession.Category.playback.rawValue
			case .record:
				return AVAudioSession.Category.record.rawValue
			case .playAndRecord:
				return AVAudioSession.Category.playAndRecord.rawValue
			case .multiRoute:
				return AVAudioSession.Category.multiRoute.rawValue
			default :
				return AVAudioSession.Category.soloAmbient.rawValue
			}
		}
		
		public var avCategory: AVAudioSession.Category {
			switch self {
			case .ambient:
				return .ambient
			case .soloAmbient:
				return .soloAmbient
			case .playback:
				return .playback
			case .record:
				return .record
			case .playAndRecord:
				return .playAndRecord
			case .multiRoute:
				return .multiRoute
			default:
				return .soloAmbient
			}
		}
	}
}
