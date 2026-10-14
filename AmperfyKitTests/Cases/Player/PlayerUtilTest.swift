//
//  PlayerUtilTest.swift
//  AmperfyKitTests
//
//  Created by Amperfy contributors on 14.10.26.
//  Copyright (c) 2026 Amperfy contributors. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

@testable import AmperfyKit
import XCTest

class PlayerUtilTest: XCTestCase {
  func testPlayableChangeIsAnimatedBetweenTwoDifferentPlayables() {
    XCTAssertTrue(PlayableChange.isAnimated(from: "a", to: "b", isReduceMotionEnabled: false))
  }

  func testPlayableChangeIsNotAnimatedForTheSamePlayable() {
    XCTAssertFalse(PlayableChange.isAnimated(from: "a", to: "a", isReduceMotionEnabled: false))
  }

  func testPlayableChangeIsNotAnimatedOnFirstDisplayOrFromAnEmptyPlayer() {
    XCTAssertFalse(PlayableChange.isAnimated(from: nil, to: "a", isReduceMotionEnabled: false))
  }

  func testPlayableChangeIsNotAnimatedToAnEmptyPlayer() {
    XCTAssertFalse(PlayableChange.isAnimated(from: "a", to: nil, isReduceMotionEnabled: false))
    XCTAssertFalse(PlayableChange.isAnimated(from: nil, to: nil, isReduceMotionEnabled: false))
  }

  func testPlayableChangeIsNotAnimatedWithReduceMotion() {
    XCTAssertFalse(PlayableChange.isAnimated(from: "a", to: "b", isReduceMotionEnabled: true))
  }
}
