//
//  RecordKit.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

public typealias RKCallback = () -> Void

public class RecordKit: RKObject {
	#if !os(macOS)
	static let deviceSampleRate = AVAudioSession.sharedInstance().sampleRate
	#else
	static let deviceSampleRate: Double = 44_100
	#endif
	
	/// Observers about components
	internal internal(set) static var asrerObservers = NSPointerArray.weakObjects()
	internal internal(set) static var converterObservers = NSPointerArray.weakObjects()
	public internal(set) static var recObservers = NSPointerArray.weakObjects()
	public internal(set) static var rbObservers = NSPointerArray.weakObjects()
	/// Reference to the AV Audio Engine
	public static var engine: AVAudioEngine {
		get {
			_ = RecordKit.deviceSampleRate // read the original sample rate before any reference to AVAudioEngine happens, so value is retained
			return _engine
		}
		set {
			_engine = newValue
		}
	}
	
	private static var _engine = AVAudioEngine()
	
	public static var finalMixer: RKMixer?
	public static var output: RKNode? {
		didSet {
			do {
				try updateSessionCategoryAndOptions()
				
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
				
			} catch {
				RKLog("Could not set output: \(error)")
			}
		}
	}
	
	/// The name of the current input device, if available.
	public static var inputDevice: RKDevice? {
		#if os(macOS)
		if let dev = EZAudioDevice.currentInput() {
			return AKDevice(name: dev.name, deviceID: dev.deviceID)
		}
		#else
		if let dev = AVAudioSession.sharedInstance().preferredInput {
			return RKDevice(name: dev.portName, deviceID: dev.uid)
		} else {
			let inputDevices = AVAudioSession.sharedInstance().currentRoute.inputs
			if inputDevices.isNotEmpty {
				for device in inputDevices {
					let dataSourceString = device.selectedDataSource?.description ?? ""
					let id = "\(device.uid) \(dataSourceString)".trimmingCharacters(in: [" "])
					return RKDevice(name: device.portName, deviceID: id)
				}
			}
		}
		#endif
		return nil
	}
	
	/// The name of the current output device, if available.
	public static var outputDevice: RKDevice? {
		#if os(macOS)
		if let dev = EZAudioDevice.currentOutput() {
			return AKDevice(name: dev.name, deviceID: dev.deviceID)
		}
		#else
		let devs = AVAudioSession.sharedInstance().currentRoute.outputs
		if devs.isNotEmpty {
			return RKDevice(name: devs[0].portName, deviceID: devs[0].uid)
		}
		
		#endif
		return nil
	}
	
	/// Change the preferred input device, giving it one of the names from the list of available inputs.
	public static func setInputDevice(_ input: RKDevice) throws {
		#if os(macOS)
		try RKTry({
			var address = AudioObjectPropertyAddress(
				mSelector: kAudioHardwarePropertyDefaultInputDevice,
				mScope: kAudioObjectPropertyScopeGlobal,
				mElement: kAudioObjectPropertyElementMaster)
			var devid = input.deviceID
			AudioObjectSetPropertyData(
				AudioObjectID(kAudioObjectSystemObject),
				&address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &devid)
		}, "")
		#else
		if let devices = AVAudioSession.sharedInstance().availableInputs {
			for device in devices {
				if device.dataSources == nil || device.dataSources!.isEmpty {
					if device.uid == input.deviceID {
						do {
							try AVAudioSession.sharedInstance().setPreferredInput(device)
						} catch {
							RKLog("Could not set the preferred input to \(input)")
						}
					}
				} else {
					for dataSource in device.dataSources! {
						if input.deviceID == "\(device.uid) \(dataSource.dataSourceName)" {
							do {
								try AVAudioSession.sharedInstance().setInputDataSource(dataSource)
							} catch {
								RKLog("Could not set the preferred input to \(input)")
							}
						}
					}
				}
			}
		}
		
		if let devices = AVAudioSession.sharedInstance().availableInputs {
			for dev in devices {
				if dev.uid == input.deviceID {
					do {
						try AVAudioSession.sharedInstance().setPreferredInput(dev)
					} catch {
						RKLog("Could not set the preferred input to \(input)")
					}
				}
			}
		}
		#endif
	}
	
	/// Change the preferred output device, giving it one of the names from the list of available output.
	public static func setOutputDevice(_ output: RKDevice) throws {
		#if os(macOS)
		try RKTry({
			var id = output.deviceID
			if let audioUnit = AudioKit.engine.outputNode.audioUnit {
				AudioUnitSetProperty(audioUnit,
									 kAudioOutputUnitProperty_CurrentDevice,
									 kAudioUnitScope_Global, 0,
									 &id,
									 UInt32(MemoryLayout<DeviceID>.size))
			}
		}, "")
		#else
		// not available on ios
		#endif
	}

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
