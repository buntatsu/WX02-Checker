//
//  WX02Web.swift
//  WX02-Checker
//
//  Created by moon on 2016/06/01.
//  Copyright © 2016年 buntatsu. All rights reserved.
//

import Foundation
import Alamofire
import Kanna

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func removeLf() -> String {
        return self.stringByReplacingOccurrencesOfString(
            "\r\n|\n", withString: "",
            options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
    }
}

struct WX02Traffic {
    var threeDaysLimitMb: Float                 // 上限値(3日間)
    var thisMonthsTrafficMb: Float              // データ通信量(今月)
    var threeDaysUntilTodayMb: Float            // 本日までの3日間
    var threeDaysUntilTheDayBeforeMb: Float     // 前日までの3日間
    var todayMb: Float                          // 本日
    var oneDayAgoMb: Float                      // 1日前
    var twoDaysAgoMb: Float                     // 2日前
    var threeDaysAgoMb: Float                   // 3日前
}

struct WX02Status {
    var battRestPercent: Int    // バッテリー(0-100)
    var wanStrength: Int        // Wan強度(WiMAX2:0-4 or Other:0-5)
    var wanType: Int            // 1:WiMAX 2+, 2:WiMAX, 3:Wi-Fi, ?:圏外
    var lanType: Int            // 2:2.4G, 4:5G[indoor], 8:5G[indoor],
                                // 16:5G[outdoor], 20:Bluetooth, 255:Check Wi-FI ch

    var wanTypeString: String {
        switch wanType {
        case 1: return "WiMAX 2+"
        case 2: return "WiMAX"
        case 3: return "Wi-Fi"
        default: return "No Reception"
        }
    }
    
    var lanTypeString: String {
        switch lanType {
        case 2: return "2.4G"
        case 4: return "5G[indoor]"
        case 8: return "5G[indoor]"
        case 16: return "5G[outdoor]"
        case 20: return "Bluetooth"
        case 255: return "Check Wi-FI ch"
        default: return "Unknown"
        }
    }
    
    var wanMaxStrength: Int {
        switch wanType {
        case 1: return 4
        default: return 5
        }
    }
}


class WX02Web {
    let regexForConvertTrafficString
        = try! NSRegularExpression(pattern: "(\\d+\\.*\\d*)([a-zA-Z]*)", options: [.CaseInsensitive])

    func createHeaders(user: String, password: String) -> [String : String] {
        let credentialData = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        return ["Authorization": "Basic \(base64Credentials)"]
    }

    /*
     *  "1024kb" -> 1
     *  "1.2mb" -> 1.2
     *  "2GB" -> 2048
     */
    private func mbValueFromTrafficString(trafficString: String) -> Float {
        var valueMb: Float = 0
        
        if let match = regexForConvertTrafficString.firstMatchInString(
            trafficString, options: [],
            range: NSMakeRange(0, trafficString.characters.count)) {
            
            if match.numberOfRanges == 3 {
                let trafficValue = Float((trafficString as NSString)
                    .substringWithRange(match.rangeAtIndex(1))) ?? 0
                let trafficUnit = (trafficString as NSString)
                    .substringWithRange(match.rangeAtIndex(2)).uppercaseString
                
                switch trafficUnit {
                case "KB":
                    valueMb = trafficValue / 1024
                case "MB":
                    valueMb = trafficValue
                case "GB":
                    valueMb = trafficValue * 1024
                default:
                    break
                }
            }
        }
        
        return valueMb
    }

    func fetchTraffic(address: String, user: String, password: String, success: (WX02Traffic) -> Void) {
        /**
         - response
            <input type="text" name="DAY_LIMIT" id="DAY_LIMIT" maxlength="128" size="40" value="3">
                :
            <li class="value">[■■■□□ □□□□□](2.59GB/7GB)</li>
            <li class="value">1.19GB</li>
                :
         
         - Contents
            上限値(3日間)
                :
            データ通信量表示      : [■■■□□ □□□□□](2.59GB/7GB)
            本日までの3日間(残り) : 451.63MB (2.56GB)
            前日までの3日間       : 896.22MB
            本日                 : 571.47KB
            1日前                : 352.64MB
            2日前                : 98.43MB
            3日前                : 445.15MB
            or 時刻情報が未取得のため表示できません
         */
        let url = "http://\(address)/index.cgi/network_count_main/"
        Alamofire.request(.GET, url, headers: createHeaders(user, password: password))
            .responseString {response in

                if let resultValue = response.result.value {
                    if let doc = Kanna.HTML(html: resultValue, encoding: NSUTF8StringEncoding) {
                        var dayLimitMb: Float = 0
                        if let dayLimit = doc.at_css("#DAY_LIMIT")?["value"] {
                            dayLimitMb = self.mbValueFromTrafficString(dayLimit + "GB")
                        }

                        let nodeSet = doc.css("li.value")
                        if nodeSet.count < 7 {
                            return
                        }
                        
                        var trafficMbArray = [Float](arrayLiteral: 0, 0, 0, 0, 0, 0, 0)
                        for i in 0...6 {
                            if let trafficString = nodeSet[i].text?.trim() {
                                trafficMbArray[i] = self.mbValueFromTrafficString(trafficString)
                            }
                        }
                        
                        let traffic = WX02Traffic(
                            threeDaysLimitMb: dayLimitMb,
                            thisMonthsTrafficMb: trafficMbArray[0],
                            threeDaysUntilTodayMb: trafficMbArray[1],
                            threeDaysUntilTheDayBeforeMb: trafficMbArray[2],
                            todayMb: trafficMbArray[3],
                            oneDayAgoMb: trafficMbArray[4],
                            twoDaysAgoMb: trafficMbArray[5],
                            threeDaysAgoMb: trafficMbArray[6]
                        )

                        success(traffic)
                    }
                }
        }
    }
    
    func fetchStatus(address: String, user: String, password: String, success: (WX02Status) -> Void) {
        /**
         - response
              <?xml version='1.0' encoding='EUC-JP'?>
              <body><status>100_2_2_0_1_1_4</status></body>
         - Contents
              [1] Battery: 0 - 100
              [2] Wan Strength: WiMAX 2+: 0 - 4, Other: 0 - 5
              [3] Wan Type: 1:WiMAX 2+, 2:WiMAX, 3:Wi-Fi, ?:圏外
              [4] ?
              [5] ?
              [6] ?
              [7] Lan Type:
                    2:2.4G, 4:5G[indoor], 8:5G[indoor],
                    16:5G[outdoor], 20:Bluetooth, 255:Check Wi-FI ch
         */
        let url = "http://\(address)/index.cgi/status_get.xml"
        Alamofire.request(.GET, url, headers: createHeaders(user, password: password))
            .responseString {response in

                if let resultValue = response.result.value {
                    if let doc = Kanna.XML(xml: resultValue, encoding: NSUTF8StringEncoding) {
                        if let str = doc.xpath("/body/status[1]").text {
                            let strArray = str.removeLf().componentsSeparatedByString("_")
                            if strArray.count >= 7 {
                                let status = WX02Status(
                                    battRestPercent: Int(strArray[0])!,
                                    wanStrength: Int(strArray[1])!,
                                    wanType: Int(strArray[2])!,
                                    lanType: Int(strArray[6])!
                                    )

                                success(status)
                            }
                        }
                    }
                }
        }
    }
}
