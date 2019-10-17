//
//  TextCellView.swift
//  monitor
//
//  Created by wyy on 2019/10/16.
//  Copyright © 2019 yahaha. All rights reserved.
//

import Cocoa

class TextCellView: NSTableCellView {
    let label: NSTextField = {
        let textField = NSTextField(wrappingLabelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(label)
        let constraints = [
                   label.widthAnchor.constraint(equalTo: widthAnchor, constant: -10),
//                   label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
//                   label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
//                   label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ImageCellView: NSTableCellView {
    let customImageView: NSImageView = {
        let imageView = NSImageView()
        return imageView
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        customImageView.frame = frameRect
        addSubview(customImageView)
    }
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(image: NSImage?, frame: NSRect){
        self.customImageView.image = image
        self.customImageView.frame = frame
    }
    
}
