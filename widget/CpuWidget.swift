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

extension CpuUsageInfo {
    var userPercentageString: String {
        String(format: "%.2f", self.userPercentage)
    }
    var systemPercentageString: String {
        String(format: "%.2f", self.sysPercentage)
    }
    
    var usagePercentage: Double {
        var total = userPercentage + sysPercentage
//        total = Double(round(100*total)/100) //保留两位
        total = total > 100 ? 100 : total
        return total
    }
}

struct CpuWidgetEntryView: View {
    var entry: Provider.Entry

    var history: [CpuUsageInfo] {
        entry.data?.cpu ?? []
    }

    var body: some View {
        VStack(spacing: 16) {
            if entry.data == nil {
                Text("Click to start")
            } else {
                VStack {
                    HStack {
                        Text("CPU".localized)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                    HStack(spacing: 2) {
                        Spacer()
                        Group {
                            Text("User")
                            
                            Text(entry.data?.cpu.last?.userPercentageString ?? "")
                                .frame(width: 38, alignment: .trailing)
                            Text(" %")
                        }
                    }
                    HStack(spacing: 2) {
                        Spacer()
                        Group {
                            Text("System")
                            Text(entry.data?.cpu.last?.systemPercentageString ?? "")
                                .frame(width: 38, alignment: .trailing)
                            Text(" %")
                        }
                    }
                }

                Chart(history) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Value", data.usagePercentage),
                        series: .value("Usage", "Usage")
                    )
                    .foregroundStyle(widgetBundle.firstColor)
                }
                .chartXAxis(.hidden)
                .chartYAxisLabel("%")
//                .chartYAxis(.hidden)
                .transition(.identity)
                .contentTransition(.identity)
            }
        }
        .transition(.identity)
        .contentTransition(.identity)
    }
}

struct CpuWidget: Widget {
    let kind: String = "widget.cpu"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                CpuWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CpuWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Cpu Widget")
        .description("")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
