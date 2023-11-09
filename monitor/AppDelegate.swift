//
//  AppDelegate.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import AppKit
import Cocoa
import WidgetKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var networkBar: NetworkBar?
    var nettop = Nettop()
    static private(set) var instance: AppDelegate! = nil
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        if nettop.statusBar {
            return false
        }
        
        WidgetCenter.shared.getCurrentConfigurations({ result in
            switch result {
            case let .success(widgets):
                // 没有开启状态栏，且没有小组件。退出应用
                if widgets.isEmpty {
                    DispatchQueue.main.async {
                        print("applicationShouldTerminateAfterLastWindowClosed")
                        self.exit()
                    }
                }
            case let .failure(error):
                Log.shared.error("get widget configuration error \(error)")
            }
        })
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
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
        removeStatusBar()
        if nettop.statusBar {
            networkBar = NetworkBar(networkTraffic: nettop)
            networkBar?.setupMenu()
        }
    }

    @objc func resetStatusBar() {
        if !nettop.statusBar {
            return
        }
        self.removeStatusBar()
        networkBar = NetworkBar(networkTraffic: nettop)
        networkBar?.setupMenu()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit()
    }

    private func removeStatusBar() {
        if let item = networkBar?.networkMenuItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        networkBar = nil
    }
    
    func stop() {
        Log.shared.info("stop.")
        nettop.stop()
    }
    
    func start() {
        self.stop()
        self.nettop.start()
    }
    
    @objc func exit() {
        self.stop()
        NSApplication.shared.terminate(nil)
    }

    static func applicationExit() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.exit()
        }
    }
}
