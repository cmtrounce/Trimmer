//
//  VideoPreviewView.swift
//  Pods-Trimmer_Example
//
//  Created by Tiziano Coroneo on 01/10/2018.
//

import UIKit
import AVFoundation

open class VideoPreviewView: UIView {

    @IBInspectable open var cornerRadius: CGFloat = 0 {
        didSet {
            playerLayer.cornerRadius = cornerRadius
            layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable open var layerColor: UIColor = .white {
        didSet {
            playerLayer.backgroundColor = layerColor.cgColor
        }
    }

    open var maskedCorners: CACornerMask = [] {
        didSet {
            playerLayer.maskedCorners = maskedCorners
            layer.maskedCorners = maskedCorners
        }
    }

    open lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.frame = self.bounds
        layer.masksToBounds = true
        layer.backgroundColor = layerColor.cgColor
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.videoGravity = .resizeAspect

        return layer
    }()
    
    open override func awakeFromNib() {
        super.awakeFromNib()

        self.layer.addSublayer(playerLayer)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.addSublayer(playerLayer)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

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
