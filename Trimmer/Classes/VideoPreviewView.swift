//
//  VideoPreviewView.swift
//  Pods-Trimmer_Example
//
//  Created by Tiziano Coroneo on 01/10/2018.
//

import UIKit
import AVFoundation

open class VideoPreviewView: UIView {

    @IBInspectable open var cornerRadius: CGFloat = 0
    
    open lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.frame = self.bounds
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return layer
    }()
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.addSublayer(playerLayer)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = self.bounds
    }
    
    open func setPlayer(_ avPlayer: AVPlayer) {
        self.playerLayer.player = avPlayer
    }
}
