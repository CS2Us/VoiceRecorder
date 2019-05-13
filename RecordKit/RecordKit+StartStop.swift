//
//  RecordKit+StartStop.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/12.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

extension RecordKit {
	/// Start up the audio engine
	@objc public static func start() throws {
		if output == nil {
			RKLog("No output node has been set yet, no processing will happen.")
		}
		// Start the engine.
		try RKTry({
			engine.prepare()
		}, "RecordKit.engine.prepare error")
		
		#if os(iOS)
		try updateSessionCategoryAndOptions()
		try AVAudioSession.sharedInstance().setActive(true)
		
		/// Notification observers
		
		// Subscribe to route changes that may affect our engine
		// Automatic handling of this change can be disabled via RKSettings.enableRouteChangeHandling
		NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self,
											   selector: #selector(restartEngineAfterRouteChange),
											   name: AVAudioSession.routeChangeNotification,
											   object: nil)
		
		// Subscribe to session/configuration changes to our engine
		// Automatic handling of this change can be disabled via RKSettings.enableCategoryChangeHandling
		NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
		NotificationCenter.default.addObserver(self,
											   selector: #selector(restartEngineAfterConfigurationChange),
											   name: .AVAudioEngineConfigurationChange,
											   object: nil)
		#endif
		
		try RKTry({
			try engine.start()
		}, "RecordKit.engine.start error")
		shouldBeRunning = true
	}
	
	@objc internal static func updateSessionCategoryAndOptions() throws {
		#if !os(macOS)
		let sessionCategory = RKSettings.computedSessionCategory()
		
		#if os(iOS)
		let sessionOptions = RKSettings.computedSessionOptions()
		try RKSettings.setSession(category: sessionCategory, with: sessionOptions)
		#elseif os(tvOS)
		try RKSettings.setSession(category: sessionCategory)
		#endif
		#endif
	}
	
	/// Stop the audio engine
	@objc public static func stop() throws {
		// Stop the engine.
		try RKTry({
			engine.stop()
		}, "RecordKit.engine.stop error")
		shouldBeRunning = false
		
		#if os(iOS)
		do {
			NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
			NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
			if !RKSettings.disableAudioSessionDeactivationOnStop {
				try AVAudioSession.sharedInstance().setActive(false)
			}
		} catch {
			RKLog("couldn't stop session \(error)")
			throw error
		}
		#endif
	}
	
	@objc public static func shutdown() throws {
		engine = AVAudioEngine()
		finalMixer = nil
		output = nil
		shouldBeRunning = false
	}
	
	// MARK: - Configuration Change Response
	
	// Listen to changes in audio configuration
	// and restart the audio engine if it stops and should be playing
	@objc fileprivate static func restartEngineAfterConfigurationChange(_ notification: Notification) {
		// Notifications aren't guaranteed to be on the main thread
		let attemptRestart = {
			do {
				// By checking the notification sender in this block rather than during observer configuration
				// we avoid needing to create a new observer if the engine somehow changes
				guard let notifyingEngine = notification.object as? AVAudioEngine, notifyingEngine == engine else {
					return
				}
				
				if RKSettings.enableCategoryChangeHandling && !engine.isRunning && shouldBeRunning {
					#if !os(macOS)
					let appIsNotActive = UIApplication.shared.applicationState != .active
					let appDoesNotSupportBackgroundAudio = !RKSettings.appSupportsBackgroundAudio
					
					if appIsNotActive && appDoesNotSupportBackgroundAudio {
						RKLog("engine not restarted after configuration change since app was not active and does not support background audio")
						return
					}
					#endif
					
					try engine.start()
					
					// Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
					if RKSettings.notificationsEnabled {
						NotificationCenter.default.post(
							name: .RKEngineRestartedAfterConfigurationChange,
							object: nil,
							userInfo: notification.userInfo)
					}
				}
			} catch {
				RKLog("error restarting engine after route change")
				// Note: doesn't throw since this is called from a notification observer
			}
		}
		if Thread.isMainThread {
			attemptRestart()
		} else {
			DispatchQueue.main.async(execute: attemptRestart)
		}
	}
	
	// Restarts the engine after audio output has been changed, like headphones plugged in.
	@objc fileprivate static func restartEngineAfterRouteChange(_ notification: Notification) {
		// Notifications aren't guaranteed to come in on the main thread
		
		let attemptRestart = {
//			do {
//				try engine.start()
//			} catch let ex {
//				RKLog("RecordKit engine start error: \(ex)")
//			}
			
			
			if RKSettings.enableRouteChangeHandling && shouldBeRunning && !engine.isRunning {
				do {
					#if !os(macOS)
					let appIsNotActive = UIApplication.shared.applicationState != .active
					let appDoesNotSupportBackgroundAudio = !RKSettings.appSupportsBackgroundAudio
					
					if appIsNotActive && appDoesNotSupportBackgroundAudio {
						RKLog("engine not restarted after route change since app was not active and does not support background audio")
						return
					}
					#endif
					
					try engine.start()
					
					// Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
					if RKSettings.notificationsEnabled {
						NotificationCenter.default.post(
							name: .RKEngineRestartedAfterRouteChange,
							object: nil,
							userInfo: notification.userInfo)
					}
				} catch {
					RKLog("error restarting engine after route change")
					// Note: doesn't throw since this is called from a notification observer
				}
			}
		}
		if Thread.isMainThread {
			attemptRestart()
		} else {
			DispatchQueue.main.async(execute: attemptRestart)
		}
	}
}
