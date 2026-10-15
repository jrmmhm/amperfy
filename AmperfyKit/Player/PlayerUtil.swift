//
//  PlayerUtil.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 18.11.21.
//  Copyright (c) 2021 Maximilian Bauer. All rights reserved.
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

import Foundation
import Intents
import MediaPlayer

// MARK: - MusicPlayable

@MainActor
public protocol MusicPlayable: AnyObject {
  func didStartPlayingFromBeginning()
  func didStartPlaying()
  func didPause()
  func didStopPlaying()
  func didElapsedTimeChange()
  func didLyricsTimeChange(time: CMTime) // high refresh count
  func didPlaylistChange()
  func didArtworkChange()
  func didNowPlayingInfoChange()
  func didShuffleChange()
  func didRepeatChange()
  func didPlaybackRateChange()
}

extension MusicPlayable {
  public func didLyricsTimeChange(time: CMTime) {} // make it an optional method
  public func didNowPlayingInfoChange() {}
}

extension MusicPlayable {
  func didShuffleChange() {}
  func didRepeatChange() {}
  func didPlaybackRateChange() {}
  func errorOccurred(error: Error) {}
}

// MARK: - RadioNowPlayingInfo

public struct RadioNowPlayingInfo: Equatable, Sendable {
  public let title: String
  public let artist: String

  public init(title: String, artist: String) {
    self.title = title
    self.artist = artist
  }

  public var isEmpty: Bool {
    title.isEmpty && artist.isEmpty
  }
}

// MARK: - PlayableChange

public enum PlayableChange {
  /// Whether a display update animates the change of the displayed playable: only between two
  /// different playables and without Reduce Motion, so no animation on first display,
  /// on refreshes of the same item, or to or from an empty player.
  public static func isAnimated(
    from previousPlayableID: String?,
    to playableID: String?,
    isReduceMotionEnabled: Bool
  )
    -> Bool {
    guard let previousPlayableID, let playableID else { return false }
    return previousPlayableID != playableID && !isReduceMotionEnabled
  }

  /// How the display follows the playable that is playing now.
  public enum DisplayUpdate: Equatable {
    /// show it at once
    case immediate
    /// keep the displayed content until the new playable's artwork is resolved
    case awaitArtwork
    /// its artwork is already awaited: keep the displayed content
    case keepAwaiting
  }

  /// A change between two different playables keeps the displayed content until the artwork of
  /// the new one is resolved, so that artwork, details and background change together. Refreshes
  /// of the displayed playable, the first display and changes to or from an empty player are
  /// immediate and end any wait.
  public static func displayUpdate(
    displayedPlayableID: String?,
    awaitedPlayableID: String?,
    playableID: String?
  )
    -> DisplayUpdate {
    guard let displayedPlayableID, let playableID, displayedPlayableID != playableID
    else { return .immediate }
    return playableID == awaitedPlayableID ? .keepAwaiting : .awaitArtwork
  }

  /// Whether a finished artwork resolution may show its playable: only the one still awaited and
  /// still playing, so that a slower resolution of an earlier song never overwrites a newer one.
  public static func isResolutionCurrent(
    resolvedPlayableID: String,
    awaitedPlayableID: String?,
    playableID: String?
  )
    -> Bool {
    resolvedPlayableID == awaitedPlayableID && resolvedPlayableID == playableID
  }

  /// Whether waiting for a playable's artwork can pay off: its file can be loaded, or a download
  /// that is allowed and not done yet may still deliver the server artwork that is displayed.
  public static func isArtworkAwaitable(
    hasImagePath: Bool,
    artworkStatus: ImageStatus?,
    artworkDisplayPreference: ArtworkDisplayPreference,
    artworkDownloadSetting: ArtworkDownloadSetting,
    isOnlineMode: Bool
  )
    -> Bool {
    guard !hasImagePath else { return true }
    return artworkStatus == .NotChecked && isOnlineMode && artworkDownloadSetting != .never &&
      artworkDisplayPreference != .id3TagOnly
  }
}

// MARK: - RepeatMode

public enum RepeatMode: Int16, CaseIterable {
  case off
  case all
  case single

  public var nextMode: RepeatMode {
    switch self {
    case .off:
      return .all
    case .all:
      return .single
    case .single:
      return .off
    }
  }

  public var description: String {
    switch self {
    case .off: return "Off"
    case .all: return "All"
    case .single: return "Single"
    }
  }

  public var asMPRepeatType: MPRepeatType {
    switch self {
    case .off: return .off
    case .all: return .all
    case .single: return .one
    }
  }

  public static func fromMPRepeatType(type: MPRepeatType) -> RepeatMode {
    switch type {
    case .off:
      return .off
    case .one:
      return .single
    case .all:
      return .all
    default:
      return .off
    }
  }

  public static func fromINPlaybackRepeatMode(mode: INPlaybackRepeatMode) -> RepeatMode {
    switch mode {
    case .unknown:
      return .off
    case .none:
      return .off
    case .all:
      return .all
    case .one:
      return .single
    @unknown default:
      return .off
    }
  }
}

// MARK: - EndOfQueueMode

/// The states of the in-app repeat button, cycled in this order: off → repeat all → repeat one →
/// autoplay → off. Autoplay applies to music while online only.
public enum EndOfQueueMode: CaseIterable {
  case off
  case repeatAll
  case repeatSingle
  case autoplay
}

// MARK: - EndOfQueueSetting

/// The stored values behind the in-app repeat button: the repeat mode is player state,
/// autoplay a persisted user setting. Both can also be changed elsewhere, so every combination
/// is valid and a repeat mode wins over autoplay, which only acts when no repeat applies.
public struct EndOfQueueSetting: Equatable {
  public var repeatMode: RepeatMode
  public var isAutoplayEnabled: Bool

  public init(repeatMode: RepeatMode, isAutoplayEnabled: Bool) {
    self.repeatMode = repeatMode
    self.isAutoplayEnabled = isAutoplayEnabled
  }

  public func displayedMode(playerMode: PlayerMode, isOnlineMode: Bool) -> EndOfQueueMode {
    switch repeatMode {
    case .all:
      return .repeatAll
    case .single:
      return .repeatSingle
    case .off:
      let isAutoplayAvailable = playerMode == .music && isOnlineMode
      return isAutoplayEnabled && isAutoplayAvailable ? .autoplay : .off
    }
  }

  /// The values after a press of the repeat button. No change in podcast mode, where repeat
  /// does not apply. Offline the autoplay state is skipped and the stored autoplay flag kept.
  public func next(playerMode: PlayerMode, isOnlineMode: Bool) -> EndOfQueueSetting {
    guard playerMode == .music else { return self }
    let nextMode: EndOfQueueMode
    switch displayedMode(playerMode: playerMode, isOnlineMode: isOnlineMode) {
    case .off: nextMode = .repeatAll
    case .repeatAll: nextMode = .repeatSingle
    case .repeatSingle: nextMode = isOnlineMode ? .autoplay : .off
    case .autoplay: nextMode = .off
    }
    let nextRepeatMode: RepeatMode
    switch nextMode {
    case .repeatAll: nextRepeatMode = .all
    case .repeatSingle: nextRepeatMode = .single
    case .autoplay, .off: nextRepeatMode = .off
    }
    return EndOfQueueSetting(
      repeatMode: nextRepeatMode,
      isAutoplayEnabled: isOnlineMode ? nextMode == .autoplay : isAutoplayEnabled
    )
  }
}

// MARK: - PlaybackRate

public enum PlaybackRate: Int, CaseIterable {
  case dot5 = 0
  case dot75
  case one
  case oneDot25
  case oneDot5
  case oneDot75
  case two

  public static func create(from playbackRate: Double) -> PlaybackRate {
    var rate = PlaybackRate.one
    if playbackRate < 0.4 {
      rate = .one
    } else if playbackRate < 0.6 {
      rate = .dot5
    } else if playbackRate < 0.8 {
      rate = .dot75
    } else if playbackRate < 1.1 {
      rate = .one
    } else if playbackRate < 1.3 {
      rate = .oneDot25
    } else if playbackRate < 1.6 {
      rate = .oneDot5
    } else if playbackRate < 1.8 {
      rate = .oneDot75
    } else if playbackRate < 2.1 {
      rate = .two
    } else {
      rate = .one
    }
    return rate
  }

  public var asDouble: Double {
    switch self {
    case .dot5: return 0.5
    case .dot75: return 0.75
    case .one: return 1
    case .oneDot25: return 1.25
    case .oneDot5: return 1.5
    case .oneDot75: return 1.75
    case .two: return 2
    }
  }

  public var description: String {
    switch self {
    case .dot5: return "0.5x"
    case .dot75: return "0.75x"
    case .one: return "1x"
    case .oneDot25: return "1.25x"
    case .oneDot5: return "1.5x"
    case .oneDot75: return "1.75x"
    case .two: return "2x"
    }
  }
}

// MARK: - PlayerQueueType

public enum PlayerQueueType: Int, CaseIterable {
  case prev = 0
  case user = 2
  case next = 3

  public var description: String {
    switch self {
    case .prev: return "Previous"
    case .user: return "Next in Queue"
    case .next: return "Next"
    }
  }
}

// MARK: - PlayerIndex

public struct PlayerIndex: Equatable {
  let queueType: PlayerQueueType
  let index: Int

  public init(queueType: PlayerQueueType, index: Int) {
    self.queueType = queueType
    self.index = index
  }

  public static func create(from indexPath: IndexPath) -> PlayerIndex? {
    guard let queueType = PlayerQueueType(rawValue: indexPath.section) else { return nil }
    return PlayerIndex(queueType: queueType, index: indexPath.row)
  }

  public var asIndexPath: IndexPath {
    IndexPath(row: index, section: queueType.rawValue)
  }
}
