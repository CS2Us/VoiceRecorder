//
//  RKView.swift
//  AudioKitUI
//
//  Created by Stéphane Peter, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import UIKit

public typealias RKView = UIView
public typealias RKColor = UIColor

/// Class to handle colors, fonts, etc.

public enum RKTheme {
	case basic
	case midnight
}

public class RKStylist {
	public static let sharedInstance = RKStylist()
	
	public var bgColor: RKColor {
		return bgColors[theme]!
	}
	
	public var fontColor: RKColor {
		return fontColors[theme]!
	}
	
	public var theme = RKTheme.midnight
	private var bgColors: [RKTheme: RKColor]
	private var fontColors: [RKTheme: RKColor]
	
	private var colorCycle: [RKTheme: [RKColor]]
	
	var counter = 0
	
	init() {
		fontColors = Dictionary()
		fontColors[.basic] = RKColor.black
		fontColors[.midnight] = RKColor.white
		
		bgColors = Dictionary()
		bgColors[.basic] = RKColor.white
		bgColors[.midnight] = #colorLiteral(red: 0.1019607843, green: 0.1019607843, blue: 0.1019607843, alpha: 1)
		
		colorCycle = Dictionary()
		colorCycle[.basic] = [RKColor(red: 165.0 / 255.0, green: 26.0 / 255.0, blue: 216.0 / 255.0, alpha: 1.0),
							  RKColor(red: 238.0 / 255.0, green: 66.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0),
							  RKColor(red: 244.0 / 255.0, green: 96.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0),
							  RKColor(red: 36.0 / 255.0, green: 110.0 / 255.0, blue: 185.0 / 255.0, alpha: 1.0),
							  RKColor(red: 14.0 / 255.0, green: 173.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)]
		colorCycle[.midnight] = [RKColor(red: 165.0 / 255.0, green: 26.0 / 255.0, blue: 216.0 / 255.0, alpha: 1.0),
								 RKColor(red: 238.0 / 255.0, green: 66.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0),
								 RKColor(red: 244.0 / 255.0, green: 96.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0),
								 RKColor(red: 36.0 / 255.0, green: 110.0 / 255.0, blue: 185.0 / 255.0, alpha: 1.0),
								 RKColor(red: 14.0 / 255.0, green: 173.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)]
	}
	
	public var nextColor: RKColor {
		get {
			counter += 1
			if counter >= colorCycle[theme]!.count {
				counter = 0
			}
			return colorCycle[theme]![counter]
		}
	}
	
	public var colorForTrueValue: RKColor {
		switch theme {
		case .basic: return RKColor(red: 35.0 / 255.0, green: 206.0 / 255.0, blue: 92.0 / 255.0, alpha: 1.0)
		case .midnight: return RKColor(red: 35.0 / 255.0, green: 206.0 / 255.0, blue: 92.0 / 255.0, alpha: 1.0)
		}
	}
	
	public var colorForFalseValue: RKColor {
		switch theme {
		case .basic: return RKColor(red: 255.0 / 255.0, green: 22.0 / 255.0, blue: 22.0 / 255.0, alpha: 1.0)
		case .midnight: return RKColor(red: 255.0 / 255.0, green: 22.0 / 255.0, blue: 22.0 / 255.0, alpha: 1.0)
		}
	}
}
