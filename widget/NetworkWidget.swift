//
//  widget.swift
//  widget
//
//  Created by wyy on 2023/11/8.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Charts
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), data: .snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entries: [SimpleEntry] = [.init(date: .now.addingTimeInterval(1), data: WidgetSharedData.instance.readData())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: SharedData?
}

struct widgetEntryView: View {
    var entry: Provider.Entry
    var history: [NetworkData] {
        entry.data?.networkHistory ?? []
    }

    var body: some View {
        VStack(spacing: 16) {
            if entry.data == nil {
                Text("Click to start")
            } else {
                VStack {
                    HStack {
                        Text("Network".localized)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Group {
                            Text(entry.data?.networkHistory.last?.upload.speedFormatted ?? "") + Text(" ↑").foregroundStyle(widgetBundle.firstColor)
                        }
                    }
                    HStack {
                        Spacer()
                        Group {
                            Text(entry.data?.networkHistory.last?.download.speedFormatted ?? "") + Text(" ↓").foregroundStyle(widgetBundle.secondColor)
                        }
                    }
                }

                Chart(history) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Value", data.adaptUploadValue(maxNetworkValue: entry.data?.maxNetworkValue ?? 0)),
                        series: .value("Upload", "Upload")
                    )
                    .foregroundStyle(widgetBundle.firstColor)

                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Value", data.adaptDownloadValue(maxNetworkValue: entry.data?.maxNetworkValue ?? 0)),
                        series: .value("Download", "Download")
                    )
                    .foregroundStyle(widgetBundle.secondColor)
                }
                .chartXAxis(.hidden)
                .chartYAxisLabel(entry.data?.networkUnit ?? "B")
//                .chartYAxis(.hidden)
                .transition(.identity)
                .contentTransition(.identity)
            }
        }
        .transition(.identity)
        .contentTransition(.identity)
    }
}

struct NetworkWidget: Widget {
    let kind: String = "widget.network"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                widgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(URL(string: "main"))
            } else {
                widgetEntryView(entry: entry)
                    .padding()
                    .background()
                    .widgetURL(URL(string: "main"))
            }
        }
        .configurationDisplayName("Network Widget".localized)
        .description("")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
