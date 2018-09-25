//
//  TrimmingControllerTests.swift
//  TrimmerVideoTests
//
//  Created by Diego Caroli on 24/09/2018.
//  Copyright © 2018 Diego Caroli. All rights reserved.
//

import XCTest
@testable import Trimmer

class TrimmingControllerTests: XCTestCase {
    
    var trimmingController: TrimmingController!

    override func setUp() {
        super.setUp()
        
        trimmingController = TrimmingController()
        trimmingController.trimmerView = TrimmerView()
        trimmingController.playPauseButton = UIButton()
    }

    override func tearDown() {
        trimmingController = nil
        
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

}
