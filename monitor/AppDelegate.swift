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
    var nettop = Nettop()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if networkBar == nil && nettop.statusBar {
            networkBar = NetworkBar(networkTraffic: nettop)
            networkBar?.setupMenu()
        }
        if NSApplication.shared.mainWindow == nil {
            let mainWindow = NSApplication.shared.windows.first { window in
                window.canBecomeMain
            }
            mainWindow?.makeMain()
        }
        nettop.rebuildCmdAndRestart()
        NotificationCenter.default.addObserver(self, selector: #selector(resetStatusBar), name: .statusBarChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(switchStatusBar), name: .statusBarSwitchNotification, object: nil)
    }

    @objc func switchStatusBar() {
        if let item = networkBar?.networkMenuItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        networkBar = nil
        if nettop.statusBar {
            networkBar = NetworkBar(networkTraffic: nettop)
            networkBar?.setupMenu()
        }
    }

    @objc func resetStatusBar() {
        if !nettop.statusBar {
            return
        }
        if let item = networkBar?.networkMenuItem {
            NSStatusBar.system.removeStatusItem(item)
            networkBar = nil
        }
        networkBar = NetworkBar(networkTraffic: nettop)
        networkBar?.setupMenu()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.exit()
    }
    
    @objc func exit() {
        Log.shared.info("exit.")
        self.nettop.stop()
        if let item = networkBar?.networkMenuItem {
            NSStatusBar.system.removeStatusItem(item)
            networkBar = nil
        }
        NSApplication.shared.terminate(nil)
    }
    
    static func applicationExit() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.exit()
        }
    }
}
