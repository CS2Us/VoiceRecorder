//
//  RKAudioDisplayLink.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public struct Destination {
	internal struct _Folder {
		static let audio: String = "RecordKit_AudioFiles"
		static let video: String = "RecordKit_VideoFiles"
	}
	private enum _Type {
		case temp(name: String, type: String)
		case cache(name: String, type: String)
		case custom(url: URL)
		case documents(name: String, type: String)
		case main(name: String, type: String)
		case resource(name: String, type: String)
		case none
	}
	public enum MimeType: CustomStringConvertible {
		case wav, caf, aif, m4r, m4a, mp4, m2a, aac, mp3
		case unknown
		
		public var description: String {
			switch self {
			case .wav: return "audio/wav"
			case .caf: return "audio/x-caf"
			case .aif: return "audio/aiff"
			case .m4r: return "audio/x-m4r"
			case .m4a: return "audio/x-m4a"
			case .mp4: return "audio/mp4"
			case .m2a: return "audio/mpeg"
			case .aac: return "audio/aac"
			case .mp3: return "audio/mpeg3"
			default:
				return "unknown"
			}
		}
	}
	private let timeSuffix = Int(Date().timeIntervalSince1970).description
	private let type: _Type
	public static var none: Destination {
		let destination = Destination(type: .none)
		return destination
	}
	
	public static func temp(name: String = "RK_DST_Temp",
							type: String = "caf") -> Destination {
		let destination = Destination(type: .temp(name: name, type: type))
		return destination
	}
	public static func cache(name: String = "RK_DST_Cache",
							 type: String = "caf") -> Destination {
		let destination = Destination(type: .cache(name: name, type: type))
		return destination
	}
	public static func documents(name: String = "RK_DST_Documents",
								 type: String = "caf") -> Destination {
		let destination = Destination(type: .documents(name: name, type: type))
		return destination
	}
	public static func custom(url: URL) -> Destination {
		let destination = Destination(type: .custom(url: url))
		return destination
	}
	public static func main(name: String, type: String) -> Destination {
		let destination = Destination(type: .main(name: name, type: type))
		return destination
	}
	public static func resource(name: String, type: String) -> Destination {
		let destination = Destination(type: .resource(name: name, type: type))
		return destination
	}
	
	public var url: URL {
		func determineUrl() -> URL {
			switch type {
			case .temp(var name, let type):
				name = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				name = name + "_\(timeSuffix)" + "." + type
				return URL(string: (NSTemporaryDirectory() + "/" + _Folder.audio + "/" + name))!
			case .cache(var name, let type):
				name = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				name = name + "_\(timeSuffix)" + "." + type
				return URL(string: (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/" + _Folder.audio + "/" + name))!
			case .custom(url: let url):
				return url
			case .documents(var name, let type):
				name = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				name = name + "_\(timeSuffix)" + "." + type
				return URL(string: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + _Folder.audio + "/" + name))!
			case .main(let name, let type):
				return URL(string: Bundle.main.path(forResource: name, ofType: type)!)!
			case .resource(let name, let type):
				return URL(string: RKSettings.resources.path(forResource: name, ofType: type)!)!
			case .none:
				return URL(string: (NSTemporaryDirectory() + "/" + _Folder.audio + "/" + "None_\(timeSuffix)"))!
			}
		}
		let determinedFileUrl = determineUrl()
		let determinedFileUrlDirectory: URL = URL(fileURLWithPath: determinedFileUrl.deletingLastPathComponent().absoluteString)
		var isDirectory: ObjCBool = ObjCBool(true)
		if !FileManager.default.fileExists(atPath: determinedFileUrlDirectory.absoluteString, isDirectory: &isDirectory) {
			try? FileManager.default.createDirectory(at: determinedFileUrlDirectory, withIntermediateDirectories: true, attributes: nil)
		}
		return determinedFileUrl
	}
	
	public var fileUrl: URL {
		if url.absoluteString.contains("file://") {
			return url
		} else {
			return URL(fileURLWithPath: url.absoluteString)
		}
	}
	
	public var directoryPath: URL {
		return fileUrl.deletingLastPathComponent()
	}
	
	public var fileNamePlusExtension: String {
		return fileUrl.lastPathComponent
	}
	
	public var fileName: String {
		return fileUrl.deletingPathExtension().lastPathComponent
	}
	
	public var fileExt: String {
		return fileUrl.pathExtension
	}
	
	public var fileId: String {
		return String(fileName.split(separator: "_").last!)
	}
	
	public var description: String {
		return String(describing: url)
	}
	
	public var duration: TimeInterval {
		let options = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
		let audioAsset = AVURLAsset(url: fileUrl, options: options)
		let audioDuration: CMTime = audioAsset.duration
		return audioDuration.seconds
	}
	
	public var mimeType: MimeType {
		switch fileExt.lowercased() {
		case "wav": return .wav
		case "caf": return .caf
		case "aif", "aiff", "aifc":
			return .aif
		case "m4r": return .m4r
		case "m4a": return .m4a
		case "mp4": return .mp4
		case "m2a", "mp2":
			return .m2a
		case "aac": return .aac
		case "mp3": return .mp3
		default:
			return .unknown
		}
	}
	
	public var audioSize: Int64 {
		return RKFileManager.default.sizeOfFile(self)
	}
}

public class RKAudioFile: AVAudioFile {
	// MARK: - private vars
	
	// Used for exporting, can be accessed with public .avAsset property
	fileprivate lazy var internalAVAsset: AVURLAsset = {
		AVURLAsset(url: URL(fileURLWithPath: self.url.path))
	}()
	
	// MARK: - open vars
	
	/// Returns an AVAsset from the AKAudioFile
	open var avAsset: AVURLAsset {
		return internalAVAsset
	}
	
	/// will have a reference to the current export session when exporting async
	open var currentExportSession: AVAssetExportSession?
	
	// Make our types Human Friendly™
	public typealias FloatChannelData = [[Float]]
	
	/// Returns audio data as an `Array` of `Float` Arrays.
	///
	/// If stereo:
	/// - `floatChannelData?[0]` will contain an Array of left channel samples as `Float`
	/// - `floatChannelData?[1]` will contains an Array of right channel samples as `Float`
	open lazy var floatChannelData: FloatChannelData? = {
		// Do we have PCM channel data?
		guard let pcmFloatChannelData = self.pcmBuffer.floatChannelData else {
			return nil
		}
		
		let channelCount = Int(self.pcmBuffer.format.channelCount)
		let frameLength = Int(self.pcmBuffer.frameLength)
		let stride = self.pcmBuffer.stride
		
		// Preallocate our Array so we're not constantly thrashing while resizing as we append.
		var result = Array(repeating: [Float](zeros: frameLength), count: channelCount)
		
		// Loop across our channels...
		for channel in 0..<channelCount {
			// Make sure we go through all of the frames...
			for sampleIndex in 0..<frameLength {
				result[channel][sampleIndex] = pcmFloatChannelData[channel][sampleIndex * stride]
			}
		}
		
		return result
	}()
	
	/// returns audio data as an AVAudioPCMBuffer
	open lazy var pcmBuffer: AVAudioPCMBuffer = {
		
		let buffer = AVAudioPCMBuffer(pcmFormat: self.processingFormat,
									  frameCapacity: AVAudioFrameCount(self.length))
		
		do {
			try self.read(into: buffer!)
		} catch let error as NSError {
			RKLog("error cannot readIntBuffer, Error: \(error)")
		}
		
		return buffer!
		
	}()
	
	/// returns the peak level expressed in dB ( -> Float).
	open lazy var maxLevel: Float = {
		var maxLev: Float = 0
		
		let buffer = self.pcmBuffer
		
		if self.samplesCount > 0 {
			for c in 0..<Int(self.channelCount) {
				let floats = UnsafeBufferPointer(start: buffer.floatChannelData?[c], count: Int(buffer.frameLength))
				let cmax = floats.max()
				let cmin = floats.min()
				
				// positive max
				maxLev = max(cmax ?? maxLev, maxLev)
				
				// negative max
				maxLev = -min(abs(cmin ?? -maxLev), -maxLev)
			}
		}
		
		if maxLev == 0 {
			return Float.leastNormalMagnitude
		} else {
			return 10 * log10(maxLev)
		}
	}()
	
	/// Initialize the audio file
	///
	/// - parameter fileURL: URL of the file
	///
	/// - returns: An initialized AKAudioFile object for reading, or nil if init failed.
	///
	public override init(forReading fileURL: URL) throws {
		try super.init(forReading: fileURL)
	}
	
	/// Initialize the audio file
	///
	/// - Parameters:
	///   - fileURL:     URL of the file
	///   - format:      The processing commonFormat to use when reading from the file.
	///   - interleaved: Whether to use an interleaved processing format.
	///
	/// - returns: An initialized AKAudioFile object for reading, or nil if init failed.
	///
	public override init(forReading fileURL: URL,
						 commonFormat format: AVAudioCommonFormat,
						 interleaved: Bool) throws {
		
		try super.init(forReading: fileURL, commonFormat: format, interleaved: interleaved)
	}
	
	/// Initialize the audio file
	///
	/// From Apple doc: The file type to create is inferred from the file extension of fileURL.
	/// This method will overwrite a file at the specified URL if a file already exists.
	///
	/// The file is opened for writing using the standard format, AVAudioPCMFormatFloat32.
	///
	/// Note: It seems that Apple's AVAudioFile class has a bug with .wav files. They cannot be set
	/// with a floating Point encoding. As a consequence, such files will fail to record properly.
	/// So it's better to use .caf (or .aif) files for recording purpose.
	///
	/// - Parameters:
	///   - fileURL:     URL of the file.
	///   - settings:    The format of the file to create.
	///   - format:      The processing commonFormat to use when writing.
	///   - interleaved: Whether to use an interleaved processing format.
	/// - throws: NSError if init failed
	/// - returns: An initialized AKAudioFile for writing, or nil if init failed.
	///
	public override init(forWriting fileURL: URL,
						 settings: [String: Any],
						 commonFormat format: AVAudioCommonFormat,
						 interleaved: Bool) throws {
		try super.init(forWriting: fileURL,
					   settings: settings,
					   commonFormat: format,
					   interleaved: interleaved)
	}
	
	/// Super.init inherited from AVAudioFile superclass
	///
	/// - Parameters:
	///   - fileURL: URL of the file.
	///   - settings: The settings of the file to create.
	///
	/// - Returns: An initialized AKAudioFile for writing, or nil if init failed.
	///
	/// From Apple doc: The file type to create is inferred from the file extension of fileURL.
	/// This method will overwrite a file at the specified URL if a file already exists.
	///
	/// The file is opened for writing using the standard format, AVAudioPCMFormatFloat32.
	///
	/// Note: It seems that Apple's AVAudioFile class has a bug with .wav files. They cannot be set
	/// with a floating Point encoding. As a consequence, such files will fail to record properly.
	/// So it's better to use .caf (or .aif) files for recording purpose.
	///
	public override init(forWriting fileURL: URL, settings: [String: Any]) throws {
		try super.init(forWriting: fileURL, settings: settings)
	}
}
