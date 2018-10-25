//
//  TrimmingController.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit
import AVFoundation

open class TrimmingController: NSObject {
    
    // MARK: IBInspectable
    /// This boolean changes the update frequency of the preview view while scrubbing. If `false`, the scrubbing will only show the frames indicated as "keyframes" (depending on the file codec), if `true`, it will show every frame, at expense of a higher power consumption and worse performance.
    @IBInspectable open var isTimePrecisionInfinity: Bool = false
    
    // MARK: IBOutlets
    @IBOutlet open var playPauseButton: UIButton!
    @IBOutlet open var trimmerView: TrimmerView!{
        didSet {
            trimmerView.delegate = self
        }
    }

    // MARK: Public properties
    public private(set) var currentStartTime: CMTime? = nil
    public private(set) var currentEndTime: CMTime? = nil

    // MARK: Private properties
    private var player: AVPlayer?
    private var isPlaying = false
    private var playbackTimeCheckerTimer: Timer?
    private var tolBefore: CMTime = CMTime.zero
    private var tolAfter: CMTime = CMTime.zero
    private var tolerance: CMTime {
        return isTimePrecisionInfinity ? .indefinite : .zero
    }
    
    // MARK: IBActions
    @IBAction open func playPauseButtonPressed() {
        if !isPlaying {
            player?.play()
            startPlaybackTimeChecker()
            playPauseButton.setTitle("Pause", for: .normal)
            isPlaying = true
        } else {
            player?.pause()
            stopPlaybackTimeChecker()
            playPauseButton.setTitle("Play", for: .normal)
            isPlaying = false
        }
    }
    
    // MARK: Methods
    open func setupPlayerLayer(for url: URL, with playerView: VideoPreviewView) {
        player = AVPlayer(url: url)

        self.currentStartTime = CMTime.zero
        self.currentEndTime = player?.currentItem?.duration

        playerView.setPlayer(player!)
        playerView.addSubview(playPauseButton)
    }
    
    open func setup( asset: AVAsset) {

        self.currentStartTime = CMTime.zero
        self.currentEndTime = asset.duration

        trimmerView.thumbnailsView.asset = asset
    }
    
    /// When the video is finish reset the pointer at the beginning
    private func pause() {
        player?.pause()
        stopPlaybackTimeChecker()
        playPauseButton.setTitle("Play", for: .normal)
        isPlaying = false
    }
    
    /// Schedule a timer
    private func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    /// Invalidate a timer
    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    /// Update the pointer position respects the current video time
    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime,
            let player = player else {
                return
        }
        
        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            /// Leave this seek with tolerance zero otherwise will be a little delay of the update of pointer position
            player.seek(to: startTime,
                        toleranceBefore: CMTime.zero,
                        toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
            pause()
            trimmerView.resetTimePointer()
        }
    }
    
}

//MARK: TrimmerViewDelegate
extension TrimmingController: TrimmerViewDelegate {
    
    public func trimmerDidBeginDragging(_ trimmer: TrimmerView,
                                        with currentTimeTrim: CMTime) {
        
        assert(currentTimeTrim.seconds >= 0)
        
        pause()
        playPauseButton.isHidden = true
    }
    
    public func trimmerDidChangeDraggingPosition(
        _ trimmer: TrimmerView,
        with currentTimePointer: CMTime) {

        assert(currentTimePointer.seconds >= 0)

        player?.seek(
            to: currentTimePointer,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance)
    }
    
    public func trimmerDidEndDragging(
        _ trimmer: TrimmerView,
        with startTime: CMTime,
        endTime: CMTime) {
        
        playPauseButton.isHidden = false
        
        player?.seek(
            to: startTime,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance)
        
        assert(startTime.seconds >= 0)
        
        assert(startTime.seconds <= trimmerView.thumbnailsView.asset.duration.seconds)
        
        assert(endTime.seconds >= 0)
        
        assert(endTime.seconds <= trimmerView.thumbnailsView.asset.duration.seconds)

        self.currentStartTime = startTime
        self.currentEndTime = endTime
    }
    
    public func trimmerScrubbingDidBegin(_ trimmer: TrimmerView,
                                         with currentTimeScrub: CMTime) {
        playPauseButton.isHidden = true
        
        assert(currentTimeScrub.seconds >= 0)
    }
    
    public func trimmerScrubbingDidChange(_ trimmer: TrimmerView,
                                         with currentTimeScrub: CMTime) {
       
        player?.seek(
            to: currentTimeScrub,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance)
        trimmerView.seek(to: currentTimeScrub)
        
        assert(currentTimeScrub.seconds >= 0)
    }

    public func trimmerScrubbingDidEnd(_ trimmer: TrimmerView,
                                       with currentTimeScrub: CMTime) {
        playPauseButton.isHidden = false

        player?.seek(
            to: currentTimeScrub,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance)

        assert(currentTimeScrub.seconds >= 0)
    }
    
}

