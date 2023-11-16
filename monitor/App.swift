//
//  App.swift
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
                    // trick
                    DispatchQueue.main.async {
                        delegate.networkBar?.openWindow = openWindow
                    }
                }
                .environmentObject(delegate.nettop)
        }
    }
}
