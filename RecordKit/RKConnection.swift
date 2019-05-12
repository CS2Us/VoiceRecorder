//
//  RKConnection.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/8.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/// A transitory used to pass connection information.
open class RKInputConnection: NSObject {
	
	open var node: RKInput
	open var bus: Int
	public init(node: RKInput, bus: Int) {
		self.node = node
		self.bus = bus
		super.init()
	}
	open var avConnection: AVAudioConnectionPoint {
		return AVAudioConnectionPoint(node: self.node.inputNode, bus: bus)
	}
}

/// Simplify making connections from a node.
@objc public protocol RKOutput: class {
	
	/// The output of this node can be connected to the inputNode of an AKInput.
	var outputNode: AVAudioNode { get }
}

extension RKOutput {
	
	/// Output connection points of outputNode.
	public var connectionPoints: [AVAudioConnectionPoint] {
		get { return outputNode.engine?.outputConnectionPoints(for: outputNode, outputBus: 0) ?? [] }
		set { RecordKit.connect(outputNode, to: newValue, fromBus: 0, format: RKSettings.audioFormat) }
	}
	
	/// Disconnects all outputNode's output connections.
	public func disconnectOutput() {
		RecordKit.engine.disconnectNodeOutput(outputNode)
	}
	
	/// Breaks connection from outputNode to an input's node if exists.
	///   - Parameter from: The node that output will disconnect from.
	public func disconnectOutput(from: RKInput) {
		connectionPoints = connectionPoints.filter({ $0.node != from.inputNode })
	}
	
	/// Add a connection to an input using the input's nextInput for the bus.
	@discardableResult public func connect(to node: RKInput) -> RKInput {
		return connect(to: node, bus: node.nextInput.bus)
	}
	
	/// Add a connection to input.node on input.bus.
	///   - Parameter input: Contains node and input bus used to make a connection.
	@discardableResult public func connect(to input: RKInputConnection) -> RKInput {
		return connect(to: input.node, bus: input.bus)
	}
	
	/// Add a connection to node on a specific bus.
	@discardableResult public func connect(to node: RKInput, bus: Int) -> RKInput {
		connectionPoints.append(AVAudioConnectionPoint(node: node.inputNode, bus: bus))
		return node
	}
	
	/// Add an output connection to each input in inputs.
	///   - Parameter nodes: Inputs that will be connected to.
	@discardableResult public func connect(to nodes: [RKInput]) -> [RKInput] {
		connectionPoints += nodes.map { $0.nextInput }.map { $0.avConnection }
		return nodes
	}
	
	/// Add an output connection to each connectionPoint in toInputs.
	///   - Parameter toInputs: Inputs that will be connected to.
	@discardableResult public func connect(toInputs: [RKInputConnection]) -> [RKInput] {
		connectionPoints += toInputs.map { $0.avConnection }
		return toInputs.map { $0.node }
	}
	
	/// Add an output connectionPoint.
	///   - Parameter connectionPoint: Input that will be connected to.
	public func connect(to connectionPoint: AVAudioConnectionPoint) {
		connectionPoints.append(connectionPoint)
	}
	
	/// Sets output connection, removes existing output connections.
	///   - Parameter node: Input that output will be connected to.
	@discardableResult public func setOutput(to node: RKInput) -> RKInput {
		return setOutput(to: node, bus: node.nextInput.bus, format: RKSettings.audioFormat)
	}
	
	/// Sets output connection, removes previously existing output connections.
	///   - Parameter node: Input that output will be connected to.
	///   - Parameter bus: The bus on the input that the output will connect to.
	///   - Parameter format: The format of the connection.
	@discardableResult public func setOutput(to node: RKInput, bus: Int, format: AVAudioFormat?) -> RKInput {
		RecordKit.connect(outputNode, to: node.inputNode, fromBus: 0, toBus: bus, format: format)
		return node
	}
	
	/// Sets output connections to an array of inputs, removes previously existing output connections.
	///   - Parameter nodes: Inputs that output will be connected to.
	///   - Parameter format: The format of the connections.
	@discardableResult public func setOutput(to nodes: [RKInput], format: AVAudioFormat?) -> [RKInput] {
		setOutput(to: nodes.map { $0.nextInput.avConnection }, format: format)
		return nodes
	}
	
	/// Sets output connections to an array of inputConnectios, removes previously existing output connections.
	///   - Parameter toInputs: Inputs that output will be connected to.
	@discardableResult public func setOutput(toInputs: [RKInputConnection]) -> [RKInput] {
		return setOutput(toInputs: toInputs, format: RKSettings.audioFormat)
	}
	
	/// Sets output connections to an array of inputConnectios, removes previously existing output connections.
	///   - Parameter toInputs: Inputs that output will be connected to.
	///   - Parameter format: The format of the connections.
	@discardableResult public func setOutput(toInputs: [RKInputConnection], format: AVAudioFormat?) -> [RKInput] {
		setOutput(to: toInputs.map { $0.avConnection }, format: format)
		return toInputs.map { $0.node }
	}
	
	/// Sets output connections to a single connectionPoint, removes previously existing output connections.
	///   - Parameter connectionPoint: Input that output will be connected to.
	public func setOutput(to connectionPoint: AVAudioConnectionPoint) {
		setOutput(to: connectionPoint, format: RKSettings.audioFormat)
	}
	
	/// Sets output connections to a single connectionPoint, removes previously existing output connections.
	///   - Parameter connectionPoint: Input that output will be connected to.
	///   - Parameter format: The format of the connections.
	public func setOutput(to connectionPoint: AVAudioConnectionPoint, format: AVAudioFormat?) {
		setOutput(to: [connectionPoint], format: format)
	}
	
	/// Sets output connections to an array of connectionPoints, removes previously existing output connections.
	///   - Parameter connectionPoints: Inputs that output will be connected to.
	///   - Parameter format: The format of the connections.
	public func setOutput(to connectionPoints: [AVAudioConnectionPoint], format: AVAudioFormat?) {
		RecordKit.connect(outputNode, to: connectionPoints, fromBus: 0, format: format)
	}
	
}

/// Manages connections to inputNode.
public protocol RKInput: RKOutput {
	
	/// The node that an output's node can connect to.  Default implementation will return outputNode.
	var inputNode: AVAudioNode { get }
	
	/// The input bus that should be used for an input connection.  Default implementation is 0.  Multi-input nodes
	/// should return an open bus.
	///
	///   - Return: An inputConnection object conatining self and the input bus to use for an input connection.
	var nextInput: RKInputConnection { get }
	
	/// Disconnects all inputs
	func disconnectInput()
	
	/// Disconnects input on a bus.
	func disconnectInput(bus: Int)
	
	/// Creates an input connection object with a bus number.
	///   - Return: An inputConnection object conatining self and the input bus to use for an input connection.
	func input(_ bus: Int) -> RKInputConnection
}

extension RKInput {
	public var inputNode: AVAudioNode {
		return outputNode
	}
	public func disconnectInput() {
		RecordKit.engine.disconnectNodeInput(inputNode)
	}
	public func disconnectInput(bus: Int) {
		RecordKit.engine.disconnectNodeInput(inputNode, bus: bus )
	}
	public var nextInput: RKInputConnection {
		
		if let mixer = inputNode as? AVAudioMixerNode {
			return input(mixer.nextAvailableInputBus)
		}
		return input(0)
	}
	public func input(_ bus: Int) -> RKInputConnection {
		return RKInputConnection(node: self, bus: bus)
	}
	
}

@objc extension AVAudioNode: RKInput {
	public var outputNode: AVAudioNode {
		return self
	}
}

// Set output connection(s)
infix operator >>>: AdditionPrecedence

@discardableResult public func >>>(left: RKOutput, right: RKInput) -> RKInput {
	return left.connect(to: right)
}
@discardableResult public func >>>(left: RKOutput, right: [RKInput]) -> [RKInput] {
	return left.connect(to: right)
}
@discardableResult public func >>>(left: [RKOutput], right: RKInput) -> RKInput {
	for node in left {
		node.connect(to: right)
	}
	return right
}
@discardableResult public func >>>(left: RKOutput, right: RKInputConnection) -> RKInput {
	return left.connect(to: right.node, bus: right.bus)
}
@discardableResult public func >>>(left: RKOutput, right: [RKInputConnection]) -> [RKInput] {
	return left.connect(toInputs: right)
}
public func >>>(left: RKOutput, right: AVAudioConnectionPoint) {
	return left.connect(to: right)
}
