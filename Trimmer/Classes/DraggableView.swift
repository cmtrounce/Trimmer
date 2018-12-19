//
//  DraggableView.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit

class DraggableView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = self.bounds.insetBy(dx: -10, dy: -20)
        return frame.contains(point) ? self : nil
    }

//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        return bounds.contains(point)
//    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if subview.frame.contains(point) {
                return true
            }
        }
        return false
    }

}
