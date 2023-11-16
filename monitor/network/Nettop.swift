//
//  Nettop.swift
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
    static let statusBarChangeNotification = Notification.Name("statusBarChangeNotification")

    static let statusBarSwitchNotification = Notification.Name("statusBarSwitchNotification")
}

enum NettopType: String, Identifiable, CustomStringConvertible, CaseIterable {
    var description: String {
        rawValue
    }

    var localized: String {
        NSLocalizedString(description, comment: "")
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
        NSLocalizedString(description, comment: "")
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

    @Published var keepDecimals: Bool {
        didSet {
            UserDefaults.standard.setValue(keepDecimals, forKey: "keepDecimals")
            NotificationCenter.default.post(name: .statusBarChangeNotification, object: nil)
        }
    }

    // 是否开启状态栏
    @Published var statusBar: Bool {
        didSet {
            UserDefaults.standard.setValue(statusBar, forKey: "statusBar")
            NotificationCenter.default.post(name: .statusBarSwitchNotification, object: nil)
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

    @Published var networkHisotries: [NetworkData] = []

    @Published var started = false

    // 是否已经弃掉第一部分数据
    var droppedCount: Int = 0
    var networkHistoryMaxValue: UInt = 0

    // 进程相关
    var cmd: [String]
    var process: ProcessHelper?
    var memoryHistories: [MemoryUsageInfo] = []
    var cpuHistories: [CpuUsageInfo] = []

    // 缓冲
    var buffer: [String] = []

    init() {
        drawLess = (UserDefaults.standard.object(forKey: "drawLess") as? Bool) ?? true
        keepDecimals = (UserDefaults.standard.object(forKey: "keepDecimals") as? Bool) ?? false
        statusBar = (UserDefaults.standard.object(forKey: "statusBar") as? Bool) ?? true
        type = NettopType(rawValue: (UserDefaults.standard.object(forKey: "type") as? String) ?? "") ?? .external
        mode = NettopMode(rawValue: (UserDefaults.standard.object(forKey: "mode") as? String) ?? "") ?? .tcpAndUdp
        cmd = []
        process = nil
    }

    deinit {
        self.stop()
    }

    func rebuildCmdAndRestart() {
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
        stop()
        started = true
        DispatchQueue.global(qos: .userInteractive).async {
            self.process = ProcessHelper.start(arguments: self.cmd, stdout: self.parseStdout)
        }
    }

    func stop() {
        started = false
        process?.terminate()
        process = nil
        droppedCount = 0
        networkHistoryMaxValue = 0
        appNetworkTrafficInfo.removeAll(keepingCapacity: true)
        WidgetSharedData.instance.reset()
        buffer.removeAll(keepingCapacity: true)

        totalBytesIn = 0
        totalBytesOut = 0
        buffer.removeAll(keepingCapacity: true)
        NotificationCenter.default.post(name: .networkInfoChangeNotification, object: nil)
    }

    func parseStdout(data: Data) {
        let stdout = String(data: data, encoding: .utf8) ?? ""
        let lines = stdout.components(separatedBy: "\n")
        DispatchQueue.main.async {
            for item in lines {
                if item.isEmpty {
                    continue
                }
                if item == "time,,bytes_in,bytes_out," {
                    self.refreshData(strings: self.buffer)
                    self.buffer.removeAll(keepingCapacity: true)
                } else {
                    if self.buffer.count < 128 {
                        self.buffer.append(item)
                    }
                }
            }
        }
    }

    private func fillHistories() {
        var histories: [NetworkData] = []
        var memories: [MemoryUsageInfo] = []
        var cpu: [CpuUsageInfo] = []
        let now = Date.now
        for i in 0 ..< 60 {
            if let date = Calendar.current.date(byAdding: .second, value: -(60 - i), to: now) {
                histories.append(.init(upload: 0, download: 0, timestamp: date))
                memories.append(.init(usageMB: 0, totoalMB: 0, timestamp: date))
                cpu.append(.init(userPercentage: 0, sysPercentage: 0, timestamp: date, totalUser: 0, totalSystem: 0, total: 0))
            }
        }
        networkHisotries = histories
        memoryHistories = memories
        cpuHistories = cpu
        networkHistoryMaxValue = 0
    }

    private func sendToWidget() {
        WidgetSharedData.instance.writeData(date: Date.now,
                                            networkHistories: networkHisotries,
                                            maxValue: networkHistoryMaxValue,
                                            memory: memoryHistories,
                                            cpu: cpuHistories)
    }

    private func refreshData(strings: [String]) {
        if droppedCount < 2 {
            droppedCount += 1
            buffer.removeAll(keepingCapacity: true)
            fillHistories()
            
            
            var cpu = SysInfo.getCpuUsageInfo(lastInfo: cpuHistories.last ?? .init(userPercentage: 0, sysPercentage: 0, timestamp: .now, totalUser: 0, totalSystem: 0, total: 0))
            cpuHistories.append(CpuUsageInfo(userPercentage: 0, sysPercentage: 0, timestamp: .now, totalUser: cpu.totalUser, totalSystem: cpu.totalSystem, total: cpu.total))
            while cpuHistories.count > 60 {
                cpuHistories.removeFirst()
            }
            if droppedCount == 2 {
                sendToWidget()
            }
            return
        }
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

        let now = Date.now
        let network = NetworkData(upload: totalBytesIn, download: totalBytesOut, timestamp: now)
        networkHisotries.append(network)
        networkHistoryMaxValue = max(totalBytesIn, totalBytesOut, networkHistoryMaxValue)
        while networkHisotries.count > 60 {
            let removed = networkHisotries.removeFirst()
            if removed.upload == networkHistoryMaxValue || removed.download == networkHistoryMaxValue {
                var maxValue: UInt = 0
                networkHisotries.forEach { item in
                    maxValue = max(item.upload, item.download, maxValue)
                }
                networkHistoryMaxValue = maxValue
            }
        }
        if let memroy = SysInfo.getMemoryUsageInfo() {
            memoryHistories.append(memroy)
            while memoryHistories.count > 60 {
                memoryHistories.removeFirst()
            }
        }
        let cpu = SysInfo.getCpuUsageInfo(lastInfo: cpuHistories.last ?? .init(userPercentage: 0, sysPercentage: 0, timestamp: .now, totalUser: 0, totalSystem: 0, total: 0))
        cpuHistories.append(cpu)
        while cpuHistories.count > 60 {
            cpuHistories.removeFirst()
        }

        totalBytesIn = totalInput
        totalBytesOut = totalOutput
        appNetworkTrafficInfo = map.values.sorted(using: sortOrder)
        sendToWidget()
        NotificationCenter.default.post(name: .networkInfoChangeNotification, object: nil)
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
