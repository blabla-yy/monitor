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
