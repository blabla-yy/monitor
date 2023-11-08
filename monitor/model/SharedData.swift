//
//  SharedData.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/11/7.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Foundation
import WidgetKit

struct WidgetSharedData {
    static var instance = WidgetSharedData()
    var dirURL: URL
    var dataFileURL: URL
    static let key = "com.blabla.monitor.widget2"
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

        dataFileURL = dirURL.appending(path: "data.txt")
    }

    func reset() {
        do {
            if FileManager.default.fileExists(atPath: dataFileURL.path) {
                try FileManager.default.removeItem(at: dataFileURL)
            }
        } catch {
            Log.shared.error("error to delete file \(dataFileURL.path), error \(error.localizedDescription)")
        }
    }

    func writeData(upload: UInt, download: UInt) {
        let content =
            """
            \(upload)
            \(download)
            \(Date.now.timeIntervalSince1970)
            """
        do {
            if !FileManager.default.fileExists(atPath: dataFileURL.path) {
                FileManager.default.createFile(atPath: dataFileURL.path, contents: nil)
            } else {
                try content.write(to: dataFileURL, atomically: true, encoding: .utf8)
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            Log.shared.error("error to write file \(dataFileURL.path), error \(error.localizedDescription)")
        }
    }
    
    func readData() -> SharedData? {
        if !FileManager.default.fileExists(atPath: dataFileURL.path) {
            return nil
        }
        do {
            let str = try String.init(contentsOf: dataFileURL, encoding: .utf8)
            let array = str.components(separatedBy: .newlines)
            if array.isEmpty || array.count != 3 {
                return nil
            }
            guard let up = UInt(array[0]),let down = UInt(array[1]), let double = Double(array[2]) else {
                return nil
            }
            return SharedData(networkUpload: up, networkDownload: down, timestamp: TimeInterval(double))
        } catch {
            Log.shared.error("error to write file \(dataFileURL.path), error \(error.localizedDescription)")
            return nil
        }
    }
}

struct SharedData: Codable {
    let networkUpload: UInt
    let networkDownload: UInt
    let timestamp: TimeInterval
    
//    let historyUpload: [UInt]
//    let hisotryDownload: [UInt]
}
