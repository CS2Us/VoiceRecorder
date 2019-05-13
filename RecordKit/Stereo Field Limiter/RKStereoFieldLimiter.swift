//
//  RKStereoFieldLimiter.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/10.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/// Stereo StereoFieldLimiter
///
open class RKStereoFieldLimiter: RKNode, RKToggleable, RKComponent, RKInput {
	public typealias RKAudioUnitType = RKStereoFieldLimiterAudioUnit
	/// Four letter unique description of the node
	public static let ComponentDescription = AudioComponentDescription(effect: "sflm")
	
	// MARK: - Properties
	
	private var internalAU: RKAudioUnitType?
	private var token: AUParameterObserverToken?
	
	fileprivate var amountParameter: AUParameter?
	
	/// Ramp Duration represents the speed at which parameters are allowed to change
	@objc open dynamic var rampDuration: Double = RKSettings.rampDuration {
		willSet {
			internalAU?.rampDuration = newValue
		}
	}
	
	/// Limiting Factor
	@objc open dynamic var amount: Double = 1 {
		willSet {
			guard amount != newValue else { return }
			
			if internalAU?.isSetUp ?? false {
				if token != nil && amountParameter != nil {
					amountParameter?.setValue(Float(newValue), originator: token!)
					return
				}
			}
			internalAU?.setParameterImmediately(.amount, value: newValue)
		}
	}
	
	/// Tells whether the node is processing (ie. started, playing, or active)
	@objc open dynamic var isStarted: Bool {
		return self.internalAU?.isPlaying ?? false
	}
	
	// MARK: - Initialization
	
	/// Initialize this booster node
	///
	/// - Parameters:
	///   - input: RKNode whose output will be amplified
	///   - amount: limit factor (Default: 1, Minimum: 0)
	///
	@objc public init(_ input: RKNode? = nil, amount: Double = 1) {
		
		self.amount = amount
		
		_Self.register()
		
		super.init()
		AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
			guard let strongSelf = self else {
				RKLog("Error: self is nil")
				return
			}
			strongSelf.avAudioUnit = avAudioUnit
			strongSelf.avAudioNode = avAudioUnit
			strongSelf.internalAU = avAudioUnit.auAudioUnit as? RKAudioUnitType
			
			input?.connect(to: strongSelf)
		}
		
		guard let tree = internalAU?.parameterTree else {
			RKLog("Parameter Tree Failed")
			return
		}
		
		self.amountParameter = tree["amount"]
		
		self.token = tree.token(byAddingParameterObserver: { [weak self] _, _ in
			
			guard let _ = self else {
				RKLog("Unable to create strong reference to self")
				return
			} // Replace _ with strongSelf if needed
			DispatchQueue.main.async {
				// This node does not change its own values so we won't add any
				// value observing, but if you need to, this is where that goes.
			}
		})
		internalAU?.setParameterImmediately(.amount, value: amount)
	}
	
	// MARK: - Control
	
	/// Function to start, play, or activate the node, all do the same thing
	@objc open func start() {
		internalAU?.start()
	}
	
	/// Function to stop or bypass the node, both are equivalent
	@objc open func stop() {
		internalAU?.stop()
	}
}
