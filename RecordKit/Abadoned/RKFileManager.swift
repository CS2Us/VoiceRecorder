//
//  RKFileManager.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/25.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

public class RKFileManager: RKObject {
	public static let `default` = RKFileManager()
	public var allFilesSize: Int64 {
		return sizeOfFolder(Destination.documents(name: "Temp" , type:"m4a"))
	}
	
	public func clearFile(url: URL) {
		try? FileManager.default.removeItem(at: url)
	}
	
	public func clearAllFiles() {
		do {
			let folderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, false).first! + "/" + Destination._Folder.audio
			let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
			for content in contents {
				do {
					let fullContentPath = folderPath + "/" + content
					try FileManager.default.removeItem(atPath: fullContentPath)
				} catch let ex {
					RKLog("clearAllFiles progress -> clear file: \(folderPath + "/" + content) error: \(ex)")
					continue
				}
			}
		} catch let ex {
			RKLog("clearAllFiles Error:\(ex)")
		}
	}
	
	func sizeOfFile(_ filePath: Destination) -> Int64 {
		do {
			let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath.fileUrl.absoluteString)
			let folderSize = fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
//			let fileSizeStr = ByteCountFormatter.string(fromByteCount: folderSize, countStyle: ByteCountFormatter.CountStyle.file)
//			return fileSizeStr
			return folderSize
		} catch let ex {
			RKLog("sizeOfFile: \(ex)")
			return 0
		}
	}
	
	func sizeOfFolder(_ folderPath: Destination) -> Int64 {
		do {
			let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath.directoryPath.absoluteString)
			var folderSize: Int64 = 0
			for content in contents {
				do {
					let fullContentPath = folderPath.directoryPath.absoluteString + "/" + content
					let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullContentPath)
					folderSize += fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
				} catch _ {
					continue
				}
			}
//			let fileSizeStr = ByteCountFormatter.string(fromByteCount: folderSize, countStyle: ByteCountFormatter.CountStyle.file)
//			return fileSizeStr
			return folderSize
			
		} catch let ex {
			RKLog("sizeOfFolder: \(ex)")
			return 0
		}
	}
}
