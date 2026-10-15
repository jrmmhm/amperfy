//
//  PopupPlayer+Visuals.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 11.02.24.
//  Copyright (c) 2024 Maximilian Bauer. All rights reserved.
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

import AmperfyKit
import DominantColors
import UIKit

extension PopupPlayerVC {
  static let playableChangeAnimationDuration = TimeInterval(0.4)
  // longest wait for the next playable's artwork before its info is shown without it
  static let playableChangeArtworkTimeout = Duration.milliseconds(300)

  func refresh() {
    refreshContextQueueSectionHeader()
    refreshUserQueueSectionHeader()
    refreshCellMasks()
    refreshCellsContent()
    refreshCurrentlyPlayingInfoView()
  }

  func refreshCurrentlyPlayingInfoView() {
    let playable = player.currentlyPlaying
    switch PlayableChange.displayUpdate(
      displayedPlayableID: displayedPlayableID,
      awaitedPlayableID: awaitedPlayableID,
      playableID: playable?.uniqueID
    ) {
    case .awaitArtwork:
      guard let playable else { return }
      awaitArtworkAndDisplay(playable: playable)
    case .immediate:
      awaitArtworkTask?.cancel()
      awaitedPlayableID = nil
      displayedPlayableID = playable?.uniqueID
      refreshCurrentlyPlayingInfo(isAnimated: false)
    case .keepAwaiting:
      break
    }
  }

  /// Keeps the displayed playable until the artwork of the new one is resolved or the wait times
  /// out, then shows artwork, details and background of the new one together in one fade.
  /// Only the newest change is shown, so fast skipping ends on the playing item.
  private func awaitArtworkAndDisplay(playable: AbstractPlayable) {
    let playableID = playable.uniqueID
    awaitArtworkTask?.cancel()
    awaitedPlayableID = playableID
    var accountSetting = appDelegate.storage.settings.accounts.activeSetting.read
    if let accountInfo = playable.account?.info {
      accountSetting = appDelegate.storage.settings.accounts.getSetting(accountInfo).read
    }
    let artworkDisplayPreference = accountSetting.artworkDisplayPreference
    let artworkDownloadSetting = accountSetting.artworkDownloadSetting
    let isOnlineMode = appDelegate.storage.settings.user.isOnlineMode
    awaitArtworkTask = Task { @MainActor in
      await LibraryEntityImage.prepareImageToDisplay(
        libraryEntity: playable,
        artworkDisplayPreference: artworkDisplayPreference,
        artworkDownloadSetting: artworkDownloadSetting,
        isOnlineMode: isOnlineMode,
        timeout: Self.playableChangeArtworkTimeout
      )
      guard !Task.isCancelled, PlayableChange.isResolutionCurrent(
        resolvedPlayableID: playableID,
        awaitedPlayableID: awaitedPlayableID,
        playableID: player.currentlyPlaying?.uniqueID
      ) else { return }
      let previousPlayableID = displayedPlayableID
      awaitedPlayableID = nil
      displayedPlayableID = playableID
      refreshCurrentlyPlayingInfo(isAnimated: PlayableChange.isAnimated(
        from: previousPlayableID,
        to: playableID,
        isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled
      ))
    }
  }

  private func refreshCurrentlyPlayingInfo(isAnimated: Bool) {
    if isAnimated {
      fadeNextContentUpdate()
      // outside the faded views: dissolves itself, also when its artwork arrives later
      largeCurrentlyPlayingView?.artworkImage
        .crossDissolveImageChangesOfNextEntity(duration: Self.playableChangeAnimationDuration)
    }
    refreshBackgroundItemArtwork()
    largeCurrentlyPlayingView?.refresh()
    for visibleCell in tableView.visibleCells {
      if let currentlyPlayingCell = visibleCell as? CurrentlyPlayingTableCell {
        currentlyPlayingCell.refresh()
        break
      }
    }
  }

  /// One ease-in-ease-out fade for the following content update of the background, the details
  /// and rating of the large player and the whole compact row including its artwork.
  private func fadeNextContentUpdate() {
    // reloadData() defers re-attaching the cached compact cell to the next layout pass,
    // and a view removed from the hierarchy loses its animations: lay out before animating
    tableView.layoutIfNeeded()
    var views: [UIView] = [backgroundImage]
    if let largeCurrentlyPlayingView {
      views.append(largeCurrentlyPlayingView.detailsContainer)
      if let ratingView = largeCurrentlyPlayingView.ratingView {
        views.append(ratingView)
      }
    }
    if let currentlyPlayingTableCell {
      views.append(currentlyPlayingTableCell.contentView)
    }
    let transition = CATransition()
    transition.type = .fade
    transition.duration = Self.playableChangeAnimationDuration
    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    for view in views {
      view.layer.add(transition, forKey: kCATransition)
    }
  }

  func refreshCurrentlyPlayingArtworks() {
    refreshBackgroundItemArtwork()
    largeCurrentlyPlayingView?.refreshArtwork()
    for visibleCell in tableView.visibleCells {
      if let currentlyPlayingCell = visibleCell as? CurrentlyPlayingTableCell {
        currentlyPlayingCell.refreshArtwork()
        break
      }
    }
  }

  func refreshOptionButton(button: UIButton, rootView: UIViewController?) {
    var config = UIButton.Configuration.playerRound()
    config.image = .ellipsis
    config.baseForegroundColor = .label
    button.isEnabled = true
    button.configuration = config

    if let currentlyPlaying = appDelegate.player.currentlyPlaying,
       let rootView = rootView {
      button.showsMenuAsPrimaryAction = true
      button.menu = UIMenu.lazyMenu {
        EntityPreviewActionBuilder(container: currentlyPlaying, on: rootView).createMenuActions()
      }
      button.isEnabled = true
    } else {
      button.isEnabled = false
    }
  }

  func refreshFavoriteButton(button: UIButton) {
    var config = UIButton.Configuration.playerRound()
    switch player.playerMode {
    case .music:
      if let playableInfo = player.currentlyPlaying,
         playableInfo.isSong {
        config.image = playableInfo.isFavorite ? .heartFill : .heartEmpty
        config.baseForegroundColor = appDelegate.storage.settings.user
          .isOnlineMode ? .redHeart : .label
        button.isEnabled = appDelegate.storage.settings.user.isOnlineMode
      } else if let playableInfo = player.currentlyPlaying,
                let radio = playableInfo.asRadio {
        config.image = .followLink
        config.baseForegroundColor = .label
        button.isEnabled = radio.siteURL != nil
      } else {
        config.image = .heartEmpty
        config.baseForegroundColor = .redHeart
        button.isEnabled = false
      }
    case .podcast:
      config.image = .info
      config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .large)
      config.baseForegroundColor = .label
      button.isEnabled = true
    }
    if #available(iOS 17.0, *) {
      button.isSymbolAnimationEnabled = true
    }
    button.configuration = config
  }

  func refreshBackgroundItemArtwork() {
    var artwork: UIImage?
    var themePreference: ThemePreference = appDelegate.storage.settings.accounts.activeSetting.read
      .themePreference
    if let playableInfo = player.currentlyPlaying, let accountInfo = playableInfo.account?.info {
      themePreference = appDelegate.storage.settings.accounts.getSetting(accountInfo).read
        .themePreference
      artwork = LibraryEntityImage.getImageToDisplayImmediately(
        libraryEntity: playableInfo,
        themePreference: themePreference,
        artworkDisplayPreference: appDelegate.storage.settings.accounts.getSetting(accountInfo).read
          .artworkDisplayPreference,
        useCache: true
      )
    } else {
      switch player.playerMode {
      case .music:
        artwork = .getGeneratedArtwork(
          theme: themePreference,
          artworkType: .song
        )
      case .podcast:
        artwork = .getGeneratedArtwork(
          theme: themePreference,
          artworkType: .podcastEpisode
        )
      }
    }
    guard let artwork = artwork else { return }
    backgroundImage.image = artwork
    artworkGradientColors = (try? artwork.dominantColors(max: 2)) ?? [
      themePreference.asColor,
      UIColor.systemBackground,
    ]
    applyGradientBackground()
  }

  internal func applyGradientBackground() {
    let colors = artworkGradientColors.compactMap { $0.cgColor }
    // remove existing gradient layer
    backgroundImage.layer.sublayers?.forEach { layer in
      if layer is CAGradientLayer {
        layer.removeFromSuperlayer()
      }
    }
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = backgroundImage.bounds
    gradientLayer.colors = colors
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    backgroundImage.layer.insertSublayer(gradientLayer, at: 0)
  }

  @objc
  internal func downloadFinishedSuccessful(notification: Notification) {
    // while the next playable's artwork is awaited, its display update sets the background
    guard awaitedPlayableID == nil,
          let downloadNotification = DownloadNotification.fromNotification(notification),
          let curPlayable = player.currentlyPlaying
    else { return }
    if curPlayable.uniqueID == downloadNotification.id {
      Task { @MainActor in
        refreshBackgroundItemArtwork()
      }
    }
    if let artwork = curPlayable.artwork,
       artwork.uniqueID == downloadNotification.id {
      Task { @MainActor in
        refreshBackgroundItemArtwork()
      }
    }
  }

  func adjustLayoutMargins() {
    view.layoutMargins = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
  }
}
