//
//  ThirdBandwidth.swift
//  BandwidthMonitor
//
//  Created by wyy on 2021/1/22.
//  Copyright © 2021 yahaha. All rights reserved.
//

import Cocoa
import Foundation

class PnetBandwidth: Bandwidth {
    static let instance = PnetBandwidth()

    override private init() {
    }

    private static func convert<T>(count: Int, data: UnsafePointer<T>) -> [T] {
        let buffer = UnsafeBufferPointer(start: data, count: count)
        return Array(buffer)
    }

    private var info: [ProcessPacketLength] = []

    private var callback: () -> Void = {}

    override func start(_ callback: @escaping () -> Void) {
        self.callback = callback
        DispatchQueue.global().async {
            take { statistic in
                PnetBandwidth.instance.info = PnetBandwidth.convert(count: Int(statistic.length), data: statistic.list)
                PnetBandwidth.instance.update()
            }
        }
    }

    private func update() {
        var map: [Int32: AppNetworks] = [:]
        for item in info {
            let ppid = SysUtils.rootPid(pid: Int32(item.pid))
            if var app = map[ppid] {
                app.bytesIn += item.download_length
                app.bytesOut += item.upload_length
            } else {
                let appInfo = NSRunningApplication(processIdentifier: ppid)
                let name = appInfo?.localizedName ?? ""
                let app = AppNetworks(id: ppid, name: name, image: appInfo?.icon, bytesIn: item.download_length, bytesOut: item.upload_length)
                map[ppid] = app
            }
        }
        appInfo = map.values.sorted {
            $0.bytesIn == $1.bytesIn ? $0.name > $1.name : $0.bytesIn > $1.bytesIn
        }
        callback()
    }
}
