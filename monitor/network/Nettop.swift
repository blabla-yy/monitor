//
//  Nettop.swift
//  BandwidthMonitor
//
//  Created by wyy on 2021/1/28.
//  Copyright © 2021 yahaha. All rights reserved.
//

import Cocoa
import Foundation

struct Networks {
    let id: String
    let name: String
    let bytesIn: UInt
    let bytesOut: UInt
}

class NettopBandwidth: Bandwidth {
    var cmd: [String]
    var info: [Networks] = []
    var timer: Timer?

    override init() {
        let shell = "nettop -t wifi -t wired -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 2 -P -n"
        cmd = shell.split(separator: " ").map { String($0) }
    }

    override func start(_ callback: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.refresh()
            callback()
        })

        if let timer = timer {
            // 如果是default 需要等待UITrackingRunLoopMode完成，才会触发计时器
            RunLoop.current.add(timer, forMode: .common)
            timer.fire()
        }
    }

    func refresh() {
        let outputString = handleCmdOutput(arguments: cmd)
        info.removeAll(keepingCapacity: true)
        appInfo.removeAll(keepingCapacity: true)
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
}
