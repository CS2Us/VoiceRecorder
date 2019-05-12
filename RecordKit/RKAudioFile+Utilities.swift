//
//  RKAudioFile+Utilities.swift
//  AudioKit
//
//  Created by Laurent Veliscek, revision history on GitHub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

extension RKAudioFile {

    /// Returns a silent RKAudioFile with a length set in samples.
    ///
    /// For a silent file of one second, set samples value to 44100...
    ///
    /// - Parameters:
    ///   - samples: the number of samples to generate (equals length in seconds multiplied by sample rate)
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp
    ///   - name: the name of the file without its extension (String).
    ///
    /// - Returns: An RKAudioFile, or nil if init failed.
    ///
    static public func silent(samples: Int64,
                              dst: Destination = .temp()) throws -> RKAudioFile {

        if samples < 0 {
            RKLog("ERROR RKAudioFile: cannot create silent RKAUdioFile with negative samples count")
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil)
        } else if samples == 0 {
            let emptyFile = try RKAudioFile(writeIn: dst)
            // we return it as a file for reading
            return try RKAudioFile(forReading: emptyFile.url)
        }

        let zeros = [Float](zeros: Int(samples))
        let silentFile = try RKAudioFile(createFileFromFloats: [zeros, zeros], dst: dst)

        return try RKAudioFile(forReading: silentFile.url)
    }

    static public func findPeak(pcmBuffer: AVAudioPCMBuffer) -> Double {
        return pcmBuffer.peakTime()
    }
}
