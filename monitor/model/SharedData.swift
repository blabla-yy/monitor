//
//  SharedData.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/11/7.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Foundation
import WidgetKit

class WidgetSharedData {
    static var instance = WidgetSharedData()
    var dirURL: URL
    var dataFileURL: URL
    static let key = "com.blabla.monitor.widget"
    
    init() {
        let bundleIdentifier = Bundle.main.bundleIdentifier
        print("bundleIdentifier: \(bundleIdentifier ?? "nil")")
        if bundleIdentifier == WidgetSharedData.key {
            dirURL = .temporaryDirectory
        } else {
            dirURL = FileManager.default.homeDirectoryForCurrentUser.appending(component: "/Library/Containers/\(WidgetSharedData.key)/Data/tmp")
        }
        print("dir path \(dirURL.path)")
        print("dir is readable \(FileManager.default.isReadableFile(atPath: dirURL.path))")
        print("dir is writable \(FileManager.default.isWritableFile(atPath: dirURL.path))")

        dataFileURL = dirURL.appending(path: "data.json")
    }

    func reset() {
        do {
            if FileManager.default.fileExists(atPath: dataFileURL.path) {
                try FileManager.default.removeItem(at: dataFileURL)
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            Log.shared.error("error to delete file \(self.dataFileURL.path), error \(error.localizedDescription)")
        }
    }

    func writeData(date: Date,
                   networkHistories: [NetworkData],
                   maxValue: UInt,
                   memory: [MemoryUsageInfo],
                   cpu: [CpuUsageInfo]) {
        do {
            if !FileManager.default.fileExists(atPath: dataFileURL.path) {
                FileManager.default.createFile(atPath: dataFileURL.path, contents: nil)
            } else {
                let data = try JSONEncoder().encode(SharedData(timestamp: date, maxNetworkValue: maxValue, networkHistory: networkHistories, memory: memory, cpu: cpu))
                try data.write(to: dataFileURL)
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            Log.shared.error("error to write file \(self.dataFileURL.path), error \(error.localizedDescription)")
        }
    }
    
    func readData() -> SharedData? {
        if !FileManager.default.fileExists(atPath: dataFileURL.path) {
            return nil
        }
        do {
            let data = try Data(contentsOf: dataFileURL)
            return try JSONDecoder().decode(SharedData.self, from: data)
        } catch {
            Log.shared.error("error to write file \(self.dataFileURL.path), error \(error.localizedDescription)")
            return nil
        }
    }
}

struct SharedData: Codable {
    let timestamp: Date
    let maxNetworkValue: UInt
    let networkHistory: [NetworkData]
    
    let memory: [MemoryUsageInfo]
    let cpu: [CpuUsageInfo]
    
    var networkUnit: String {
        if maxNetworkValue > 1024 * 1024 {
            return "MB"
        } else if maxNetworkValue > 1024 {
            return "KB"
        }
        return "B"
    }
}

struct MemoryUsageInfo: Codable, Identifiable {
    let usageMB: UInt64
    let totoalMB: UInt64
    let timestamp: Date
    
    var id: Date { timestamp }
    
    var usagePercentage: Double {
        usageMB == 0 || totoalMB == 0 ? 0 : Double(usageMB / totoalMB)
    }
}

struct CpuUsageInfo: Codable, Identifiable {
    let userPercentage: Double
    let sysPercentage: Double
    
    let timestamp: Date
    
    let totalUser:Int64
    let totalSystem: Int64
    let total: Int64
    
    var id: Date { timestamp }
}

struct NetworkData: Codable, Identifiable {
    let upload: UInt
    let download: UInt
    let timestamp: Date
    
    func adaptUploadValue(maxNetworkValue: UInt) -> UInt {
        if maxNetworkValue > 1024 * 1024 {
            return upload / 1024 / 1024
        } else if maxNetworkValue > 1024 {
            return upload / 1024
        }
        return upload
    }
    
    func adaptDownloadValue(maxNetworkValue: UInt) -> UInt {
        if maxNetworkValue > 1024 * 1024 {
            return download / 1024 / 1024
        } else if maxNetworkValue > 1024 {
            return download / 1024
        }
        return download
    }
    
    var id: Date {
        timestamp
    }
}
