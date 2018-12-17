
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

    @IBInspectable open var draggableViewWidth: CGFloat = 20

    @IBInspectable open var pointerViewWidth: CGFloat = 2

    @IBInspectable open var handleViewWidth: CGFloat = 2

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
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var leftDraggableView: UIView = {
        let view = DraggableView()
        view.frame = .zero
        view.backgroundColor = mainColor
        view.isUserInteractionEnabled = true
        view.tag = 0
        return view
    }()

    lazy var rightDraggableView: UIView = {
        let view = DraggableView()
        view.frame = .zero
        view.backgroundColor = mainColor
        view.isUserInteractionEnabled = true
        view.tag = 1
        return view
    }()

    var thumbnailsView: ThumbnailsView = {
        let thumbsView = ThumbnailsView()
        thumbsView.frame = .zero
        thumbsView.isUserInteractionEnabled = true
        return thumbsView
    }()

    lazy var leftMaskView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        view.alpha = alphaView
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var rightMaskView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        view.alpha = alphaView
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var leftHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = handleViewColor
        view.layer.cornerRadius = 2
        return view
    }()

    lazy var rightHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = handleViewColor
        view.layer.cornerRadius = 2
        return view
    }()

    lazy var pointerView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = UIColor.white
        return view
    }()

    

    var trimViewRect: CGRect {
        return CGRect(x: leftDraggableView.frame.minX,
                      y: 0,
                      width: rightDraggableView.frame.maxX - leftDraggableView.frame.minX,
                      height: bounds.height)
    }

    var thumbnailsViewRect: CGRect {
        return CGRect(x: 0,
                      y: 0,
                      width: frame.width,
                      height: frame.height)
    }

    var leftDraggableViewRect: CGRect {
        return CGRect(x: 0,
                      y: 0,
                      width: draggableViewWidth,
                      height: bounds.height)
    }

    var rightDraggableViewRect: CGRect {
        return CGRect(x: leftDraggableViewRect.maxX + maximumDistance,
                      y: 0,
                      width: draggableViewWidth,
                      height: bounds.height)
    }

    var leftMaskViewRect: CGRect {
        return CGRect(x: 0,
                      y: 0,
                      width: leftDraggableView.frame.minX,
                      height: bounds.height)
    }

    var rightMaskViewRect: CGRect {
        return CGRect(x: rightDraggableView.frame.maxX,
                      y: 0,
                      width: bounds.width - rightDraggableView.frame.maxX,
                      height: bounds.height)
    }

    var leftHandleViewRect: CGRect {
        return CGRect(x: leftDraggableView.frame.width/2,
                      y: rightDraggableView.frame.height/4,
                      width: handleViewWidth,
                      height: leftDraggableView.bounds.height / 2)
    }

    var rightHandleViewRect: CGRect {
        return CGRect(x: rightDraggableView.frame.width/2,
                      y: rightDraggableView.frame.height/4,
                      width: handleViewWidth,
                      height: rightDraggableView.bounds.height / 2)
    }

    var pointerViewRect: CGRect {
        return CGRect(x: leftDraggableView.frame.maxX,
                      y: borderWidth,
                      width: pointerViewWidth,
                      height: bounds.height - borderWidth * 2)
    }

    let maximumDistance: CGFloat = 150
    let minimumDistance: CGFloat = 20

    open override func awakeFromNib() {
        super.awakeFromNib()

        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

//        thumbnailsView.frame = thumbnailsViewRect
//        trimView.frame = trimViewRect
//        leftDraggableView.frame = leftDraggableViewRect
//        rightDraggableView.frame = rightDraggableViewRect
//
//        leftMaskView.frame = leftMaskViewRect
//        rightMaskView.frame = rightMaskViewRect
//
//        leftHandleView.frame = leftHandleViewRect
//        rightHandleView.frame = rightHandleViewRect
    }

    private func commonInit() {
        addSubview(thumbnailsView)
        addSubview(trimView)
        addSubview(pointerView)
        addSubview(leftDraggableView)
        addSubview(rightDraggableView)

        leftDraggableView.addSubview(leftHandleView)
        rightDraggableView.addSubview(rightHandleView)

        addSubview(leftMaskView)
        addSubview(rightMaskView)

        updateFrame()

        setupPanGestures()
    }

    private func updateFrame() {
        thumbnailsView.frame = thumbnailsViewRect
        leftDraggableView.frame = leftDraggableViewRect
        rightDraggableView.frame = rightDraggableViewRect

        trimView.frame = trimViewRect

        leftMaskView.frame = leftMaskViewRect
        rightMaskView.frame = rightMaskViewRect

        leftHandleView.frame = leftHandleViewRect
        rightHandleView.frame = rightHandleViewRect

        pointerView.frame = pointerViewRect
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

    var currentLeftPosition = CGFloat()
    var currentRightPosition = CGFloat()

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        sender.maximumNumberOfTouches = 1
        let isLeftGesture = (view == leftDraggableView)

        let translation = sender.translation(in: self)

        let currentDistance = rightDraggableView.frame.minX - leftDraggableView.frame.maxX


        switch sender.state {

        //        case .began:
        //                if let start = startTime {
        //                                    delegate?.trimmerDidBeginDragging?(self, with: start)
        //                                }

        case .changed:

        if currentDistance >= maximumDistance {
            print("greater than max distance")
            if isLeftGesture {
                if translation.x < 0 {
                    moveBoth(sender : sender, isLeftPan: isLeftGesture, currentDistance: currentDistance)
                }
                if translation.x > 0 {
                    moveDraggable(sender : sender, pan: leftDraggableView)
                }
            } else {
                if translation.x > 0 {
                    moveBoth(sender : sender, isLeftPan: isLeftGesture, currentDistance: currentDistance)
                }
                if translation.x < 0 {
                    moveDraggable(sender : sender, pan: rightDraggableView)
                }
            }

        } else if currentDistance <= maximumDistance && currentDistance > minimumDistance {
            print("less than max distance and greater than minDistance")
            if isLeftGesture {
                if leftDraggableView.center.x >= 0{
                    moveDraggable(sender : sender, pan: leftDraggableView)
                }
            } else {
                if rightDraggableView.center.x <= bounds.width {
                    moveDraggable(sender : sender, pan: rightDraggableView)
                }
            }
        } else if currentDistance <= minimumDistance {
            print("less than min distance")
            if isLeftGesture {
                if translation.x < 0 && leftDraggableView.center.x > leftDraggableView.bounds.width/2 {
                    moveDraggable(sender : sender, pan: leftDraggableView)
                }
                if translation.x > 0 {
                    moveBoth(sender : sender, isLeftPan: isLeftGesture, currentDistance: currentDistance)
                }
            } else {
                if translation.x > 0 && rightDraggableView.center.x < bounds.width - rightDraggableView.bounds.width/2{
                    moveDraggable(sender : sender, pan: rightDraggableView)
                }
                if translation.x < 0 {
                    moveBoth(sender : sender, isLeftPan: isLeftGesture, currentDistance: currentDistance)
                }
            }

        }

        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }

        //            guard let maxDistance = maximumDistanceBetweenDraggableViews else { return }
        //            if isLeftGesture,
        //                (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) >= maxDistance {
        //                currentLeadingConstraint = trimViewLeadingConstraint.constant
        //                currentTrailingConstraint = trimViewTrailingConstraint.constant
        //            } else if isLeftGesture {
        //                currentLeadingConstraint = trimViewLeadingConstraint.constant
        //            } else if !isLeftGesture {
        ////            (bounds.width - draggableViewWidth * 2 - trimViewLeadingConstraint.constant - abs(trimViewTrailingConstraint.constant)) > maxDistance {
        //                currentLeadingConstraint = trimViewLeadingConstraint.constant
        //                currentTrailingConstraint = trimViewTrailingConstraint.constant
        //            } else {
        //                currentTrailingConstraint = trimViewTrailingConstraint.constant
        //            }

        //            if let start = startTime {
        //                delegate?.trimmerDidBeginDragging?(self, with: start)
        //            }

        //        case .changed:
        //            let translation = sender.translation(in: view)
        //            guard let maxDistance = maximumDistanceBetweenDraggableViews else { return }
        //            guard let minDistance = minimumDistanceBetweenDraggableViews else { return }
        //            let currenAreaBetweenPan = rightDraggableView.frame.origin.x - leftDraggableView.frame.origin.x
        //            let newDestionation = CGAffineTransform(translationX: translation.x, y: 0)
        //            let newScale = CGAffineTransform(scaleX: translation.x, y: 0)
        //
        //            if isLeftGesture{
        //                if currenAreaBetweenPan >= maxDistance {
        //                    if translation.x < 0 {
        //                        leftDraggableView.transform = newDestionation
        //                        rightDraggableView.transform = newDestionation
        //                    }else {
        //                        leftDraggableView.transform = newDestionation
        //                    }
        //                }
        //            }else {
        //                if currenAreaBetweenPan >= maxDistance {
        //                    if translation.x > 0 {
        //                        leftDraggableView.transform = newDestionation
        //                        rightDraggableView.transform = newDestionation
        //                    }else {
        //                        rightDraggableView.transform = newDestionation
        //
        //                    }
        //                }
        //            }
        //
        //            UIView.animate(withDuration: 0.1) {
        //                self.layoutIfNeeded()
        //            }
        //
        //            if isLeftGesture, let startTime = startTime {
        //                delegate?.trimmerDidChangeDraggingPosition?(self, with: startTime)
        //                timePointerView.isHidden = true
        //            } else if let endTime = endTime {
        //                delegate?.trimmerDidChangeDraggingPosition?(self, with: endTime)
        //                timePointerView.isHidden = true
        //            }
        //
        //        case .cancelled, .failed, .ended:
        //            if let startTime = startTime, let endTime = endTime {
        //                delegate?.trimmerDidEndDragging?(
        //                    self,
        //                    with: startTime,
        //                    endTime: endTime)

        //                timePointerView.isHidden = false
        //                timePointerViewLeadingAnchor.constant = 0
        //            }

                default:
                    break
        }
    }

    func moveBoth(sender : UIPanGestureRecognizer, isLeftPan : Bool, currentDistance : CGFloat) {
        if isLeftPan {
            if leftDraggableView.center.x < leftDraggableView.bounds.width/2 {
                sender.setTranslation(CGPoint.zero, in: self)
                return
            } else if rightDraggableView.center.x > bounds.width - rightDraggableView.bounds.width/2 {
                if (sender.translation(in: self).x < 0){
                    if(currentDistance < maximumDistance){

                        moveDraggable(sender: sender, pan: leftDraggableView)

                    }else {
                        leftDraggableView.center = CGPoint(x: leftDraggableView.center.x + sender.translation(in: self).x, y: leftDraggableView.center.y)
                        rightDraggableView.center = CGPoint(x: rightDraggableView.center.x + sender.translation(in: self).x, y: rightDraggableView.center.y)
                        if rightDraggableView.frame.minX - pointerView.frame.maxX <= 0.1 && sender.translation(in: self).x < 0 {
                            pointerView.frame.origin.x = rightDraggableView.frame.minX
                        } else if pointerView.frame.minX - leftDraggableView.frame.maxX <= 0.1 && sender.translation(in: self).x > 0 {
                            pointerView.frame.origin.x = leftDraggableView.frame.maxX
                        }
                        sender.setTranslation(CGPoint.zero, in: self)

                    }
                }else if (sender.translation(in: self).x > 0){
                    if(currentDistance < maximumDistance ) {
                        if (currentDistance > minimumDistance){
                            moveDraggable(sender: sender, pan: leftDraggableView)
                        }else {
                            sender.setTranslation(CGPoint.zero, in: self)
                            return
                        }
                    }
                }
            } else if currentDistance <= minimumDistance || currentDistance >= maximumDistance {
                leftDraggableView.center = CGPoint(x: leftDraggableView.center.x + sender.translation(in: self).x, y: leftDraggableView.center.y)
                rightDraggableView.center = CGPoint(x: rightDraggableView.center.x + sender.translation(in: self).x, y: rightDraggableView.center.y)

                if rightDraggableView.frame.minX - pointerView.frame.maxX <= 0.1 && sender.translation(in: self).x < 0 {
                    pointerView.frame.origin.x = rightDraggableView.frame.minX
                } else if pointerView.frame.minX - leftDraggableView.frame.maxX <= 0.1 && sender.translation(in: self).x > 0 {
                    pointerView.frame.origin.x = leftDraggableView.frame.maxX
                }
                sender.setTranslation(CGPoint.zero, in: self)
            } else if currentDistance >= minimumDistance {
                moveDraggable(sender: sender, pan: leftDraggableView)
            }
        }
        else {
            if rightDraggableView.center.x >= bounds.width - rightDraggableView.bounds.width/2 {
                sender.setTranslation(CGPoint.zero, in: self)
                return
            } else if leftDraggableView.center.x < leftDraggableView.bounds.width/2 {
                if (sender.translation(in: self).x > 0){
                    if(currentDistance < maximumDistance){
                        moveDraggable(sender: sender, pan: rightDraggableView)
                    }else {
                        leftDraggableView.center = CGPoint(x: leftDraggableView.center.x + sender.translation(in: self).x, y: leftDraggableView.center.y)
                        rightDraggableView.center = CGPoint(x: rightDraggableView.center.x + sender.translation(in: self).x, y: rightDraggableView.center.y)

                        if rightDraggableView.frame.minX - pointerView.frame.maxX <= 0.1 && sender.translation(in: self).x < 0 {
                            pointerView.frame.origin.x = rightDraggableView.frame.minX
                        } else if pointerView.frame.minX - leftDraggableView.frame.maxX <= 0.1 && sender.translation(in: self).x > 0 {
                            pointerView.frame.origin.x = leftDraggableView.frame.maxX
                        }

                        sender.setTranslation(CGPoint.zero, in: self)
                    }
                }else if (sender.translation(in: self).x < 0){
                    if(currentDistance < maximumDistance ) {
                        if (currentDistance > minimumDistance){
                            moveDraggable(sender: sender, pan: rightDraggableView)
                        }else {
                            sender.setTranslation(CGPoint.zero, in: self)
                            return
                        }
                    }
                }
            } else if currentDistance <= minimumDistance || currentDistance >= maximumDistance {
                leftDraggableView.center = CGPoint(x: leftDraggableView.center.x + sender.translation(in: self).x, y: leftDraggableView.center.y)
                rightDraggableView.center = CGPoint(x: rightDraggableView.center.x + sender.translation(in: self).x, y: rightDraggableView.center.y)

                if rightDraggableView.frame.minX - pointerView.frame.maxX <= 0.1 && sender.translation(in: self).x < 0 {
                    pointerView.frame.origin.x = rightDraggableView.frame.minX
                } else if pointerView.frame.minX - leftDraggableView.frame.maxX <= 0.1 && sender.translation(in: self).x > 0 {
                    pointerView.frame.origin.x = leftDraggableView.frame.maxX
                }

                sender.setTranslation(CGPoint.zero, in: self)
            } else if currentDistance >= minimumDistance {
                moveDraggable(sender: sender, pan: rightDraggableView)
            }
        }

        trimView.frame = trimViewRect
        leftMaskView.frame = leftMaskViewRect
        rightMaskView.frame = rightMaskViewRect

    }

    func moveDraggable(sender: UIPanGestureRecognizer, pan: UIView) {

        pan.center = CGPoint(x: pan.center.x + sender.translation(in: self).x, y: pan.center.y)
        if pan.tag == 0 {
            leftMaskView.frame = leftMaskViewRect
            if pointerView.frame.minX - pan.frame.maxX <= 0.1 && sender.translation(in: self).x > 0 {
                pointerView.frame.origin.x = pan.frame.maxX
            }
        } else {
            rightMaskView.frame = rightMaskViewRect
            if pan.frame.minX - pointerView.frame.maxX <= 0.1 && sender.translation(in: self).x < 0 {
                pointerView.frame.origin.x = pan.frame.minX
            }
        }
        trimView.frame = trimViewRect
        sender.setTranslation(CGPoint.zero, in: self)
//        pan.center.x = pan.center.x + point.x

    }

        @objc func handleScrubbingPan(_ sender: UIPanGestureRecognizer) {
            switch sender.state {
//            case .began:
//                currentPointerLeadingConstraint = position.x + view.frame.minX - draggableViewWidth
//
//                guard let time = thumbnailsView.getTime(
//                    from: currentPointerLeadingConstraint) else { return }
//                delegate?.trimmerScrubbingDidBegin?(self,
//                                                    with: time)

            case .changed:
                if pointerView.frame.minX >= (leftDraggableView.frame.maxX + 5) {
                    pointerView.center = CGPoint(x: pointerView.center.x + sender.translation(in: self).x, y: pointerView.center.y)
                    sender.setTranslation(CGPoint.zero, in: self)
                }
                else {
                    if sender.translation(in: self).x > 0{
                        pointerView.center = CGPoint(x: pointerView.center.x + sender.translation(in: self).x, y: pointerView.center.y)
                        sender.setTranslation(CGPoint.zero, in: self)
                    }
                }

                if pointerView.frame.maxX <= (rightDraggableView.frame.maxX - 5) {
                    pointerView.center = CGPoint(x: pointerView.center.x + sender.translation(in: self).x, y: pointerView.center.y)
                    sender.setTranslation(CGPoint.zero, in: self)
                }
                else {
                    if sender.translation(in: self).x < 0{
                        pointerView.center = CGPoint(x: pointerView.center.x + sender.translation(in: self).x, y: pointerView.center.y)
                        sender.setTranslation(CGPoint.zero, in: self)
                    }
                }



//                guard let time = thumbnailsView.getTime(
//                    from: currentPointerLeadingConstraint) else { return }
//                delegate?.trimmerScrubbingDidChange?(self,
//                                                     with: time)
//            case .failed, .ended, .cancelled:
//                guard let time = thumbnailsView.getTime(
//                    from: currentPointerLeadingConstraint) else { return }
//                delegate?.trimmerScrubbingDidEnd?(self,
//                                                  with: time)
            default:
                break
            }
        }


}
//
//@IBDesignable
//open class TrimmerViewOld: UIView {
//
//    //MARK: Properties
//
//    // Return the minimum distance between the left and right view expressed in seconds
//    private var minimumDistanceBetweenDraggableViews: CGFloat? {
//        return (CGFloat(maxVideoDurationAfterTrimming)
//            * thumbnailsView.durationSize
//            / CGFloat(thumbnailsView.videoDuration.seconds))/3
////        return CGFloat(minVideoDurationAfterTrimming)
////            * thumbnailsView.durationSize
////            / CGFloat(thumbnailsView.videoDuration.seconds)
//    }
//
//    // Return the maximum distance between the left and right view expressed in seconds
//    private var maximumDistanceBetweenDraggableViews: CGFloat? {
//        return CGFloat(maxVideoDurationAfterTrimming)
//            * thumbnailsView.durationSize
//            / CGFloat(thumbnailsView.videoDuration.seconds)
//    }
//
//    /// Return the time of the start
//    var startTime: CMTime? {
//        let startPosition = leftDraggableView.frame.maxX - thumbnailsView.frame.origin.x
//
//        return thumbnailsView.getTime(from: startPosition)
//    }
//
//    /// Return the time of the end
//    var endTime: CMTime? {
//        let endPosition = rightDraggableView.frame.minX - thumbnailsView.frame.origin.x
//
//        return thumbnailsView.getTime(from: endPosition)
//    }
//
//    var thumbnailViewRect: CGRect {
//        return CGRect(
//            x: draggableViewWidth,
//            y: 0,
//            width: bounds.width - draggableViewWidth * 2,
//            height: bounds.height)
//    }
//
//    // MARK: Setups views
//    private func setup() {
//        backgroundColor = UIColor.clear
//        thumbnailsView.frame = thumbnailViewRect
//
//        addSubview(thumbnailsView)
//        addSubview(trimView)
//
//        addSubview(leftDraggableView)
//        addSubview(rightDraggableView)
////        addSubview(leftMaskView)
////        addSubview(rightMaskView)
//        leftDraggableView.addSubview(leftHandleView)
//        rightDraggableView.addSubview(rightHandleView)
//
//        setupTimePointer()
//        setupPanGestures()
//    }
//
//    private func setupTimePointer() {
//        if isTimePointerVisible {
//            addSubview(timePointerView)
//
//            NSLayoutConstraint.activate([
//                timePointerViewHeightAnchor,
//                timePointerViewWidthgAnchor,
//                timePointerViewTopAnchor,
//                timePointerViewLeadingAnchor
//                ])
//        } else {
//            timePointerView.removeFromSuperview()
//
//            NSLayoutConstraint.deactivate([
//                timePointerViewHeightAnchor,
//                timePointerViewWidthgAnchor,
//                timePointerViewTopAnchor,
//                timePointerViewLeadingAnchor
//                ])
//        }
//    }
//

//

//
//    //MARK: Methods
//
//    /// Update the leading contraint of the left draggable view after the pan gesture
//    func updateLeadingConstraint(with translation: CGPoint) {
//        guard let minDistance = minimumDistanceBetweenDraggableViews
//            else { return }
//
//        let maxConstraint = self.bounds.width
//            - (draggableViewWidth * 2)
//            - minDistance
//
//        assert(maxConstraint >= 0)
//
//        let newPosition = clamp(
//            currentLeadingConstraint + translation.x,
//            0, maxConstraint)
//
////        trimViewLeadingConstraint.constant = newPosition
//
//    }
//
//    /// Update the trailing contraint of the right draggable view after the pan gesture
//    func updateTrailingConstraint(with translation: CGPoint) {
//        guard let minDistance = minimumDistanceBetweenDraggableViews
//            else { return }
//
//        let maxConstraint = self.bounds.width
//            - (draggableViewWidth * 2)
//            - minDistance
//
//        let newPosition = clamp(
//            currentTrailingConstraint + translation.x,
//            -maxConstraint, 0)
//
////        trimViewTrailingConstraint.constant = newPosition
//    }
//
//    /// Set up the new position of the pointer when the video play
//    func seek(to time: CMTime) {
//        guard let newPosition = thumbnailsView.getPosition(from: time)
//            else { return }
//
//        assert(thumbnailsView.getNormalizedTime(from: time)! < 1.1)
//
//        let offsetPosition = thumbnailsView
//            .convert(CGPoint(x: newPosition, y: 0), to: trimView)
//            .x - draggableViewWidth
//
//        let maxPosition = rightDraggableView.frame.minX
//            - leftDraggableView.frame.maxX
//            - timePointerView.frame.width
//
//        let clampedPosition = clamp(offsetPosition, 0, maxPosition)
//        timePointerViewLeadingAnchor.constant = CGFloat(clampedPosition)
//        layoutIfNeeded()
//    }
//
//    /// Reset the pointer near the left draggable view
//    func resetTimePointer() {
//        timePointerViewLeadingAnchor.constant = 0
//    }
//
//    public func updateSubviews() {
//        resetTimePointer()
//        
//        guard let asset = thumbnailsView.asset,
//            let videoTrack = asset
//            .tracks(withMediaType: .video).first else { return }
//
//        let newStartTime = CMTime(value: trimStartPosition, timescale: timeScale)
//        if let leadingValue = thumbnailsView.getPosition(from: newStartTime) {
////            trimViewLeadingConstraint.constant = leadingValue
//        }
//
//        let newEndTime = CMTime(
//            value: trimEndPosition + videoTrack.minFrameDuration.value,
//            timescale: timeScale)
//        if let trailingValue = thumbnailsView.getPosition(from: newEndTime) {
////            trimViewTrailingConstraint.constant = trailingValue - bounds.width + draggableViewWidth * 2
//        }
//    }
//
//}

private func clamp<T: Comparable>(_ number: T, _ minimum: T, _ maximum: T) -> T {
    return min(maximum, max(minimum, number))
}
