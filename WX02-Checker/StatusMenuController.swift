//
//  StatusMenuController.swift
//  WX02-Checker
//
//  Created by moon on 2016/06/01.
//  Copyright © 2016年 buntatsu. All rights reserved.
//

import Cocoa

let DEFAULT_USER = "admin"

class StatusMenuController: NSObject, NSMenuDelegate, PreferencesWindowDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var statusView: WX02StatusView!
    var statusMenuItem: NSMenuItem!
    
    var preferencesWindow: PreferencesWindow!
    
    let statusItem = NSStatusBar.systemStatusBar()
        .statusItemWithLength(NSVariableStatusItemLength)
    let wx02Web = WX02Web()

    let fefreshRate: NSTimeInterval = 3
    var refreshTimer: NSTimer?

    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.template = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        statusMenuItem = statusMenu.itemWithTitle("WX02 Status")
        statusMenuItem.view = statusView

        statusMenu.delegate = self
        
        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func preferencesClicked(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        preferencesWindow.showWindow(nil)
    }
    
    func updateStatus() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let address = defaults.stringForKey("address")
        let user = defaults.stringForKey("user") ?? DEFAULT_USER
        let password = defaults.stringForKey("password")
        
        wx02Web.fetchTraffic(address!, user: user, password: password!) { traffic in
            self.statusView.update(traffic)
        }
        wx02Web.fetchStatus(address!, user: user, password: password!) { status in
            self.statusView.update(status)
        }
    }
    
    func timerFireMethod(timer: NSTimer) {
        self.updateStatus()
    }

    func enableTimer() {
        refreshTimer = NSTimer(
            timeInterval: fefreshRate, target: self,
            selector: #selector(StatusMenuController.timerFireMethod(_:)),
            userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(refreshTimer!, forMode: NSRunLoopCommonModes)
    }

    func disableTimer() {
        refreshTimer!.invalidate()
    }

    func menuWillOpen(menu: NSMenu) {
        updateStatus()
        enableTimer()
    }
    
    func menuDidClose(menu: NSMenu) {
        disableTimer()
    }
    
    func preferencesDidUpdate() {
        updateStatus()
    }
}