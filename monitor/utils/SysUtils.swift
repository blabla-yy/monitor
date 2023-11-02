//
//  Sysctl.swift
//  monitor
//
//  Created by wyy on 2019/10/14.
//  Copyright © 2019 yahaha. All rights reserved.
//
import OSLog
import Foundation

enum SysctlError: Error {
    case unknown
    case malformedUTF8
    case invalidSize
    case posixError(POSIXErrorCode)
}

struct Log {
    static let shared = Logger.init()
}

struct SysUtils {
    static func ppid(pid: Int32) -> Int32 {
        do {
            let keys = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
            return try keys.withUnsafeBufferPointer { keysPointer throws -> Int32 in
                var kinfo = kinfo_proc()
                var size  = MemoryLayout<kinfo_proc>.stride
                
                let preFlightResult = Darwin.sysctl(UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress), UInt32(keys.count), &kinfo, &size, nil, 0)
                if preFlightResult != 0 {
                    throw POSIXErrorCode(rawValue: errno).map {
                        Log.shared.error("POSIXErrorCode \($0.rawValue)")
                        return SysctlError.posixError($0)
                        } ?? SysctlError.unknown
                }
                return kinfo.kp_eproc.e_ppid
            }
        } catch let e { Log.shared.error("ppid error \(e.localizedDescription)") }
        return -1
    }
    
    // 除了1
    static func rootPid(pid: Int32) -> Int32 {
        var lastPid = pid
        var res = pid

        while res > 1 {
            lastPid = res
            res = ppid(pid: pid)
            if lastPid == res {
                break
            }
        }
        return lastPid
    }
}
