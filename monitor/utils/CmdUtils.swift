//
//  CmdUtils.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Foundation

func handleCmdOutput(arguments: [String]) -> String? {
    let process = Process()
    let output = Pipe()
    process.launchPath = "/usr/bin/env"
    process.arguments = arguments
    process.standardOutput = output

    process.launch()
    process.waitUntilExit()
    let fileHandle = output.fileHandleForReading
    let outputString = String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)

    process.terminate()
    fileHandle.closeFile()
    return outputString
}

struct ProcessHelper {
    let process: Process

    static func start(arguments: [String],
                      stdout: @escaping (Data) -> Void) -> ProcessHelper {
        let process = Process()
        let output = Pipe()
        let readingHandle = output.fileHandleForReading
        process.launchPath = "/usr/bin/env"
        process.arguments = arguments
        process.standardOutput = output

        let stderr = Pipe()
        process.standardError = stderr

        readingHandle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                return
            }
            stdout(data)
        }

        stderr.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                return
            }
            let output = String(data: data, encoding: .utf8) ?? ""
            if !output.isEmpty {
                print("process has error: \(output)")
            }
        }
//        if #available(macOS 10.13, *) {
//            process.run()
//        } else {
        process.launch()
        return ProcessHelper(process: process)
    }

    func isRunning() -> Bool {
        process.isRunning
    }

    func wait() {
        if process.isRunning {
            process.waitUntilExit()
        }
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
        }
    }
}
