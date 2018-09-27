//
//  ViewController.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 19/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit
import AVFoundation
import Trimmer

class ViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet var playerView: UIView!
    @IBOutlet var trimmingController: TrimmingController!
    
    
    // MARK: Properties
    var asset: AVAsset!
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.backgroundColor = UIColor.clear
        
        guard let path = Bundle(for: ViewController.self)
            .path(forResource: "IMG_0065", ofType: "m4v")
            else { fatalError("impossible load video") }

        let fileURL = URL(fileURLWithPath: path, isDirectory: false)
        asset = AVAsset(url: fileURL)

        trimmingController.setupPlayerLayer(for: fileURL, with: playerView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        trimmingController.setup(asset: asset)
        
    }

}
