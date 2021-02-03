//
//  bandwidth.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Cocoa
import Foundation

struct AppNetworks {
    let id: Int32
    let name: String
    let image: NSImage?
    var bytesIn: UInt
    var bytesOut: UInt
}

class Bandwidth {
    var appInfo: [AppNetworks] = []

    func clear() {
        appInfo.removeAll()
    }

    func start(_ callback: @escaping () -> Void) {
    }

    public static func formatSpeed(v: UInt) -> String {
        if v == 0 {
            return "0 B/s"
        }
        if v / 1024 < 1 {
            return "\(v) B/s"
        }

        var value = Double(v) / 1024.0
        if value / 1024 < 1 {
            return String(format: "%.2f KB/s", value)
        }

        value = Double(value) / 1024.0
        if value / 1024 < 1 {
            return String(format: "%.2f MB/s", value)
        }

        value = Double(value) / 1024
        return String(format: "%.2f GB/s", value)
    }

    func total() -> (String, String) {
        var input: UInt = 0
        var output: UInt = 0
        for item in appInfo {
            input += item.bytesIn
            output += item.bytesOut
        }
        return (Bandwidth.formatSpeed(v: input), Bandwidth.formatSpeed(v: output))
    }

    func addAppInfo(_ item: Networks, map: inout [Int32: AppNetworks]) {
        if let pid = Int32(item.id) {
            let ppid = SysUtils.rootPid(pid: pid)
            if var app = map[ppid] {
                app.bytesIn += item.bytesIn
                app.bytesOut += item.bytesOut
            } else {
                let appInfo = NSRunningApplication(processIdentifier: ppid)
                let name = appInfo?.localizedName ?? item.name
                let app = AppNetworks(id: ppid, name: name, image: appInfo?.icon, bytesIn: item.bytesIn, bytesOut: item.bytesOut)
                map[ppid] = app
            }
        }
    }
}
