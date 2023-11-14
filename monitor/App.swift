//
//  App.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/11/1.
//  Copyright © 2023 yahaha. All rights reserved.
//

import SwiftUI

@main
struct Main: App {
    static let id = "main"

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        WindowGroup(id: Main.id) {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        delegate.networkBar?.openWindow = openWindow
//                        let task = Process()
//                        let cmd = "whoami"
//                        task.launchPath = "/usr/bin/osascript"
//                        task.arguments = ["-e", "do shell script \"\(cmd)\" with administrator privileges"]
//
//                        let pipe = Pipe()
//                        task.standardOutput = pipe
//                        task.launch()
//
//                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//                        let output = String(data: data, encoding: .utf8)!
//
//                        print(output)
                    }
                }
                .environmentObject(delegate.nettop)
        }
    }
}
