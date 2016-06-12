//
//  WX02StatusView.swift
//  WX02-Checker
//
//  Created by moon on 2016/06/01.
//  Copyright © 2016年 buntatsu. All rights reserved.
//

import Cocoa

class WX02StatusView: NSView {
    @IBOutlet weak var threeDaysTrafficTextField: NSTextField!

    @IBOutlet weak var trafficChartView: TrafficChartView!

    @IBOutlet weak var twoDaysAgoTrafficTextField: NSTextField!
    @IBOutlet weak var oneDayAgoTrafficTextField: NSTextField!
    @IBOutlet weak var todayTrafficTextField: NSTextField!

    @IBOutlet weak var wanStrengthIndicator: NSLevelIndicator!
    @IBOutlet weak var wanTypeTextField: NSTextField!
    @IBOutlet weak var lanTypeTextField: NSTextField!

    @IBOutlet weak var twoDaysAgoTrafficColor: NSTextField!
    @IBOutlet weak var oneDayAgoTrafficColor: NSTextField!
    @IBOutlet weak var todayTrafficColor: NSTextField!

    @IBOutlet weak var twoDaysAgoLabel: NSTextField!
    @IBOutlet weak var oneDayAgoLabel: NSTextField!
    @IBOutlet weak var todayLabel: NSTextField!

    override func awakeFromNib() {
        trafficChartView.setChartColor(
            twoDaysAgo: twoDaysAgoLabel.backgroundColor!,
            oneDayAgo: oneDayAgoLabel.backgroundColor!,
            today: todayLabel.backgroundColor!)
    }
    
    func update(traffic: WX02Traffic) {
        dispatch_async(dispatch_get_main_queue()) {
            let threeDaysTraffic
                = self.stringFromTraffic(traffic.twoDaysAgoMb + traffic.oneDayAgoMb + traffic.todayMb)
            let limit = self.stringFromTraffic(traffic.threeDaysLimitMb, precision: "%.0f")
            self.threeDaysTrafficTextField.stringValue = "\(threeDaysTraffic) / \(limit)"

            self.twoDaysAgoTrafficTextField.stringValue = self.stringFromTraffic(traffic.twoDaysAgoMb)
            self.oneDayAgoTrafficTextField.stringValue = self.stringFromTraffic(traffic.oneDayAgoMb)
            self.todayTrafficTextField.stringValue = self.stringFromTraffic(traffic.todayMb)

            self.trafficChartView.setTraffic(
                limitMb: traffic.threeDaysLimitMb,
                twoDaysAgoMb: traffic.twoDaysAgoMb,
                oneDayAgoMb: traffic.oneDayAgoMb,
                todayMb: traffic.todayMb)
        }
    }

    func update(status: WX02Status) {
        dispatch_async(dispatch_get_main_queue()) {
            self.wanStrengthIndicator.maxValue = Double(status.wanMaxStrength)
            self.wanStrengthIndicator.integerValue = status.wanStrength
            self.wanTypeTextField.stringValue = status.wanTypeString
            self.lanTypeTextField.stringValue = status.lanTypeString
        }
    }
    
    internal func stringFromTraffic(trafficMb: Float, precision: String = "%.2f") -> String {
        if trafficMb >= 1024 {
            return String(format: "\(precision) GB", trafficMb / 1024)
        }
        return String(format: "\(precision) MB", trafficMb)
    }
}
