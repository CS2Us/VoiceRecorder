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
		switch type {
		case .temp(var url):
			url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
			return URL(string: (NSTemporaryDirectory() + "/" + url))!
		case .cache(var url):
			url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
			return URL(string: (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/" + url))!
		case .custom(url: let url):
			return url
		case .documents(var url):
			url = url.split(separator: ".").first! + "_\(timeSuffix)" + "." + url.split(separator: ".").last!
			return URL(string: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + url))!
		case .main(let name, let type):
			return URL(string: Bundle.main.path(forResource: name, ofType: type)!)!
		case .resource(let name, let type):
			return URL(string: RKSettings.resources.path(forResource: name, ofType: type)!)!
		case .none:
			return URL(string: (NSTemporaryDirectory() + "/" + "None_\(timeSuffix)"))!
		}
	}
	
	public var directoryPath: URL {
		return url.deletingLastPathComponent()
	}
	
	public var fileNamePlusExtension: String {
		return url.lastPathComponent
	}
	
	public var fileName: String {
		return url.deletingPathExtension().lastPathComponent
	}
	
	public var fileExt: String {
		return url.pathExtension
	}
	
	public var fileId: String {
		return String(fileName.split(separator: "_").last!)
	}
	
	public var description: String {
		return String(describing: url)
	}
	
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
	
	
}
