//
//  PreferencesWindow.swift
//  WX02-Checker
//
//  Created by moon on 2016/06/06.
//  Copyright © 2016年 buntatsu. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

class PreferencesWindow: NSWindowController, NSWindowDelegate  {
    @IBOutlet weak var addressTextField: NSTextField!
    @IBOutlet weak var userTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!
    
    var delegate: PreferencesWindowDelegate?

    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)

        let defaults = NSUserDefaults.standardUserDefaults()

        if let address = defaults.stringForKey("address") {
            addressTextField.stringValue = address
        }
        let user = defaults.stringForKey("user") ?? DEFAULT_USER
        userTextField.stringValue = user
        if let password = defaults.stringForKey("password") {
            passwordTextField.stringValue = password
        }
    }
    
    override func showWindow(sender: AnyObject?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
    
    func windowWillClose(notification: NSNotification) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(addressTextField.stringValue, forKey: "address")
        defaults.setValue(userTextField.stringValue, forKey: "user")
        defaults.setValue(passwordTextField.stringValue, forKey: "password")
        
        delegate?.preferencesDidUpdate()
    }
}
