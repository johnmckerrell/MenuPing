//
//  AppDelegate.swift
//  MenuPing
//
//  Created by John McKerrell on 19/06/2017.
//  Copyright © 2017 MKE Computing Ltd. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var pinger = Pinger()
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        pinger.configuration = Pinger.Configuration(interval: 1, timeout: 10, host: "8.8.8.8")
        pinger.configuration = Pinger.Configuration(interval: 1, timeout: 10, host: "192.168.0.135")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

