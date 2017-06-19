//
//  Pinger.swift
//  MenuPing
//
//  Created by John McKerrell on 19/06/2017.
//  Copyright © 2017 MKE Computing Ltd. All rights reserved.
//

import Cocoa
import GBPing

fileprivate extension UserDefaults {
    fileprivate struct Keys {
        static let host = "host"
        static let interval = "interval"
        static let timeout = "timeout"
    }
    
    static var pingerConfiguration: Pinger.Configuration? {
        set {
            let defaults = UserDefaults.standard

            guard let newValue = newValue else {
                defaults.removeObject(forKey: Keys.host)
                defaults.removeObject(forKey: Keys.interval)
                defaults.removeObject(forKey: Keys.timeout)
                return
            }
            defaults.set(newValue.host, forKey: Keys.host)
            defaults.set(newValue.interval, forKey: Keys.interval)
            defaults.set(newValue.timeout, forKey: Keys.timeout)
        }
        get {
            let defaults = UserDefaults.standard
            guard let host = defaults.object(forKey: Keys.host) as? String,
                let interval = defaults.object(forKey: Keys.interval) as? TimeInterval,
                let timeout = defaults.object(forKey: Keys.timeout) as? TimeInterval
                else {
                    return nil
            }
            return Pinger.Configuration(interval: interval, timeout: timeout, host: host)
        }
    }
}

class Pinger: NSObject {
    struct Configuration {
        let interval: TimeInterval
        let timeout: TimeInterval
        let host: String
    }
    var activelyPinging = true
    
    fileprivate var statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    fileprivate var ping = GBPing()
    
    var configuration: Configuration? {
        didSet {
            UserDefaults.pingerConfiguration = configuration
            stop()
            start()
        }
    }
    
    fileprivate let goodImage = NSImage(named: "cloud-toolbar-good")!
    fileprivate let badImage = NSImage(named: "cloud-toolbar-bad")!
    fileprivate var lastSuccessPingSequence: UInt = 0
    
    override init() {
        configuration = UserDefaults.pingerConfiguration
    }
    
    func start() {
        guard let configuration = configuration else {
            return
        }
        statusItem.image = goodImage
        ping.host = configuration.host
        ping.timeout = configuration.timeout
        ping.pingPeriod = configuration.interval
        ping.delegate = self
        ping.setup { (success, error) in
            switch success {
            case true:
                self.ping.startPinging()
                self.activelyPinging = true
            case false:
                print("Ping setup error: \(error != nil ? String(describing:error!) : "-unknown-")")
            }
        }
    }
    
    func stop() {
        ping.stop()
    }
    
    func handleFailure(pinger: GBPing, error: Error?, summary: GBPingSummary?) {
        guard let summary = summary else {
            statusItem.image = badImage
            print("Ping failure error: \(error != nil ? String(describing:error!) : "-unknown-")")
            return
        }
        
        guard summary.sequenceNumber > lastSuccessPingSequence else {
            return
        }
        
        statusItem.image = badImage
    }
}

extension Pinger: GBPingDelegate {
    func ping(_ pinger: GBPing!, didFailWithError error: Error!) {
        print("Ping error: \(error)")
        handleFailure(pinger: pinger, error: error, summary: nil)
    }
    func ping(_ pinger: GBPing!, didTimeoutWith summary: GBPingSummary!) {
        print("Ping timeout: \(summary)")
        handleFailure(pinger: pinger, error: nil, summary: summary)
    }
    func ping(_ pinger: GBPing!, didReceiveReplyWith summary: GBPingSummary!) {
        print("Successful reply")
        self.statusItem.image = self.goodImage
        self.lastSuccessPingSequence = summary.sequenceNumber
    }
    func ping(_ pinger: GBPing!, didSendPingWith summary: GBPingSummary!) {
        print("Sent ping successfully")
    }
    func ping(_ pinger: GBPing!, didReceiveUnexpectedReplyWith summary: GBPingSummary!) {
        print("Unexpected reply")
    }
    func ping(_ pinger: GBPing!, didFailToSendPingWith summary: GBPingSummary!, error: Error!) {
        print("Failed to send ping!")
        handleFailure(pinger: pinger, error: error, summary: summary)
    }
}
