//
//  bandwidth.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Cocoa
import Foundation

struct Networks {
    let id: String
    let name: String
    let bytesIn: UInt
    let bytesOut: UInt
}

struct AppNetworks {
    let id: Int32
    let name: String
    let image: NSImage?
    var bytesIn: UInt
    var bytesOut: UInt
}

class Bandwidth {
    var info: [Networks] = []
    var appInfo: [AppNetworks] = []
    var cmd: [String]

    init() {
        let shell = "nettop -t wifi -t wired -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 2 -P -n"
        cmd = shell.split(separator: " ").map { String($0) }
    }

    func clear() {
        info.removeAll()
    }

    func refresh() {
        let outputString = handleCmdOutput(arguments: cmd)
        info.removeAll()
        appInfo.removeAll()
        if let output = outputString {
            var first = true
            var map: [Int32: AppNetworks] = [:]
            let strings = output.split(separator: "\n").filter({
                if $0.hasPrefix("time,") {
                    first = !first
                    return false
                }
                return first
            })

            for s in strings {
                let fields = s.split(separator: ",").map({ String($0) })
                if fields.count >= 4 {
                    var info = fields[1].split(separator: ".")
                    let id = info.count > 1 ? String(info.popLast() ?? "?") : "?"
                    let name = info.count == 1 ? String(info[0]) : info.joined(separator: ".")
                    let input = UInt(fields[2]) ?? 0
                    let output = UInt(fields[3]) ?? 0
                    let item = Networks(id: id, name: name, bytesIn: input, bytesOut: output)
                    self.info.append(item)
                    addAppInfo(item, map: &map)
                }
            }

            appInfo = map.values.sorted {
                $0.bytesIn == $1.bytesIn ? $0.name > $1.name : $0.bytesIn > $1.bytesIn
            }
        }
    }

    private func addAppInfo(_ item: Networks, map: inout [Int32: AppNetworks]) {
        if let pid = Int32(item.id) {
            let ppid = SysUtils.rootPid(pid: pid)
            if var app = map[ppid] {
                app.bytesIn += item.bytesIn
                app.bytesOut += item.bytesOut
            } else {
                let appInfo = NSRunningApplication(processIdentifier: ppid)
                let name = appInfo?.localizedName ?? item.name
                let app = AppNetworks(id: ppid, name: name, image: appInfo?.icon , bytesIn: item.bytesIn, bytesOut: item.bytesOut)
                map[ppid] = app
            }
        }
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
        for item in info {
            input += item.bytesIn
            output += item.bytesOut
        }
        return (Bandwidth.formatSpeed(v: input), Bandwidth.formatSpeed(v: output))
    }
}
