//
//  SettingsTest.swift
//  AmperfyKitTests
//
//  Created by Amperfy contributors on 12.10.26.
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

class SettingsTest: XCTestCase {
  func testUserSettingsSavedWithoutVolumeButtonKeyKeepTheirValues() throws {
    var settings = UserSettings()
    settings.isShowMusicPlayerSkipButtons = true
    settings.isPlayerShuffleButtonEnabled = false
    settings.isShowPlayerVolumeButton = false

    // simulate settings saved by a version that did not know the key yet
    var json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any]
    )
    XCTAssertNotNil(json.removeValue(forKey: "_isShowPlayerVolumeButton"))
    let legacyData = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(UserSettings.self, from: legacyData)
    XCTAssertTrue(decoded.isShowMusicPlayerSkipButtons)
    XCTAssertFalse(decoded.isPlayerShuffleButtonEnabled)
    XCTAssertTrue(decoded.isShowPlayerVolumeButton)
  }

  func testUserSettingsVolumeButtonRoundTrip() throws {
    var settings = UserSettings()
    XCTAssertTrue(settings.isShowPlayerVolumeButton)
    settings.isShowPlayerVolumeButton = false

    let decoded = try JSONDecoder().decode(
      UserSettings.self,
      from: JSONEncoder().encode(settings)
    )
    XCTAssertFalse(decoded.isShowPlayerVolumeButton)
  }
}
