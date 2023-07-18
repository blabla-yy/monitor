//
//  Nettop.swift
//  BandwidthMonitor
//
//  Created by wyy on 2021/1/28.
//  Copyright © 2021 yahaha. All rights reserved.
//

import Cocoa
import Foundation

// 进程流量信息
fileprivate struct Networks {
    let id: String
    let name: String
    let bytesIn: UInt
    let bytesOut: UInt
}

// 包含App得进程流量信息
struct AppNetworks {
    let id: Int32
    let name: String
    let image: NSImage?
    var bytesIn: UInt
    var bytesOut: UInt
    
    var formatIn: String {
        formatSpeed(v: bytesIn)
    }
    
    var formatOut: String {
        formatSpeed(v: bytesOut)
    }
}

func formatSpeed(v: UInt) -> String {
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

class NettopBandwidth {
    // 最终输出使用
    var appInfo: [AppNetworks] = []

    // 进程相关
    let cmd: [String]
    var process: ProcessHelper?

    // 缓冲
    var buffer: [String] = []

    var onRefresh: () -> Void
    
    init() {
        let shell = "nettop -t wifi -t wired -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 0 -P -n"
        cmd = shell.split(separator: " ").map { String($0) }
        process = nil
        onRefresh = {}
    }

    func start(_ callback: @escaping () -> Void) {
        process?.terminate()
        self.onRefresh = callback
        process = ProcessHelper.start(arguments: cmd, stdout: parseStdout)
        
    }
    
    func stop() {
        process?.terminate()
        self.appInfo.removeAll(keepingCapacity: true)
        self.buffer.removeAll(keepingCapacity: true)
    }

    func parseStdout(data: Data) {
        let stdout = String(data: data, encoding: .utf8) ?? ""
        stdout
            .components(separatedBy: "\n")
            .forEach { item in
                if item.isEmpty {
                    return
                }
                if item == "time,,bytes_in,bytes_out," {
                    refreshData(strings: self.buffer)
                    self.buffer.removeAll(keepingCapacity: true)
                } else {
                    if buffer.count < 128 {
                        buffer.append(item)
                    }
                }
            }
    }

    private func refreshData(strings: [String]) {
//        info.removeAll(keepingCapacity: true)
        appInfo.removeAll(keepingCapacity: true)

        var map: [Int32: AppNetworks] = [:]

        for s in strings {
            let fields = s.split(separator: ",").map({ String($0) })
            if fields.count >= 4 {
                var info = fields[1].split(separator: ".")
                let id = info.count > 1 ? String(info.popLast() ?? "?") : "?"
                let name = info.count == 1 ? String(info[0]) : info.joined(separator: ".")
                let input = UInt(fields[2]) ?? 0
                let output = UInt(fields[3]) ?? 0
                let item = Networks(id: id, name: name, bytesIn: input, bytesOut: output)
                addAppInfo(item, map: &map)
            }
        }

        appInfo = map.values.sorted {
            $0.bytesIn == $1.bytesIn ? $0.name > $1.name : $0.bytesIn > $1.bytesIn
        }
        self.onRefresh()
    }

    func total() -> (String, String) {
        var input: UInt = 0
        var output: UInt = 0
        for item in appInfo {
            input += item.bytesIn
            output += item.bytesOut
        }
        return (formatSpeed(v: input), formatSpeed(v: output))
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
                let app = AppNetworks(id: ppid, name: name, image: appInfo?.icon, bytesIn: item.bytesIn, bytesOut: item.bytesOut)
                map[ppid] = app
            }
        }
    }
}
