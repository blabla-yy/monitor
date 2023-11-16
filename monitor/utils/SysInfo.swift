//
//  MemoryInfo.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/11/16.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Darwin
import Foundation

struct SysInfo {
    static func getMemoryUsageInfo() -> MemoryUsageInfo? {
        var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var hostInfo = vm_statistics_data_t()
        let hostPort: mach_port_t = mach_host_self()

        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                host_statistics(hostPort, HOST_VM_INFO, $0, &hostSize)
            }
        }

        if result == KERN_SUCCESS {
            var free = UInt64(hostInfo.free_count) / 1024
            if free > UInt64.max / 4096 {
                free = free / 1024 * 4096
            } else {
                free = free * 4096 / 1024
            }
            let total = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
            return .init(usageMB: total - free, totoalMB: total, timestamp: .now)
        } else {
            Log.shared.error("Error with result: \(result)")
        }

        return nil
    }

    static func getCpuUsageInfo(lastInfo: CpuUsageInfo) -> CpuUsageInfo {
        var cpuInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processors: natural_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processors, &cpuInfo, &processorMsgCount)

        let lastUserUsage = lastInfo.totalUser
        let lastSystemUsage = lastInfo.totalSystem
        let lastTotal = lastInfo.total

        if result == KERN_SUCCESS {
            let cpuInfoArray = cpuInfo!

            var deltaUser: Int64 = lastUserUsage
            var deltaSystem: Int64 = lastSystemUsage
            var deltaTotal: Int64 = lastTotal

            for i in 0 ..< Int(processors) {
                let user = cpuInfoArray.advanced(by: Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)).pointee
                let system = cpuInfoArray.advanced(by: Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)).pointee
                let idle = cpuInfoArray.advanced(by: Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)).pointee
                let nice = cpuInfoArray.advanced(by: Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)).pointee
                deltaUser -= Int64(user)
                deltaSystem = deltaSystem - Int64(system) - Int64(nice)
                deltaTotal = deltaTotal - Int64(user) - Int64(system) - Int64(idle) - Int64(nice)
            }
            deltaTotal = -deltaTotal
            deltaSystem = -deltaSystem
            deltaUser = -deltaUser

            vm_deallocate(mach_task_self_, vm_address_t(Int(bitPattern: cpuInfo)), vm_size_t(processorMsgCount))

            return CpuUsageInfo(userPercentage: Double(deltaUser) / Double(deltaTotal) * 100,
                                sysPercentage: Double(deltaSystem) / Double(deltaTotal) * 100,
                                timestamp: .now,
                                totalUser: lastUserUsage + deltaUser,
                                totalSystem: lastSystemUsage + deltaSystem,
                                total: lastTotal + deltaTotal)
        } else {
            print("Error: \(mach_error_string(result))")
        }
        return .init(userPercentage: 0, sysPercentage: 0, timestamp: .now, totalUser: 0, totalSystem: 0, total: 0)
    }
}
