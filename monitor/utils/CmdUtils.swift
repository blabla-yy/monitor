//
//  CmdUtils.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Foundation
import Cocoa

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
    let stdoutFD: FileHandle
    let stderrFD: FileHandle

    static func getPreferredShell() -> String {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: "/bin/zsh") {
            return "/bin/zsh"
        } else {
            return "/bin/bash"
        }
    }
    
    static func start(arguments: [String],
                      stdout: @escaping (Data) -> Void) -> ProcessHelper {
        let process = Process()
        let output = Pipe()
        let readingHandle = output.fileHandleForReading
        process.launchPath = ProcessHelper.getPreferredShell()
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
                Log.shared.error("process has error: \(output)")
            }
        }
        process.launch()
        return ProcessHelper(process: process, stdoutFD: readingHandle, stderrFD: stderr.fileHandleForReading)
    }

    func isRunning() -> Bool {
        process.isRunning
    }

    func wait() {
        if process.isRunning {
            process.waitUntilExit()
            try? self.stderrFD.close()
            try? self.stdoutFD.close()
        }
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
            try? self.stderrFD.close()
            try? self.stdoutFD.close()
        }
    }
}
