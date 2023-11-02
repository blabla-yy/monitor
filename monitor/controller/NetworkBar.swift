//
//  NetworkBar.swift
//  monitor
//
//  Created by wyy on 2019/10/15.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

// MARK: - NetworkBar

extension NSUserInterfaceItemIdentifier {
    static let tableCellView = NSUserInterfaceItemIdentifier("TableCellView")
}

class NetworkBar: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    // 网络信息
    let networkTraffic: Nettop

    init(networkTraffic: Nettop) {
        self.networkTraffic = networkTraffic
    }

    private var sample: String {
        if networkTraffic.keepDecimals {
            return "999.99 MB/s ↑"
        } else {
            return "999 MB/s ↑"
        }
    }

    // 文本最大宽度
    private var maxStatusBarWidth: CGFloat {
        NSAttributedString(string: sample, attributes: textAttributes).size().width + 1
    }

    private var maxSingleCellWidth: CGFloat {
        return NSTextField(labelWithString: sample).intrinsicContentSize.width
    }

    lazy var networkMenuItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: maxStatusBarWidth)
    }()

    // table view
    private lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        let column1 = NSTableColumn()
        let column2 = NSTableColumn()
        let column3 = NSTableColumn()
        let column4 = NSTableColumn()

        column1.title = ""
        column1.width = 40
        column1.isEditable = false

        column2.title = "processName".localized
        column2.width = 120
        column2.isEditable = false

        column3.title = "upload".localized
        column3.width = maxSingleCellWidth + 10
        column3.isEditable = false

        column4.title = "download".localized
        column4.width = maxSingleCellWidth + 10
        column4.isEditable = false

        tableView.addTableColumn(column1)
        tableView.addTableColumn(column2)
        tableView.addTableColumn(column3)
        tableView.addTableColumn(column4)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsColumnResizing = true
        tableView.autoresizingMask = [.width, .height]
        return tableView
    }()

    // 流量文本格式
    private lazy var textAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.maximumLineHeight = 10
        let baseline = -(NSFont.systemFont(ofSize: 9).capHeight) / 2
        paragraphStyle.paragraphSpacing = baseline
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .right
        return [
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 9),
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            .baselineOffset: baseline,
        ] as [NSAttributedString.Key: Any]
    }()

    func setupMenu() {
        let menu = NSMenu()
        let item = NSMenuItem()
        item.isEnabled = true
        item.view = tableView
        menu.addItem(item)
        menu.addItem(NSMenuItem.separator())

        let mainWindow = NSMenuItem(title: "Open main window".localized, action: #selector(openMainWindow), keyEquivalent: "n")
        mainWindow.keyEquivalentModifierMask = [.command]
        mainWindow.target = self
        mainWindow.isEnabled = true
        menu.addItem(mainWindow)

        let quitItem = NSMenuItem(title: "quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        networkMenuItem.menu = menu
        if let button = networkMenuItem.button {
            button.attributedTitle = NSAttributedString(string: "0 ↑\n0 ↓", attributes: textAttributes)
//            button.attributedTitle = NSAttributedString(string: "\(sample)\n\(sample)", attributes: textAttributes)
            button.imagePosition = .imageLeft
            let cell = button.cell as? NSButtonCell
            cell?.alignment = .right
            tableView.reloadData()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .networkInfoChangeNotification, object: nil)
    }

    // trick
    var openWindow: OpenWindowAction?
    @objc func openMainWindow() {
        DispatchQueue.main.async {
            if let mainWindow = NSApplication.shared.mainWindow {
                mainWindow.orderFrontRegardless()
                mainWindow.makeKey()
                return
            }
            let exist = NSApplication.shared.windows.first { window in
                window.canBecomeMain
            }
            if let exist = exist {
                exist.makeMain()
                exist.orderFrontRegardless()
                exist.makeKey()
                return
            }

            self.openWindow?.callAsFunction(id: Main.id)
            let window = NSApplication.shared.windows.first { window in
                window.canBecomeMain
            }
            window?.makeMain()
            window?.orderFrontRegardless()
            window?.makeKey()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return (networkTraffic.appNetworkTrafficInfo.count > 10 ? 10 : networkTraffic.appNetworkTrafficInfo.count) + 1
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var content: String?
        var image: NSImage?
        var alignment: NSTextAlignment?

        // 第一行为标题，第一行第一列不输出
        if row == 0 {
            if tableColumn != tableView.tableColumns[0] {
                content = tableColumn?.title
                switch tableColumn {
                case tableView.tableColumns[1]: alignment = .left
                case tableView.tableColumns[2]: alignment = .right
                case tableView.tableColumns[3]: alignment = .right
                default: break
                }
            }
        } else {
            // 第一列是图标，其余为信息
            let array = networkTraffic.appNetworkTrafficInfo
            if array.count > row - 1 {
                let info = array[row - 1]
                switch tableColumn {
                case tableView.tableColumns[0]:
                    image = info.image
                case tableView.tableColumns[1]:
                    content = String(info.name)
                    alignment = .left
                case tableView.tableColumns[2]:
                    content = info.bytesOut.speedFormatted
                    alignment = .right
                case tableView.tableColumns[3]:
                    content = info.bytesIn.speedFormatted
                    alignment = .right
                default:
                    content = ""
                }
            }
        }
        if let pic = image {
            let cellView = getImageCellView(tableView: tableView)
            cellView?.setImage(image: pic, frame: NSRect(x: 10, y: 0, width: 16, height: 16))
            return cellView
        } else if let text = content {
            let cellView = getTextCellView(tableView: tableView)
            cellView?.label.stringValue = text
            if let align = alignment {
                cellView?.label.alignment = align
            }
            return cellView
        }
        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 16
    }

    // 获取文本cell
    func getTextCellView(tableView: NSTableView) -> TextCellView? {
        var cellView = tableView.makeView(withIdentifier: .tableCellView, owner: tableView) as? TextCellView
        if cellView == nil {
            cellView = TextCellView()
            cellView?.identifier = .tableCellView
        }
        return cellView
    }

    // 获取图像cell
    func getImageCellView(tableView: NSTableView) -> ImageCellView? {
        var cellView = tableView.makeView(withIdentifier: .tableCellView, owner: tableView) as? ImageCellView
        if cellView == nil {
            cellView = ImageCellView()
            cellView?.identifier = .tableCellView
        }
        return cellView
    }

    @objc func refresh() {
        if let button = networkMenuItem.button {
            let upload = networkTraffic.totalBytesOut.formatSpeed(keepDecimals: networkTraffic.keepDecimals)
            let download = networkTraffic.totalBytesIn.formatSpeed(keepDecimals: networkTraffic.keepDecimals)
            button.attributedTitle = NSAttributedString(string: "\(upload) ↑\n\(download) ↓", attributes: textAttributes)
            tableView.reloadData()
        }
    }
}
