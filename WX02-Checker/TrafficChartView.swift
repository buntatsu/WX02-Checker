//
//  MyView1.swift
//  PieChart
//
//  Created by moon on 2016/06/01.
//  Copyright © 2016年 buntatsu. All rights reserved.
//

import Cocoa

@IBDesignable class TrafficChartView: NSView {
    let angleOffset: Float = 90
    
    var limitMb:Float = 3 * 1024
    var twoDaysAgoTrafficMb: Float = 0
    var oneDayAgoTrafficMb: Float = 0
    var todayTrafficMb: Float = 0

    var twoDaysAgoTrafficColor = NSColor.blueColor()
    var oneDayAgoTrafficColor = NSColor.greenColor()
    var todayTrafficColor: NSColor = NSColor.orangeColor()
    var limitOverColor: NSColor = NSColor.redColor()

    func setChartColor(twoDaysAgo twoDaysAgo: NSColor, oneDayAgo: NSColor, today: NSColor) {
        self.twoDaysAgoTrafficColor = twoDaysAgo
        self.oneDayAgoTrafficColor = oneDayAgo
        self.todayTrafficColor = today
    }
    
    func setTraffic(limitMb limitMb: Float, twoDaysAgoMb: Float, oneDayAgoMb: Float, todayMb: Float) {
        twoDaysAgoTrafficMb = twoDaysAgoMb
        oneDayAgoTrafficMb = oneDayAgoMb
        todayTrafficMb = todayMb
        setNeedsDisplayInRect(self.bounds)
    }

    private func drawArc(pieCenter: NSPoint, radius: CGFloat,
                         startArc: Float, endArc: Float,
                         color: NSColor, fill: Bool = true) {
        let bPath = NSBezierPath()
        bPath.appendBezierPathWithArcWithCenter(
            pieCenter, radius: radius,
            startAngle: CGFloat(startArc * 360 + angleOffset),
            endAngle: CGFloat(endArc * 360 + angleOffset),
            clockwise: false)
        color.set()
        if fill {
            bPath.lineToPoint(pieCenter)
            bPath.fill()
        } else {
            bPath.lineWidth = CGFloat(0.6)
            bPath.stroke()
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        let pieCenter = NSMakePoint(dirtyRect.size.width / 2, dirtyRect.size.height / 2)
        let radius: CGFloat = dirtyRect.size.height / 2
        
        if (twoDaysAgoTrafficMb + oneDayAgoTrafficMb + todayTrafficMb) >= limitMb {
            // limit over
            drawArc(pieCenter, radius: radius,
                    startArc: 0,
                    endArc: 1.0,
                    color: limitOverColor)

            // draw limit over text
            let limitOverText = "Limit Over"
            let textAttributes = [
                NSForegroundColorAttributeName: NSColor.whiteColor(),
                NSFontAttributeName: NSFont.systemFontOfSize(12)
            ]
            let size = limitOverText.sizeWithAttributes(textAttributes)
            limitOverText.drawAtPoint(
                NSPoint(x: pieCenter.x - size.width * 0.5, y: pieCenter.y - size.height * 0.5),
                withAttributes: textAttributes)

            return
        }

        var totalUsedPercent: Float = 0

        // used Two Days Ago
        drawArc(pieCenter, radius: radius,
                startArc: totalUsedPercent,
                endArc: totalUsedPercent + twoDaysAgoTrafficMb / limitMb,
                color: twoDaysAgoTrafficColor)
        totalUsedPercent += twoDaysAgoTrafficMb / limitMb

        // used One Day Ago
        drawArc(pieCenter, radius: radius,
                startArc: totalUsedPercent,
                endArc: totalUsedPercent + oneDayAgoTrafficMb / limitMb,
                color: oneDayAgoTrafficColor)
        totalUsedPercent += oneDayAgoTrafficMb / limitMb

        // used Today
        drawArc(pieCenter, radius: radius,
                startArc: totalUsedPercent,
                endArc: totalUsedPercent + todayTrafficMb / limitMb,
                color: todayTrafficColor)
        totalUsedPercent += todayTrafficMb / limitMb

        // free
        drawArc(pieCenter, radius: radius - 0.5,
                startArc: totalUsedPercent,
                endArc: 1.0,
                color: NSColor.darkGrayColor(),
                fill: false)
    }
}