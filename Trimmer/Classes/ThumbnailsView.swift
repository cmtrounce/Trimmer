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

    private var assetImageGenerator: AVAssetImageGenerator?

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
    }

    /// Normalized time
    func getNormalizedTime(from time: CMTime) -> CGFloat? {
//        let result = CGFloat(time.seconds / videoDuration.seconds)
//        assert(result < 1.05)
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
//        removeOldThumbnails()
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

//        assert(frameForTimes.count == thumbsStackView.arrangedSubviews.count)

        DispatchQueue.global(qos: .userInitiated).async { [assetImageGenerator] in
            var index = 0

            assetImageGenerator?.generateCGImagesAsynchronously(
            forTimes: frameForTimes) { (time, image, _, _, error) in

                guard error == nil else {
                    print("\nError = \(error!)\n")
                    return
                }

                guard let image = image else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let imageViews = self?.thumbsStackView
                        .arrangedSubviews as? [UIImageView] else { return }
                    imageViews[index].image = UIImage(cgImage: image)
                    index += 1
                }
            }
        }
    }

}
//
//class ThumbnailsView: UIView {
//
//    // MARK: Properties
//    private let thumbsStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.distribution = .fillEqually
//        return stackView
//    }()
//
//    open var asset: AVAsset! {
//        didSet {
//            self.setNeedsLayout()
//        }
//    }
//
//    private lazy var assetImageGenerator: AVAssetImageGenerator = makeAssetGenerator(from: asset, withThumbnailSize: thumbnailSize)
//
//    private lazy var thumbnailSize: CGSize = getThumbnailSize(from: asset, with: bounds)
//
////    private var totalTimeLength: Int {
////        return Int(videoDuration.seconds * Double(videoDuration.timescale))
////    }
//
//    /// Return the duration of the video
//    var videoDuration: CMTime {
//        guard let videoAssetTrack = asset.tracks(withMediaType: .video).first else { return .zero }
//        return videoAssetTrack.timeRange.duration
//    }
//
//    /// Return the width size that contains the thumbnails
//    var durationSize: CGFloat {
//        return bounds.width
//    }
//
//    /// Return the number of thumbnails that will be genearate
//    open var currentThumbnailsCount: Int {
//        guard asset != nil else { return 0 }
//        var number = bounds.width / thumbnailSize.width
//        number.round(.toNearestOrAwayFromZero)
//        return abs(Int(number))
//    }
//
//    var lastThumbnailsCount: Int = 0 {
//        didSet {
//            if lastThumbnailsCount != oldValue,
//                lastThumbnailsCount != 0 {
//                regenerateThumbViews(count: lastThumbnailsCount)
//                generateThumbnails()
//            }
//        }
//    }
//
//    /// Return the length of each step of the video
//    private var videoStep: CMTime {
//        return CMTime(value: videoDuration.value / Int64(currentThumbnailsCount),
//                      timescale: videoDuration.timescale)
//
//    }
//
//    // MARK: Inits
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setup()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//
//    // MARK: View Life Cycle
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setup()
//    }
//
//    override func didMoveToSuperview() {
//        super.didMoveToSuperview()
//        self.setNeedsLayout()
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        thumbsStackView.frame = bounds
//        lastThumbnailsCount = currentThumbnailsCount
//    }
//
//    // MARK: Methods
//    private func setup() {
//        addSubview(thumbsStackView)
//        resetAsset()
//    }
//
//    func resetAsset() {
//        self.lastThumbnailsCount = 0
//        self.thumbnailSize = getThumbnailSize(from: asset, with: bounds)
//        self.assetImageGenerator = makeAssetGenerator(
//            from: asset, withThumbnailSize: thumbnailSize)
//    }
//
//    /// Generate the thumbnail for each image view
//    private func generateThumbnails() {
//        assetImageGenerator.cancelAllCGImageGeneration()
//
//        guard bounds.height != 0 else { return }
//        thumbnailSize = getThumbnailSize(from: asset, with: bounds)
//
//        regenerateThumbViews(count: lastThumbnailsCount)
//
//        assetImageGenerator = makeAssetGenerator(from: asset, withThumbnailSize: thumbnailSize)
//
//        let frameForTimes: [NSValue] = (0..<currentThumbnailsCount).map {
//            let cmTime = CMTime(value: Int64($0) * videoStep.value,
//                                timescale: videoDuration.timescale)
//
//            assert(cmTime < videoDuration)
//
//            return NSValue(time: cmTime)
//        }
//
//        (frameForTimes.count == thumbsStackView.arrangedSubviews.count)
//
//        DispatchQueue.global(qos: .userInitiated).async { [assetImageGenerator] in
//            var index = 0
//
//            assetImageGenerator.generateCGImagesAsynchronously(
//            forTimes: frameForTimes) { (time, image, _, _, error) in
//
//                guard error == nil else {
//                    print("\nError = \(error!)\n")
//                    return
//                }
//
//                guard let image = image else { return }
//
//                DispatchQueue.main.async { [weak self] in
//                    guard let imageViews = self?.thumbsStackView
//                        .arrangedSubviews as? [UIImageView] else { return }
//                    imageViews[index].image = UIImage(cgImage: image)
//                    index += 1
//                }
//            }
//        }
//    }
//
//    /// Return the video time from a position of a view
//    func getTime(from position: CGFloat) -> CMTime? {
//        let normalizedRatio = getNormalizedPosition(from: position)
//
//        let positionTimeValue = Double(normalizedRatio)
//            * Double(videoDuration.value)
//
//        return CMTime(
//            value: Int64(positionTimeValue),
//            timescale: videoDuration.timescale)
//    }
//
//    /// Normalized time
//    func getNormalizedTime(from time: CMTime) -> CGFloat? {
//        let result = CGFloat(time.seconds / videoDuration.seconds)
//        assert(result < 1.05)
//        return result
//    }
//
//    /// Return the the position of a view from the video time
//    func getPosition(from time: CMTime) -> CGFloat? {
//        return getNormalizedTime(from: time)
//            .map { $0 * durationSize }
//    }
//
//    /// Normalized position
//    func getNormalizedPosition(from position: CGFloat) -> CGFloat {
//        return max(min(1, position / durationSize), 0)
//    }
//
//    /// Delete the old thumbnails
//    func regenerateThumbViews(count: Int) {
//        thumbsStackView.arrangedSubviews
//            .forEach { view in
//                thumbsStackView.removeArrangedSubview(view)
//                view.removeFromSuperview()
//        }
//
//        (0..<count).map { _ in
//            let imageView = UIImageView()
//            imageView.frame.size = thumbnailSize
//            imageView.backgroundColor = UIColor.black
//            return imageView
//            }.forEach(thumbsStackView.addArrangedSubview)
//    }
//}
//
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
//
//fileprivate func getThumbnailSize(
//    from asset: AVAsset,
//    with bounds: CGRect) -> CGSize {
//
//    guard let track = asset.tracks(withMediaType: AVMediaType.video).first
//        else { fatalError() }
//
//    let targetSize = bounds.size
//    let assetSize = track.naturalSize.applying(track.preferredTransform)
//
//    assert(targetSize.width > 0)
//    assert(targetSize.height > 0)
//
//    let scaleFactor = targetSize.height / assetSize.height
//    let newWidth = assetSize.width * scaleFactor
//
//    return CGSize(width: newWidth,
//                  height: assetSize.height)
//}
//
