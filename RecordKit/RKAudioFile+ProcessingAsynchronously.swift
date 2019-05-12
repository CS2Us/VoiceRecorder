//
//  RKAudioFile+ProcessingAsynchronously.swift
//  AudioKit
//
//  Created by Laurent Veliscek and Brandon Barber, revision history on GitHub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

///  Major Revision: Async process objects are now handled by RKAudioFile ProcessFactory singleton.
///  So there's no more need to handle asyncProcess objects.
///  You can process a file asynchronously using:
///
///      file.normalizeAsynchronously(completionHandler: callback)
///
///  where completionHandler as an RKAudioFile.AsyncProcessCallback signature :
///
///      asyncProcessCallback(processedFile: RKAudioFile?, error: NSError?) -> Void
///
///  When process has been completed, completionHandler is triggered
///  Then, processedFile is nil if an error occurred (error is the process thrown error)
///  Or processedFile is the resulting processed RKAudioFile (and error is nil)
///
///  IMPORTANT: Any RKAudioFile process will output a .caf RKAudioFile
///  set with a PCM Linear Encoding (no compression)
///  But it can be applied to any readable file (.wav, .m4a, .mp3...)
///  So it can be used to convert any readable file (compressed or not) into a PCM Linear Encoded RKAudioFile
///  (That is not possible using RKAudioFile export method, that relies on AVAsset Export methods)
///

extension RKAudioFile {
    /// typealias for RKAudioFile Async Process Completion Handler
    ///
    /// If processedFile != nil, process succeeded (then error is nil)
    /// If processedFile == nil, process failed, error is the process thrown error
    public typealias AsyncProcessCallback = (_ processedFile: RKAudioFile?, _ error: NSError?) -> Void

    /// ExportFormat enum to set target format when exporting RKAudiofiles
    ///
    /// - wav: Waveform Audio File Format (WAVE, or more commonly known as WAV due to its filename extension)
    /// - aif: Audio Interchange File Format
    /// - mp4: MPEG-4 Part 14 Compression
    /// - m4a: MPEG 4 Audio
    /// - caf: Core Audio Format
    ///
    public enum ExportFormat {
        /// Waveform Audio File Format (WAVE, or more commonly known as WAV due to its filename extension)
        case wav

        /// Audio Interchange File Format
        case aif

        /// MPEG-4 Part 14 Compression
        case mp4

        /// MPEG 4 Audio
        case m4a

        /// Core Audio Format
        case caf

        // Returns a Uniform Type identifier for each audio file format
        fileprivate var UTI: CFString {
            switch self {
            case .wav:
                return AVFileType.wav as CFString
            case .aif:
                return AVFileType.aiff as CFString
            case .mp4:
                return AVFileType.m4a as CFString
            case .m4a:
                return AVFileType.m4a as CFString
            case .caf:
                return AVFileType.caf as CFString
            }
        }

        // Available Export Formats
        static var supportedFileExtensions: [String] {
            return ["wav", "aif", "mp4", "m4a", "caf"]
        }
    }

    // MARK: - RKAudioFile public interface with private RKAudioFile ProcessFactory singleton

    /// Returns the remaining not completed queued Async processes (Int)
    public static var queuedAsyncProcessCount: Int {
        return ProcessFactory.sharedInstance.queuedProcessCount
    }

    /// Returns the total scheduled Async processes count (Int)
    public static var scheduledAsyncProcessesCount: Int {
        return ProcessFactory.sharedInstance.scheduledProcessesCount
    }

    /// Returns the completed Async processes count (Int)
    public static var completedAsyncProcessesCount: Int {
        return scheduledAsyncProcessesCount - queuedAsyncProcessCount
    }

    /// Process the current RKAudioFile in background to return an
    /// RKAudioFile normalized with a peak of newMaxLevel dB if succeeded
    ///
    /// Completion Handler is function with an RKAudioFile.AsyncProcessCallback signature:
    /// ```
    /// func myCallback(processedFile: RKAudioFile?, error: NSError?) -> Void
    /// ```
    ///
    /// in this callback, you can check that process succeeded by testing processedFile value :
    /// . if processedFile != nil, process succeeded (and error is nil)
    /// . if processedFile == nil, process failed, error is the process thrown error
    ///
    /// Notice that completionHandler will be triggered from a
    /// background thread. Any UI update should be made using:
    ///
    /// ```
    /// dispatch_async(dispatch_get_main_queue()) {
    ///   // UI updates...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp (Default is .Temp)
    ///   - name: the name of the resulting file without its extension (String).
    ///   - newMaxLevel: max level targeted as a Float value (default if 0 dB)
    ///   - completionHandler: RKCallback that will be triggered as soon as process has been completed or failed.
    ///
    public func normalizeAsynchronously(dst: Destination = .temp(),
                                        newMaxLevel: Float = 0.0,
                                        completionHandler: @escaping AsyncProcessCallback) {
        ProcessFactory.sharedInstance.queueNormalizeAsyncProcess(sourceFile: self,
                                                                 dst: dst,
                                                                 newMaxLevel: newMaxLevel,
                                                                 completionHandler: completionHandler)
    }

    /// Process the current RKAudioFile in background to return the current RKAudioFile reversed (will play backward)
    ///
    /// Completion Handler is function with an RKAudioFile.AsyncProcessCallback signature:
    /// ```
    /// func myCallback(processedFile: RKAudioFile?, error: NSError?) -> Void
    /// ```
    ///
    /// in this callback, you can check that process succeeded by testing processedFile value :
    /// . if processedFile != nil, process succeeded (and error is nil)
    /// . if processedFile == nil, process failed, error is the process thrown error
    ///
    /// Notice that completionHandler will be triggered from a
    /// background thread. Any UI update should be made using:
    ///
    /// ```
    /// dispatch_async(dispatch_get_main_queue()) {
    ///   // UI updates...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - completionHandler: the callback that will be triggered when process has been completed
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp (Default is .Temp)
    ///   - name: the name of the resulting file without its extension (String).
    ///   - completionHandler: RKCallback that will be triggered as soon as process has been completed or failed.
    ///
    public func reverseAsynchronously(dst: Destination = .temp(),
                                      completionHandler: @escaping AsyncProcessCallback) {
        ProcessFactory.sharedInstance.queueReverseAsyncProcess(sourceFile: self,
                                                               dst: dst, completionHandler: completionHandler)
    }

    /// Process an RKAudioFile in background to return an RKAudioFile with appended audio data from another RKAudioFile.
    ///
    /// Completion Handler is function with an RKAudioFile.AsyncProcessCallback signature:
    /// ```
    /// func myCallback(processedFile: RKAudioFile?, error: NSError?) -> Void
    /// ```
    ///
    /// in this callback, you can check that process succeeded by testing processedFile value :
    /// . if processedFile != nil, process succeeded (and error is nil)
    /// . if processedFile == nil, process failed, error is the process thrown error
    ///
    /// Notice that completionHandler will be triggered from a
    /// background thread. Any UI update should be made using:
    ///
    /// ```
    /// dispatch_async(dispatch_get_main_queue()) {
    ///   // UI updates...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - file: an RKAudioFile that will be used to append audio from.
    ///   - dst: where the file will be located, can be set to .Resources, .Documents or .Temp (Default is .Temp)
    ///   - name: the name of the resulting file without its extension (String).
    ///   - completionHandler: RKCallback that will be triggered as soon as process has been completed or failed.
    ///
    public func appendAsynchronously(file: RKAudioFile,
                                     dst: Destination = .temp(),
                                     completionHandler: @escaping AsyncProcessCallback) {
        ProcessFactory.sharedInstance.queueAppendAsyncProcess(sourceFile: self,
                                                              appendedFile: file,
                                                              dst: dst,
                                                              completionHandler: completionHandler)
    }

    /// Process the current RKAudioFile in background to return an RKAudioFile with an extracted range of audio data.
    ///
    /// if "toSample" parameter is set to zero, it will be set to be the number of samples of the file,
    /// so extraction will go from fromSample value to the end of file.
    ///
    /// Completion Handler is function with an RKAudioFile.AsyncProcessCallback signature:
    /// ```
    /// func myCallback(processedFile: RKAudioFile?, error: NSError?) -> Void
    /// ```
    ///
    /// in this callback, you can check that process succeeded by testing processedFile value :
    /// . if processedFile != nil, process succeeded (and error is nil)
    /// . if processedFile == nil, process failed, error is the process thrown error
    ///
    /// Notice that completionHandler will be triggered from a
    /// background thread. Any UI update should be made using:
    ///
    /// ```
    /// dispatch_async(dispatch_get_main_queue()) {
    ///   // UI updates...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - fromSample: the starting sampleFrame for extraction. (default is zero)
    ///   - toSample: the ending sampleFrame for extraction (default is zero)
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp (Default is .temp)
    ///   - name: the name of the resulting file without its extension (String).
    ///   - completionHandler: RKCallback that will be triggered as soon as process has been completed or failed.
    ///
    public func extractAsynchronously(fromSample: Int64 = 0,
                                      toSample: Int64 = 0,
                                      dst: Destination = .temp(),
                                      name: String = "",
                                      completionHandler: @escaping AsyncProcessCallback) {
        ProcessFactory.sharedInstance.queueExtractAsyncProcess(sourceFile: self,
                                                               fromSample: fromSample,
                                                               toSample: toSample,
                                                               dst: dst,
                                                               name: name,
                                                               completionHandler: completionHandler)
    }

    /// Exports Asynchronously to a new RKAudiofile with trimming options.
    ///
    /// Can export from wav/aif/caf to wav/aif/m4a/mp4/caf
    /// Can export from m4a/mp4 to m4a/mp4
    /// Exporting from a compressed format to a PCM format (mp4/m4a to wav/aif/caf) is not supported.
    ///
    /// fromSample and toSample can be set to extract only a portion of the current RKAudioFile.
    /// If toSample is zero, it will be set to the file's duration (no end trimming)
    ///
    /// As soon as callback has been triggered, you can use ExportSession.status to
    /// check if export succeeded or not. If export succeeded, you can get the exported
    /// RKAudioFile using ExportSession.exportedAudioFile. ExportSession.progress
    /// lets you monitor export progress.
    ///
    /// See playground for an example of use.
    ///
    /// - Parameters:
    ///   - name: the name of the exported file without its extension (String).
    ///   - dst: where the file will be located, can be set to .resources,  .documents or .temp
    ///   - ExportFormat: the output file format as an ExportFormat enum value (.aif, .wav, .m4a, .mp4, .caf)
    ///   - fromSample: start range in samples
    ///   - toSample: end range time in samples
    ///   - callback: AsyncProcessCallback function that will be triggered when export completed.
    ///
    public func exportAsynchronously(dst: Destination,
                                     exportFormat: ExportFormat,
                                     fromSample: Int64 = 0,
                                     toSample: Int64 = 0,
                                     callback: @escaping AsyncProcessCallback) {
        // clear this initially
        currentExportSession = nil

        let fromFileExt = fileExt.lowercased()

        // Only mp4, m4a, .wav, .aif can be exported...
        guard ExportFormat.supportedFileExtensions.contains(fromFileExt) else {
            RKLog("ERROR: RKAudioFile \".\(fromFileExt)\" is not supported for export.")
            callback(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil))
            return
        }

        // Compressed formats cannot be exported to PCM
        let fromFileFormatIsCompressed = (fromFileExt == "m4a" || fromFileExt == "mp4")
        let outFileFormatIsCompressed = (exportFormat == .m4a || exportFormat == .mp4)

        // set avExportPreset
        var avExportPreset: String = ""

        if fromFileFormatIsCompressed {
            if !outFileFormatIsCompressed {
                RKLog("ERROR RKAudioFile: cannot export from .\(fileExt) to .\(String(describing: exportFormat))")
                callback(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil))
            } else {
                avExportPreset = AVAssetExportPresetPassthrough
            }
        } else {
            if outFileFormatIsCompressed {
                avExportPreset = AVAssetExportPresetAppleM4A
            } else {
                avExportPreset = AVAssetExportPresetPassthrough
            }
        }

        // In and OUT times trimming settings
        let inFrame: Int64
        let outFrame: Int64

        if toSample == 0 {
            outFrame = samplesCount
        } else {
            outFrame = min(samplesCount, toSample)
        }

        inFrame = abs(min(samplesCount, fromSample))

        if outFrame <= inFrame {
            RKLog("ERROR RKAudioFile export: In time must be less than Out time")

            callback(nil,
                     NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil))

            return
        }

        let asset = url.isFileURL ? AVURLAsset(url: url) : AVURLAsset(url: URL(fileURLWithPath: url.absoluteString))
        if let internalExportSession = AVAssetExportSession(asset: asset, presetName: avExportPreset) {
            RKLog("internalExportSession session created")

            // store a reference to the export session so progress can be checked if desired
            currentExportSession = internalExportSession

            internalExportSession.outputURL = dst.fileUrl

            RKLog("Exporting to", dst.fileUrl)

            // Sets the output file encoding (avoid .wav encoded as m4a...)
            internalExportSession.outputFileType = AVFileType(rawValue: exportFormat.UTI as String as String)

            let startTime = CMTimeMake(value: inFrame, timescale: Int32(sampleRate))
            let stopTime = CMTimeMake(value: outFrame, timescale: Int32(sampleRate))
            let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: stopTime)
            internalExportSession.timeRange = timeRange

            let session = ExportSession(AVAssetExportSession: internalExportSession, callback: callback)

            ExportFactory.queueExportSession(session: session)

        } else {
            RKLog("ERROR export: cannot create AVAssetExportSession")
            callback(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotCreateFile, userInfo: nil))
            return
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // MARK: - ProcessFactory Private class

    // private process factory
    fileprivate class ProcessFactory {
        fileprivate var processIDs = [Int]()
        fileprivate var lastProcessID: Int = 0

        // Singleton
        static let sharedInstance = ProcessFactory()

        // The queue that will be used for background RKAudioFile Async Processing
        fileprivate let processQueue = DispatchQueue(label: "RKAudioFileProcessQueue", attributes: [])

        // Append Normalize Process
        fileprivate func queueNormalizeAsyncProcess(sourceFile: RKAudioFile,
                                                    dst: Destination,
                                                    newMaxLevel: Float,
                                                    completionHandler: @escaping AsyncProcessCallback) {
            let processID = ProcessFactory.sharedInstance.lastProcessID
            ProcessFactory.sharedInstance.lastProcessID += 1
            ProcessFactory.sharedInstance.processIDs.append(processID)

            ProcessFactory.sharedInstance.processQueue.async {
                RKLog("Beginning Normalizing file \"\(sourceFile.fileNamePlusExtension)\" (process #\(processID))")
                var processedFile: RKAudioFile?
                var processError: NSError?
                do {
                    processedFile = try sourceFile.normalized(dst: dst,
                                                              newMaxLevel: newMaxLevel)
                } catch let error as NSError {
                    processError = error
                }
                let lastCompletedProcess = ProcessFactory.sharedInstance.processIDs.removeLast()
                if let file = processedFile {
                    RKLog("Completed Normalizing file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                          "\"\(file.fileNamePlusExtension)\" (process #\(lastCompletedProcess))")
                } else {
                    if let error = processError {
                        RKLog("Failed Normalizing file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                              "Error: \"\(error)\" (process #\(lastCompletedProcess))")
                    } else {
                        RKLog("Failed Normalizing file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                              "Unknown Error (process #\(lastCompletedProcess))")
                        let userInfo: [AnyHashable: Any] = [
                            NSLocalizedDescriptionKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                         value: "An Async Process unknown error occurred",
                                                                         comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                                value: "An Async Process unknown error occurred",
                                                                                comment: "")
                        ]
                        processError = NSError(domain: "RKAudioFile ASync Process Unknown Error",
                                               code: 0,
                                               userInfo: userInfo as? [String: Any])
                    }
                }
                completionHandler(processedFile, processError)
            }
        }

        // Append Reverse Process
        fileprivate func queueReverseAsyncProcess(sourceFile: RKAudioFile,
                                                  dst: Destination,
                                                  completionHandler: @escaping AsyncProcessCallback) {
            let processID = ProcessFactory.sharedInstance.lastProcessID
            ProcessFactory.sharedInstance.lastProcessID += 1
            ProcessFactory.sharedInstance.processIDs.append(processID)

            ProcessFactory.sharedInstance.processQueue.async {
                RKLog("Beginning Reversing file \"\(sourceFile.fileNamePlusExtension)\" (process #\(processID))")
                var processedFile: RKAudioFile?
                var processError: NSError?
                do {
                    processedFile = try sourceFile.reversed(dst: dst)
                } catch let error as NSError {
                    processError = error
                }
                let lastCompletedProcess = ProcessFactory.sharedInstance.processIDs.removeLast()
                if let file = processedFile {
                    RKLog("Completed Reversing file",
                          sourceFile.fileNamePlusExtension, "->",
                          file.fileNamePlusExtension,
                          "(process #\(lastCompletedProcess))")
                } else {
                    if let error = processError {
                        RKLog("Failed Reversing file \"\(sourceFile.fileNamePlusExtension)\" -> " +
                            "Error: \"\(error)\" (process #\(lastCompletedProcess))")
                    } else {
                        RKLog("Failed Reversing file \"\(sourceFile.fileNamePlusExtension)\" -> " +
                            "Unknown Error (process #\(lastCompletedProcess))")
                        let userInfo: [AnyHashable: Any] = [
                            NSLocalizedDescriptionKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                         value: "Ans Async Process unknown error occurred",
                                                                         comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                                value: "Ans Async Process unknown error occurred",
                                                                                comment: "")
                        ]
                        processError = NSError(domain: "RKAudioFile ASync Process Unknown Error",
                                               code: 0,
                                               userInfo: userInfo as? [String: Any])
                    }
                }
                completionHandler(processedFile, processError)
            }
        }

        // Append Append Process
        fileprivate func queueAppendAsyncProcess(sourceFile: RKAudioFile,
                                                 appendedFile: RKAudioFile,
                                                 dst: Destination,
                                                 completionHandler: @escaping AsyncProcessCallback) {
            let processID = ProcessFactory.sharedInstance.lastProcessID
            ProcessFactory.sharedInstance.lastProcessID += 1
            ProcessFactory.sharedInstance.processIDs.append(processID)

            ProcessFactory.sharedInstance.processQueue.async {
                RKLog("Beginning Appending file \"\(sourceFile.fileNamePlusExtension)\" (process #\(processID))")
                var processedFile: RKAudioFile?
                var processError: NSError?
                do {
                    processedFile = try sourceFile.appendedBy(file: appendedFile,
                                                              dst: dst)
                } catch let error as NSError {
                    processError = error
                }
                let lastCompletedProcess = ProcessFactory.sharedInstance.processIDs.removeLast()
                if let file = processedFile {
                    RKLog("Completed Appending file \"\(sourceFile.fileNamePlusExtension)\" ->",
                          "\"\(file.fileNamePlusExtension)\" (process #\(lastCompletedProcess))")
                } else {
                    if let error = processError {
                        RKLog("Failed Appending file \"\(sourceFile.fileNamePlusExtension)\" ->",
                              "Error: \"\(error)\" (process #\(lastCompletedProcess))")
                    } else {
                        RKLog("Failed Appending file \"\(sourceFile.fileNamePlusExtension)\" ->",
                              "Unknown Error (process #\(lastCompletedProcess))")
                        let userInfo: [AnyHashable: Any] = [
                            NSLocalizedDescriptionKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                         value: "Ans Async Process unknown error occurred",
                                                                         comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                                value: "Ans Async Process unknown error occurred",
                                                                                comment: "")
                        ]
                        processError = NSError(domain: "RKAudioFile ASync Process Unknown Error",
                                               code: 0,
                                               userInfo: userInfo as? [String: Any])
                    }
                }
                completionHandler(processedFile, processError)
            }
        }

        // Queue extract Process
        fileprivate func queueExtractAsyncProcess(sourceFile: RKAudioFile,
                                                  fromSample: Int64 = 0,
                                                  toSample: Int64 = 0,
                                                  dst: Destination,
                                                  name: String,
                                                  completionHandler: @escaping AsyncProcessCallback) {
            let processID = ProcessFactory.sharedInstance.lastProcessID
            ProcessFactory.sharedInstance.lastProcessID += 1
            ProcessFactory.sharedInstance.processIDs.append(processID)

            ProcessFactory.sharedInstance.processQueue.async {
                RKLog("Beginning Extracting from file \"\(sourceFile.fileNamePlusExtension)\" (process #\(processID))")
                var processedFile: RKAudioFile?
                var processError: NSError?
                do {
                    processedFile = try sourceFile.extracted(fromSample: fromSample,
                                                             toSample: toSample,
                                                             dst: dst,
                                                             name: name)
                } catch let error as NSError {
                    processError = error
                }
                let lastCompletedProcess = ProcessFactory.sharedInstance.processIDs.removeLast()
                if let file = processedFile {
                    RKLog("Completed Extracting from file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                          "\"\(file.fileNamePlusExtension)\" (process #\(lastCompletedProcess))")
                } else {
                    if let error = processError {
                        RKLog("Failed Extracting from file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                              "Error: \"\(error)\" (process #\(lastCompletedProcess))")
                    } else {
                        RKLog("Failed Extracting from file \"\(sourceFile.fileNamePlusExtension)\" -> ",
                              "Unknown Error (process #\(lastCompletedProcess))")
                        let userInfo: [AnyHashable: Any] = [
                            NSLocalizedDescriptionKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                         value: "Ans Async Process unknown error occurred",
                                                                         comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("RKAudioFile ASync Process Unknown Error",
                                                                                value: "Ans Async Process unknown error occurred",
                                                                                comment: "")
                        ]
                        processError = NSError(domain: "RKAudioFile ASync Process Unknown Error",
                                               code: 0,
                                               userInfo: userInfo as? [String: Any])
                    }
                }
                completionHandler(processedFile, processError)
            }
        }

        fileprivate var queuedProcessCount: Int {
            return processIDs.count
        }

        fileprivate var scheduledProcessesCount: Int {
            return lastProcessID
        }
    }

    // MARK: - ExportFactory Private classes

    // private ExportSession wraps an AVAssetExportSession with an id and the completion callback
    fileprivate class ExportSession {
        fileprivate var avAssetExportSession: AVAssetExportSession
        fileprivate var id: Int
        fileprivate var callback: AsyncProcessCallback

        fileprivate init(AVAssetExportSession avAssetExportSession: AVAssetExportSession,
                         callback: @escaping AsyncProcessCallback) {
            self.avAssetExportSession = avAssetExportSession
            self.callback = callback
            id = ExportFactory.lastExportSessionID
            ExportFactory.lastExportSessionID += 1
        }
    }

    // Export Factory is a singleton that handles Export Sessions serially
    fileprivate class ExportFactory {
        fileprivate static var exportSessions = [Int: ExportSession]()
        fileprivate static var lastExportSessionID: Int = 0
        fileprivate static var isExporting = false
        fileprivate static var currentExportProcessID: Int = 0

        // Singleton
        static let sharedInstance = ExportFactory()

        fileprivate static func completionHandler() {
            if let session = exportSessions[currentExportProcessID] {
                switch session.avAssetExportSession.status {
                case AVAssetExportSession.Status.failed:
                    session.callback(nil, session.avAssetExportSession.error as NSError?)
                case AVAssetExportSession.Status.cancelled:
                    session.callback(nil, session.avAssetExportSession.error as NSError?)
                default:
                    if let outputURL = session.avAssetExportSession.outputURL {
                        do {
                            let audiofile = try RKAudioFile(forReading: outputURL)
                            session.callback(audiofile, nil)
                        } catch let error as NSError {
                            session.callback(nil, error)
                        }
                    } else {
                        RKLog("ERROR RKAudioFile export: outputURL is nil")
                        session.callback(nil,
                                         NSError(domain: NSURLErrorDomain,
                                                 code: NSURLErrorCannotCreateFile,
                                                 userInfo: nil))
                    }
                }
                RKLog("ExportFactory: session #\(session.id) Completed")
                exportSessions.removeValue(forKey: currentExportProcessID)
                if !exportSessions.isEmpty {
                    // currentExportProcessID = exportSessions.first!.0
                    currentExportProcessID += 1
                    RKLog("ExportFactory: exporting session #\(currentExportProcessID)")
                    exportSessions[currentExportProcessID]!.avAssetExportSession.exportAsynchronously(completionHandler: completionHandler)

                } else {
                    isExporting = false
                    RKLog("ExportFactory: All exports have been completed")
                }
            } else {
                RKLog("ExportFactory: Error : sessionId: \(currentExportProcessID) doesn't exist")
            }
        }

        // Append the exportSession to the ExportFactory Export Queue
        fileprivate static func queueExportSession(session: ExportSession) {
            exportSessions[session.id] = session

            if !isExporting {
                isExporting = true
                currentExportProcessID = session.id
                RKLog("ExportFactory: exporting session #\(session.id)")
                exportSessions[currentExportProcessID]!.avAssetExportSession.exportAsynchronously(completionHandler: completionHandler)
            } else {
                RKLog("ExportFactory: is busy")
                RKLog("ExportFactory: Queuing session #\(session.id)")
            }
        }
    }
}
