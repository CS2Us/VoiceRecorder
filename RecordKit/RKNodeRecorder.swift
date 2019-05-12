//
//  RKNodeRecorder.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/11.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

public class RKNodeRecorder: RKObject {
	public var engine = RecordKit.engine
	
	// The node we record from
	open var node: RKNode?
	
	// The file to record to
	fileprivate var internalAudioFile: RKAudioFile
	
	/// Used for fixing recordings being truncated
	fileprivate var recordBufferDuration: Double = 16_384 / RKSettings.sampleRate
	
	/// return the RKAudioFile for reading
	open var audioFile: RKAudioFile? {
		do {
			return try RKAudioFile(forReading: internalAudioFile.url)
			
		} catch let error as NSError {
			RKLog("Cannot create internal audio file for reading")
			RKLog("Error: \(error.localizedDescription)")
			return nil
		}
	}
	
	/// True if we are recording.
	@objc public private(set) dynamic var isRecording = false
	
	/// An optional duration for the recording to auto-stop when reached
	open var durationToRecord: Double = 0
	
	/// Duration of recording
	open var recordedDuration: Double {
		return internalAudioFile.duration
	}
	
	// MARK: - Initialization
	
	/// Initialize the node recorder
	///
	/// Recording buffer size is defaulted to be RKSettings.bufferLength
	/// You can set a different value by setting an RKSettings.recordingBufferLength
	///
	/// - Parameters:
	///   - node: Node to record from
	///   - file: Audio file to record to
	///
	public init(node: RKNode? = RecordKit.output,
				file: RKAudioFile? = nil) throws {
		
		// AVAudioSession buffer setup
		
		guard let existingFile = file else {
			// We create a record file in temp directory
			do {
				internalAudioFile = try RKAudioFile()
			} catch let error as NSError {
				RKLog("RKNodeRecorder Error: Cannot create an empty audio file")
				throw error
			}
			self.node = node
			return
		}
		
		do {
			// We initialize RKAudioFile for writing (and check that we can write to)
			internalAudioFile = try RKAudioFile(forWriting: existingFile.url,
												settings: existingFile.fileFormat.settings)
		} catch let error as NSError {
			RKLog("RKNodeRecorder Error: cannot write to \(existingFile.fileNamePlusExtension)")
			throw error
		}
		
		self.node = node
	}
	
	// MARK: - Methods
	
	/// Start recording
	@objc open func record() {
		if isRecording == true {
			RKLog("RKNodeRecorder Warning: already recording")
			return
		}
		
		guard let node = node else {
			RKLog("RKNodeRecorder Error: input node is not available")
			return
		}
		
		let recordingBufferLength: AVAudioFrameCount = RKSettings.bufferLength.samplesCount
		isRecording = true
		
		RKLog("RKNodeRecorder: recording")
		node.avAudioUnitOrNode.installTap(
			onBus: 0,
			bufferSize: recordingBufferLength,
			format: RKSettings.audioFormat) { [weak self] (buffer: AVAudioPCMBuffer!, _) -> Void in
				guard let strongSelf = self else {
					RKLog("Error: self is nil")
					return
				}
				
				do {
					strongSelf.recordBufferDuration = Double(buffer.frameLength) / RKSettings.sampleRate
					try strongSelf.internalAudioFile.write(from: buffer)
					//RKLog("RKNodeRecorder writing (file duration: \(strongSelf.internalAudioFile.duration) seconds)")
					
					// allow an optional timed stop
					if strongSelf.durationToRecord != 0 && strongSelf.internalAudioFile.duration >= strongSelf.durationToRecord {
						strongSelf.stop()
					}
					
				} catch let error as NSError {
					RKLog("Write failed: error -> \(error.localizedDescription)")
				}
		}
	}
	
	/// Stop recording
	@objc open func stop() {
		if isRecording == false {
			RKLog("RKNodeRecorder Warning: Cannot stop recording, already stopped")
			return
		}
		
		isRecording = false
		
		if RKSettings.fixTruncatedRecordings {
			//  delay before stopping so the recording is not truncated.
			let delay = UInt32(recordBufferDuration * 1_000_000)
			usleep(delay)
		}
		node?.avAudioUnitOrNode.removeTap(onBus: 0)
	}
	
	/// Reset the RKAudioFile to clear previous recordings
	open func reset() throws {
		
		// Stop recording
		if isRecording == true {
			stop()
		}
		
		// Delete the physical recording file
		let fileManager = FileManager.default
		let settings = internalAudioFile.processingFormat.settings
		let url = internalAudioFile.url
		
		do {
			if let path = audioFile?.url.path {
				try fileManager.removeItem(atPath: path)
			}
		} catch let error as NSError {
			RKLog("Error: Can't delete", audioFile?.fileNamePlusExtension ?? "nil", error.localizedDescription)
		}
		
		// Creates a blank new file
		do {
			internalAudioFile = try RKAudioFile(forWriting: url, settings: settings)
			RKLog("RKNodeRecorder: file has been cleared")
		} catch let error as NSError {
			RKLog("Error: Can't record to", internalAudioFile.fileNamePlusExtension)
			throw error
		}
	}
}
