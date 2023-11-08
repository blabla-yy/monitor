//
//  widget.swift
//  widget
//
//  Created by wyy on 2023/11/8.
//  Copyright © 2023 yahaha. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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

struct widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if entry.data == nil {
                Text("打开应用")
            } else {
                Text("Upload:")
                Text(entry.data?.networkUpload.speedFormatted ?? "")
                    .animation(nil)
                
                Text("Download:")
                Text(entry.data?.networkDownload.speedFormatted ?? "")
                    .animation(nil)
            }
            
        }
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
