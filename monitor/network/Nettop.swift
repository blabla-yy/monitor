//
//  Nettop.swift
//  BandwidthMonitor
//
//  Created by wyy on 2021/1/28.
//  Copyright © 2021 yahaha. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

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
}

class NettopBandwidth: ObservableObject {
    // 最终输出使用
    @Published var appBandwidthInfo: [AppNetworks] = []
    @Published var totalBytesIn: UInt = 0
    @Published var totalBytesOut: UInt = 0

    // 进程相关
    let cmd: [String]
    var process: ProcessHelper?

    // 缓冲
    var buffer: [String] = []

    var onRefresh: () -> Void

    init() {
        let shell = "export STDBUF=\"U\" && nettop -t wifi -t wired -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 0 -P -n -s 1"
        cmd = ["-c", shell]
        process = nil
        onRefresh = {}
    }

    func start(_ callback: @escaping () -> Void) {
        process?.terminate()
        onRefresh = callback
        process = ProcessHelper.start(arguments: cmd, stdout: parseStdout)
    }

    func stop() {
        process?.terminate()
        appBandwidthInfo.removeAll(keepingCapacity: true)
        buffer.removeAll(keepingCapacity: true)
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
        appBandwidthInfo.removeAll(keepingCapacity: true)
        var map: [Int32: AppNetworks] = [:]

        var totalInput: UInt = 0
        var totalOutput: UInt = 0
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
                totalInput += item.bytesIn
                totalOutput += item.bytesOut
            }
        }
        totalBytesIn = totalInput
        totalBytesOut = totalOutput
        appBandwidthInfo = map.values.sorted {
            $0.bytesIn == $1.bytesIn ? $0.name > $1.name : $0.bytesIn > $1.bytesIn
        }
        onRefresh()
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
