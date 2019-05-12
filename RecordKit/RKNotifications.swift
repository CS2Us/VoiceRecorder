//
//  RKNotifications.swift
//  RecordKit
//
//  Created by guoyiyuan on 2019/5/12.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation

/// Object to handle notifications for events that can affect the audio

extension Notification.Name {
	/// After the audio route is changed, (headphones plugged in, for example) AudioKit restarts,
	///  and engineRestartAfterRouteChange is sent.
	///
	/// The userInfo dictionary of this notification contains the AVAudioSessionRouteChangeReasonKey
	///  and AVAudioSessionSilenceSecondaryAudioHintTypeKey keys, which provide information about the route change.
	///
	public static let RKEngineRestartedAfterRouteChange =
		Notification.Name(rawValue: "io.recordkit.enginerestartedafterroutechange")
	
	/// After the audio engine configuration is changed, (change in input or output hardware's channel count or
	/// sample rate, for example) AudioKit restarts, and engineRestartAfterCategoryChange is sent.
	///
	/// The userInfo dictionary of this notification is the same as the originating
	/// AVAudioEngineConfigurationChange notification's userInfo.
	///
	public static let RKEngineRestartedAfterConfigurationChange =
		Notification.Name(rawValue: "io.recordkit.enginerestartedafterconfigurationchange")
	
}
