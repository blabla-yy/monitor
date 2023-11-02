//
//  UIntExtensions.swift
//  BandwidthMonitor
//
//  Created by wyy on 2023/7/18.
//  Copyright © 2023 yahaha. All rights reserved.
//

import Foundation

extension UInt {
    var speedFormatted: String {
        self.formatSpeed()
    }
    
    func formatSpeed(keepDecimals: Bool = true) -> String {
        if self == 0 {
            return "0 B/s"
        }
        if self / 1024 < 1 {
            return "\(self) B/s"
        }
        let format = keepDecimals ? "%.2f" : "%.0f"

        var value = Double(self) / 1024.0
        if value / 1024 < 1 {
            return String(format: "\(format) KB/s", value)
        }

        value = Double(value) / 1024.0
        if value / 1024 < 1 {
            return String(format: "\(format) MB/s", value)
        }

        value = Double(value) / 1024
        return String(format: "\(format) GB/s", value)
    }
}
