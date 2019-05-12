//
//  AKMoogLadderPresets.swift
//  AudioKit
//
//  Created by Nicholas Arner, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

/// Preset for the AKMoogLadder
public extension RKMoogLadder {

    /// Blurry, foggy filter
    public func presetFogMoogLadder() {
        cutoffFrequency = 515.578
        resonance = 0.206
    }

    /// Dull noise filter
    public func presetDullNoiseMoogLadder() {
        cutoffFrequency = 3_088.157
        resonance = 0.075
    }

    /// Print out current values in case you want to save it as a preset
    public func printCurrentValuesAsPreset() {
        RKLog("public func presetSomeNewMoogLadderFilter() {")
        RKLog("    cutoffFrequency = \(String(format: "%0.3f", cutoffFrequency))")
        RKLog("    resonance = \(String(format: "%0.3f", resonance))")
        RKLog("    ramp duration = \(String(format: "%0.3f", rampDuration))")
        RKLog("}\n")
    }

}
