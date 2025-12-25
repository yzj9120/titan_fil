//
//  MethodChannel.swift
//  Runner
//
//  Created by 曹安东 on 2024/3/16.
//

import FlutterMacOS
import Foundation

class MethodChannel {
    let channelName: String = "com.titan_fil.titanNetwork/defineChannel" // define相关接口
    var channel: FlutterMethodChannel

    init(controller: FlutterViewController) {
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
    }

    func registerFunc() {
        channel.setMethodCallHandler { (_ call: FlutterMethodCall, _ result: FlutterResult) in
            if call.method == "getAppVersion" {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                result(appVersion)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
