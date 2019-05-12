//
//  RKAudioFile+Info.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/12.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension AVAudioFile {
	
	// MARK: - Public Properties
	
	/// The number of samples can be accessed by .length property,
	/// but samplesCount has a less ambiguous meaning
	open var samplesCount: Int64 {
		return length
	}
	
	/// strange that sampleRate is a Double and not an Integer
	open var sampleRate: Double {
		return fileFormat.sampleRate
	}
	/// Number of channels, 1 for mono, 2 for stereo
	open var channelCount: UInt32 {
		return fileFormat.channelCount
	}
	
	/// Duration in seconds
	open var duration: Double {
		return Double(samplesCount) / (sampleRate)
	}
	
	/// true if Audio Samples are interleaved
	open var interleaved: Bool {
		return fileFormat.isInterleaved
	}
	
	/// true only if file format is "deinterleaved native-endian float (AVAudioPCMFormatFloat32)"
	open var standard: Bool {
		return fileFormat.isStandard
	}
	
	/// Human-readable version of common format
	open var commonFormatString: String {
		return "\(fileFormat.commonFormat)"
	}
	
	/// the directory path as a URL object
	open var directoryPath: URL {
		return url.deletingLastPathComponent()
	}
	
	/// the file name with extension as a String
	open var fileNamePlusExtension: String {
		return url.lastPathComponent
	}
	
	/// the file name without extension as a String
	open var fileName: String {
		return url.deletingPathExtension().lastPathComponent
	}
	
	/// the file extension as a String (without ".")
	open var fileExt: String {
		return url.pathExtension
	}
	
	override open var description: String {
		return super.description + "\n" + String(describing: fileFormat)
	}
	
	/// returns file Mime Type if exists
	/// Otherwise, returns nil
	/// (useful when sending an AKAudioFile by email)
	public var mimeType: String? {
		switch fileExt.lowercased() {
		case "wav":
			return "audio/wav"
		case "caf":
			return "audio/x-caf"
		case "aif", "aiff", "aifc":
			return "audio/aiff"
		case "m4r":
			return "audio/x-m4r"
		case "m4a":
			return "audio/x-m4a"
		case "mp4":
			return "audio/mp4"
		case "m2a", "mp2":
			return "audio/mpeg"
		case "aac":
			return "audio/aac"
		case "mp3":
			return "audio/mpeg3"
		default:
			return nil
		}
	}
	
	/// Static function to delete all audiofiles from Temp directory
	///
	/// AKAudioFile.cleanTempDirectory()
	///
	public static func cleanTempDirectory() {
		var deletedFilesCount = 0
		
		let fileManager = FileManager.default
		let tempPath = NSTemporaryDirectory()
		
		do {
			let fileNames = try fileManager.contentsOfDirectory(atPath: "\(tempPath)")
			
			// function for deleting files
			func deleteFileWithFileName(_ fileName: String) {
				let filePathName = "\(tempPath)/\(fileName)"
				do {
					try fileManager.removeItem(atPath: filePathName)
					RKLog("\"\(fileName)\" deleted.")
					deletedFilesCount += 1
				} catch let error as NSError {
					RKLog("Couldn't delete \(fileName) from Temp Directory")
					RKLog("Error: \(error)")
				}
			}
			
			// Checks file type (only Audio Files)
			fileNames.forEach { fn in
				let lower = fn.lowercased()
				_ = [".wav", ".caf", ".aif", ".mp4", ".m4a"].first {
					lower.hasSuffix($0)
					}.map { _ in
						deleteFileWithFileName(fn)
				}
			}
			
			RKLog(deletedFilesCount, "files deleted")
			
		} catch let error as NSError {
			RKLog("Couldn't access Temp Directory")
			RKLog("Error:", error)
		}
	}
	
}
