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
        let entry = SimpleEntry(date: Date(), data: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [SimpleEntry] = [.init(date: .now.addingTimeInterval(1), data: WidgetSharedData.instance.readData())]
        print(entries.first!)
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

    let uploadForeground = Color.yellow
    let downloadForegroud = Color.green

    var body: some View {
        VStack(spacing: 20) {
            if entry.data == nil {
                Text("开始监控")
            } else {
                VStack {
                    HStack {
                        Text("实时流量")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Group {
                            Text(entry.data?.networkHistory.last?.upload.speedFormatted ?? "") + Text(" ↑").foregroundStyle(uploadForeground)
                        }
                    }
                    HStack {
                        Spacer()
                        Group {
                            Text(entry.data?.networkHistory.last?.download.speedFormatted ?? "") + Text(" ↓").foregroundStyle(downloadForegroud)
                        }
                    }
                }

                Chart(history) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("KB", data.uploadKB),
                        series: .value("Upload", "Upload")
                    )
                    .foregroundStyle(uploadForeground)

                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("KB", data.downloadKB),
                        series: .value("Download", "Download")
                    )
                    .foregroundStyle(downloadForegroud)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .transition(.identity)
                .contentTransition(.identity)
            }
        }
        .transition(.identity)
        .contentTransition(.identity)
    }
}

struct widget: Widget {
    let kind: String = "network.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                widgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                widgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
