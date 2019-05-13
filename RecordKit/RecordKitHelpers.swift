//
//  RecordKitHelpers.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/6.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

@inline(__always)
func RKLog(fullname: String = #function, file: String = #file, line: Int = #line, _ items: Any...) {
	guard RKSettings.enableLogging else { return }
	let fileName = (file as NSString).lastPathComponent
	let content = (items.map { String(describing: $0) }).joined(separator: " ")
	Swift.print("\(fileName):\(fullname):\(line):\(content)")
}

@inline(__always)
func RKLogBrisk(_ message: String) {
	guard RKSettings.enableLogging else { return }
	Swift.print(message)
}

@inline(__always)
func SizeOf32<T>(_ X: T) -> UInt32 {
	return UInt32(MemoryLayout<T>.stride)
}

@inline(__always)
func SizeOf32<T>(_ X: T.Type) -> UInt32 {
	return UInt32(MemoryLayout<T>.stride)
}

@inline(__always)
public func Desc(formatID: AudioFormatID) -> String {
	switch formatID {
	case kAudioFormatLinearPCM: return "kAudioFormatLinearPCM"
	case kAudioFormatAC3: return "kAudioFormatAC3"
	case kAudioFormat60958AC3: return "kAudioFormat60958AC3"
	case kAudioFormatAppleIMA4: return "kAudioFormatAppleIMA4"
	case kAudioFormatMPEG4AAC: return "kAudioFormatMPEG4AAC"
	case kAudioFormatMPEG4CELP: return "kAudioFormatMPEG4CELP"
	case kAudioFormatMPEG4HVXC: return "kAudioFormatMPEG4HVXC"
	case kAudioFormatMPEG4TwinVQ: return "kAudioFormatMPEG4TwinVQ"
	case kAudioFormatMACE3: return "kAudioFormatMACE3"
	case kAudioFormatMACE6: return "kAudioFormatMACE6"
	case kAudioFormatULaw: return "kAudioFormatULaw"
	case kAudioFormatALaw: return "kAudioFormatALaw"
	case kAudioFormatQDesign: return "kAudioFormatQDesign"
	case kAudioFormatQDesign2: return "kAudioFormatQDesign2"
	case kAudioFormatQUALCOMM: return "kAudioFormatQUALCOMM"
	case kAudioFormatMPEGLayer1: return "kAudioFormatMPEGLayer1"
	case kAudioFormatMPEGLayer2: return "kAudioFormatMPEGLayer2"
	case kAudioFormatMPEGLayer3: return "kAudioFormatMPEGLayer3"
	case kAudioFormatTimeCode: return "kAudioFormatTimeCode"
	case kAudioFormatMIDIStream: return "kAudioFormatMIDIStream"
	case kAudioFormatParameterValueStream: return "kAudioFormatParameterValueStream"
	case kAudioFormatAppleLossless: return "kAudioFormatAppleLossless"
	case kAudioFormatMPEG4AAC_HE: return "kAudioFormatMPEG4AAC_HE"
	case kAudioFormatMPEG4AAC_LD: return "kAudioFormatMPEG4AAC_LD"
	case kAudioFormatMPEG4AAC_ELD: return "kAudioFormatMPEG4AAC_ELD"
	case kAudioFormatMPEG4AAC_ELD_SBR: return "kAudioFormatMPEG4AAC_ELD_SBR"
	case kAudioFormatMPEG4AAC_ELD_V2: return "kAudioFormatMPEG4AAC_ELD_V2"
	case kAudioFormatMPEG4AAC_HE_V2: return "kAudioFormatMPEG4AAC_HE_V2"
	case kAudioFormatMPEG4AAC_Spatial: return "kAudioFormatMPEG4AAC_Spatial"
	case kAudioFormatAMR: return "kAudioFormatAMR"
	case kAudioFormatAMR_WB: return "kAudioFormatAMR_WB"
	case kAudioFormatAudible: return "kAudioFormatAudible"
	case kAudioFormatiLBC: return "kAudioFormatiLBC"
	case kAudioFormatDVIIntelIMA: return "kAudioFormatDVIIntelIMA"
	case kAudioFormatMicrosoftGSM: return "kAudioFormatMicrosoftGSM"
	case kAudioFormatAES3: return "kAudioFormatAES3"
	case kAudioFormatEnhancedAC3: return "kAudioFormatEnhancedAC3"
	case kAudioFormatFLAC: return "kAudioFormatFLAC"
	case kAudioFormatOpus: return "kAudioFormatOpus"
	default: return "Unknown Format ID"
	}
}

@inline(__always)
public func Desc(formatFlags: AudioFormatFlags) -> String {
	switch formatFlags {
	case kAudioFormatFlagIsFloat: return "kAudioFormatFlagIsFloat"
	case kAudioFormatFlagIsBigEndian: return "kAudioFormatFlagIsBigEndian"
	case kAudioFormatFlagIsSignedInteger: return "kAudioFormatFlagIsSignedInteger"
	case kAudioFormatFlagIsPacked: return "kAudioFormatFlagIsPacked"
	case kAudioFormatFlagIsAlignedHigh: return "kAudioFormatFlagIsAlignedHigh"
	case kAudioFormatFlagIsNonInterleaved: return "kAudioFormatFlagIsNonInterleaved"
	case kAudioFormatFlagIsNonMixable: return "kAudioFormatFlagIsNonMixable"
	case kAudioFormatFlagsAreAllClear: return "kAudioFormatFlagsAreAllClear"
	case kLinearPCMFormatFlagIsFloat: return "kLinearPCMFormatFlagIsFloat"
	case kLinearPCMFormatFlagIsBigEndian: return "kLinearPCMFormatFlagIsBigEndian"
	case kLinearPCMFormatFlagIsSignedInteger: return "kLinearPCMFormatFlagIsSignedInteger"
	case kLinearPCMFormatFlagIsPacked: return "kLinearPCMFormatFlagIsPacked"
	case kLinearPCMFormatFlagIsAlignedHigh: return "kLinearPCMFormatFlagIsAlignedHigh"
	case kLinearPCMFormatFlagIsNonInterleaved: return "kLinearPCMFormatFlagIsNonInterleaved"
	case kLinearPCMFormatFlagIsNonMixable: return "kLinearPCMFormatFlagIsNonMixable"
	case kLinearPCMFormatFlagsSampleFractionShift: return "kLinearPCMFormatFlagsSampleFractionShift"
	case kLinearPCMFormatFlagsSampleFractionMask: return "kLinearPCMFormatFlagsSampleFractionMask"
	case kLinearPCMFormatFlagsAreAllClear: return "kLinearPCMFormatFlagsAreAllClear"
	case kAppleLosslessFormatFlag_16BitSourceData: return "kAppleLosslessFormatFlag_16BitSourceData"
	case kAppleLosslessFormatFlag_20BitSourceData: return "kAppleLosslessFormatFlag_20BitSourceData"
	case kAppleLosslessFormatFlag_24BitSourceData: return "kAppleLosslessFormatFlag_24BitSourceData"
	case kAppleLosslessFormatFlag_32BitSourceData: return "kAppleLosslessFormatFlag_32BitSourceData"
	default: return "Unknown Format Flags"
	}
}

/// Adding instantiation with component and callback
public extension AVAudioUnit {
	class func _instantiate(with component: AudioComponentDescription, callback: @escaping (AVAudioUnit) -> Void) {
		AVAudioUnit.instantiate(with: component, options: []) { avAudioUnit, _ in
			avAudioUnit.map {
				RecordKit.engine.attach($0)
				callback($0)
			}
		}
	}
}

extension AVAudioNode {
	func inputConnections() -> [AVAudioConnectionPoint] {
		return (0..<numberOfInputs).compactMap { engine?.inputConnectionPoint(for: self, inputBus: $0) }
	}
}

/// Helper function to convert codes for Audio Units
/// - parameter string: Four character string to convert
///
public func fourCC(_ string: String) -> UInt32 {
	let utf8 = string.utf8
	precondition(utf8.count == 4, "Must be a 4 char string")
	var out: UInt32 = 0
	for char in utf8 {
		out <<= 8
		out |= UInt32(char)
	}
	return out
}

public extension AUParameter {
	@nonobjc
	convenience init(identifier: String,
					 name: String,
					 address: AUParameterAddress,
					 range: ClosedRange<Double>,
					 unit: AudioUnitParameterUnit,
					 flags: AudioUnitParameterOptions) {
		
		self.init(identifier: identifier,
				  name: name,
				  address: address,
				  min: AUValue(range.lowerBound),
				  max: AUValue(range.upperBound),
				  unit: unit,
				  flags: flags)
	}
}

extension AudioUnitParameterOptions {
	public static let `default`:AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable, .flag_CanRamp]
}

extension RangeReplaceableCollection where Iterator.Element: ExpressibleByIntegerLiteral {
	/// Initialize array with zeros, ~10x faster than append for array of size 4096
	///
	/// - parameter count: Number of elements in the array
	///
	
	public init(zeros count: Int) {
		self.init(repeating: 0, count: count)
	}
}

extension ClosedRange {
	/// Clamp value to the range
	///
	/// - parameter value: Value to clamp
	///
	public func clamp(_ value: Bound) -> Bound {
		return Swift.min(Swift.max(value, lowerBound), upperBound)
	}
}

/// Extension to calculate scaling factors, useful for UI controls
extension Double {
	
	/// Return a value on [minimum, maximum] to a [0, 1] range, according to a taper
	///
	/// - Parameters:
	///   - to: Source range (cannot include zero if taper is not positive)
	///   - taper: For taper > 0, there is an algebraic curve, taper = 1 is linear, and taper < 0 is exponential
	///
	public func normalized(from range: ClosedRange<Double>, taper: Double = 1) -> Double {
		assert(!(range.contains(0.0) && taper < 0), "Cannot have negative taper with a range containing zero.")
		
		if taper > 0 {
			// algebraic taper
			return pow(((self - range.lowerBound ) / (range.upperBound - range.lowerBound)), (1.0 / taper))
		} else {
			// exponential taper
			return range.lowerBound * exp(log(range.upperBound / range.lowerBound) * self)
		}
	}
	
	/// Return a value on [0, 1] to a [minimum, maximum] range, according to a taper
	///
	/// - Parameters:
	///   - to: Target range (cannot contain zero if taper is not positive)
	///   - taper: For taper > 0, there is an algebraic curve, taper = 1 is linear, and taper < 0 is exponential
	///
	public func denormalized(to range: ClosedRange<Double>, taper: Double = 1) -> Double {
		
		assert(!(range.contains(0.0) && taper < 0), "Cannot have negative taper with a range containing zero.")
		
		// Avoiding division by zero in this trivial case
		if range.upperBound - range.lowerBound < 0.000_01 {
			return range.lowerBound
		}
		
		if taper > 0 {
			// algebraic taper
			return range.lowerBound + (range.upperBound - range.lowerBound) * pow(self, taper)
		} else {
			// exponential taper
			var adjustedMinimum: Double = 0.0
			var adjustedMaximum: Double = 0.0
			if range.lowerBound == 0 { adjustedMinimum = 0.000_000_000_01 }
			if range.upperBound == 0 { adjustedMaximum = 0.000_000_000_01 }
			
			return log(self / adjustedMinimum) / log(adjustedMaximum / adjustedMinimum)
		}
	}
}

/// Random double in range
///
/// - parameter in: Range of randomization
///
public func random(in range: ClosedRange<Double>) -> Double {
	let precision = 1_000_000
	let width = range.upperBound - range.lowerBound
	
	return Double(arc4random_uniform(UInt32(precision))) / Double(precision) * width + range.lowerBound
}

// Anything that can hold a value (strings, arrays, etc)
public protocol Occupiable {
	var isEmpty: Bool { get }
	var isNotEmpty: Bool { get }
}

// Give a default implementation of isNotEmpty, so conformance only requires one implementation
extension Occupiable {
	public var isNotEmpty: Bool {
		return !isEmpty
	}
}

extension String: Occupiable { }

// I can't think of a way to combine these collection types. Suggestions welcome.
extension Array: Occupiable { }
extension Dictionary: Occupiable { }
extension Set: Occupiable { }

#if !os(macOS)
extension AVAudioSession.CategoryOptions: Occupiable { }
#endif
