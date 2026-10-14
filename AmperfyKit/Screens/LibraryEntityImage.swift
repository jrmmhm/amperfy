//
//  LibraryEntityImage.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 10.06.21.
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

import CoreData
import UIKit

extension LibraryEntityImage {
  // Cache should not be used between different instances -> iOS and Carplay
  static public func getImageToDisplayImmediately(
    libraryEntity: AbstractLibraryEntity,
    themePreference: ThemePreference,
    artworkDisplayPreference: ArtworkDisplayPreference,
    useCache: Bool
  )
    -> UIImage {
    if let artworkImagePath = libraryEntity.imagePath(
      setting: artworkDisplayPreference
    ) {
      if useCache, let cachedImg = Self.cache.object(forKey: artworkImagePath as NSString) {
        return cachedImg
      } else if let directlyLoadedImage = UIImage(named: artworkImagePath) {
        return directlyLoadedImage
      }
    }
    return UIImage.getGeneratedArtwork(
      theme: themePreference,
      artworkType: libraryEntity.getDefaultArtworkType()
    )
  }
}

// MARK: - LibraryEntityImage

@MainActor
public class LibraryEntityImage: RoundedImage {
  static private let cache: NSCache<NSString, UIImage> = NSCache()

  private let appDelegate: AmperKit

  private var entity: AbstractLibraryEntity?
  private var backupArtworkType: ArtworkType?
  private var accountNotificationHandler: AccountNotificationHandler?
  // opt-in cross-dissolve of image changes, bound to the entity it was armed for
  private var isCrossDissolveArmed = false
  private var crossDissolveEntity: AbstractLibraryEntity?
  private var crossDissolveDuration: TimeInterval = 0

  required public init?(coder: NSCoder) {
    self.appDelegate = AmperKit.shared
    super.init(coder: coder)
    self.accountNotificationHandler = AccountNotificationHandler(
      storage: appDelegate.storage,
      notificationHandler: appDelegate.notificationHandler
    )
    accountNotificationHandler?.registerCallbackForAllAccounts { [weak self] accountInfo in
      guard let self else { return }
      appDelegate.notificationHandler.register(
        self,
        selector: #selector(downloadFinishedSuccessful(notification:)),
        name: .downloadFinishedSuccess,
        object: appDelegate.getMeta(accountInfo).artworkDownloadManager
      )
      appDelegate.notificationHandler.register(
        self,
        selector: #selector(downloadFinishedSuccessful(notification:)),
        name: .downloadFinishedSuccess,
        object: appDelegate.getMeta(accountInfo).playableDownloadManager
      )
    }
  }

  override public init(frame: CGRect) {
    self.appDelegate = AmperKit.shared
    super.init(frame: .zero)
    self.accountNotificationHandler = AccountNotificationHandler(
      storage: appDelegate.storage,
      notificationHandler: appDelegate.notificationHandler
    )
    accountNotificationHandler?.registerCallbackForAllAccounts { [weak self] accountInfo in
      guard let self else { return }
      appDelegate.notificationHandler.register(
        self,
        selector: #selector(downloadFinishedSuccessful(notification:)),
        name: .downloadFinishedSuccess,
        object: appDelegate.getMeta(accountInfo).artworkDownloadManager
      )
      appDelegate.notificationHandler.register(
        self,
        selector: #selector(downloadFinishedSuccessful(notification:)),
        name: .downloadFinishedSuccess,
        object: appDelegate.getMeta(accountInfo).playableDownloadManager
      )
    }
  }

  /// Opt-in, default off: every image change of the next entity passed to `display(entity:)`
  /// cross-dissolves, including artwork that is loaded or downloaded afterwards. Until loaded
  /// artwork arrives, the previous image stays visible instead of the placeholder.
  /// Ends when another entity, an artwork type or an image is displayed.
  public func crossDissolveImageChangesOfNextEntity(duration: TimeInterval) {
    isCrossDissolveArmed = true
    crossDissolveDuration = duration
  }

  private var isCrossDissolveActive: Bool {
    guard let crossDissolveEntity, let entity else { return false }
    return crossDissolveEntity == entity
  }

  private func endCrossDissolve() {
    isCrossDissolveArmed = false
    crossDissolveEntity = nil
  }

  public func display(entity: AbstractLibraryEntity) {
    if isCrossDissolveArmed {
      isCrossDissolveArmed = false
      crossDissolveEntity = entity
    } else if crossDissolveEntity != entity {
      crossDissolveEntity = nil
    }
    self.entity = entity
    backupArtworkType = entity.getDefaultArtworkType()
    refresh()
  }

  public func displayAndUpdate(entity: AbstractLibraryEntity) {
    guard self.entity != entity else { return }

    display(entity: entity)
    if let artwork = entity.artwork, let accountInfo = entity.account?.info {
      appDelegate.getMeta(accountInfo).artworkDownloadManager.download(object: artwork)
    }
  }

  internal func display(image: UIImage) {
    endCrossDissolve()
    self.image = image
    entity = nil
  }

  public func display(artworkType: ArtworkType) {
    endCrossDissolve()
    backupArtworkType = artworkType
    entity = nil
    refresh()
  }

  private var placeholderImage: UIImage {
    var theme = appDelegate.storage.settings.accounts.activeSetting.read.themePreference
    if let accountInfo = entity?.account?.info {
      theme = appDelegate.storage.settings.accounts.getSetting(accountInfo).read.themePreference
    }
    return UIImage.getGeneratedArtwork(
      theme: theme,
      artworkType: backupArtworkType ?? .song
    )
  }

  private var entityImagePathToDisplay: String? {
    var artworkDisplayPreference = appDelegate.storage.settings.accounts.activeSetting.read
      .artworkDisplayPreference
    if let accountInfo = entity?.account?.info {
      artworkDisplayPreference = appDelegate.storage.settings.accounts.getSetting(accountInfo).read
        .artworkDisplayPreference
    }
    return entity?.imagePath(
      setting: artworkDisplayPreference
    )
  }

  private func refresh() {
    let imagePathToDisplay = entityImagePathToDisplay

    if let imagePathToDisplay,
       let cachedImg = Self.cache.object(forKey: imagePathToDisplay as NSString) {
      setImage(cachedImg)
      return
    }

    // during a cross-dissolve the previous image stays until the artwork is loaded
    if !isCrossDissolveActive || imagePathToDisplay == nil || image == nil {
      setImage(placeholderImage)
    }
    guard let imagePathToDisplay else { return }

    Task.detached(priority: .high) { [weak self] in
      await self?.loadImageAndCacheIt(imagePath: imagePathToDisplay)
    }
  }

  private func setImage(_ newImage: UIImage) {
    guard isCrossDissolveActive, image != nil, image !== newImage,
          !UIAccessibility.isReduceMotionEnabled
    else {
      image = newImage
      return
    }
    UIView.transition(
      with: self,
      duration: crossDissolveDuration,
      options: .transitionCrossDissolve,
      animations: { self.image = newImage }
    )
  }

  @concurrent
  private func loadImageAndCacheIt(
    imagePath: String
  ) async {
    guard !Task.isCancelled else { return }
    let loadedImage = UIImage(contentsOfFile: imagePath)
    let readyImage = await loadedImage?.byPreparingForDisplay()
    guard !Task.isCancelled else { return }
    Task { @MainActor [weak self] in
      guard let self else { return }
      guard let readyImage else {
        // a kept previous image must not outlive a failed load
        if isCrossDissolveActive, entityImagePathToDisplay == imagePath {
          setImage(placeholderImage)
        }
        return
      }
      Self.cache.setObject(readyImage, forKey: imagePath as NSString)
      refresh()
    }
  }

  @objc
  private func downloadFinishedSuccessful(notification: Notification) {
    guard let downloadNotification = DownloadNotification.fromNotification(notification), let entity
    else { return }
    if let playable = entity as? AbstractPlayable,
       playable.uniqueID == downloadNotification.id, let accountInfo = playable.account?.info {
      Task { @MainActor in
        guard let imagePath = entity.imagePath(
          setting: appDelegate.storage.settings.accounts.getSetting(accountInfo).read
            .artworkDisplayPreference
        ) else { return }
        await self.loadImageAndCacheIt(
          imagePath: imagePath
        )
      }
    }
    if let artwork = entity.artwork,
       artwork.uniqueID == downloadNotification.id, let accountInfo = artwork.account?.info {
      Task { @MainActor in
        guard let imagePath = entity.imagePath(
          setting: appDelegate.storage.settings.accounts.getSetting(accountInfo).read
            .artworkDisplayPreference
        ) else { return }
        await self.loadImageAndCacheIt(
          imagePath: imagePath
        )
      }
    }
  }
}
