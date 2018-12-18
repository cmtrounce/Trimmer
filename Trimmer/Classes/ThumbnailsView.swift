//
//  ThumbnailsView.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 19/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit
import AVFoundation

class ThumbnailsView: UIView {

    private let thumbsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    public var asset: AVAsset? {
        didSet {
            didAssetChange(for: asset)
        }
    }

    var assetImageGenerator: AVAssetImageGenerator?
    let imageGenerationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Generation queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var thumbs: [UIImage] = []

    /// Return the duration of the video
    var videoDuration: CMTime {
        guard let asset = asset,
            let videoAssetTrack = asset.tracks(withMediaType: .video).first else { return .zero }
        return videoAssetTrack.timeRange.duration
    }

    /// Return the width size that contains the thumbnails
    var durationSize: CGFloat {
        return bounds.width
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        thumbsStackView.frame = bounds
        if bounds.width != 0,
            bounds.height != 0,
            let asset = asset {
            regenerateThumbnails(for: asset)
        }
    }

    private func commonInit() {
        thumbsStackView.frame = bounds
        addSubview(thumbsStackView)
    }

    func didAssetChange(for asset: AVAsset?) {
        guard let asset = asset else { return }
        regenerateThumbnails(for: asset)
    }

    /// Return the video time from a position of a view
    func getTime(from position: CGFloat) -> CMTime? {
        let normalizedRatio = getNormalizedPosition(from: position)

        let positionTimeValue = Double(normalizedRatio)
            * Double(videoDuration.value)

        return CMTime(
            value: Int64(positionTimeValue),
            timescale: videoDuration.timescale)

//        let positionToTime = (bounds.width / CGFloat(videoDuration.seconds)) * position
//        return CMTime(value: CMTimeValue(positionToTime), timescale: videoDuration.timescale)
    }

    func getTimeWithMaxDuration(from position: CGFloat, maxDuration : CMTime) -> CMTime? {
        print("position : \(position)")
        let normalizedRatio = getNormalizedPosition(from: position)

        let positionTimeValue = Double(normalizedRatio)
            * Double(maxDuration.value)

        return CMTime(
            value: Int64(positionTimeValue),
            timescale: videoDuration.timescale)
    }

    /// Normalized time
    func getNormalizedTime(from time: CMTime) -> CGFloat? {
//        let result = CGFloat(time.seconds / videoDuration.seconds)
//        assert(result < 1.05)
//        return result
        return max(min(1, CGFloat(time.seconds / videoDuration.seconds)), 0)
    }

    /// Return the the position of a view from the video time
    func getPosition(from time: CMTime) -> CGFloat? {
        return getNormalizedTime(from: time)
            .map { $0 * durationSize }
    }

    /// Normalized position
    func getNormalizedPosition(from position: CGFloat) -> CGFloat {
        return max(min(1, position / durationSize), 0)
    }

    private func getThumbnailSize(from asset: AVAsset) -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first,
            bounds.width != 0,
            bounds.height != 0 else { return nil }

        layoutIfNeeded()

        let targetSize = bounds.size
        let assetSize = track.naturalSize.applying(track.preferredTransform)

        assert(targetSize.width > 0)
        assert(targetSize.height > 0)

        let scaleFactor = targetSize.height / assetSize.height
        let newWidth = assetSize.width * scaleFactor

        return CGSize(width: newWidth,
                      height: assetSize.height)
    }

    public func regenerateThumbnails(for asset: AVAsset) {
        guard let thumbnailSize = getThumbnailSize(from: asset),
            thumbnailSize.width != 0 else { return }

        assetImageGenerator?.cancelAllCGImageGeneration()
        removeOldThumbnails()
        let thumbnailCount = getThumbnailsCount(from: thumbnailSize)
        addThumbnailViews(for: thumbnailCount, thumbnailSize: thumbnailSize)
        generateThumbnails(for: asset, thumbnailSize: thumbnailSize, thumbnailCount: thumbnailCount)
    }

    private func removeOldThumbnails() {
        thumbsStackView.arrangedSubviews
                    .forEach { view in
                        thumbsStackView.removeArrangedSubview(view)
                        view.removeFromSuperview()
        }
    }

    private func addThumbnailViews(for thumbnailCount: Int, thumbnailSize: CGSize) {
        (0..<thumbnailCount).map { _ in
            let imageView = UIImageView()
            imageView.frame.size = thumbnailSize
            imageView.backgroundColor = UIColor.black
            return imageView
            }.forEach(thumbsStackView.addArrangedSubview)
    }

    /// Return the number of thumbnails that will be genearate
    func getThumbnailsCount(from thumbnailSize: CGSize) -> Int {
        guard asset != nil else { return 0 }
        var number = bounds.width / thumbnailSize.width
        number.round(.toNearestOrAwayFromZero)
        return abs(Int(number))
    }

    // Generate the thumbnail for each image view
    private func generateThumbnails(for asset: AVAsset, thumbnailSize: CGSize, thumbnailCount: Int) {
        let videoStep: CMTime = CMTime(value: videoDuration.value / Int64(thumbnailCount),
                                       timescale: videoDuration.timescale)

        assetImageGenerator = makeAssetGenerator(from: asset, withThumbnailSize: thumbnailSize)
        assetImageGenerator?.cancelAllCGImageGeneration()

        let frameForTimes: [NSValue] = (0..<thumbnailCount).map {
            let cmTime = CMTime(value: Int64($0) * videoStep.value,
                                timescale: videoDuration.timescale)

            assert(cmTime < videoDuration)

            return NSValue(time: cmTime)
        }

        assert(frameForTimes.count == thumbsStackView.arrangedSubviews.count)

        let operation = ThumbnailGenerationOperation(
            frameForTimes: frameForTimes,
            thumbnailView: self)

        operation.completionBlock = {

            guard !operation.isCancelled else { return }

            DispatchQueue.main.async { [weak self] in
                guard
                    let imageViews = self?.thumbsStackView
                        .arrangedSubviews as? [UIImageView],
                    let thumbs = self?.thumbs
                    else { return }

                zip(imageViews, thumbs).forEach { $0.image = $1 }
            }
        }

        imageGenerationQueue.cancelAllOperations()
//        imageGenerationQueue.operations.forEach { $0. }
        imageGenerationQueue.addOperation(operation)
    }
}

class ThumbnailGenerationOperation: Operation {

    let frameForTimes: [NSValue]
    weak var thumbnailView: ThumbnailsView?

    var assetGenerator: AVAssetImageGenerator? {
        return thumbnailView?.assetImageGenerator
    }

    override var isAsynchronous: Bool {
        return true
    }

    private var _isExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    override var isExecuting: Bool {
        return _isExecuting
    }

    var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    override var isFinished: Bool {
        return _isFinished
    }

    init(
        frameForTimes: [NSValue],
        thumbnailView: ThumbnailsView) {

        _isExecuting = false
        _isFinished = false

        self.frameForTimes = frameForTimes
        self.thumbnailView = thumbnailView
    }

//    override func main() {
//
//        guard !isCancelled else { return }
//
//        thumbnailView?.thumbs = []
//
//        assetGenerator?.generateCGImagesAsynchronously(
//        forTimes: frameForTimes) { [weak thumbnailView] (time, image, _, result, error) in
//
//            guard error == nil else {
//                    print("\n Asset generation Error = \(error!)\n")
//                    return
//            }
//
//            guard let image = image else {
//                print("\n Asset generation result = \(result.rawValue)\n")
//                return
//            }
//
//            guard !self.isCancelled
//                else { return }
//
//            thumbnailView?.thumbs
//                .append(UIImage(cgImage: image))
//        }
//    }

    override func start() {
        guard !isCancelled else {
            _isFinished = true
            return
        }

        thumbnailView?.thumbs = []

       assetGenerator?.generateCGImagesAsynchronously(
        forTimes: frameForTimes) { [weak thumbnailView] (time, image, _, result, error) in

            guard error == nil else {
                print("\n Asset generation Error = \(error!)\n")
                self._isFinished = true
                return
            }

            guard let image = image else {
                print("\n Asset generation result = \(result.rawValue)\n")
                self._isFinished = true
                return
            }

            guard !self.isCancelled else {
                self._isFinished = true
                return
            }

            self._isExecuting = true
            thumbnailView?.thumbs
                .append(UIImage(cgImage: image))
            if thumbnailView?.thumbs.count ?? 0 == self.frameForTimes.count {
                self._isExecuting = false
                self._isFinished = true
            }
        }
    }

}

fileprivate func makeAssetGenerator(
    from asset: AVAsset,
    withThumbnailSize thumbnailSize: CGSize) -> AVAssetImageGenerator {

    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceAfter = CMTime.zero
    generator.requestedTimeToleranceBefore = CMTime.zero
    generator.appliesPreferredTrackTransform = true

    let scale = UIScreen.main.nativeScale
    let generatorSize = CGSize(
        width: thumbnailSize.width * scale,
        height: thumbnailSize.height * scale)

    generator.maximumSize = generatorSize

    return generator
}
