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
struct AppNetworks: Identifiable {
    let id: Int32
    let name: String
    let image: NSImage?
    var bytesIn: UInt
    var bytesOut: UInt
}

extension Notification.Name {
    static let networkInfoChangeNotification = Notification.Name("networkInfoChangeNotification")
}

enum NettopType: String, Identifiable, CustomStringConvertible, CaseIterable {
    var description: String {
        rawValue
    }

    var localized: String {
        NSLocalizedString(self.description, comment: "")
    }
    
    var id: Self {
        return self
    }

    case wifi
    case wired
    case loopback
    case awdl
//    case expensive
//    case undefined
    case external
    case all
}

enum NettopMode: String, Identifiable, CustomStringConvertible, CaseIterable {
    var id: Self {
        return self
    }
    
    var localized: String {
        NSLocalizedString(self.description, comment: "")
    }

    var description: String {
        rawValue
    }

    case tcpAndUdp
    case tcp
    case udp
    case route
}

class Nettop: ObservableObject {
    // 最终输出使用
    @Published var appNetworkTrafficInfo: [AppNetworks] = []
    @Published var sortOrder = [KeyPathComparator(\AppNetworks.bytesIn, order: .reverse)]
    @Published var totalBytesIn: UInt = 0
    @Published var totalBytesOut: UInt = 0

    @Published var drawLess: Bool {
        didSet {
            rebuildCmdAndRestart()
            UserDefaults.standard.setValue(drawLess, forKey: "drawLess")
        }
    }

    @Published var type: NettopType {
        didSet {
            rebuildCmdAndRestart()
            UserDefaults.standard.setValue(type.description, forKey: "type")
        }
    }

    @Published var mode: NettopMode {
        didSet {
            rebuildCmdAndRestart()
            UserDefaults.standard.setValue(mode.description, forKey: "mode")
        }
    }

    // 进程相关
    var cmd: [String]
    var process: ProcessHelper?

    // 缓冲
    var buffer: [String] = []

    init() {
        self.drawLess = (UserDefaults.standard.object(forKey: "drawLess") as? Bool) ?? true
        self.type = NettopType(rawValue: (UserDefaults.standard.object(forKey: "type") as? String) ?? "") ?? .external
        self.mode = NettopMode(rawValue: (UserDefaults.standard.object(forKey: "mode") as? String) ?? "") ?? .tcpAndUdp
        cmd = []
        process = nil
        rebuildCmdAndRestart()
    }

    deinit {
        self.stop()
    }

    private func rebuildCmdAndRestart() {
        let mode: String
        switch self.mode {
        case .tcpAndUdp: mode = ""
        case .route: mode = "-m route"
        case .tcp: mode = "-m tcp"
        case .udp: mode = "-m udp"
        }
        
        let type: String
        if self.type == .all {
            type = ""
        } else {
            type = "-t \(self.type)"
        }

        let drawLess = self.drawLess ? " -c " : ""
        let shell = "export STDBUF=\"U\" && nettop \(drawLess) \(mode) \(type) -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 0 -P -n -s 1"
        Log.shared.info("\(shell)")
        cmd = ["-c", shell]
        start()
    }

    func start() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.process?.terminate()
            self.process = ProcessHelper.start(arguments: self.cmd, stdout: self.parseStdout)
        }
    }

    func stop() {
        process?.terminate()
        appNetworkTrafficInfo.removeAll(keepingCapacity: true)
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
//        appNetworkTrafficInfo.removeAll(keepingCapacity: true)
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
                Nettop.addAppInfo(item, map: &map)
                totalInput += item.bytesIn
                totalOutput += item.bytesOut
            }
        }
        DispatchQueue.main.async {
            self.totalBytesIn = totalInput
            self.totalBytesOut = totalOutput
            self.appNetworkTrafficInfo = map.values.sorted(using: self.sortOrder)
            NotificationCenter.default.post(name: .networkInfoChangeNotification, object: nil)
        }
    }

    private static func addAppInfo(_ item: Networks, map: inout [Int32: AppNetworks]) {
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
