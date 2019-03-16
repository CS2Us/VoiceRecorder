//
//  RKASRer.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/3/11.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import AVFoundation

protocol RKASRerDelegate {
	func asr(_ asr: RKASRer, recognitionResult: String)
}

class RKASRer: NSObject {
	private var _delegate: RKASRerDelegate?
	private var _asrEventManager: BDSEventManager
	
	static func asrer(_ delegate: RKASRerDelegate) -> RKASRer {
		let asrer = RKASRer()
		asrer._delegate = delegate
		return asrer
	}
	
	override init() {
		_asrEventManager = BDSEventManager.createEventManager(withName: BDS_ASR_NAME)
		super.init()
		_asrEventManager.setDelegate(self)
		_asrEventManager.setParameter(EVRDebugLogLevelTrace, forKey: BDS_ASR_DEBUG_LOG_LEVEL)
		_asrEventManager.setParameter([RKSettings.ASRApiKey, RKSettings.ASRSecretKey], forKey: BDS_ASR_API_SECRET_KEYS)
		_asrEventManager.setParameter(RKSettings.ASRAppID, forKey: BDS_ASR_OFFLINE_APP_CODE)
		_asrEventManager.setParameter(EVoiceRecognitionRecordSampleRate16K, forKey: BDS_ASR_SAMPLE_RATE)
		_asrEventManager.setParameter(EVoiceRecognitionLanguageEnglish, forKey: BDS_ASR_LANGUAGE)
		//		_asrEventManager.setParameter(RKSettings.maxDuration * 1000, forKey: BDS_ASR_MFE_MAX_WAIT_DURATION)
		
		
		enableModelVAD() /** 开启端点检测 **/
		enableNLU() /** 开启语义理解 **/
		enablePunctuation() /** 开启标点输出 **/
	}
	
	func audioStreamRecognition(inputStream: RKAudioInputStream) throws {
		_asrEventManager.sendCommand(BDS_ASR_CMD_STOP)
		_asrEventManager.setParameter(inputStream, forKey: BDS_ASR_AUDIO_INPUT_STREAM)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_FILE_PATH)
		_asrEventManager.sendCommand(BDS_ASR_CMD_START)
	}
	
	func fileRecognition(_ filePath: String = RKSettings.asrFileDst.url.absoluteString) throws {
		_asrEventManager.sendCommand(BDS_ASR_CMD_STOP)
		_asrEventManager.setParameter(filePath, forKey: BDS_ASR_AUDIO_FILE_PATH)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_INPUT_STREAM)
		_asrEventManager.sendCommand(BDS_ASR_CMD_START)
	}
	
	func longSpeechRecognition() throws {
		_asrEventManager.sendCommand(BDS_ASR_CMD_STOP)
		_asrEventManager.setParameter(false, forKey:BDS_ASR_NEED_CACHE_AUDIO)
		_asrEventManager.setParameter(true, forKey:BDS_ASR_ENABLE_LONG_SPEECH)
		_asrEventManager.setParameter(true, forKey:BDS_ASR_ENABLE_LOCAL_VAD)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_FILE_PATH)
		_asrEventManager.setParameter("", forKey: BDS_ASR_AUDIO_INPUT_STREAM)
		_asrEventManager.sendCommand(BDS_ASR_CMD_START)
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
	func voiceRecognitionClientWorkStatus(_ workStatus: Int32, obj aObj: Any!) {
		switch TBDVoiceRecognitionClientWorkStatus(UInt32(workStatus)) {
		case EVoiceRecognitionClientWorkStatusStartWorkIng:
			RKLog("识别工作开始，开始采集及处理数据")
		case EVoiceRecognitionClientWorkStatusStart:
			RKLog("检测到用户开始说话")
		case EVoiceRecognitionClientWorkStatusFlushData:
			let result = try? String.init(data: JSONSerialization.data(withJSONObject: aObj, options: .prettyPrinted), encoding: .utf8)
			RKLog("连续上屏 \(String(describing: result))")
		//			_delegate?.asr(self, recognitionResult: result)
		case EVoiceRecognitionClientWorkStatusEnd:
			RKLog("本地声音采集结束，等待识别结果返回并结束录音")
		case EVoiceRecognitionClientWorkStatusFinish:
			RKLog("语音识别功能完成，服务器返回正确结果")
		default: break
		}
	}
}
