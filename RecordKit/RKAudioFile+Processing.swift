//
//  RKAudioFile+Processing.swift
//  AudioKit
//
//  Created by Laurent Veliscek, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//
//
//  IMPORTANT: Any RKAudioFile process will output a .caf RKAudioFile
//  set with a PCM Linear Encoding (no compression)
//  But it can be applied to any readable file (.wav, .m4a, .mp3...)
//

extension RKAudioFile {

    /// Normalize an RKAudioFile to have a peak of newMaxLevel dB.
    ///
    /// - Parameters:
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp
    ///   - name: the name of the file without its extension (String).  If none is given, a unique random name is used.
    ///   - newMaxLevel: max level targeted as a Float value (default if 0 dB)
    ///
    /// - returns: An RKAudioFile, or nil if init failed.
    ///
    public func normalized(dst: Destination = .temp(),
                           newMaxLevel: Float = 0.0 ) throws -> RKAudioFile {

        let level = self.maxLevel
        var outputFile = try RKAudioFile (writeIn: dst)

        if self.samplesCount == 0 {
            RKLog("WARNING RKAudioFile: cannot normalize an empty file")
            return try RKAudioFile(forReading: outputFile.url)
        }

        if level == Float.leastNormalMagnitude {
            RKLog("WARNING RKAudioFile: cannot normalize a silent file")
            return try RKAudioFile(forReading: outputFile.url)
        }

        let gainFactor = Float( pow(10.0, newMaxLevel / 20.0) / pow(10.0, level / 20.0))

        let arrays = self.floatChannelData ?? [[]]

        var newArrays: [[Float]] = []
        for array in arrays {
            let newArray = array.map { $0 * gainFactor }
            newArrays.append(newArray)
        }

        outputFile = try RKAudioFile(createFileFromFloats: newArrays,
                                     dst: dst)
        return try RKAudioFile(forReading: outputFile.url)
    }

    /// Returns an RKAudioFile with audio reversed (will playback in reverse from end to beginning).
    ///
    /// - Parameters:
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp
    ///   - name: the name of the file without its extension (String).  If none is given, a unique random name is used.
    ///
    /// - Returns: An RKAudioFile, or nil if init failed.
    ///
    public func reversed(dst: Destination = .temp()) throws -> RKAudioFile {

        var outputFile = try RKAudioFile (writeIn: dst)

        if self.samplesCount == 0 {
            return try RKAudioFile(forReading: outputFile.url)
        }

        let arrays = self.floatChannelData ?? [[]]

        var newArrays: [[Float]] = []
        for array in arrays {
            newArrays.append(Array(array.reversed()))
        }
        outputFile = try RKAudioFile(createFileFromFloats: newArrays,
                                     dst: dst)
        return try RKAudioFile(forReading: outputFile.url)
    }

    /// Returns an RKAudioFile with appended audio data from another RKAudioFile.
    ///
    /// Notice that Source file and appended file formats must match.
    ///
    /// - Parameters:
    ///   - file: an RKAudioFile that will be used to append audio from.
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp
    ///   - name: the name of the file without its extension (String).  If none is given, a unique random name is used.
    ///
    /// - Returns: An RKAudioFile, or nil if init failed.
    ///
    public func appendedBy(file: RKAudioFile,
                           dst: Destination = .temp(),
                           name: String = UUID().uuidString) throws -> RKAudioFile {

        var sourceBuffer = self.pcmBuffer
        var appendedBuffer = file.pcmBuffer

        if self.fileFormat != file.fileFormat {
            RKLog("WARNING RKAudioFile.append: appended file should be of same format as source file")
            RKLog("WARNING RKAudioFile.append: trying to fix by converting files...")
            // We use extract method to get a .CAF file with the right format for appending
            // So sourceFile and appended File formats should match
            do {
                // First, we convert the source file to .CAF using extract()
                let convertedFile = try self.extracted()
                sourceBuffer = convertedFile.pcmBuffer
                RKLog("RKAudioFile.append: source file has been successfully converted")

                if convertedFile.fileFormat != file.fileFormat {
                    do {
                        // If still don't match we convert the appended file to .CAF using extract()
                        let convertedAppendFile = try file.extracted()
                        appendedBuffer = convertedAppendFile.pcmBuffer
                        RKLog("RKAudioFile.append: appended file has been successfully converted")
                    } catch let error as NSError {
                        RKLog("ERROR RKAudioFile.append: cannot set append file format match source file format")
                        throw error
                    }
                }
            } catch let error as NSError {
                RKLog("ERROR RKAudioFile: Cannot convert sourceFile to .CAF")
                throw error
            }
        }

        // We check that both pcm buffers share the same format
        if appendedBuffer.format != sourceBuffer.format {
            RKLog("ERROR RKAudioFile.append: Couldn't match source file format with appended file format")
            let userInfo: [AnyHashable: Any] = [
                NSLocalizedDescriptionKey: NSLocalizedString(
                    "RKAudioFile append process Error",
                    value: "Couldn't match source file format with appended file format",
                    comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(
                    "RKAudioFile append process Error",
                    value: "Couldn't match source file format with appended file format",
                    comment: "")
            ]
            throw NSError(domain: "RKAudioFile ASync Process Unknown Error", code: 0, userInfo: userInfo as? [String: Any])
        }

        let outputFile = try RKAudioFile (writeIn: dst)

        // Write the buffer in file
        do {
            try outputFile.write(from: sourceBuffer)
        } catch let error as NSError {
            RKLog("ERROR RKAudioFile: cannot writeFromBuffer Error: \(error)")
            throw error
        }

        do {
            try outputFile.write(from: appendedBuffer)
        } catch let error as NSError {
            RKLog("ERROR RKAudioFile: cannot writeFromBuffer Error: \(error)")
            throw error
        }

        return try RKAudioFile(forReading: outputFile.url)
    }

    /// Returns an RKAudioFile that will contain a range of samples from the current RKAudioFile
    ///
    /// - Parameters:
    ///   - fromSample: the starting sampleFrame for extraction.
    ///   - toSample: the ending sampleFrame for extraction
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp
    ///   - name: the name of the file without its extension (String).  If none is given, a unique random name is used.
    ///
    /// - Returns: An RKAudioFile, or nil if init failed.
    ///
    public func extracted(fromSample: Int64 = 0,
                          toSample: Int64 = 0,
                          dst: Destination = .temp(),
                          name: String = UUID().uuidString) throws -> RKAudioFile {

        let fixedFrom = abs(fromSample)
        let fixedTo: Int64 = toSample == 0 ? Int64(self.samplesCount) : min(toSample, Int64(self.samplesCount))
        if fixedTo <= fixedFrom {
            RKLog("ERROR RKAudioFile: cannot extract, from must be less than to")
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil)
        }

        let arrays = self.floatChannelData ?? [[]]

        var newArrays: [[Float]] = []

        for array in arrays {
            let extract = Array(array[Int(fixedFrom)..<Int(fixedTo)])
            newArrays.append(extract)
        }

        let newFile = try RKAudioFile(createFileFromFloats: newArrays, dst: dst)
        return try RKAudioFile(forReading: newFile.url)
    }
}
