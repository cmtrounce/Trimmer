//
//  TrimmerViewTests.swift
//  TrimmerVideoTests
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import XCTest
import AVFoundation
@testable import Trimmer

class TrimmerViewTests: XCTestCase {

    var trimmerView: TrimmerView!
    var bundle: Bundle!
    var fileURL: URL!
    var asset: AVAsset!
    
    override func setUp() {
        super.setUp()
        
        trimmerView = TrimmerView()
        bundle = Bundle(for: type(of: self))
        fileURL = bundle.url(forResource: "IMG_0065", withExtension: "m4v")
        asset = AVAsset(url: fileURL)
        
        trimmerView.frame = CGRect(x: 0, y: 0, width: 140, height: 50)
        trimmerView.thumbnailsView = ThumbnailsView(
            frame: CGRect(x: 20, y: 0, width: 100, height: 50))
        trimmerView.rightDraggableView = UIView(frame: CGRect(x: 120,
                                                              y: 0,
                                                              width: 20,
                                                              height: 50))
        trimmerView.thumbnailsView.asset = asset
        
        _ = trimmerView.awakeFromNib()
    }
    
    override func tearDown() {
        trimmerView = nil
        bundle = nil
        fileURL = nil
        asset = nil
        
        super.tearDown()
    }
    
    func testBorderColor() {
        trimmerView.mainColor = UIColor.blue
        
        XCTAssertEqual(trimmerView.trimView.layer.borderColor,
                       trimmerView.mainColor.cgColor)
    }
    
    func testLeftViewBackgroundColor() {
        trimmerView.mainColor = UIColor.blue
        
        XCTAssertEqual(trimmerView.leftDraggableView.backgroundColor,
                       trimmerView.mainColor)
    }
    
    func testRightViewBackgroundColor() {
        trimmerView.mainColor = UIColor.blue
        
        XCTAssertEqual(trimmerView.rightDraggableView.backgroundColor,
                       trimmerView.mainColor)
    }
    
    func testTrimViewWidth() {
        trimmerView.borderWidth = 4
        
        XCTAssertEqual(trimmerView.trimView.layer.borderWidth,
                       trimmerView.borderWidth)
    }
    
    private func testAlphaLeftMaskView() {
        trimmerView.alphaView = 0.5
        
        XCTAssertEqual(trimmerView.leftMaskView.alpha,
                       trimmerView.alphaView)
    }
    
    private func testAlphaRightMaskView() {
        trimmerView.alphaView = 0.5
        
        XCTAssertEqual(trimmerView.rightMaskView.alpha,
                       trimmerView.alphaView)
    }
    
    func testStarTimeWithFullVideo() {
        XCTAssertEqual(trimmerView.startTime,
                       CMTime(value: CMTimeValue(0), timescale: 600))
    }
    
    func testEndTimeWithFullVideo() {
        let value = Int(asset.duration.seconds * Double(asset.duration.timescale))
        XCTAssertEqual(trimmerView.endTime,
                       CMTime(value: CMTimeValue(value), timescale: 600))
    }
    
    func testWithNoLeadingTranslationPointer() {
        XCTAssertEqual(trimmerView.trimViewLeadingConstraint.constant, 0)
    }
    
    func testWithLeadingTranslationPointer() {
        trimmerView.updateLeadingConstraint(with: CGPoint(x: 20, y: 0))
        XCTAssertEqual(trimmerView.trimViewLeadingConstraint.constant, 20)
    }
    
    func testWithNoTrailingTranslationPointer() {
        XCTAssertEqual(trimmerView.trimViewTrailingConstraint.constant, 0)
    }
    
    func testWithTailingTranslationPointer() {
        trimmerView.updateTrailingConstraint(with: CGPoint(x: -20, y: 0))
        XCTAssertEqual(trimmerView.trimViewTrailingConstraint.constant, -20)
    }
    
    func testSeekLeading() {
        trimmerView.seek(to: CMTime(value: CMTimeValue(0), timescale: 600))
        XCTAssertEqual(trimmerView.trimViewLeadingConstraint.constant,
                       0)
    }
    
    func testSeekTrailing() {
        let value = Int(asset.duration.seconds * Double(asset.duration.timescale))
        trimmerView.seek(to: CMTime(value: CMTimeValue(value), timescale: 600))
        
        XCTAssertEqual(trimmerView.trimViewTrailingConstraint.constant,
                       0)
    }

}
