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
	private struct _Folder {
		static let audio: String = "RecordKit_AudioFiles"
		static let video: String = "RecordKit_VideoFiles"
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
	private enum _Type {
		case temp(url: String)
		case cache(url: String)
		case custom(url: URL)
		case documents(url: String)
		case main(name: String, type: String)
		case resource(name: String, type: String)
		case none
	}
	private let timeSuffix = Int(Date().timeIntervalSince1970).description
	private let type: _Type
	public static var none: Destination {
		let destination = Destination(type: .none)
		return destination
	}
	
	public static func temp(url: String) -> Destination {
		let destination = Destination(type: .temp(url: url))
		return destination
	}
	public static func cache(url: String) -> Destination {
		let destination = Destination(type: .cache(url: url))
		return destination
	}
	public static func custom(url: URL) -> Destination {
		let destination = Destination(type: .custom(url: url))
		return destination
	}
	public static func documents(url: String) -> Destination {
		let destination = Destination(type: .documents(url: url))
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
			case .temp(var url):
				url = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
				return URL(string: (NSTemporaryDirectory() + "/" + _Folder.audio + "/" + url))!
			case .cache(var url):
				url = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
				return URL(string: (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/" + _Folder.audio + "/" + url))!
			case .custom(url: let url):
				return url
			case .documents(var url):
				url = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
				url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
				return URL(string: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + _Folder.audio + "/" + url))!
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
	
	public var duration: TimeInterval {
		let options = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
		let audioAsset = AVURLAsset(url: fileUrl, options: options)
		let audioDuration: CMTime = audioAsset.duration
		return audioDuration.seconds
	}
	
	public var audioSize: Int64 {
		return RKFileManager.default.sizeOfFile(self)
	}
}
