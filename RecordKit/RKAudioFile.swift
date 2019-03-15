//
//  RKAudioDisplayLink.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

/** file type **/
public enum FileExt {
	case m4a
	case pcm
	case wav
}

/** destination **/
public enum Destination {
	case temp(url: String)
	case documents(url: String)
	case resource(name: String, type: String)
	
	public var url: URL {
		switch self {
		case .temp(let url):
			return URL(string: (NSTemporaryDirectory() + url))!
		case .documents(let url):
			return URL(string: (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + url))!
		case .resource(let name, let type):
			return URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: type)!)
		}
	}
}

class RKAudioFile: RKNode {
	private var _audioFile: AVAudioFile!
	
	override init() {
		super.init()

	}
}
