//
//  StatusBarController.swift
//  monitor
//
//  Created by wyy on 2019/10/12.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Cocoa

protocol BarItem {
    func updateView()
    func stop()
}

// MARK: -IStatusBar

class IStatusBar {
    var netwok = NetworkBar()
    var enableNetwork = true
    var timer: Timer?

    // MARK: - Timer
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            DispatchQueue.global().async {
                if self.enableNetwork {
                    self.netwok.updateView()
                }
            }
        })
        
        if let timer = timer {
            // 如果是default 需要等待UITrackingRunLoopMode完成，才会触发计时器
            RunLoop.current.add(timer, forMode: .common)
            timer.fire()
        }
    }
}
