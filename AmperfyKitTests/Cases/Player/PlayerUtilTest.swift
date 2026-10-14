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

  // MARK: - Repeat button with autoplay

  private func setting(_ repeatMode: RepeatMode, _ isAutoplayEnabled: Bool) -> EndOfQueueSetting {
    EndOfQueueSetting(repeatMode: repeatMode, isAutoplayEnabled: isAutoplayEnabled)
  }

  private var allStoredSettings: [EndOfQueueSetting] {
    RepeatMode.allCases.flatMap { repeatMode in
      [false, true].map { setting(repeatMode, $0) }
    }
  }

  func testDisplayedModeShowsARepeatModeWheneverOneIsSet() {
    for playerMode in [PlayerMode.music, .podcast] {
      for isOnlineMode in [false, true] {
        for isAutoplayEnabled in [false, true] {
          XCTAssertEqual(
            setting(.all, isAutoplayEnabled)
              .displayedMode(playerMode: playerMode, isOnlineMode: isOnlineMode),
            .repeatAll
          )
          XCTAssertEqual(
            setting(.single, isAutoplayEnabled)
              .displayedMode(playerMode: playerMode, isOnlineMode: isOnlineMode),
            .repeatSingle
          )
        }
      }
    }
  }

  func testDisplayedModeShowsAutoplayOnlyForMusicWhileOnline() {
    XCTAssertEqual(
      setting(.off, true).displayedMode(playerMode: .music, isOnlineMode: true),
      .autoplay
    )
    XCTAssertEqual(setting(.off, true).displayedMode(playerMode: .music, isOnlineMode: false), .off)
    XCTAssertEqual(
      setting(.off, true).displayedMode(playerMode: .podcast, isOnlineMode: true),
      .off
    )
    XCTAssertEqual(
      setting(.off, true).displayedMode(playerMode: .podcast, isOnlineMode: false),
      .off
    )
    for playerMode in [PlayerMode.music, .podcast] {
      for isOnlineMode in [false, true] {
        XCTAssertEqual(
          setting(.off, false).displayedMode(playerMode: playerMode, isOnlineMode: isOnlineMode),
          .off
        )
      }
    }
  }

  func testRepeatButtonCyclesThroughFourStatesOnline() {
    var current = setting(.off, false)
    var displayedModes = [current.displayedMode(playerMode: .music, isOnlineMode: true)]
    for _ in 0 ..< 4 {
      current = current.next(playerMode: .music, isOnlineMode: true)
      displayedModes.append(current.displayedMode(playerMode: .music, isOnlineMode: true))
    }
    XCTAssertEqual(displayedModes, [.off, .repeatAll, .repeatSingle, .autoplay, .off])
    XCTAssertEqual(current, setting(.off, false))
  }

  func testRepeatButtonCycleSkipsAutoplayOffline() {
    var current = setting(.off, false)
    var displayedModes = [current.displayedMode(playerMode: .music, isOnlineMode: false)]
    for _ in 0 ..< 3 {
      current = current.next(playerMode: .music, isOnlineMode: false)
      displayedModes.append(current.displayedMode(playerMode: .music, isOnlineMode: false))
    }
    XCTAssertEqual(displayedModes, [.off, .repeatAll, .repeatSingle, .off])
    XCTAssertEqual(current, setting(.off, false))
  }

  func testRepeatButtonPressFromEveryStoredCombinationOnline() {
    let expectedNext: [(EndOfQueueSetting, EndOfQueueSetting)] = [
      (setting(.off, false), setting(.all, false)),
      (setting(.all, false), setting(.single, false)),
      (setting(.single, false), setting(.off, true)),
      (setting(.off, true), setting(.off, false)),
      (setting(.all, true), setting(.single, false)),
      (setting(.single, true), setting(.off, true)),
    ]
    XCTAssertEqual(expectedNext.count, allStoredSettings.count)
    for (current, next) in expectedNext {
      XCTAssertEqual(current.next(playerMode: .music, isOnlineMode: true), next, "from \(current)")
    }
  }

  func testRepeatButtonPressFromEveryStoredCombinationOfflineKeepsAutoplay() {
    let expectedNext: [(EndOfQueueSetting, EndOfQueueSetting)] = [
      (setting(.off, false), setting(.all, false)),
      (setting(.all, false), setting(.single, false)),
      (setting(.single, false), setting(.off, false)),
      (setting(.off, true), setting(.all, true)),
      (setting(.all, true), setting(.single, true)),
      (setting(.single, true), setting(.off, true)),
    ]
    XCTAssertEqual(expectedNext.count, allStoredSettings.count)
    for (current, next) in expectedNext {
      XCTAssertEqual(current.next(playerMode: .music, isOnlineMode: false), next, "from \(current)")
    }
  }

  func testRepeatButtonPressDoesNothingInPodcastMode() {
    for current in allStoredSettings {
      for isOnlineMode in [false, true] {
        XCTAssertEqual(current.next(playerMode: .podcast, isOnlineMode: isOnlineMode), current)
      }
    }
  }

  @MainActor
  func testDisplayedModeIsRebuiltFromStoredValuesAfterRestart() throws {
    let library = CoreDataHelper().createSeededStorage()
    library.getPlayerData().setRepeatMode(.off)
    var settings = UserSettings()
    settings.isAutoplayEnabled = true

    // simulate a restart: both values are read back from their stores
    let restoredSettings = try JSONDecoder().decode(
      UserSettings.self,
      from: JSONEncoder().encode(settings)
    )
    var restoredPlayer = library.getPlayerData()
    XCTAssertEqual(
      setting(restoredPlayer.repeatMode, restoredSettings.isAutoplayEnabled)
        .displayedMode(
          playerMode: restoredPlayer.playerMode,
          isOnlineMode: restoredSettings.isOnlineMode
        ),
      .autoplay
    )

    library.getPlayerData().setRepeatMode(.single)
    restoredPlayer = library.getPlayerData()
    XCTAssertEqual(
      setting(restoredPlayer.repeatMode, restoredSettings.isAutoplayEnabled)
        .displayedMode(
          playerMode: restoredPlayer.playerMode,
          isOnlineMode: restoredSettings.isOnlineMode
        ),
      .repeatSingle
    )
  }
}
