//
//  AppDelegate.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import AppKit
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var networkBar: NetworkBar?
    var nettop: Nettop = .init()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if networkBar == nil {
            networkBar = NetworkBar(networkTraffic: nettop)
            networkBar?.setupMenu()
        }
        if NSApplication.shared.mainWindow == nil {
            let mainWindow = NSApplication.shared.windows.first { window in
                window.canBecomeMain
            }
            mainWindow?.makeMain()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        networkBar?.networkTraffic.stop()
    }

    func applicationWillBecomeActive(_ notification: Notification) {
    }
}
