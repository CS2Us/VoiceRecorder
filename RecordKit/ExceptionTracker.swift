//
//  ExceptionTracker.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

public func RKTry<T>(_ operation: @escaping (() throws -> T), _ errorDescription: String) throws {
	var error: Error?
	
	let theTry = {
		do {
			let error = try operation()
			if let status = (error as? OSStatus) {
				if status != noErr {
					throw NSError(domain: "com.matrixmiaou.RecordKit.OSStatus.Error", code: Int(error as! OSStatus), userInfo: nil)
				}
			}
		} catch let ex {
			error = ex
		}
	}
	
	let theCatch: (NSException) -> Void = { except in
		var userInfo = [String: Any]()
		userInfo[NSLocalizedDescriptionKey] = except.description
		userInfo[NSLocalizedFailureReasonErrorKey] = except.reason
		userInfo["exception"] = except
		
		error = NSError(domain: "com.matrixmiaou.RecordKit",
						code: 0,
						userInfo: userInfo)
	}
	
	RKTryOperation(theTry, theCatch)
	
	if let error = error { // Caught an exception
		throw error
	}
}
