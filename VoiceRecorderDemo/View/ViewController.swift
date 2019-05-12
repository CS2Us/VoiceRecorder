//
//  AppDelegate.swift
//  Recorder
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import UIKit
import RecordKit

class ViewController: UIViewController {

    var state = State.readyToRecord
	private lazy var player: RKPlayer = {
		return RecordKit.rb.player
	}()
	private lazy var mic: RKMicrophone = {
		return RecordKit.rb.mic
	}()
	private lazy var recorder: RKNodeRecorder = {
		return RecordKit.rb.recorder
	}()
	private lazy var moogLadder: RKMoogLadder = {
		return RecordKit.rb.moogLadder
	}()

	private var plot: RKNodeOutputPlot = RKNodeOutputPlot()
	@IBOutlet private weak var plotHolder: UIView!
	
	@IBOutlet private weak var infoLabel: UILabel!
	@IBOutlet private weak var resetButton: UIButton!
	@IBOutlet private weak var mainButton: UIButton!
	@IBOutlet private weak var tempButton: UIButton!
	
	private lazy var frequencySlider: RKSlider = {
		let slider = RKSlider(property: "Frequency")
		slider.value = 0
		slider.color = .cyan // $ac7061
		slider.textColor = .white
		return slider
	}()
	@IBOutlet private weak var frequencySliderHolder: UIView!
	
	private lazy var resonanceSlider: RKSlider = {
		let slider = RKSlider(property: "Resonance")
		slider.value = 0
		slider.color = .cyan
		slider.textColor = .white
		return slider
	}()
	@IBOutlet private weak var resonanceSliderHolder: UIView!
	
	@IBOutlet private weak var loopButton: UIButton!
	@IBOutlet private weak var moogLadderTitle: UILabel!

    enum State {
        case readyToRecord
        case recording
        case readyToPlay
        case playing

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		plotHolder.addSubview(plot)
		frequencySliderHolder.addSubview(frequencySlider)
		resonanceSliderHolder.addSubview(resonanceSlider)
		plot.node = mic
		setupButtonNames()
		setupUIForRecording()
	}

    // CallBack triggered when playing has ended
    // Must be seipatched on the main queue as completionHandler
    // will be triggered by a background thread
    func playingEnded() {
        DispatchQueue.main.async {
            self.setupUIForPlaying ()
        }
    }
	
	@IBAction func tempButtonTouched(sender: UIButton) {
		tempButton.isSelected = !tempButton.isSelected
		if tempButton.isSelected {
			tempButton.setTitle("Resume", for: .normal)
			RecordKit.recordStop()
		} else {
			tempButton.setTitle("Stop", for: .normal)
			RecordKit.recordResume()
		}
	}

    @IBAction func mainButtonTouched(sender: UIButton) {
        switch state {
        case .readyToRecord :
            infoLabel.text = "Recording"
            mainButton.setTitle("Endup", for: .normal)
			tempButton.setTitle("Stop", for: .normal)
			tempButton.isEnabled = true
            state = .recording
            RecordKit.recordStart()
        case .recording :
			RecordKit.recordCancle()
			setupUIForPlaying()
        case .readyToPlay :
            player.play()
            infoLabel.text = "Playing..."
            mainButton.setTitle("Endup", for: .normal)
			tempButton.setTitle("Not in Work", for: .normal)
			tempButton.isEnabled = false
            state = .playing
            plot.node = player

        case .playing :
            player.stop()
            setupUIForPlaying()
            plot.node = mic
        }
    }

    struct Constants {
        static let empty = ""
    }

    func setupButtonNames() {
        resetButton.setTitle(Constants.empty, for: UIControl.State.disabled)
        mainButton.setTitle(Constants.empty, for: UIControl.State.disabled)
        loopButton.setTitle(Constants.empty, for: UIControl.State.disabled)
    }

    func setupUIForRecording () {
        state = .readyToRecord
        infoLabel.text = "Ready to record"
        mainButton.setTitle("Record", for: .normal)
        resetButton.isEnabled = false
        resetButton.isHidden = true
        setSliders(active: false)
    }

    func setupUIForPlaying () {
        let recordedDuration = player.audioFile?.duration
        infoLabel.text = "Recorded: \(String(format: "%0.1f", recordedDuration!)) seconds"
        mainButton.setTitle("Play", for: .normal)
        state = .readyToPlay
        resetButton.isHidden = false
        resetButton.isEnabled = true
        setSliders(active: true)
        moogLadder.cutoffFrequency = frequencySlider.range.upperBound
        frequencySlider.value = moogLadder.cutoffFrequency
        resonanceSlider.value = moogLadder.resonance
    }

    func setSliders(active: Bool) {
        loopButton.isEnabled = active
        moogLadderTitle.isEnabled = active
        frequencySlider.callback = updateFrequency
        frequencySlider.isHidden = !active
        resonanceSlider.callback = updateResonance
        resonanceSlider.isHidden = !active
        frequencySlider.range = 10 ... 20_000
        frequencySlider.taper = 3
        moogLadderTitle.text = active ? "Moog Ladder Filter" : Constants.empty
    }

    @IBAction func loopButtonTouched(sender: UIButton) {

        if player.isLooping {
            player.isLooping = false
            sender.setTitle("Loop is Off", for: .normal)
        } else {
            player.isLooping = true
            sender.setTitle("Loop is On", for: .normal)

        }

    }
    @IBAction func resetButtonTouched(sender: UIButton) {
        player.stop()
        plot.node = mic
        do {
            try recorder.reset()
        } catch { print("Errored resetting.") }

        //try? player.replaceFile((recorder.audioFile)!)
        setupUIForRecording()
    }

    func updateFrequency(value: Double) {
        moogLadder.cutoffFrequency = value
        frequencySlider.property = "Frequency"
        frequencySlider.format = "%0.0f"
    }

    func updateResonance(value: Double) {
        moogLadder.resonance = value
        resonanceSlider.property = "Resonance"
        resonanceSlider.format = "%0.3f"
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		plot.frame = plotHolder.bounds
		frequencySlider.frame = frequencySliderHolder.bounds
		resonanceSlider.frame = resonanceSliderHolder.bounds
	}
}
