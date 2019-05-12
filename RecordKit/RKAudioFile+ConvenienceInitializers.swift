//
//  RKAudioFile+ConvenienceInitializers.swift
//  AudioKit
//
//  Created by Laurent Veliscek, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

extension NSError {
  static var fileCreateError: NSError {
    return NSError(domain: NSURLErrorDomain,
                   code: NSURLErrorCannotCreateFile,
                   userInfo: nil)
  }
}

func ??<T> (lhs: T?, rhs: NSError) throws -> T {
  guard let l = lhs else { throw rhs }
  return l
}

func || (lhs: Bool, rhs: NSError) throws -> Bool {
  guard lhs else { throw rhs }
  return lhs
}

extension RKAudioFile {

    /// Opens a file for reading.
    ///
    /// - parameter name:    Filename, including the extension
    /// - parameter dst: Location of file, can be set to .Resources, .Documents or .Temp
    ///
    /// - returns: An initialized RKAudioFile for reading, or nil if init failed
    ///
    public convenience init(readFileName name: String,
							dst: Destination) throws {
        try self.init(forReading: dst.fileUrl)
    }

    /// Initialize file for recording / writing purpose
    ///
    /// Default is a .caf RKAudioFile with AudioKit settings
    /// If file name is an empty String, a unique Name will be set
    /// If no dst is set, dst will be the Temp Directory
    ///
    /// From Apple doc: The file type to create is inferred from the file extension of fileURL.
    /// This method will overwrite a file at the specified URL if a file already exists.
    ///
    /// Note: It seems that Apple's AVAudioFile class has a bug with .wav files. They cannot be set
    /// with a floating Point encoding. As a consequence, such files will fail to record properly.
    /// So it's better to use .caf (or .aif) files for recording purpose.
    ///
    /// Example of use: to create a temp .caf file with a unique name for recording:
    /// let recordFile = RKAudioFile()
    ///
    /// - Parameters:
    ///   - name: the name of the file without its extension (String).
    ///   - ext: the extension of the file without "." (String).
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp
    ///   - settings: The settings of the file to create.
    ///   - format: The processing commonFormat to use when writing.
    ///   - interleaved: Bool (Whether to use an interleaved processing format.)
    ///
    public convenience init(writeIn dst: Destination = .temp(),
                            settings: [String: Any] = RKSettings.audioFormat.settings)
        throws {
            let fileURL = dst.fileUrl

            // Directory exists ?
            let absDirPath = fileURL.deletingLastPathComponent().path

            _ = try FileManager.default.fileExists(atPath: absDirPath) || .fileCreateError

            // AVLinearPCMIsNonInterleaved cannot be set to false (ignored but throw a warning)
            var fixedSettings = settings

            fixedSettings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)

            do {
                try self.init(forWriting: fileURL, settings: fixedSettings)
            } catch let error as NSError {
                RKLog("ERROR: Couldn't create an RKAudioFile", error)
                throw NSError.fileCreateError
            }
    }

    /// Instantiate a file from Floats Arrays.
    ///
    /// To create a stereo file, you pass [leftChannelFloats, rightChannelFloats]
    /// where leftChannelFloats and rightChannelFloats are 2 arrays of FLoat values.
    /// Arrays must both have the same number of Floats.
    ///
    /// - Parameters:
    ///   - floatsArrays: An array of Arrays of floats
    ///   - name: the name of the file without its extension (String).
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp
    ///
    /// - Returns: a .caf RKAudioFile set to AudioKit settings (32 bits float @ 44100 Hz)
    ///
    public convenience init(createFileFromFloats floatsArrays: [[Float]],
                            dst: Destination = .temp()) throws {

        let channels = floatsArrays.count
        var fixedSettings = RKSettings.audioFormat.settings

        fixedSettings[AVNumberOfChannelsKey] = channels

        try self.init(writeIn: dst, settings: fixedSettings)

        // create buffer for floats
        let format = AVAudioFormat(standardFormatWithSampleRate: RKSettings.sampleRate,
                                   channels: AVAudioChannelCount(channels))

        let buffer = AVAudioPCMBuffer(pcmFormat: format!,
                                      frameCapacity: AVAudioFrameCount(floatsArrays[0].count))

        // Fill the buffers

        for channel in 0..<channels {
            let channelNData = buffer?.floatChannelData?[channel]
            for f in 0..<Int(buffer?.frameCapacity ?? 0) {
                channelNData?[f] = floatsArrays[channel][f]
            }
        }

        // set the buffer frameLength
        buffer?.frameLength = (buffer?.frameCapacity)!

        // Write the buffer in file
        do {
            try self.write(from: buffer!)
        } catch let error as NSError {
            RKLog("ERROR RKAudioFile: cannot writeFromBuffer Error", error)
            throw error
        }
    }

    /// Convenience init to instantiate a file from an AVAudioPCMBuffer.
    ///
    /// - Parameters:
    ///   - buffer: the AVAudioPCMBuffer that will be used to fill the RKAudioFile
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp
    ///   - name: the name of the file without its extension (String).
    ///
    /// - Returns: a .caf RKAudioFile set to AudioKit settings (32 bits float @ 44100 Hz)
    ///
    public convenience init(fromAVAudioPCMBuffer buffer: AVAudioPCMBuffer,
                            dst: Destination = .temp()) throws {

        try self.init(writeIn: dst)

        // Write the buffer in file
        do {
            try self.write(from: buffer)
        } catch let error as NSError {
            RKLog("ERROR RKAudioFile: cannot writeFromBuffer Error: \(error)")
            throw error
        }
    }
}
