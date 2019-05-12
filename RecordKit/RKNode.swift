//
//  RKNode.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension AVAudioConnectionPoint {
	convenience init(_ node: RKNode, to bus: Int) {
		self.init(node: node.avAudioUnitOrNode, bus: bus)
	}
}

/// Parent class for all nodes in AudioKit
open class RKNode: RKObject {
	/// The internal AVAudioEngine AVAudioNode
	@objc open var avAudioNode: AVAudioNode
	
	/// The internal AVAudioUnit, which is a subclass of AVAudioNode with more capabilities
	@objc open var avAudioUnit: AVAudioUnit?
	
	/// Returns either the avAudioUnit (preferred
	@objc open var avAudioUnitOrNode: AVAudioNode {
		return avAudioUnit ?? avAudioNode
	}
	
	/// Create the node
	override public init() {
		self.avAudioNode = AVAudioNode()
	}
	
	/// Initialize the node from an AVAudioUnit
	@objc public init(avAudioUnit: AVAudioUnit, attach: Bool = false) {
		self.avAudioUnit = avAudioUnit
		avAudioNode = avAudioUnit
		if attach {
			RecordKit.engine.attach(avAudioUnit)
		}
	}
	
	/// Initialize the node from an AVAudioNode
	@objc public init(avAudioNode: AVAudioNode, attach: Bool = false) {
		self.avAudioNode = avAudioNode
		if attach {
			RecordKit.engine.attach(avAudioNode)
		}
	}
	
	//Subclasses should override to detach all internal nodes
	open func detach() {
		RecordKit.detach(nodes: [avAudioUnitOrNode])
	}
}

extension RKNode: RKOutput {
	public var outputNode: AVAudioNode {
		return avAudioUnitOrNode
	}
	
	@available(*, deprecated, renamed: "connect(to:bus:)")
	open func addConnectionPoint(_ node: RKNode, bus: Int = 0) {
		connectionPoints.append(AVAudioConnectionPoint(node, to: bus))
	}
}

//Deprecated
extension RKNode {
	
	@objc @available(*, deprecated, renamed: "detach")
	open func disconnect() {
		detach()
	}
	
	@available(*, deprecated, message: "Use AudioKit.dettach(nodes:) instead")
	open func disconnect(nodes: [AVAudioNode]) {
		RecordKit.detach(nodes: nodes)
	}
}

/// Protocol for dictating that a node can be in a started or stopped state
@objc public protocol RKToggleable {
	/// Tells whether the node is processing (ie. started, playing, or active)
	var isStarted: Bool { get }
	
	/// Function to start, play, or activate the node, all do the same thing
	func start()
	
	/// Function to stop or bypass the node, both are equivalent
	func stop()
}

/// Default functions for nodes that conform to AKToggleable
public extension RKToggleable {
	
	/// Synonym for isStarted that may make more sense with musical instruments
	var isPlaying: Bool {
		return isStarted
	}
	
	/// Antonym for isStarted
	var isStopped: Bool {
		return !isStarted
	}
	
	/// Antonym for isStarted that may make more sense with effects
	var isBypassed: Bool {
		return !isStarted
	}
	
	/// Synonym to start that may more more sense with musical instruments
	func play() {
		start()
	}
	
	/// Synonym for stop that may make more sense with effects
	func bypass() {
		stop()
	}
}
