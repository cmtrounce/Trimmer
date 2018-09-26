//
//  TrimmingControllerTests.swift
//  TrimmerVideoTests
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import XCTest
import AVFoundation
@testable import Trimmer

class TrimmingControllerTests: XCTestCase {
    
    var trimmingController: TrimmingController!
    var bundle: Bundle!
    var fileURL: URL!
    var asset: AVAsset!

    override func setUp() {
        super.setUp()
        
        trimmingController = TrimmingController()
        trimmingController.trimmerView = TrimmerView()
        trimmingController.trimmerView.thumbnailsView = ThumbnailsView()
        trimmingController.playPauseButton = UIButton()
        
        bundle = Bundle(for: type(of: self))
        fileURL = bundle.url(forResource: "IMG_0065", withExtension: "m4v")
        asset = AVAsset(url: fileURL)
    }

    override func tearDown() {
        trimmingController = nil
        bundle = nil
        fileURL = nil
        asset = nil
        
        super.tearDown()
    }
    
    func testDelegateNotNil() {
        XCTAssertNotNil(trimmingController.trimmerView.delegate)
    }
    
    func testPauseTextPlayButton() {
    trimmingController.playPauseButtonPressed()
        XCTAssertEqual(trimmingController.playPauseButton.currentTitle, "Pause")
    }
    
    func testPlayTextPlayButton() {
        trimmingController.playPauseButtonPressed()
        trimmingController.playPauseButtonPressed()
        XCTAssertEqual(trimmingController.playPauseButton.currentTitle, "Play")
    }
    
    func testGenerateAsset() {
        trimmingController.trimmerView.thumbnailsView.asset = asset
        XCTAssertGreaterThan(trimmingController.trimmerView.thumbnailsView.thumbnailsCount,
                                       0)
    }

}
