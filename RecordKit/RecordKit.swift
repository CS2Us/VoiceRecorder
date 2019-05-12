//
//  RecordKit.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public class RecordKit: RKObject {
	internal static let deviceSampleRate = AVAudioSession.sharedInstance().sampleRate
	
	/// Observers about components
	public internal(set) static var microphoneObservers = NSPointerArray.weakObjects()
	public internal(set) static var asrerObservers = NSPointerArray.weakObjects()
	public internal(set) static var converterObservers = NSPointerArray.weakObjects()
	/// Reference to the AV Audio Engine
	public internal(set) static var engine = AVAudioEngine()
	
	public static var finalMixer: RKMixer?
	public static var output: RKNode? {
		didSet {
			// if the assigned output is already a mixer, avoid creating an additional mixer and just use
			// that input as the finalMixer
			if let mixerInput = output as? RKMixer {
				finalMixer = mixerInput
			} else {
				// otherwise at this point create the finalMixer and add the input to it
				let mixer = RKMixer()
				output?.connect(to: mixer)
				finalMixer = mixer
			}
			guard let finalMixer = finalMixer else { return }
			engine.connect(finalMixer.avAudioNode, to: engine.outputNode, format: RKSettings.audioFormat)
		}
	}
}

@objc
public protocol RecordKitSessionHandle {
	// MARK:- Handle interruption
	@objc(handleInterruption:)
	optional func handleInterruption(notification: Notification)
	// MARK: - Handle RouteChange
	@objc(handleRouteChange:)
	optional func handleRouteChange(notification: Notification)
	@objc(sessionShouldBeInit)
	optional func sessionShouldBeInit()
	@objc(sessionShouldBeDeinit)
	optional func sessionShouldBeDeinit()
}

public extension NSPointerArray {
	func addObject(_ object: AnyObject?) {
		guard let strongObject = object else { return }
		
		let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
		addPointer(pointer)
	}
	
	func insertObject(_ object: AnyObject?, at index: Int) {
		guard index < count, let strongObject = object else { return }
		
		let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
		insertPointer(pointer, at: index)
	}
	
	func replaceObject(at index: Int, withObject object: AnyObject?) {
		guard index < count, let strongObject = object else { return }
		
		let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
		replacePointer(at: index, withPointer: pointer)
	}
	
	func object(at index: Int) -> AnyObject? {
		guard index < count, let pointer = self.pointer(at: index) else { return nil }
		return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
	}
	
	func removeObject(at index: Int) {
		guard index < count else { return }
		
		removePointer(at: index)
	}
}
