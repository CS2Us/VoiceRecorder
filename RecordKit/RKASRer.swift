//
//  RKASRer.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/11.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

@objc
public protocol RKASRerHandle {
	@objc(asrRecognitionWorking:)
	optional func asrRecognitionFlushing(_ asr: RKASRer)
	@objc(asrRecognitionError:)
	optional func asrRecognitionError(_ asr: RKASRer)
	@objc(asrRecognitionCompleted:)
	optional func asrRecognitionCompleted(_ asr: RKASRer)
}

public class RKASRer: RKObject {
	private var _asrEventManager: BDSEventManager
	private var _longSpeech: Bool = false
	
	public var originalObj: Any?
	public var flushResult: String?
	public var chunkResult: String?
	public var finalResult: String?
	public var speechId: String?
	public var dst: Destination = .none {
		didSet {
			speechId = dst.fileId
		}
	}
	
	public static func asrer() -> RKASRer {
		let asrer = RKASRer()
		return asrer
	}
	
	override init() {
		_asrEventManager = BDSEventManager.createEventManager(withName: BDS_ASR_NAME)
		super.init()
		_asrEventManager.setDelegate(self)
		_asrEventManager.setParameter(true, forKey: BDS_ASR_DISABLE_AUDIO_OPERATION)
		_asrEventManager.setParameter(EVRDebugLogLevelTrace, forKey: BDS_ASR_DEBUG_LOG_LEVEL)
		_asrEventManager.setParameter([RKSettings.ASRApiKey, RKSettings.ASRSecretKey], forKey: BDS_ASR_API_SECRET_KEYS)
		_asrEventManager.setParameter(RKSettings.ASRAppID, forKey: BDS_ASR_OFFLINE_APP_CODE)
		_asrEventManager.setParameter(EVoiceRecognitionRecordSampleRate16K, forKey: BDS_ASR_SAMPLE_RATE)
		_asrEventManager.setParameter(EVoiceRecognitionLanguageChinese, forKey: BDS_ASR_LANGUAGE)
		_asrEventManager.setParameter(RKSettings.maxDuration * 1000000, forKey: BDS_ASR_MFE_MAX_WAIT_DURATION)
		

		enableModelVAD() /** 开启端点检测 **/
		enableNLU() /** 开启语义理解 **/
		enablePunctuation() /** 开启标点输出 **/
	}
	
	public func audioStreamRecognition(inputStream: InputStream) throws {
		_longSpeech = false
		resetRecognition()
		_asrEventManager.setParameter(inputStream, forKey: BDS_ASR_AUDIO_INPUT_STREAM)
		_asrEventManager.sendCommand(BDS_ASR_CMD_START)
	}
	
	public func fileRecognition() {
		resetRecognition()
		_asrEventManager.setDelegate(self)
		if dst.duration >= RKSettings.ASRLimitDuration {
			_longSpeech = true
			_asrEventManager.setParameter(dst.url.absoluteString, forKey: BDS_ASR_AUDIO_FILE_PATH)
			_asrEventManager.sendCommand(BDS_ASR_CMD_START)
			longSpeechRecognition()
		} else {
			_longSpeech = false
			_asrEventManager.setParameter(dst.url.absoluteString, forKey: BDS_ASR_AUDIO_FILE_PATH)
			_asrEventManager.sendCommand(BDS_ASR_CMD_START)
		}
	}
	
	public func longSpeechRecognition() {
		_longSpeech = true
		resetRecognition()
		_asrEventManager.setParameter(true, forKey:BDS_ASR_ENABLE_LONG_SPEECH)
		_asrEventManager.setParameter(true, forKey:BDS_ASR_ENABLE_LOCAL_VAD)
		_asrEventManager.sendCommand(BDS_ASR_CMD_START)
	}
	
	internal func endRecognition() {
		_asrEventManager.sendCommand(BDS_ASR_CMD_STOP)
		_asrEventManager.sendCommand(BDS_ASR_CMD_CANCEL)
		
		RecordKit.asrerObservers.allObjects
			.map{$0 as? RKASRerHandle}.filter{$0 != nil}.forEach { observer in
				observer?.asrRecognitionCompleted?(self)
		}
	}
	
	internal func resetRecognition() {
		_asrEventManager.setParameter(false, forKey:BDS_ASR_ENABLE_LONG_SPEECH)
		_asrEventManager.setParameter(false, forKey:BDS_ASR_ENABLE_LOCAL_VAD)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_FILE_PATH)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_INPUT_STREAM)
		_asrEventManager.sendCommand(BDS_ASR_CMD_CANCEL)
	}
	
	deinit {
		RKLogBrisk("识别器销毁")
	}
}

extension RKASRer {
	private func enableNLU() {
		_asrEventManager.setParameter(true, forKey: BDS_ASR_ENABLE_NLU)
		_asrEventManager.setParameter("1536", forKey: BDS_ASR_PRODUCT_ID)
	}

	private func enablePunctuation() {
		_asrEventManager.setParameter(false, forKey: BDS_ASR_DISABLE_PUNCTUATION)
		/** 英文标点 **/
		//		_asrEventManager.setParameter("1737", forKey: BDS_ASR_PRODUCT_ID)
		/** 普通话标点 **/
		_asrEventManager.setParameter("1537", forKey: BDS_ASR_PRODUCT_ID)
	}

	private func enableModelVAD() {
		_asrEventManager.setParameter(RKSettings.resources.path(forResource: "bds_easr_basic_model", ofType: "dat")!, forKey: BDS_ASR_MODEL_VAD_DAT_FILE)
		_asrEventManager.setParameter(true, forKey: BDS_ASR_ENABLE_MODEL_VAD)
	}
}

extension RKASRer: BDSClientASRDelegate {
	public func voiceRecognitionClientWorkStatus(_ workStatus: Int32, obj aObj: Any!) {
		switch TBDVoiceRecognitionClientWorkStatus(UInt32(workStatus)) {
		case EVoiceRecognitionClientWorkStatusStartWorkIng:
			RKLog("CALLBACK: start vr, log: \(String(describing: parseDataToDic(data: aObj as! String)))")
		case EVoiceRecognitionClientWorkStatusStart:
			RKLog("CALLBACK: detect voice start point.\n")
		case EVoiceRecognitionClientWorkStatusEnd:
			RKLog("CALLBACK: detect voice end point.\n")
		case EVoiceRecognitionClientWorkStatusFlushData:
			originalObj = aObj
			flushResult = (((aObj as! NSDictionary)["results_recognition"]) as! NSArray).firstObject as? String
			RecordKit.asrerObservers.allObjects
				.map{$0 as? RKASRerHandle}.filter{$0 != nil}.forEach { observer in
					observer?.asrRecognitionFlushing?(self)
			}
			RKLog("CALLBACK: partial result - \(String(describing: parseDicDescription(data: aObj)))")
		case EVoiceRecognitionClientWorkStatusFinish:
			chunkResult = (((aObj as! NSDictionary)["results_recognition"]) as! NSArray).firstObject as? String
			if !_longSpeech {
				finalResult = chunkResult
				RecordKit.asrerObservers.allObjects
					.map{$0 as? RKASRerHandle}.filter{$0 != nil}.forEach { observer in
						observer?.asrRecognitionCompleted?(self)
				}
			} else {
				finalResult = (finalResult ?? "") + (chunkResult ?? "")
			}
			RKLog("CALLBACK: final result - \(String(describing: parseDicDescription(data: aObj)))")
		case EVoiceRecognitionClientWorkStatusError:
			originalObj = aObj
			RecordKit.asrerObservers.allObjects
				.map{$0 as? RKASRerHandle}.filter{$0 != nil}.forEach { observer in
					observer?.asrRecognitionError?(self)
			}
			RKLog("CALLBACK: encount error - \(aObj as! NSError)")
		case EVoiceRecognitionClientWorkStatusCancel:
			RKLog("CALLBACK: user press cancel.\n")
		case EVoiceRecognitionClientWorkStatusRecorderEnd:
			RKLog("CALLBACK: recorder closed.\n")
		case EVoiceRecognitionClientWorkStatusLongSpeechEnd:
			RKLog("CALLBACK: Long Speech end.\n")
		default: break
		}
	}

	private func parseDicDescription(data: Any) -> String {
		if let data = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
			return String.init(data: data, encoding: .utf8) ?? ""
		}
		return ""
	}

	private func parseDataToDic(data: String) -> [String:String] {
		var tmp = [String]()
		var dict = [String:String]()
		let items = data.components(separatedBy: "&")
		for item in items {
			tmp = item.components(separatedBy: "=")
			if tmp.count == 2 {
				dict[tmp.first!] = tmp.last!
			}
		}
		return dict
	}
}
