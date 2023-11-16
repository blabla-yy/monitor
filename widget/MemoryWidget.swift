//
//  widget.swift
//  widget
//
//  Created by wyy on 2023/11/16.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Charts
import SwiftUI
import WidgetKit


struct MemoryWidgetEntryView: View {
    var entry: Provider.Entry

    

    var history: [MemoryUsageInfo] {
        entry.data?.memory ?? []
    }
    var body: some View {
        VStack(spacing: 16) {
            if history.isEmpty {
                Text("Click to start")
            } else {
                VStack {
                    HStack {
                        Text("Memory".localized)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Group {
                            Text("\(entry.data?.memory.last?.usageMB ?? 0)") + Text(" MB")
//                                .foregroundStyle(widgetBundle.firstColor)
                        }
                    }
//                    HStack {
//                        Spacer()
//                        Group {
//                            Text("\(entry.data?.memory.last?.usagePercentage ?? 0)") + Text(" %")
//                            ProgressView(value: entry.data?.memory.last?.usagePercentage ?? 0)
//                                            .progressViewStyle(.circular)
//                                            .foregroundStyle(widgetBundle.secondColor)
//                        }
//                    }
                }

                Chart(history) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Value", data.usageMB),
                        series: .value("Usage", "Usage")
                    )
                    .foregroundStyle(widgetBundle.firstColor)

                    
                }
                .chartXAxis(.hidden)
                .chartYAxisLabel("MB")
//                .chartYAxis(.hidden)
                .transition(.identity)
                .contentTransition(.identity)
            }
        }
        .transition(.identity)
        .contentTransition(.identity)
    }
}

struct MemoryWidget: Widget {
    let kind: String = "widget.memory"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                MemoryWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MemoryWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Memroy Widget")
        .description("")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
