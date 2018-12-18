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
    @IBOutlet var playerView: VideoPreviewView!
    @IBOutlet var trimmingController: TrimmingController! {
        didSet {
            trimmingController.delegate = self
        }
    }

    var trimStartPosition: Int64 = 0
    var trimEndPosition: Int64 = 0
    var timescale: Int32 = 0
    
    // MARK: Properties
    var asset: AVAsset!
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.backgroundColor = UIColor.clear
        
        guard let path = Bundle(for: ViewController.self)
            .path(forResource: "frame", ofType: "mov")
            else { fatalError("impossible load video") }

        let fileURL = URL(fileURLWithPath: path, isDirectory: false)
        asset = AVAsset(url: fileURL)

        trimmingController.setupPlayerLayer(for: fileURL, with: playerView)

        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }

        trimEndPosition = videoTrack.timeRange.duration.value
//        trimmingController.trimmerView.updateDistances()

        timescale = videoTrack.naturalTimeScale
        trimmingController.setup(asset: asset!,
                                 trimStartPosition: 0,
                                 trimEndPosition: trimEndPosition,
                                 timeScale: timescale)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        trimmingController.updateSubviewsTrimmerView()
    }

}

extension ViewController: TrimmingControllerDelegate {
    func didRequestUpdateTimes(_ controller: TrimmingController, startTime: CMTime, endTime: CMTime) {
        controller.updateTimes(trimStartPosition: startTime.value,
                               trimEndPosition: endTime.value,
                               timeScale: timescale)
    }
}
