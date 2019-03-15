//
//  VoicePresenter.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/14.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import BonMot
import RecordKit

fileprivate let maxPreferContentHeight: CGFloat = UIScreen.main.bounds.height - 20
fileprivate let initialPreferContentHeight: CGFloat = 120
fileprivate let recordPreferContentHeight: CGFloat = 120
fileprivate let wavePreferContentHeight: CGFloat = 100
fileprivate let infoPreferContentHeight: CGFloat = 60

class AudioViewController: UIViewController {
	private var maskVc: MaskViewController = MaskViewController()
	private var mainVc: MainViewController = MainViewController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initComponent()
	}
	
	private func initComponent() {
		addChild(maskVc)
		addChild(mainVc)
		view.addSubview(maskVc.view)
		view.addSubview(mainVc.view)
		
		mainVc.view.layer.cornerRadius = 6
		mainVc.view.layer.masksToBounds = true
		mainVc.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		mainVc.view.backgroundColor = UIColor.white.withAlphaComponent(0.94)
	}
}

fileprivate class MaskViewController: UIViewController {
	var audioDidUpdate: ((AudioRecordUpdateNotification.UpdateInfo?) -> ())?
	var audioDidFinish: ((AudioRecordFinishNotification.FinishInfo?) -> ())?
	var audioDidFail: ((AudioRecordFailNotification.FailInfo?) -> ())?
	
	private lazy var maskView: UIView = {
		let maskView = UIView(frame: UIScreen.main.bounds)
		maskView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		maskView.isHidden = true
		return maskView
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(maskView)
		audioDidUpdate = { [weak self] _ in self?.maskView.isHidden = false }
		audioDidFail = { [weak self] _ in self?.maskView.isHidden = true }
		audioDidFinish = { [weak self] _ in self?.maskView.isHidden = true }
	}
}

fileprivate class MainViewController: UIViewController {
	private let recordButton: UIButton = UIButton(frame: .zero)
	private let rollingOutputView: RollingOutputView = RollingOutputView()
	private let infoView: (container: UIView, recordTypeLabel: UILabel, recordTimeLabel: UILabel) = (UIView(), UILabel(), UILabel())
	private let visualBlurView: UIVisualEffectView = UIVisualEffectView(frame: .zero)
	private var meterDisplayLink: CADisplayLink?
	private lazy var panViewGesture: UIPanGestureRecognizer = {
		let panGesture = UIPanGestureRecognizer()
		panGesture.addTarget(self, action: #selector(panViewGesture(sender:)))
		panGesture.maximumNumberOfTouches = 1
		return panGesture
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initComponent()
		initObserver()
	}
	
	private func initComponent() {
		view.addSubview(visualBlurView)
		view.addSubview(recordButton)
		view.addSubview(rollingOutputView)
		view.addSubview(infoView.container)
		
		func initVisualBlurView() {
			visualBlurView.effect = UIBlurEffect(style: .light)
//			visualBlurView.alpha = 0.6
			visualBlurView.frame = view.bounds
		}
		
		func initRecordButton() {
			recordButton.setImage(UIImage(named: "start_record"), for: .normal)
			recordButton.setImage(UIImage(named: "stop_record"), for: .selected)
			recordButton.layer.cornerRadius = 40
			recordButton.layer.masksToBounds = true
			recordButton.addTarget(self, action: #selector(clickRecordButton), for: .touchDown)
		}
		
		func initrollingOutputView() {
			rollingOutputView.backgroundColor = UIColor.clear
		}
		
		func initInfoView() {
			let recordTypeLabel = infoView.recordTypeLabel
			let recordTimeLabel = infoView.recordTimeLabel
			infoView.container.addSubview(recordTypeLabel)
			infoView.container.addSubview(recordTimeLabel)
			recordTimeLabel.do {
				$0.translatesAutoresizingMaskIntoConstraints = false
				$0.textAlignment = .center
				let c0Style = StringStyle([.font(UIFont.pingFangSCRegular(fontSize: 14)),
											  .color(UIColor.Gray.c0)])
				let c2Style = StringStyle([.font(UIFont.pingFangSCRegular(fontSize: 13)),
											.color(UIColor.Gray.c2)])
				let finalStyle = StringStyle(.xmlRules([
					.style("c0", c0Style),
					.style("c2", c2Style)]))
				$0.attributedText = "<c0>65秒</c0> <c2>/ 120秒</c2>".styled(with: finalStyle)
				
			}
			recordTypeLabel.do {
				$0.translatesAutoresizingMaskIntoConstraints = false
				$0.textColor = UIColor.Gray.c0
				$0.font = UIFont.pingFangSCRegular(fontSize: 18)
				$0.textAlignment = .center
				$0.text = "录音中"
			}

			let views = ["recordTypeLabel":recordTypeLabel, "recordTimeLabel":recordTimeLabel]
			let metrics = ["padding":5]
			var constraints = [NSLayoutConstraint]()
			
			constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(padding)-[recordTypeLabel]-(padding)-[recordTimeLabel]-|", options: [], metrics: metrics, views: views))
			constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-[recordTypeLabel]-|", options: [], metrics: metrics, views: views))
			constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-[recordTimeLabel]-|", options: [], metrics: metrics, views: views))
			
			infoView.container.addConstraints(constraints)
		}
		
		initVisualBlurView()
		initRecordButton()
		initrollingOutputView()
		initInfoView()
		
		recordButton.translatesAutoresizingMaskIntoConstraints = false
		rollingOutputView.translatesAutoresizingMaskIntoConstraints = false
		infoView.container.translatesAutoresizingMaskIntoConstraints = false
		
		let views = ["recordButton":recordButton, "rollingOutputView":rollingOutputView, "infoView":infoView.container]
		let metrics = ["padding":15, "recordButtonHeight":80, "recordButtonWidth":80, "recordButtonBottomToViewBottom":15, "infoViewHeight":infoPreferContentHeight, "infoViewTopToViewTop":20]
		var constraints = [NSLayoutConstraint]()
		
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(<=infoViewTopToViewTop)-[infoView(==infoViewHeight)]-(padding@750)-[rollingOutputView]-(padding@750)-[recordButton(==recordButtonHeight)]-(recordButtonBottomToViewBottom)-|", options: [], metrics: metrics, views: views))
		/** recordButton **/
		constraints.append(NSLayoutConstraint(item: recordButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[recordButton(==80)]", options: [], metrics: metrics, views: views))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[rollingOutputView]|", options: [], metrics: metrics, views: views))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[infoView]|", options: [], metrics: metrics, views: views))
		
		rollingOutputView.setContentHuggingPriority(.defaultLow, for: .vertical)
		rollingOutputView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
		
		view.addConstraints(constraints)
		view.addGestureRecognizer(panViewGesture)
	}
	
	private func initObserver() {
	}
	
	override func willMove(toParent parent: UIViewController?) {
		super.willMove(toParent: parent)
		guard let parent = parent else { return }
		let origin = CGPoint(x: 0, y: parent.view.frame.maxY - initialPreferContentHeight)
		let size = CGSize(width: parent.view.bounds.width, height: initialPreferContentHeight)
		view.frame = CGRect(origin: origin, size: size)
	}
	
	@IBAction private func panViewGesture(sender: UIPanGestureRecognizer) {
		let translation = sender.translation(in: view)
		let origin = CGPoint(x: 0, y: view.frame.minY + translation.y)
		let size = CGSize(width: view.bounds.width, height: view.superview!.frame.maxY - origin.y)
		if size.height >= maxPreferContentHeight { return }
		if size.height <= initialPreferContentHeight + wavePreferContentHeight + infoPreferContentHeight {
			
		} else {
			view.frame = CGRect(origin: origin, size: size)
		}
		sender.setTranslation(.zero, in: nil)
	}
	
	@IBAction private func clickRecordButton() {
		recordButton.isSelected = !recordButton.isSelected
		if recordButton.isSelected {
			RecordKit.default.recordStart(destinationURL: .documents(url: "VoiceOutput.m4a"), outputFileType: kAudioFileM4AType, outputFormat: kAudioFormatMPEG4AAC)
			UIView.animate(withDuration: 0.3, animations: {
				let origin = CGPoint(x: 0, y: self.view.frame.maxY - recordPreferContentHeight - wavePreferContentHeight - infoPreferContentHeight)
				let size = CGSize(width: self.view.bounds.width, height: self.view.frame.maxY - origin.y)
				self.view.frame = CGRect(origin: origin, size: size)
				self.view.setNeedsLayout()
				self.view.layoutIfNeeded()
			})
		} else {
			RecordKit.default.recordEndup()
			UIView.animate(withDuration: 0.3, animations: {
				let origin = CGPoint(x: 0, y: self.view.frame.maxY - initialPreferContentHeight)
				let size = CGSize(width: self.view.bounds.width, height: initialPreferContentHeight)
				self.view.frame = CGRect(origin: origin, size: size)
				self.view.setNeedsLayout()
				self.view.layoutIfNeeded()
			})
		}
	}
}
