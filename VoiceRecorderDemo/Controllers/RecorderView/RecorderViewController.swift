//
//  RecordViewController.swift
//  VoiceMemosClone
//
//  Created by Hassan El Desouky on 1/12/19.
//  Copyright © 2019 Hassan El Desouky. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate
import RecordKit

enum RecorderState {
    case recording
    case stopped
    case denied
}

protocol RecorderViewControllerDelegate: class {
    func didStartRecording()
    func didFinishRecording()
}

let keyID = "key"

class RecorderViewController: UIViewController {

    //MARK:- Properties
    var handleView = UIView()
    var recordButton = RecordButton()
    var timeLabel = UILabel()
    var audioView = AudioVisualizerView()
    let settings = [AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: true, AVSampleRateKey: Float64(44100), AVNumberOfChannelsKey: 1] as [String : Any]
    let audioEngine = AVAudioEngine()
    private var renderTs: Double = 0
    private var recordingTs: Double = 0
    private var silenceTs: Double = 0
    private var audioFile: AVAudioFile?
    weak var delegate: RecorderViewControllerDelegate?
    
    //MARK:- Outlets
    @IBOutlet weak var fadeView: UIView!

    //MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHandelView()
        setupRecordingButton()
        setupTimeLabel()
        setupAudioView()
		
		initObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let notificationName = AVAudioSession.interruptionNotification
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecording(_:)), name: notificationName, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
	
	fileprivate func initObserver() {
		Broadcaster.register(RKMicrophoneHandle.self, observer: self)
	}
    
    //MARK:- Setup Methods
    fileprivate func setupHandelView() {
        handleView.layer.cornerRadius = 2.5
        handleView.backgroundColor = UIColor(r: 208, g: 207, b: 205)
        view.addSubview(handleView)
        handleView.translatesAutoresizingMaskIntoConstraints = false
        handleView.widthAnchor.constraint(equalToConstant: 37.5).isActive = true
        handleView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        handleView.alpha = 0
    }
    
    fileprivate func setupRecordingButton() {
        recordButton.isRecording = false
        recordButton.addTarget(self, action: #selector(handleRecording(_:)), for: .touchUpInside)
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 65 ).isActive = true
    }
    
    fileprivate func setupTimeLabel() {
        view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -16).isActive = true
        timeLabel.text = "00.00"
        timeLabel.textColor = .gray
        timeLabel.alpha = 0
    }
    
    fileprivate func setupAudioView() {
        audioView.frame = CGRect(x: 0, y: 24, width: view.frame.width, height: 135)
        view.addSubview(audioView)
        //TODO: Add autolayout constraints
        audioView.alpha = 0
        audioView.isHidden = true
    }
    
    //MARK:- Actions
    @objc func handleRecording(_ sender: RecordButton) {
        var defaultFrame: CGRect = CGRect(x: 0, y: 24, width: view.frame.width, height: 135)
        if recordButton.isRecording {
            defaultFrame = self.view.frame
            audioView.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.handleView.alpha = 1
                self.timeLabel.alpha = 1
                self.audioView.alpha = 1
                self.view.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.bounds.width, height: -300)
                self.view.layoutIfNeeded()
            }, completion: nil)
            self.checkPermissionAndRecord()
        } else {
            audioView.isHidden = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.handleView.alpha = 0
                self.timeLabel.alpha = 0
                self.audioView.alpha = 0
                self.view.frame = defaultFrame
                self.view.layoutIfNeeded()
            }, completion: nil)
            self.stopRecording()
        }
    }
    
    //MARK:- Update User Interface
    private func updateUI(_ recorderState: RecorderState) {
        switch recorderState {
        case .recording:
            UIApplication.shared.isIdleTimerDisabled = true
            self.audioView.isHidden = false
            self.timeLabel.isHidden = false
            break
        case .stopped:
            UIApplication.shared.isIdleTimerDisabled = false
            self.audioView.isHidden = true
            self.timeLabel.isHidden = true
            break
        case .denied:
            UIApplication.shared.isIdleTimerDisabled = false
            self.recordButton.isHidden = true
            self.audioView.isHidden = true
            self.timeLabel.isHidden = true
            break
        }
    }


    // MARK:- Recording
    private func startRecording() {
        if let d = self.delegate {
            d.didStartRecording()
        }
        
        self.recordingTs = NSDate().timeIntervalSince1970
        self.silenceTs = 0
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }

		RecordKit.default.recordStart(destinationURL: .documents(url: "VoiceOutput.m4a"), outputFileType: kAudioFileM4AType, outputFormat: kAudioFormatMPEG4AAC)
        self.updateUI(.recording)
    }
    
    private func stopRecording() {
        if let d = self.delegate {
            d.didFinishRecording()
        }
		
		RecordKit.default.recordCancle()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch  let error as NSError {
            print(error.localizedDescription)
            return
        }
        self.updateUI(.stopped)
    }
    
    private func checkPermissionAndRecord() {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (result) in
                DispatchQueue.main.async {
                    if result {
                        self.startRecording()
                    }
                    else {
                        self.updateUI(.denied)
                    }
                }
            })
            break
        case .granted:
            self.startRecording()
            break
        case .denied:
            self.updateUI(.denied)
            break
        }
    }
    
    private func isRecording() -> Bool {
        return RecordKit.default.isRecording
    }
    
    // MARK:- Handle interruption
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let key = userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber
            else { return }
        if key.intValue == 1 {
            DispatchQueue.main.async {
                if self.isRecording() {
                    self.stopRecording()
                }
            }
        }
    }
    
}

extension RecorderViewController: RKMicrophoneHandle {
	func microphoneWorking(_ microphone: RKMicrophone, bufferList: UnsafePointer<AudioBufferList>, numberOfFrames: UInt32) {
		let level: Float = -50
		let length: UInt32 = 1024
		
		guard let floatBuffers: UnsafeMutablePointer<UnsafeMutablePointer<Float>?> = {
			let floatConverter = EZAudioFloatConverter(inputFormat: microphone.inputFormat.asbd)
			let floatBuffers = EZAudioUtilities.floatBuffers(withNumberOfFrames: length, numberOfChannels: microphone.inputFormat.channelCount)
			floatConverter?.convertData(from: UnsafeMutablePointer<AudioBufferList>(mutating: bufferList), withNumberOfFrames: numberOfFrames, toFloatBuffers: floatBuffers)
			return floatBuffers
			}(), let floatData: UnsafePointer<Float> = UnsafePointer(floatBuffers[0]) else { return }
		
		var value: Float = 0
		vDSP_meamgv(floatData, 1, &value, vDSP_Length(length))
		var average: Float = ((value == 0) ? -100 : 20.0 * log10f(value))
		if average > 0 {
			average = 0
		} else if average < -100 {
			average = -100
		}
		let silent = average < level
		let ts = NSDate().timeIntervalSince1970
		if ts - self.renderTs > 0.1 {
			let floats = UnsafeBufferPointer(start: floatData, count: Int(bufferList.pointee.mNumberBuffers))
			let frame = floats.map({ (f) -> Int in
				return Int(f * Float(Int16.max))
			})
			DispatchQueue.main.async {
				let seconds = (ts - self.recordingTs)
				self.timeLabel.text = seconds.toTimeString
				self.renderTs = ts
				let len = self.audioView.waveforms.count
				for i in 0 ..< len {
					let idx = ((frame.count - 1) * i) / len
					let f: Float = sqrt(1.5 * abs(Float(frame[idx])) / Float(Int16.max))
					self.audioView.waveforms[i] = min(49, Int(f * 50))
				}
				self.audioView.active = !silent
				self.audioView.setNeedsDisplay()
			}
		}
	}
}
