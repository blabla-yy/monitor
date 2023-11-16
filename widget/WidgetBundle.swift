//
//  widgetBundle.swift
//  widget
//
//  Created by wyy on 2023/11/8.
//  Copyright © 2023 yahaha. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct widgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        NetworkWidget()
        MemoryWidget()
        CpuWidget()
    }
    
    static let firstColor = Color.yellow
    static let secondColor = Color.green
}
