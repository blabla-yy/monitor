//
//  SettingView.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/11/1.
//  Copyright © 2023 yahaha. All rights reserved.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var nettop: Nettop
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some View {
        Form {
            Section {
                Picker("Mode", selection: .init(get: {
                    nettop.mode
                }, set: {
                    nettop.mode = $0
                }), content: {
                    ForEach(NettopMode.allCases) {
                        Text($0.localized)
                    }
                })
                
                Picker("Type", selection: .init(get: {
                    nettop.type
                }, set: {
                    nettop.type = $0
                }), content: {
                    ForEach(NettopType.allCases) {
                        Text($0.localized)
                    }
                })
                
                Toggle("Reduce energy consumption", isOn: .init(get: {
                    self.nettop.drawLess
                }, set: {
                    self.nettop.drawLess = $0
                }))
            } header: {
                Text("Basic")
            }
            
            Section {
                Toggle("Switch", isOn: .init(get: {
                    self.nettop.statusBar
                }, set: {
                    self.nettop.statusBar = $0
                }))
                Toggle("Keep Decimals", isOn: .init(get: {
                    self.nettop.keepDecimals
                }, set: {
                    self.nettop.keepDecimals = $0
                }))
            } header: {
                Text("Status Bar")
            }
            
            Section {
                Button("Exit") {
                    appDelegate.exit()
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingView()
        .environmentObject(Nettop())
}
