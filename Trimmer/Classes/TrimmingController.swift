//
//  TrimmingController.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit
import AVFoundation

public protocol TrimmingControllerDelegate: class {
    func didRequestUpdateTimes(
        _ controller: TrimmingController,
        startTime: CMTime,
        endTime: CMTime)
}

open class TrimmingController: NSObject {

    // MARK: IBInspectable
    /// This boolean changes the update frequency of the preview view while scrubbing. If `false`, the scrubbing will only show the frames indicated as "keyframes" (depending on the file codec), if `true`, it will show every frame, at expense of a higher power consumption and worse performance.
    @IBInspectable open var isTimePrecisionInfinity: Bool = false

    @IBInspectable open var playImage: UIImage?
    @IBInspectable open var pauseImage: UIImage?

    // MARK: IBOutlets
    @IBOutlet open var playPauseButton: UIButton?
    @IBOutlet open var trimmerView: TrimmerView!{
        didSet {
            trimmerView.delegate = self
        }
    }

    public weak var delegate: TrimmingControllerDelegate?

    // MARK: Public properties
    public private(set) var currentStartTime: CMTime? = nil
    public private(set) var currentEndTime: CMTime? = nil
    public private(set) var timeScale: Int32? = nil
    private let maxDuration: Double = 3

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

            if pauseImage != nil {
                playPauseButton?.setImage(
                    pauseImage!.withRenderingMode(.alwaysOriginal),
                    for: .normal)
            } else {
                playPauseButton?.setTitle("Pause", for: .normal)
            }


            isPlaying = true
        } else {
            player?.pause()
            stopPlaybackTimeChecker()

            if playImage != nil {
                playPauseButton?.setImage(
                    playImage!.withRenderingMode(.alwaysOriginal),
                    for: .normal)
            } else {
                playPauseButton?.setTitle("Play", for: .normal)
            }

            isPlaying = false
        }
    }

    // MARK: Methods
    open func setupPlayerLayer(for url: URL, with playerView: VideoPreviewView) {
        player = AVPlayer(url: url)

        self.currentStartTime = CMTime.zero
        self.currentEndTime = player?.currentItem?.duration

        playerView.setPlayer(player!)
        playPauseButton.map(playerView.addSubview)
    }

    open func setup(asset: AVAsset,
                    trimStartPosition: Int64,
                    trimEndPosition: Int64,
                    timeScale: Int32) {

        self.currentStartTime = CMTime(value: trimStartPosition, timescale: timeScale)
        self.currentEndTime = CMTime(value: trimEndPosition, timescale: timeScale)
        self.timeScale = timeScale

        let newMaxDuration = CMTime(seconds: maxDuration, preferredTimescale: timeScale)
        let newEndTime = min(newMaxDuration, currentEndTime!)

         self.currentEndTime = CMTime(value: newEndTime.value, timescale: timeScale)

        trimmerView.thumbnailsView.asset = asset
        trimmerView.trimStartPosition = trimStartPosition
        trimmerView.trimEndPosition = newEndTime.value
        trimmerView.timeScale = timeScale
        trimmerView.maxVideoDurationAfterTrimming = newEndTime.seconds

        player?.seek(to: currentStartTime!,
                     toleranceBefore: CMTime.zero,
                     toleranceAfter: CMTime.zero)
        trimmerView.seek(to: currentStartTime!)
    }

    open func updateTimes(trimStartPosition: Int64,
                          trimEndPosition: Int64,
                          timeScale: Int32) {
        self.currentStartTime = CMTime(value: trimStartPosition, timescale: timeScale)
        self.currentEndTime = CMTime(value: trimEndPosition, timescale: timeScale)
        self.timeScale = timeScale

        trimmerView.trimStartPosition = trimStartPosition
        trimmerView.trimEndPosition = trimEndPosition
        trimmerView.timeScale = timeScale

        player?.seek(to: currentStartTime!,
                     toleranceBefore: CMTime.zero,
                     toleranceAfter: CMTime.zero)
        trimmerView.seek(to: currentStartTime!)
    }

    /// When the video is finish reset the pointer at the beginning
    public func pause() {
        player?.pause()
        stopPlaybackTimeChecker()

        if playImage != nil {
            playPauseButton?.setImage(
                playImage!.withRenderingMode(.alwaysOriginal),
                for: .normal)
        } else {
            playPauseButton?.setTitle("Play", for: .normal)
        }

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
        guard let startTime = self.currentStartTime,
            let endTime = self.currentEndTime,
            let timeScale = self.timeScale,
            let player = player else {
                return
        }

        let playBackTime = player.currentTime()

        //convert the timescale of the current time to the current media timescale
        let timeAccordingToMediaTimescale = CMTimeConvertScale(
            playBackTime,
            timescale: timeScale,
            method: .default)
        trimmerView.seek(to: timeAccordingToMediaTimescale)

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

    public func updateSubviewsTrimmerView() {
        trimmerView.updateSubviews()
    }

}

//MARK: TrimmerViewDelegate
extension TrimmingController: TrimmerViewDelegate {

    public func trimmerDidBeginDragging(_ trimmer: TrimmerView,
                                        with currentTimeTrim: CMTime) {

        assert(currentTimeTrim.seconds >= 0)

        pause()
        playPauseButton?.isHidden = true
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

        playPauseButton?.isHidden = false

        player?.seek(
            to: startTime,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance)

        assert(startTime.seconds >= 0)

        assert(startTime.seconds <= trimmerView.thumbnailsView.asset!.duration.seconds)

        assert(endTime.seconds >= 0)

        assert(endTime.seconds <= trimmerView.thumbnailsView.asset!.duration.seconds)

        self.currentStartTime = startTime
        self.currentEndTime = endTime

        delegate?.didRequestUpdateTimes(self,
                                        startTime: startTime,
                                        endTime: endTime)
    }

    public func trimmerScrubbingDidBegin(_ trimmer: TrimmerView,
                                         with currentTimeScrub: CMTime) {
        playPauseButton?.isHidden = true

        assert(currentTimeScrub.seconds >= 0)
    }

    public func trimmerScrubbingDidChange(_ trimmer: TrimmerView,
                                          with currentTimeScrub: CMTime) {
        guard let currentPosition = trimmer
            .thumbnailsView.getPosition(from: currentTimeScrub) else { return }
        if currentPosition >= trimmer.leftDraggableView.frame.minX &&
            currentPosition <= (trimmer.rightDraggableView.frame.minX - trimmer.draggableViewWidth) {
            player?.seek(
                to: currentTimeScrub,
                toleranceBefore: tolerance,
                toleranceAfter: tolerance)
            trimmerView.seek(to: currentTimeScrub)

            assert(currentTimeScrub.seconds >= 0)
        }
    }

    public func trimmerScrubbingDidEnd(_ trimmer: TrimmerView,
                                       with currentTimeScrub: CMTime) {
        playPauseButton?.isHidden = false

        guard let currentPosition = trimmer
            .thumbnailsView.getPosition(from: currentTimeScrub) else { return }

        if currentPosition >= trimmer.leftDraggableView.frame.minX &&
            currentPosition <= (trimmer.rightDraggableView.frame.minX - trimmer.draggableViewWidth) {
            player?.seek(
                to: currentTimeScrub,
                toleranceBefore: tolerance,
                toleranceAfter: tolerance)

            assert(currentTimeScrub.seconds >= 0)
        }
    }

}

