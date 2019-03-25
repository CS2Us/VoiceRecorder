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
import RecordKit

fileprivate let maxPreferContentHeight: CGFloat = UIScreen.main.bounds.height - 20
fileprivate let initialPreferContentHeight: CGFloat = 120
fileprivate let recordPreferContentHeight: CGFloat = 120
fileprivate let wavePreferContentHeight: CGFloat = 100
fileprivate let infoPreferContentHeight: CGFloat = 60

class AudioViewController: UIViewController {
	private var maskVc: MaskViewController = MaskViewController()
	private var mainVc: MainViewController = MainViewController()
	private var asrer: RKASRer = RKASRer.asrer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initComponent()
		initObserver()
//		let path = Destination.main(name: "ASRTempFile_1553139209", type: "wav").url
//		try? asrer.fileRecognition(Destination.main(name: "ASRTempFile_1553139209", type: "wav"))
	}
	
	private func initComponent() {
		addChild(maskVc)
		addChild(mainVc)
		view.addSubview(maskVc.view)
		view.addSubview(mainVc.view)
		
		mainVc.view.layer.cornerRadius = 6
		mainVc.view.layer.masksToBounds = true
//		mainVc.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		mainVc.view.backgroundColor = UIColor.white.withAlphaComponent(0.94)
	}
	
	private func initObserver() {
		Broadcaster.register(RKASRerHandle.self, observer: self)
	}
}

fileprivate class MaskViewController: UIViewController {
	private lazy var maskView: UIView = {
		let maskView = UIView(frame: UIScreen.main.bounds)
		maskView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		maskView.isHidden = true
		return maskView
	}()
	private lazy var button: UIButton = {
		let button = UIButton(type: .custom)
		button.addTarget(self, action: #selector(testFileRecoginition), for: .touchDown)
		button.setTitle("Test File Recognition", for: .normal)
		button.setTitleColor(UIColor.red, for: .normal)
		button.layer.borderColor = UIColor.red.cgColor
		button.layer.borderWidth = 1
		return button
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(maskView)
		view.addSubview(button)
		button.frame = CGRect(x: 180, y: 300, width: 240, height: 60)
	}
	
	@IBAction func testFileRecoginition() {
		button.isSelected = !button.isSelected
		if button.isSelected {
			ImportExternalFileService.shared.importRecordFile(url: Destination.main(name: "ASRTempFile_1553133607", type: "wav").url)
		} else {
			ImportExternalFileService.shared.disposeImport()
		}
	}
}

fileprivate class MainViewController: UIViewController {
	private let recordButton: UIButton = UIButton(frame: .zero)
	private let rollingOutputView: RollingOutputView = RollingOutputView(frame: .zero)
	private let infoView: (container: UIView, recordTypeLabel: UILabel, recordTimeLabel: UILabel) = (UIView(), UILabel(), UILabel())
	private let visualBlurView: UIVisualEffectView = UIVisualEffectView(frame: .zero)
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
		
		func initRollingOutputView() {
//			rollingOutputView.backgroundColor = UIColor.red
		}
		
		func initInfoView() {
			let recordTypeLabel = infoView.recordTypeLabel
			let recordTimeLabel = infoView.recordTimeLabel
			infoView.container.addSubview(recordTypeLabel)
			infoView.container.addSubview(recordTimeLabel)
//			recordTimeLabel.do {
//				$0.translatesAutoresizingMaskIntoConstraints = false
//				$0.textAlignment = .center
//				let c0Style = StringStyle([.font(UIFont.pingFangSCRegular(fontSize: 14)),
//											  .color(UIColor.Gray.c0)])
//				let c2Style = StringStyle([.font(UIFont.pingFangSCRegular(fontSize: 13)),
//											.color(UIColor.Gray.c2)])
//				let finalStyle = StringStyle(.xmlRules([
//					.style("c0", c0Style),
//					.style("c2", c2Style)]))
//				$0.attributedText = "<c0>65秒</c0> <c2>/ 120秒</c2>".styled(with: finalStyle)
				
//			}
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
		initRollingOutputView()
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
		Broadcaster.register(RKMicrophoneHandle.self, observer: rollingOutputView)
		Broadcaster.register(RKAudioConverterHandle.self, observer: rollingOutputView)
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
			rollingOutputView.beginRolling()
			print("cache: \(RKFileManager.default.allFilesSize)")
			UIView.animate(withDuration: 0.3, animations: {
				let origin = CGPoint(x: 0, y: self.view.frame.maxY - recordPreferContentHeight - wavePreferContentHeight - infoPreferContentHeight)
				let size = CGSize(width: self.view.bounds.width, height: self.view.frame.maxY - origin.y)
				self.view.frame = CGRect(origin: origin, size: size)
				self.view.setNeedsLayout()
				self.view.layoutIfNeeded()
			})
		} else {
			RecordKit.default.recordEndup()
			rollingOutputView.endUpRolling()
			print("cache: \(RKFileManager.default.allFilesSize)")
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


extension AudioViewController: RKASRerHandle {
	func asrRecognitionFlushing(_ asr: RKASRer) {
		print("fileID: \(asr.speechId!)")
	}
	
	func asrRecognitionCompleted(_ asr: RKASRer) {
//		print("识别结束 fileID: \(asr.speechId!), words: \(asr.finalResult ?? asr.chunkResult ?? asr.flushResult!)")
	}
	
	func asrRecognitionError() {
		print("识别错误")
	}
}

// 外部导入音频测试
class ImportExternalFileService {
	class ImportExternalStream: RKAudioInputStream {
		private var asrer: RKASRer?
		private var audioConverter: RKAudioConverter?
		
		static func externalStream() -> ImportExternalStream {
			let stream = ImportExternalStream()
			stream.asrer = RKASRer.asrer()
			stream.audioConverter = RKAudioConverter.converter()
			stream.audioConverter?.outputFileType = kAudioFileWAVEType
			stream.audioConverter?.outputFormat = RKSettings.IOFormat(formatID: kAudioFormatLinearPCM, bitDepth: .int16, sampleRate: 16000)
			stream.audioConverter?.outputUrl = Destination.temp(url: "External.wav")
			stream.initObserver()
			return stream
		}
		
		override func initObserver() {
			Broadcaster.register(RKAudioConverterHandle.self, observer: self)
			Broadcaster.register(RKASRerHandle.self, observer: self)
		}
		
		func read(url: URL) {
			audioConverter?.inputUrl = Destination.custom(url: url)
			do {
				try audioConverter?.prepare(inRealtime: false)
				try audioConverter?.convert(inputStream: RKAudioInputStream.inputStream())
			} catch {
				alertImportError()
			}
		}
	}
	
	private var externalStream: ImportExternalStream?
	static let shared = ImportExternalFileService()
	
	func importRecordFile(url: URL) {
		externalStream = ImportExternalStream.externalStream()
		externalStream?.read(url: url)
	}
	
	func disposeImport() {
		externalStream?.disposeImport()
	}
}

extension ImportExternalFileService.ImportExternalStream: RKAudioConverterHandle {
	func audioConvertCompleted(_ converter: RKAudioConverter) {
		do {
			try asrer?.fileRecognition(converter.outputUrl)
		} catch {
			alertImportError()
		}
	}
	func audioConvertError() { alertImportError() }
}

extension ImportExternalFileService.ImportExternalStream: RKASRerHandle {
	func asrRecognitionCompleted(_ asr: RKASRer) {
		upload(url: asr.inputUrl.url, recognizeResult: asr.finalResult ?? asr.chunkResult ?? asr.flushResult ?? "")
	}
	func asrRecognitionError(_ asr: RKASRer) {
		upload(url: asr.inputUrl.url, recognizeResult: asr.finalResult ?? asr.chunkResult ?? asr.flushResult ?? "")
	}
}

extension ImportExternalFileService.ImportExternalStream {
	private func alertImportError() {
		let alert = UIAlertController(title: nil, message: "音频导入失败，请重试", preferredStyle: .alert)
		let action = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
		alert.addAction(action)
		UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
			self.disposeImport()
		})
	}
	
	private func alertImportSuccess() {
		let alert = UIAlertController(title: nil, message: "音频导入成功", preferredStyle: .alert)
		let cancleAction = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
		let checkAction = UIAlertAction(title: "查看音频", style: .default, handler: { _ in
			
		})
		alert.addAction(cancleAction)
		alert.addAction(checkAction)
		UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
			self.disposeImport()
		})
	}
	
	private func upload(url: URL, recognizeResult: String) {
		print("上传结果未可知")
		disposeImport()
	}
	
	func disposeImport() {
		audioConverter = nil
		asrer = nil
	}
}
