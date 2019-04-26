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
