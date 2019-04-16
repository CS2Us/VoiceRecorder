//
//  NoiseSViewController.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/4/15.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit
import RecordKit
import DSPKit

class NoiseSViewController: UIViewController {
	private var dspNsKit: DSPKit_Ns?
	private var destination: Destination?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		dspNsKit = DSPKit_Ns.init(url: Destination.main(name: "NoisySpeech-16k_16bit_stereo", type: "wav").url, mode: aggressive15dB)
	}
	
	@IBAction func clickSegmentControl(_ sender: UISegmentedControl) {
//		guard let dest = destination, let parser = parser else {
//			return
//		}
//		switch sender.selectedSegmentIndex {
//		case 0: // 降噪
//			do {
//				let data = try Data(contentsOf: dest.fileUrl)
//				try parser.parse(data: data)
//				for idx in 0..<Int(parser.packetCount) {
//					let data_out = parser.packets[idx]
//				}
//			} catch let ex {
//				print("获取音频流数据错误")
//			}
//		default:
//			return
//		}
	}
	
}

