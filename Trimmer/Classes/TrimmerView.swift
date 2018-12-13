
//
//  TrimmerView.swift
//  TrimmerVideo
//
//  Created by Diego Caroli on 19/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol TrimmerViewDelegate: class {
    @objc optional func trimmerDidBeginDragging(
        _ trimmer: TrimmerView,
        with currentTimeTrim: CMTime)

    @objc optional func trimmerDidChangeDraggingPosition(
        _ trimmer: TrimmerView,
        with currentTimeTrim: CMTime)

    @objc optional func trimmerDidEndDragging(
        _ trimmer: TrimmerView,
        with startTime: CMTime,
        endTime: CMTime)

    @objc optional func trimmerScrubbingDidBegin(
        _ trimmer: TrimmerView,
        with currentTimeScrub: CMTime)

    @objc optional func trimmerScrubbingDidChange(
        _ trimmer: TrimmerView,
        with currentTimeScrub: CMTime)

    @objc optional func trimmerScrubbingDidEnd(
        _ trimmer: TrimmerView,
        with currentTimeScrub: CMTime)
}

@IBDesignable
open class TrimmerView: UIView {

    // MARK: IBInspectable
    @IBInspectable open var mainColor: UIColor = .orange {
        didSet {
            trimView.layer.borderColor = mainColor.cgColor
            leftDraggableView.backgroundColor = mainColor
            rightDraggableView.backgroundColor = mainColor
        }
    }

    @IBInspectable open var borderWidth: CGFloat = 2 {
        didSet {
            trimView.layer.borderWidth = borderWidth
        }
    }

    @IBInspectable open var alphaView: CGFloat = 0.7 {
        didSet {
            leftMaskView.alpha = alphaView
            rightMaskView.alpha = alphaView
        }
    }

    @IBInspectable open var draggableViewWidth: CGFloat = 20 {
        didSet {
            dimmingViewLeadingAnchor = thumbnailsView.leadingAnchor
                .constraint(equalTo: leadingAnchor, constant: draggableViewWidth)
            dimmingViewTrailingAnchor = thumbnailsView.trailingAnchor
                .constraint(equalTo: trailingAnchor, constant: -draggableViewWidth)
            trimViewWidthContraint = trimView.widthAnchor
                .constraint(greaterThanOrEqualToConstant: draggableViewWidth * 2 + borderWidth)
            leftDraggableViewWidthAnchor = leftDraggableView.widthAnchor
                .constraint(equalToConstant: draggableViewWidth)
            rightDraggableViewWidthAnchor = rightDraggableView.widthAnchor
                .constraint(equalToConstant: draggableViewWidth)
        }
    }

    @IBInspectable open var timePointerViewWidth: CGFloat = 2 {
        didSet {
            timePointerViewWidthgAnchor = timePointerView.widthAnchor
                .constraint(equalToConstant: timePointerViewWidth)
            timePointerViewHeightAnchor = timePointerView.heightAnchor
                .constraint(equalToConstant: bounds.height - timePointerViewWidth * 2)
        }
    }

    @IBInspectable open var handleViewWidth: CGFloat = 2 {
        didSet {
            leftHandleViewWidth = leftHandleView.widthAnchor
            .constraint(equalToConstant: handleViewWidth)
            rightHandleViewWidth = rightHandleView.widthAnchor
                .constraint(equalToConstant: handleViewWidth)
        }
    }

    @IBInspectable open var handleViewHeight: CGFloat = 25 {
        didSet {
            leftHandleViewHeight = leftHandleView.heightAnchor
                .constraint(equalToConstant: handleViewHeight)
            rightHandleViewHeight = rightHandleView.heightAnchor
                .constraint(equalToConstant: handleViewHeight)
        }
    }

    @IBInspectable open var handleViewColor: UIColor = .white {
        didSet {
            leftHandleView.backgroundColor = handleViewColor
            rightHandleView.backgroundColor = handleViewColor
        }
    }

    @IBInspectable open var minVideoDurationAfterTrimming: Double = 2
    @IBInspectable open var maxVideoDurationAfterTrimming: Double = 6

    @IBInspectable open var isTimePointerVisible: Bool = true

    open weak var delegate: TrimmerViewDelegate?

    var trimStartPosition: Int64 = 0
    var trimEndPosition: Int64 = 0
    var timeScale: Int32 = 0

    //MARK: Views
    lazy var trimView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .clear
        view.layer.borderWidth = borderWidth
        view.layer.borderColor = mainColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var leftDraggableView: UIView = {
        let view = DraggableView()
        view.frame = .zero
        view.backgroundColor = mainColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var rightDraggableView: UIView = {
        let view = DraggableView()
        view.frame = .zero
        view.backgroundColor = mainColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var leftMaskView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        view.alpha = alphaView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var rightMaskView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        view.alpha = alphaView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private let timePointerView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    var thumbnailsView: ThumbnailsView = {
        let thumbsView = ThumbnailsView()
        thumbsView.frame = .zero
        thumbsView.translatesAutoresizingMaskIntoConstraints = false
        thumbsView.isUserInteractionEnabled = true
        return thumbsView
    }()

    lazy var leftHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = handleViewColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2
        return view
    }()

    lazy var rightHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = handleViewColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2
        return view
    }()

    //MARK: Properties

    // Return the minimum distance between the left and right view expressed in seconds
    private var minimumDistanceBetweenDraggableViews: CGFloat? {
        return CGFloat(minVideoDurationAfterTrimming)
            * thumbnailsView.durationSize
            / CGFloat(thumbnailsView.videoDuration.seconds)
    }

    // Return the maximum distance between the left and right view expressed in seconds
    private var maximumDistanceBetweenDraggableViews: CGFloat? {
        return CGFloat(maxVideoDurationAfterTrimming)
            * thumbnailsView.durationSize
            / CGFloat(thumbnailsView.videoDuration.seconds)
    }

    /// Return the time of the start
    var startTime: CMTime? {
        let startPosition = leftDraggableView.frame.maxX - thumbnailsView.frame.origin.x

        return thumbnailsView.getTime(from: startPosition)
    }

    /// Return the time of the end
    var endTime: CMTime? {
        let endPosition = rightDraggableView.frame.minX - thumbnailsView.frame.origin.x

        return thumbnailsView.getTime(from: endPosition)
    }

    var thumbnailViewRect: CGRect {
        return CGRect(
            x: draggableViewWidth,
            y: 0,
            width: bounds.width - 2 * draggableViewWidth,
            height: bounds.height)
    }

    // MARK: Constraints
    private(set) lazy var currentLeadingConstraint: CGFloat = 0
    private(set) lazy var currentTrailingConstraint: CGFloat = 0
    private(set) lazy var currentPointerLeadingConstraint: CGFloat = 0

    private lazy var dimmingViewTopAnchor = thumbnailsView.topAnchor
        .constraint(equalTo: topAnchor, constant: 0)
    private lazy var dimmingViewBottomAnchor = thumbnailsView.bottomAnchor
        .constraint(equalTo: bottomAnchor, constant: 0)
    private lazy var dimmingViewLeadingAnchor = thumbnailsView.leadingAnchor
        .constraint(equalTo: leadingAnchor, constant: draggableViewWidth)
    private lazy var dimmingViewTrailingAnchor = thumbnailsView.trailingAnchor
        .constraint(equalTo: trailingAnchor, constant: -draggableViewWidth)

    private lazy var trimViewTopAnchorConstraint = trimView.topAnchor
        .constraint(equalTo: topAnchor, constant: 0)
    private lazy var trimViewBottomAnchorConstraint = trimView.bottomAnchor
        .constraint(equalTo: bottomAnchor, constant: 0)
    lazy var trimViewLeadingConstraint = trimView.leadingAnchor
        .constraint(equalTo: leadingAnchor, constant: 0)
    lazy var trimViewTrailingConstraint = trimView.trailingAnchor
        .constraint(equalTo: trailingAnchor, constant: 0)
    private lazy var trimViewWidthContraint = trimView.widthAnchor
        .constraint(greaterThanOrEqualToConstant: draggableViewWidth * 2 + borderWidth)

    private lazy var leftDraggableViewLeadingAnchor = leftDraggableView.leadingAnchor
        .constraint(equalTo: trimView.leadingAnchor, constant: 0)
    private lazy var leftDraggableViewWidthAnchor = leftDraggableView.widthAnchor
        .constraint(equalToConstant: draggableViewWidth)
    private lazy var leftDraggableViewTopAnchor = leftDraggableView.topAnchor
        .constraint(equalTo: trimView.topAnchor, constant: 0)
    private lazy var leftDraggableViewBottomAnchor = leftDraggableView.bottomAnchor
        .constraint(equalTo: trimView.bottomAnchor, constant: 0)

    private lazy var rightDraggableViewTopAnchor = rightDraggableView.topAnchor
        .constraint(equalTo: trimView.topAnchor, constant: 0)
    private lazy var rightDraggableViewBottomAnchor = rightDraggableView.bottomAnchor
        .constraint(equalTo: trimView.bottomAnchor, constant: 0)
    private lazy var rightDraggableViewTrailingAnchor = rightDraggableView.trailingAnchor
        .constraint(equalTo: trimView.trailingAnchor, constant: 0)
    private lazy var rightDraggableViewWidthAnchor = rightDraggableView.widthAnchor
        .constraint(equalToConstant: draggableViewWidth)

    private lazy var leftMaskViewTopAnchor = leftMaskView.topAnchor
        .constraint(equalTo: trimView.topAnchor, constant: 0)
    private lazy var leftMaskViewBottomAnchor = leftMaskView.bottomAnchor
        .constraint(equalTo: trimView.bottomAnchor, constant: 0)
    private lazy var leftMaskViewLeadingAnchor = leftMaskView.leadingAnchor
        .constraint(equalTo: leadingAnchor, constant: 0)
    private lazy var leftMaskViewTrailingAnchor = leftMaskView.trailingAnchor
        .constraint(equalTo: leftDraggableView.leadingAnchor, constant: 0)

    private lazy var rightMaskViewTopAnchor = rightMaskView.topAnchor
        .constraint(equalTo: topAnchor, constant: 0)
    private lazy var rightMaskViewBottomAnchor = rightMaskView.bottomAnchor
        .constraint(equalTo: bottomAnchor, constant: 0)
    private lazy var rightMaskViewTrailingAnchor = rightMaskView.trailingAnchor
        .constraint(equalTo: trailingAnchor, constant: 0)
    private lazy var rightMaskViewLeadingAnchor = rightMaskView.leadingAnchor
        .constraint(equalTo: rightDraggableView.trailingAnchor, constant: 0)

    private lazy var timePointerViewWidthgAnchor = timePointerView.widthAnchor
        .constraint(equalToConstant: timePointerViewWidth)
    private lazy var timePointerViewHeightAnchor = timePointerView.heightAnchor
        .constraint(equalToConstant: bounds.height - borderWidth * 2)
    private lazy var timePointerViewTopAnchor = timePointerView.topAnchor
        .constraint(equalTo: topAnchor, constant: borderWidth)
    private lazy var timePointerViewLeadingAnchor = timePointerView.leadingAnchor
        .constraint(equalTo: leftDraggableView.trailingAnchor, constant: 0)

    private lazy var leftHandleViewCenterX = leftHandleView.centerXAnchor
        .constraint(equalTo: leftDraggableView.centerXAnchor)
    private lazy var leftHandleViewCenterY = leftHandleView.centerYAnchor
        .constraint(equalTo: leftDraggableView.centerYAnchor)
    private lazy var leftHandleViewWidth = leftHandleView.widthAnchor
        .constraint(equalToConstant: handleViewWidth)
    private lazy var leftHandleViewHeight = leftHandleView.heightAnchor
        .constraint(equalToConstant: handleViewHeight)

    private lazy var rightHandleViewCenterX = rightHandleView.centerXAnchor
        .constraint(equalTo: rightDraggableView.centerXAnchor)
    private lazy var rightHandleViewCenterY = rightHandleView.centerYAnchor
        .constraint(equalTo: rightDraggableView.centerYAnchor)
    private lazy var rightHandleViewWidth = rightHandleView.widthAnchor
        .constraint(equalToConstant: handleViewWidth)
    private lazy var rightHandleViewHeight = rightHandleView.heightAnchor
        .constraint(equalToConstant: handleViewHeight)

    // MARK: View Life Cycle
    override open func awakeFromNib() {
        super.awakeFromNib()

        setup()

        trimViewLeadingConstraint.priority = .defaultHigh
        trimViewTrailingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            dimmingViewTopAnchor,
            dimmingViewBottomAnchor,
            dimmingViewLeadingAnchor,
            dimmingViewTrailingAnchor,

            trimViewTopAnchorConstraint,
            trimViewBottomAnchorConstraint,
            trimViewLeadingConstraint,
            trimViewTrailingConstraint,

            trimViewWidthContraint,

            leftDraggableViewLeadingAnchor,
            leftDraggableViewWidthAnchor,
            leftDraggableViewTopAnchor,
            leftDraggableViewBottomAnchor,

            rightDraggableViewTopAnchor,
            rightDraggableViewBottomAnchor,
            rightDraggableViewTrailingAnchor,
            rightDraggableViewWidthAnchor,

            leftMaskViewTopAnchor,
            leftMaskViewBottomAnchor,
            leftMaskViewLeadingAnchor,
            leftMaskViewTrailingAnchor,

            rightMaskViewTopAnchor,
            rightMaskViewBottomAnchor,
            rightMaskViewLeadingAnchor,
            rightMaskViewTrailingAnchor,

            leftHandleViewCenterX,
            leftHandleViewCenterY,
            leftHandleViewWidth,
            leftHandleViewHeight,

            rightHandleViewCenterX,
            rightHandleViewCenterY,
            rightHandleViewWidth,
            rightHandleViewHeight
            ])
    }

//    open override func layoutSubviews() {
//        super.layoutSubviews()
//
//        thumbnailsView.frame = thumbnailViewRect
//    }

    // MARK: Setups views
    private func setup() {
        backgroundColor = UIColor.clear
        thumbnailsView.frame = thumbnailViewRect

        addSubview(thumbnailsView)
        addSubview(trimView)

        addSubview(leftDraggableView)
        addSubview(rightDraggableView)
        addSubview(leftMaskView)
        addSubview(rightMaskView)
        leftDraggableView.addSubview(leftHandleView)
        rightDraggableView.addSubview(rightHandleView)

        setupTimePointer()
        setupPanGestures()
    }

    private func setupTimePointer() {
        if isTimePointerVisible {
            addSubview(timePointerView)

            NSLayoutConstraint.activate([
                timePointerViewHeightAnchor,
                timePointerViewWidthgAnchor,
                timePointerViewTopAnchor,
                timePointerViewLeadingAnchor
                ])
        } else {
            timePointerView.removeFromSuperview()

            NSLayoutConstraint.deactivate([
                timePointerViewHeightAnchor,
                timePointerViewWidthgAnchor,
                timePointerViewTopAnchor,
                timePointerViewLeadingAnchor
                ])
        }
    }

    //MARK: Gestures
    private func setupPanGestures() {
        let leftPanGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan))
        leftDraggableView.addGestureRecognizer(leftPanGesture)

        let rightPanGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan))
        rightDraggableView.addGestureRecognizer(rightPanGesture)

        let thumbsPanGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleScrubbingPan))
        trimView.addGestureRecognizer(thumbsPanGesture)
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }

        let isLeftGesture = (view == leftDraggableView)
        switch sender.state {

        case .began:
            if isLeftGesture,
                let maxDistance = maximumDistanceBetweenDraggableViews,
                (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) >= maxDistance,
                trimViewLeadingConstraint.constant >= 0 {
                currentLeadingConstraint = trimViewLeadingConstraint.constant
                currentTrailingConstraint = trimViewTrailingConstraint.constant
            } else if isLeftGesture {
                currentLeadingConstraint = trimViewLeadingConstraint.constant
            } else if let maxDistance = maximumDistanceBetweenDraggableViews,
            (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) >= maxDistance,
                trimViewTrailingConstraint.constant <= 0 {
                currentLeadingConstraint = trimViewLeadingConstraint.constant
                currentTrailingConstraint = trimViewTrailingConstraint.constant
            } else {
                currentTrailingConstraint = trimViewTrailingConstraint.constant
            }

            if let start = startTime {
                delegate?.trimmerDidBeginDragging?(self, with: start)
            }

        case .changed:
            let translation = sender.translation(in: view)

            if isLeftGesture,
                let maxDistance = maximumDistanceBetweenDraggableViews,
                (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) >= maxDistance,
                currentLeadingConstraint >= 0 {
//                translation.x >= 0 {
                updateLeadingConstraint(with: translation)
                updateTrailingConstraint(with: translation)
            } else if isLeftGesture {
                updateLeadingConstraint(with: translation)
            } else if let maxDistance = maximumDistanceBetweenDraggableViews,
                (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) >= maxDistance,
                currentTrailingConstraint <= 0 {
//                translation.x <= 0 {
                updateLeadingConstraint(with: translation)
                updateTrailingConstraint(with: translation)
            } else {
                updateTrailingConstraint(with: translation)
            }

            UIView.animate(withDuration: 0.1) {
                self.layoutIfNeeded()
            }

            if isLeftGesture, let startTime = startTime {
                delegate?.trimmerDidChangeDraggingPosition?(self, with: startTime)
                timePointerView.isHidden = true
            } else if let endTime = endTime {
                delegate?.trimmerDidChangeDraggingPosition?(self, with: endTime)
                timePointerView.isHidden = true
            }

        case .cancelled, .failed, .ended:
            if let startTime = startTime, let endTime = endTime {
                delegate?.trimmerDidEndDragging?(
                    self,
                    with: startTime,
                    endTime: endTime)

                timePointerView.isHidden = false
                timePointerViewLeadingAnchor.constant = 0
            }

        default:
            break
        }
    }

    @objc func handleScrubbingPan(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        let translation = sender.translation(in: view)
        sender.setTranslation(.zero, in: view)
        let position = sender.location(in: view)

        switch sender.state {
        case .began:
            currentPointerLeadingConstraint = position.x + view.frame.minX - draggableViewWidth

            guard let time = thumbnailsView.getTime(
                from: currentPointerLeadingConstraint) else { return }
            delegate?.trimmerScrubbingDidBegin?(self,
                                                with: time)

        case .changed:
            currentPointerLeadingConstraint += translation.x
            guard let time = thumbnailsView.getTime(
                from: currentPointerLeadingConstraint) else { return }
            delegate?.trimmerScrubbingDidChange?(self,
                                                 with: time)
        case .failed, .ended, .cancelled:
            guard let time = thumbnailsView.getTime(
                from: currentPointerLeadingConstraint) else { return }
            delegate?.trimmerScrubbingDidEnd?(self,
                                              with: time)
        default:
            break
        }
    }

    //MARK: Methods

    /// Update the leading contraint of the left draggable view after the pan gesture
    func updateLeadingConstraint(with translation: CGPoint) {
        guard let minDistance = minimumDistanceBetweenDraggableViews
            else { return }

        let maxConstraint = self.bounds.width
            - (draggableViewWidth * 2)
            - minDistance

        assert(maxConstraint >= 0)

        let newPosition = clamp(
            currentLeadingConstraint + translation.x,
            0, maxConstraint)

        trimViewLeadingConstraint.constant = newPosition

    }

    /// Update the trailing contraint of the right draggable view after the pan gesture
    func updateTrailingConstraint(with translation: CGPoint) {
        guard let minDistance = minimumDistanceBetweenDraggableViews
            else { return }

        let maxConstraint = self.bounds.width
            - (draggableViewWidth * 2)
            - minDistance

        let newPosition = clamp(
            currentTrailingConstraint + translation.x,
            -maxConstraint, 0)

        trimViewTrailingConstraint.constant = newPosition
    }

    /// Set up the new position of the pointer when the video play
    func seek(to time: CMTime) {
        guard let newPosition = thumbnailsView.getPosition(from: time)
            else { return }

        assert(thumbnailsView.getNormalizedTime(from: time)! < 1.1)

        let offsetPosition = thumbnailsView
            .convert(CGPoint(x: newPosition, y: 0), to: trimView)
            .x - draggableViewWidth

        let maxPosition = rightDraggableView.frame.minX
            - leftDraggableView.frame.maxX
            - timePointerView.frame.width

        let clampedPosition = clamp(offsetPosition, 0, maxPosition)
        timePointerViewLeadingAnchor.constant = CGFloat(clampedPosition)
        layoutIfNeeded()
    }

    /// Reset the pointer near the left draggable view
    func resetTimePointer() {
        timePointerViewLeadingAnchor.constant = 0
    }

    public func updateSubviews() {
        resetTimePointer()
        
        guard let asset = thumbnailsView.asset,
            let videoTrack = asset
            .tracks(withMediaType: .video).first else { return }

        let newStartTime = CMTime(value: trimStartPosition, timescale: timeScale)
        if let leadingValue = thumbnailsView.getPosition(from: newStartTime) {
            trimViewLeadingConstraint.constant = leadingValue
        }

        let newEndTime = CMTime(
            value: trimEndPosition + videoTrack.minFrameDuration.value,
            timescale: timeScale)
        if let trailingValue = thumbnailsView.getPosition(from: newEndTime) {
            trimViewTrailingConstraint.constant = trailingValue - bounds.width + draggableViewWidth * 2
        }
    }

}

private func clamp<T: Comparable>(_ number: T, _ minimum: T, _ maximum: T) -> T {
    return min(maximum, max(minimum, number))
}
