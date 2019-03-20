//
//  ViewController.swift
//  VoiceRecorderDemo
//
//  Created by guoyiyuan on 2019/2/14.
//  Copyright © 2019 guoyiyuan. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation

class ViewController: UIViewController {
	private lazy var tableView: UITableView = {
		let tableView = UITableView(frame: view.bounds, style: .plain)
		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		return tableView
	}()
	private lazy var audioVc: AudioViewController = {
		let vc = AudioViewController()
		return vc
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		initComponent()
	}

	func initComponent() {
		view.addSubview(tableView)
		
		addChild(audioVc)
		view.addSubview(audioVc.view)
	}
}

extension ViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
		return cell!
	}
}

extension ViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		switch editingStyle {
		case .delete: break
		default: break
		}
	}
}

