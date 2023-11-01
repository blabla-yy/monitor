//
//  ContentView.swift
//  NetworkMonitor
//
//  Created by wyy on 2023/10/31.
//  Copyright © 2023 yahaha. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var wifi: Bool
    @State var wired: Bool
    var body: some View {
        VStack {
            Toggle(isOn: <#T##Binding<Bool>#>, label: <#T##() -> Label#>)
            RealTimeNetworkTrafficView()
        }
    }
}

struct RealTimeNetworkTrafficView: View {
    @EnvironmentObject var nettop: Nettop
    @State var searchText = ""
    @State var filtered: [AppNetworks] = []
    @State var sortOrder = [KeyPathComparator(\AppNetworks.bytesIn, order: .reverse)]

    @State var selection: Set<AppNetworks.ID> = []
    var body: some View {
        Table(filtered, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("") { item in
                Image(nsImage: item.image ?? .init())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
            }
            .width(24)

            TableColumn("pid", value: \.id.description)
                .width(min: 36, ideal: 36)
            TableColumn("processName", value: \.name)
            TableColumn("upload", value: \.bytesOut) { item in
                Text(item.bytesOut.speedFormatted)
            }
            TableColumn("download", value: \.bytesIn) { item in
                Text(item.bytesIn.speedFormatted)
            }
        }
        .searchable(text: $searchText)
        .onReceive(NotificationCenter.default.publisher(for: .networkInfoChangeNotification), perform: { _ in
            self.refreshTable()
        })
        .onChange(of: sortOrder) { _ in
            filtered.sort(using: sortOrder)
        }
        .onChange(of: searchText) { _ in
            self.refreshTable()
        }
    }

    func refreshTable() {
        searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pid = Int(searchText)
        if searchText.isEmpty {
            filtered = nettop.appNetworkTrafficInfo
        } else {
            filtered = nettop.appNetworkTrafficInfo.filter { item in
                if let pid = pid {
                    return item.id == pid
                }
                return item.name.contains(searchText)
            }
        }
        if sortOrder != nettop.sortOrder {
            filtered = filtered.sorted(using: sortOrder)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Nettop())
}
