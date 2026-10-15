//
//  AlbumTest.swift
//  AmperfyKitTests
//
//  Created by Maximilian Bauer on 31.12.19.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
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
import CoreData
import XCTest

// MARK: - AlbumTest

@MainActor
class AlbumTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var library: LibraryStorage!
  var account: Account!
  var testAlbum: Album!
  let testId = "23489"

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    library = cdHelper.createSeededStorage()
    account = library.getAccount(info: TestAccountInfo.create1())
    testAlbum = library.createAlbum(account: account)
    testAlbum.id = testId
  }

  override func tearDown() {}

  func testCreation() {
    let album = library.createAlbum(account: account)
    XCTAssertEqual(album.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.id, "")
    XCTAssertEqual(album.identifier, "Unknown Album")
    XCTAssertEqual(album.name, "Unknown Album")
    XCTAssertEqual(album.year, 0)
    XCTAssertEqual(album.artist, nil)
    XCTAssertEqual(album.songs.count, 0)
    XCTAssertEqual(album.songCount, 0)
    XCTAssertNil(album.artwork)
    XCTAssertNil(
      album.imagePath(setting: .serverArtworkOnly)
    )
    XCTAssertEqual(
      album.getDefaultArtworkType(), .album
    )
    XCTAssertFalse(album.playables.hasCachedItems)
    XCTAssertFalse(album.isOrphaned)
  }

  func testArtist() {
    guard let artist = library.getArtist(for: account, id: cdHelper.seeder.artists[0].id)
    else { XCTFail(); return }
    testAlbum.artist = artist
    XCTAssertEqual(testAlbum.artist!.id, artist.id)
    library.saveContext()
    guard let albumFetched = library.getAlbum(
      for: account,
      id: testId,
      isDetailFaultResolution: true
    )
    else { XCTFail(); return }
    XCTAssertEqual(albumFetched.artist!.id, artist.id)
  }

  func testTitle() {
    let testTitle = "Alright"
    testAlbum.name = testTitle
    XCTAssertEqual(testAlbum.name, testTitle)
    XCTAssertEqual(testAlbum.identifier, testTitle)
    library.saveContext()
    guard let albumFetched = library.getAlbum(
      for: account,
      id: testId,
      isDetailFaultResolution: true
    )
    else { XCTFail(); return }
    XCTAssertEqual(albumFetched.name, testTitle)
    XCTAssertEqual(albumFetched.identifier, testTitle)
  }

  func testYear() {
    let testYear = 2001
    testAlbum.year = testYear
    XCTAssertEqual(testAlbum.year, testYear)
    library.saveContext()
    guard let albumFetched = library.getAlbum(
      for: account,
      id: testId,
      isDetailFaultResolution: true
    )
    else { XCTFail(); return }
    XCTAssertEqual(albumFetched.year, testYear)
  }

  func testArtworkAndImage() {
    let testData = UIImage.getGeneratedArtwork(theme: .blue, artworkType: .album).pngData()!
    let relFilePath = URL(string: "testArtwork")!
    let absFilePath = CacheFileManager.shared.getAbsoluteAmperfyPath(relFilePath: relFilePath)!
    try! CacheFileManager.shared.writeDataExcludedFromBackup(
      data: testData,
      to: absFilePath,
      accountInfo: account.info
    )
    testAlbum.artwork = library.createArtwork(account: account)
    testAlbum.artwork?.relFilePath = relFilePath
    testAlbum.artwork?.status = .CustomImage
    XCTAssertNotNil(testAlbum.artwork?.imagePath)
    library.saveContext()
    guard let albumFetched = library.getAlbum(
      for: account,
      id: testId,
      isDetailFaultResolution: true
    )
    else { XCTFail(); return }
    XCTAssertNotNil(albumFetched.artwork?.imagePath)
    try! CacheFileManager.shared.removeItem(at: absFilePath, accountInfo: account.info)
  }

  func testSongs() {
    guard let album3Items = library.getAlbum(
      for: account,
      id: cdHelper.seeder.albums[0].id,
      isDetailFaultResolution: true
    ) else { XCTFail(); return }
    XCTAssertEqual(album3Items.songs.count, 3)
    XCTAssertEqual(album3Items.songCount, 3)
    guard let album2Items = library.getAlbum(
      for: account,
      id: cdHelper.seeder.albums[2].id,
      isDetailFaultResolution: true
    ) else { XCTFail(); return }
    XCTAssertEqual(album2Items.songs.count, 2)
    XCTAssertEqual(album2Items.songCount, 2)
  }

  func testHasCachedSongs() {
    guard let albumNoCached = library.getAlbum(
      for: account,
      id: cdHelper.seeder.albums[0].id,
      isDetailFaultResolution: true
    ) else { XCTFail(); return }
    XCTAssertFalse(albumNoCached.playables.hasCachedItems)
    guard let albumTwoCached = library.getAlbum(
      for: account,
      id: cdHelper.seeder.albums[2].id,
      isDetailFaultResolution: true
    ) else { XCTFail(); return }
    XCTAssertTrue(albumTwoCached.playables.hasCachedItems)
  }

  func testIsOrphaned() {
    testAlbum.name = "blub"
    XCTAssertFalse(testAlbum.isOrphaned)
    testAlbum.name = "Unknown Album"
    XCTAssertFalse(testAlbum.isOrphaned)
    testAlbum.name = "Orphaned"
    XCTAssertFalse(testAlbum.isOrphaned)
    testAlbum.name = "Unknown (Orphaned)"
    XCTAssertTrue(testAlbum.isOrphaned)
    testAlbum.name = "blub"
    XCTAssertFalse(testAlbum.isOrphaned)
  }
}

// MARK: - RemoteAlbumListingCheckTest

@MainActor
class RemoteAlbumListingCheckTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var library: LibraryStorage!
  var account: Account!

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    let context = cdHelper.createInMemoryManagedObjectContext()
    cdHelper.clearContext(context: context)
    library = LibraryStorage(context: context)
    account = library.getAccount(info: TestAccountInfo.create1())
  }

  override func tearDown() {}

  private func createAlbums(count: Int) -> [Album] {
    (0 ..< count).map { index in
      let album = library.createAlbum(account: account)
      album.id = "album-\(index)"
      return album
    }
  }

  private func addSongs(count: Int, to album: Album) {
    for index in 0 ..< count {
      let song = library.createSong(account: account)
      song.id = "\(album.id)-song-\(index)"
      song.album = album
    }
  }

  private func listing(of albums: [Album], songCounts: [String: Int] = [:]) -> RemoteListing {
    RemoteListing(albumIDs: Set(albums.map { $0.id }), albumSongCounts: songCounts)
  }

  func testEmptyListing_IsNotTrusted() {
    _ = createAlbums(count: 5)
    let check = library.checkRemoteAlbumListing(for: account, listing: RemoteListing())
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
  }

  func testSmallLibrary_OneAbsentAlbumIsCandidate() {
    let albums = createAlbums(count: 5)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(4)))
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.absentAlbums.map { $0.id }, ["album-4"])
  }

  func testSmallLibrary_FourAbsentAlbumsAreNotTrusted() {
    let albums = createAlbums(count: 5)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(1)))
    )
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
  }

  func testSeventeenAlbums_ThreeAbsentAreTrusted() {
    let albums = createAlbums(count: 17)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(14)))
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(Set(check.absentAlbums.map { $0.id }), ["album-14", "album-15", "album-16"])
  }

  func testSeventeenAlbums_FourAbsentAreNotTrusted() {
    let albums = createAlbums(count: 17)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(13)))
    )
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
  }

  func testTenthOfLibraryAbsent_IsTrusted() {
    let albums = createAlbums(count: 30)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(27)))
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.absentAlbums.count, 3)
  }

  func testMoreThanTenthOfLibraryAbsent_IsNotTrusted() {
    let albums = createAlbums(count: 30)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(26)))
    )
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
  }

  func testTwentyAbsentAlbums_AreTrusted() {
    let albums = createAlbums(count: 300)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(280)))
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.absentAlbums.count, 20)
  }

  func testMoreThanTwentyAbsentAlbums_AreNotTrusted() {
    let albums = createAlbums(count: 300)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(279)))
    )
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
  }

  func testDeletedAlbumsAndAlbumsWithoutIdAreNoCandidates() {
    let albums = createAlbums(count: 5)
    albums[4].remoteStatus = .deleted
    let albumWithoutId = library.createAlbum(account: account)
    XCTAssertEqual(albumWithoutId.id, "")
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(4)))
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
    XCTAssertTrue(check.reappearedAlbums.isEmpty)
  }

  func testDeletedAlbumInListing_HasReappeared() {
    let albums = createAlbums(count: 5)
    albums[0].remoteStatus = .deleted
    let check = library.checkRemoteAlbumListing(for: account, listing: listing(of: albums))
    XCTAssertTrue(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
    XCTAssertEqual(check.reappearedAlbums.map { $0.id }, ["album-0"])
  }

  func testDeletedAlbumListedWithoutSongs_HasNotReappeared() {
    let albums = createAlbums(count: 5)
    albums[0].remoteStatus = .deleted
    albums[1].remoteStatus = .deleted
    albums[2].remoteStatus = .deleted
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: [
        "album-0": 0, // the server lists the emptied album
        "album-1": 3,
        // album-2 without a song count
      ])
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(Set(check.reappearedAlbums.map { $0.id }), ["album-1", "album-2"])
  }

  func testSongCountMismatch_OnlyMoreLocalSongsOfSyncedAlbums() {
    let albums = createAlbums(count: 5)
    albums.forEach {
      addSongs(count: 2, to: $0)
      $0.isSongsMetaDataSynced = true
    }
    albums[2].isSongsMetaDataSynced = false
    library.saveContext()
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: [
        "album-0": 1, // a song was removed on the server
        "album-1": 3, // the server counts more songs (Navidrome keeps missing files)
        "album-2": 1, // songs never synced
        "album-3": 2, // unchanged
        // album-4 without a song count
      ])
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.albumsWithRemovedSongs.map { $0.id }, ["album-0"])
  }

  func testSongCountMismatch_IsCapped() {
    let albums = createAlbums(count: 25)
    var songCounts = [String: Int]()
    albums.forEach {
      addSongs(count: 1, to: $0)
      $0.isSongsMetaDataSynced = true
      songCounts[$0.id] = 0
    }
    library.saveContext()
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: songCounts)
    )
    XCTAssertEqual(check.albumsWithRemovedSongs.count, LibraryStorage.maxRemoteDeletionCandidates)
  }

  private func createSyncedAlbums(count: Int, songCount: Int) -> [Album] {
    let albums = createAlbums(count: count)
    albums.forEach {
      addSongs(count: songCount, to: $0)
      $0.isSongsMetaDataSynced = true
    }
    library.saveContext()
    return albums
  }

  func testAddedSong_GrownOneSongAlbumIsResynced() {
    let albums = createSyncedAlbums(count: 5, songCount: 1)
    var songCounts = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, 1) })
    songCounts["album-1"] = 2
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: songCounts)
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.albumsWithAddedSongs.map { $0.id }, ["album-1"])
    let candidates = RemoteAlbumCandidates(check: check)
    XCTAssertTrue(candidates.isListingTrusted)
    XCTAssertEqual(candidates.resyncAlbumIDs, ["album-1"])
  }

  func testAddedSongs_OnlyMoreServerSongsOfSyncedAlbums() {
    let albums = createSyncedAlbums(count: 5, songCount: 2)
    albums[2].isSongsMetaDataSynced = false
    library.saveContext()
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: [
        "album-0": 1, // a song was removed on the server
        "album-1": 3, // a song was added on the server
        "album-2": 3, // songs never synced
        "album-3": 2, // unchanged
        // album-4 without a song count
      ])
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertEqual(check.albumsWithAddedSongs.map { $0.id }, ["album-1"])
    XCTAssertEqual(check.albumsWithRemovedSongs.map { $0.id }, ["album-0"])
    XCTAssertEqual(RemoteAlbumCandidates(check: check).resyncAlbumIDs, ["album-0", "album-1"])
  }

  func testAddedSongs_UntrustedListingStillResyncsGrownAlbum() {
    let albums = createSyncedAlbums(count: 17, songCount: 1)
    let listedAlbums = Array(albums.prefix(12)) // 5 of 17 albums absent
    var songCounts = Dictionary(uniqueKeysWithValues: listedAlbums.map { ($0.id, 1) })
    songCounts["album-0"] = 2
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: listedAlbums, songCounts: songCounts)
    )
    XCTAssertFalse(check.isPlausible)
    XCTAssertTrue(check.absentAlbums.isEmpty)
    XCTAssertTrue(check.albumsWithRemovedSongs.isEmpty)
    XCTAssertEqual(check.albumsWithAddedSongs.map { $0.id }, ["album-0"])
    let candidates = RemoteAlbumCandidates(check: check)
    XCTAssertFalse(candidates.isListingTrusted)
    XCTAssertTrue(candidates.absentAlbumIDs.isEmpty)
    XCTAssertFalse(candidates.hasReappearedAlbums)
    XCTAssertEqual(candidates.resyncAlbumIDs, ["album-0"])
  }

  func testAddedSongs_AreCapped() {
    let albums = createSyncedAlbums(count: 25, songCount: 1)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(
        of: albums,
        songCounts: Dictionary(uniqueKeysWithValues: albums.map { ($0.id, 2) })
      )
    )
    XCTAssertEqual(check.albumsWithAddedSongs.count, LibraryStorage.maxRemoteDeletionCandidates)
  }

  func testAddedSongs_DeletedAlbumsAndAlbumsWithoutIdAreNoCandidates() {
    let albums = createSyncedAlbums(count: 5, songCount: 1)
    albums[4].remoteStatus = .deleted
    let albumWithoutId = library.createAlbum(account: account)
    addSongs(count: 1, to: albumWithoutId)
    albumWithoutId.isSongsMetaDataSynced = true
    library.saveContext()
    var songCounts = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, 1) })
    songCounts["album-4"] = 2
    songCounts[""] = 2
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: albums, songCounts: songCounts)
    )
    XCTAssertTrue(check.isPlausible)
    XCTAssertTrue(check.albumsWithAddedSongs.isEmpty)
  }

  func testAddedSongs_AlbumsWithNewServerCountComeFirst() {
    let albums = createSyncedAlbums(count: 25, songCount: 1)
    // album-0 ... album-19 were resynced before and keep a missing file in the server count
    albums.prefix(20).forEach { $0.remoteSongCount = 2 }
    // album-20 ... album-24 grew since their sync and sort after the others
    albums.suffix(5).forEach { $0.remoteSongCount = 1 }
    library.saveContext()
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(
        of: albums,
        songCounts: Dictionary(uniqueKeysWithValues: albums.map { ($0.id, 2) })
      )
    )
    let addedIDs = Set(check.albumsWithAddedSongs.map { $0.id })
    XCTAssertEqual(check.albumsWithAddedSongs.count, LibraryStorage.maxRemoteDeletionCandidates)
    XCTAssertTrue(addedIDs.isSuperset(of: albums.suffix(5).map { $0.id }))
  }

  private func createSyncedAlbumsWithSongs(count: Int) -> [Album] {
    let albums = createAlbums(count: count)
    albums.forEach {
      addSongs(count: 2, to: $0)
      $0.isSongsMetaDataSynced = true
    }
    library.saveContext()
    return albums
  }

  private func songListing(of albums: [Album], without songIDs: Set<String> = []) -> RemoteListing {
    let allSongIDs = albums.flatMap { $0.songs.map { $0.id } }
    return RemoteListing(songIDs: Set(allSongIDs).subtracting(songIDs))
  }

  func testEmptySongListing_IsNotTrusted() {
    // a server without the empty search3 query answers with no songs
    _ = createSyncedAlbumsWithSongs(count: 5)
    XCTAssertNil(library.getAlbumsWithSongsMissing(for: account, fromListing: RemoteListing()))
  }

  func testSongMissingFromListing_GivesItsAlbum() {
    let albums = createSyncedAlbumsWithSongs(count: 5)
    let albumsWithMissingSongs = library.getAlbumsWithSongsMissing(
      for: account,
      fromListing: songListing(of: albums, without: ["album-3-song-1"])
    )
    XCTAssertEqual(albumsWithMissingSongs?.map { $0.id }, ["album-3"])
  }

  func testCompleteSongListing_GivesNoAlbum() {
    let albums = createSyncedAlbumsWithSongs(count: 5)
    let albumsWithMissingSongs = library.getAlbumsWithSongsMissing(
      for: account,
      fromListing: songListing(of: albums)
    )
    XCTAssertEqual(albumsWithMissingSongs?.count, 0)
  }

  func testSongMissingFromListing_IgnoresUnsyncedAlbumsAndDeletedSongs() {
    let albums = createSyncedAlbumsWithSongs(count: 5)
    albums[1].isSongsMetaDataSynced = false
    albums[2].songs.first { $0.id == "album-2-song-0" }?.remoteStatus = .deleted
    albums[3].remoteStatus = .deleted
    library.saveContext()
    let albumsWithMissingSongs = library.getAlbumsWithSongsMissing(
      for: account,
      fromListing: songListing(
        of: albums,
        without: ["album-1-song-0", "album-2-song-0", "album-3-song-0"]
      )
    )
    XCTAssertEqual(albumsWithMissingSongs?.count, 0)
  }

  func testSongsMissingFromTooManyAlbums_AreNotTrusted() {
    let albums = createSyncedAlbumsWithSongs(count: 5)
    XCTAssertNil(library.getAlbumsWithSongsMissing(
      for: account,
      fromListing: songListing(
        of: albums,
        without: ["album-0-song-0", "album-1-song-0", "album-2-song-0", "album-3-song-0"]
      )
    ))
  }

  func testSongsMissingFromThreeOfSeventeenAlbums_AreTrusted() {
    let albums = createSyncedAlbumsWithSongs(count: 17)
    let albumsWithMissingSongs = library.getAlbumsWithSongsMissing(
      for: account,
      fromListing: songListing(
        of: albums,
        without: ["album-0-song-0", "album-1-song-1", "album-2-song-0"]
      )
    )
    XCTAssertEqual(albumsWithMissingSongs?.map { $0.id }, ["album-0", "album-1", "album-2"])
  }

  func testRemoteAlbumDeletionPlausibility() {
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 2, localCount: 17))
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 3, localCount: 17))
    XCTAssertFalse(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 4, localCount: 17))
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 3, localCount: 3))
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 4, localCount: 40))
    XCTAssertFalse(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 5, localCount: 40))
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(
      candidateCount: 20,
      localCount: 1000
    ))
    XCTAssertFalse(LibraryStorage.isRemoteAlbumDeletionPlausible(
      candidateCount: 21,
      localCount: 300
    ))
    XCTAssertFalse(LibraryStorage.isRemoteAlbumDeletionPlausible(
      candidateCount: 21,
      localCount: 1000
    ))
    // the guard for deleting downloads keeps its own floor
    XCTAssertTrue(LibraryStorage.isRemoteAlbumDeletionPlausible(candidateCount: 3, localCount: 23))
    XCTAssertFalse(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 3, localCount: 23))
  }

  func testRemoteDeletionPlausibility() {
    XCTAssertTrue(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 1, localCount: 1))
    XCTAssertFalse(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 2, localCount: 19))
    XCTAssertTrue(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 2, localCount: 20))
    XCTAssertTrue(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 20, localCount: 1000))
    XCTAssertFalse(LibraryStorage.isRemoteDeletionPlausible(candidateCount: 21, localCount: 1000))
  }
}

// MARK: - AlbumVisibilityTest

@MainActor
class AlbumVisibilityTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var context: NSManagedObjectContext!
  var library: LibraryStorage!
  var account: Account!
  var genre: Genre!
  var artist: Artist!
  var album: Album!

  static let allListingSites = [
    "album list",
    "genre albums",
    "genre albums search",
    "artist albums",
    "artist albums search",
    "album search",
    "random albums",
  ]

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    context = cdHelper.createInMemoryManagedObjectContext()
    cdHelper.clearContext(context: context)
    library = LibraryStorage(context: context)
    account = library.getAccount(info: TestAccountInfo.create1())
    genre = library.createGenre(account: account)
    genre.name = "Test Genre"
    artist = library.createArtist(account: account)
    artist.id = "artist-1"
    artist.name = "Test Artist"
    album = library.createAlbum(account: account)
    album.id = "album-1"
    album.name = "Test Album"
    album.artist = artist
    album.genre = genre
  }

  override func tearDown() {}

  private func addSongs(count: Int, isCached: Bool = false) -> [Song] {
    (0 ..< count).map { index in
      let song = library.createSong(account: account)
      song.id = "song-\(index)"
      song.title = "Song \(index)"
      song.album = album
      if isCached {
        song.relFilePath = URL(string: "testSong\(index)")
      }
      return song
    }
  }

  private func isListed(by predicate: NSPredicate?) -> Bool {
    let fetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
    fetchRequest.predicate = predicate
    let albums = (try? context.fetch(fetchRequest)) ?? []
    return albums.contains(album.managedObject)
  }

  /// the seven places that decide whether an album is listed
  private func listingSitesShowingAlbum() -> [String] {
    library.saveContext()
    let companion = CoreDataCompanion(context: context)
    let albumList = AlbumFetchedResultsController(
      coreDataCompanion: companion,
      account: account,
      sortType: .name,
      isGroupedInAlphabeticSections: false
    )
    let genreAlbums = GenreAlbumsFetchedResultsController(
      for: genre,
      coreDataCompanion: companion,
      isGroupedInAlphabeticSections: false
    )
    let genreAlbumsPredicate = genreAlbums.fetchResultsController.fetchRequest.predicate
    genreAlbums.search(searchText: "Test", onlyCached: false)
    let artistAlbums = ArtistAlbumsItemsFetchedResultsController(
      for: artist,
      coreDataCompanion: companion,
      isGroupedInAlphabeticSections: false
    )
    let artistAlbumsPredicate = artistAlbums.fetchResultsController.fetchRequest.predicate
    artistAlbums.search(searchText: "Test", onlyCached: false)

    var sites = [String]()
    if isListed(by: albumList.fetchResultsController.fetchRequest.predicate) {
      sites.append("album list")
    }
    if isListed(by: genreAlbumsPredicate) {
      sites.append("genre albums")
    }
    if isListed(by: genreAlbums.fetchResultsController.fetchRequest.predicate) {
      sites.append("genre albums search")
    }
    if isListed(by: artistAlbumsPredicate) {
      sites.append("artist albums")
    }
    if isListed(by: artistAlbums.fetchResultsController.fetchRequest.predicate) {
      sites.append("artist albums search")
    }
    if isListed(by: library.getSearchAlbumsPredicate(
      for: account,
      searchText: "Test",
      onlyCached: false,
      displayFilter: .all
    )) {
      sites.append("album search")
    }
    if library.getRandomAlbums(for: account, count: 10, onlyCached: false).contains(album) {
      sites.append("random albums")
    }
    return sites
  }

  func testAvailableAlbum_IsListedEverywhere() {
    _ = addSongs(count: 2)
    XCTAssertEqual(listingSitesShowingAlbum(), Self.allListingSites)
  }

  func testAlbumLosingSomeSongs_StaysListed() {
    let songs = addSongs(count: 3)
    library.saveContext()
    album.markAsRemoteDeleted(songs: [songs[0]])
    XCTAssertEqual(songs[0].remoteStatus, .deleted)
    XCTAssertEqual(songs[1].remoteStatus, .available)
    XCTAssertEqual(album.songs.count, 2)
    XCTAssertEqual(album.remoteStatus, .available)
    XCTAssertEqual(listingSitesShowingAlbum(), Self.allListingSites)
  }

  func testAlbumLosingLastSong_IsHiddenEverywhere() {
    let songs = addSongs(count: 2)
    library.saveContext()
    album.markAsRemoteDeleted(songs: songs)
    XCTAssertTrue(songs.allSatisfy { $0.remoteStatus == .deleted })
    XCTAssertTrue(album.songs.isEmpty)
    XCTAssertEqual(album.remoteStatus, .deleted)
    XCTAssertEqual(listingSitesShowingAlbum(), [])
  }

  func testNeverSyncedAlbum_StaysListed() {
    album.markAsRemoteDeleted(songs: [])
    XCTAssertEqual(album.remoteStatus, .available)
    XCTAssertEqual(listingSitesShowingAlbum(), Self.allListingSites)
  }

  func testDeletedAlbumWithDeletedDownloadedSongs_IsHiddenEverywhere() {
    _ = addSongs(count: 2, isCached: true)
    album.markAsRemoteDeleted()
    XCTAssertEqual(listingSitesShowingAlbum(), [])
  }

  func testDeletedAlbumWithAvailableDownloadedSong_IsListed() {
    _ = addSongs(count: 1, isCached: true)
    album.remoteStatus = .deleted
    XCTAssertEqual(listingSitesShowingAlbum(), Self.allListingSites)
  }
}

// MARK: - ServerDeletedDownloadsTest

@MainActor
class ServerDeletedDownloadsTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var library: LibraryStorage!
  var account: Account!
  let now = Date(timeIntervalSince1970: 1_000_000)

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    let context = cdHelper.createInMemoryManagedObjectContext()
    cdHelper.clearContext(context: context)
    library = LibraryStorage(context: context)
    account = library.getAccount(info: TestAccountInfo.create1())
  }

  override func tearDown() {}

  private func createAlbum(id: String, isDeleted: Bool) -> Album {
    let album = library.createAlbum(account: account)
    album.id = id
    album.remoteStatus = isDeleted ? .deleted : .available
    return album
  }

  @discardableResult
  private func createSong(
    id: String,
    album: Album? = nil,
    isCached: Bool = true,
    isDeleted: Bool = true
  )
    -> Song {
    let song = library.createSong(account: account)
    song.id = id
    song.album = album
    if isCached {
      song.relFilePath = URL(string: "testSong-\(id)")
    }
    song.remoteStatus = isDeleted ? .deleted : .available
    return song
  }

  private func ids(_ count: Int) -> Set<String> {
    Set((0 ..< count).map { "song-\($0)" })
  }

  private func run(
    scan: String?,
    isListingTrusted: Bool = true,
    isGuardTripped: Bool = false
  )
    -> RemoteDeletionRun {
    RemoteDeletionRun(
      scans: RemoteDeletionScans(albumListing: scan),
      isListingTrusted: isListingTrusted,
      isGuardTripped: isGuardTripped
    )
  }

  private func held(
    _ songIDs: Set<String>,
    scan: String?,
    date: Date? = nil
  )
    -> [String: ServerDeletedDownloadEvidence] {
    let evidence = ServerDeletedDownloadEvidence(scan: scan, date: date ?? now)
    return Dictionary(uniqueKeysWithValues: songIDs.map { ($0, evidence) })
  }

  private func decide(
    run: RemoteDeletionRun?,
    candidateIDs: Set<String>,
    cachedSongCount: Int = 1000,
    heldSongs: [String: ServerDeletedDownloadEvidence] = [:],
    playingSongID: String? = nil,
    isEnabled: Bool = true,
    at date: Date? = nil
  )
    -> ServerDeletedDownloadsDecision {
    LibraryStorage.decideServerDeletedDownloads(
      isEnabled: isEnabled,
      run: run,
      candidateIDs: candidateIDs,
      playingSongID: playingSongID,
      cachedSongCount: cachedSongCount,
      heldSongs: heldSongs,
      now: date ?? now
    )
  }

  func testCandidates_AreDownloadedDeletedSongsWithoutAvailableAlbum() {
    let deletedAlbum = createAlbum(id: "album-deleted", isDeleted: true)
    let revivedAlbum = createAlbum(id: "album-revived", isDeleted: false)
    createSong(id: "left-album")
    createSong(id: "of-deleted-album", album: deletedAlbum)
    createSong(id: "of-revived-album", album: revivedAlbum)
    createSong(id: "not-downloaded", isCached: false)
    createSong(id: "available", isDeleted: false)
    library.saveContext()
    let candidateIDs = Set(library.getServerDeletedCachedSongs(for: account).map { $0.id })
    XCTAssertEqual(candidateIDs, ["left-album", "of-deleted-album"])
  }

  func testDecision_SettingOffDeletesNothingAndClearsHeldSongs() {
    let decision = decide(
      run: run(scan: "scan-2"),
      candidateIDs: ids(3),
      heldSongs: held(ids(3), scan: "scan-1"),
      isEnabled: false
    )
    XCTAssertEqual(decision, ServerDeletedDownloadsDecision())
  }

  func testDecision_ErroredRunDeletesNothingAndKeepsHeldSongs() {
    let decision = decide(
      run: nil,
      candidateIDs: ids(3),
      heldSongs: held(["song-0"], scan: "scan-1")
    )
    XCTAssertTrue(decision.songsToDelete.isEmpty)
    XCTAssertEqual(decision.heldSongs, held(["song-0"], scan: "scan-1"))
  }

  func testDecision_UntrustedOrGuardTrippedRunDeletesNothing() {
    let runs = [
      run(scan: "scan-2", isListingTrusted: false),
      run(scan: "scan-2", isListingTrusted: true, isGuardTripped: true),
      run(scan: "scan-2", isListingTrusted: false, isGuardTripped: true),
      // the run an Ampache server reports
      RemoteDeletionRun(scans: RemoteDeletionScans()),
    ]
    for untrustedRun in runs {
      let decision = decide(
        run: untrustedRun,
        candidateIDs: ids(3),
        heldSongs: held(["song-0"], scan: "scan-1")
      )
      XCTAssertTrue(decision.songsToDelete.isEmpty)
      XCTAssertEqual(decision.heldSongs, held(["song-0"], scan: "scan-1"))
    }
  }

  func testDecision_UpToTwentyCandidatesAreDeleted() {
    let decision = decide(run: run(scan: "scan-1"), candidateIDs: ids(20))
    XCTAssertEqual(decision.songsToDelete, held(ids(20), scan: "scan-1"))
    XCTAssertTrue(decision.heldSongs.isEmpty)
  }

  func testDecision_MoreThanTwentyCandidatesAreHeld() {
    let decision = decide(run: run(scan: "scan-1"), candidateIDs: ids(21))
    XCTAssertTrue(decision.songsToDelete.isEmpty)
    XCTAssertEqual(decision.heldSongs, held(ids(21), scan: "scan-1"))
  }

  func testDecision_MoreThanATenthOfTheDownloadsAreHeld() {
    let held3 = decide(run: run(scan: "scan-1"), candidateIDs: ids(3), cachedSongCount: 20)
    XCTAssertTrue(held3.songsToDelete.isEmpty)
    XCTAssertEqual(Set(held3.heldSongs.keys), ids(3))
    let deleted2 = decide(run: run(scan: "scan-1"), candidateIDs: ids(2), cachedSongCount: 20)
    XCTAssertEqual(Set(deleted2.songsToDelete.keys), ids(2))
    XCTAssertTrue(deleted2.heldSongs.isEmpty)
  }

  func testDecision_SmallLibraryMayLoseOneDownload() {
    let one = decide(run: run(scan: "scan-1"), candidateIDs: ids(1), cachedSongCount: 5)
    XCTAssertEqual(Set(one.songsToDelete.keys), ids(1))
    let two = decide(run: run(scan: "scan-1"), candidateIDs: ids(2), cachedSongCount: 5)
    XCTAssertTrue(two.songsToDelete.isEmpty)
    XCTAssertEqual(Set(two.heldSongs.keys), ids(2))
  }

  func testDecision_LaterRunWithNewerScanConfirmsHeldSongs() {
    let decision = decide(
      run: run(scan: "scan-2"),
      candidateIDs: ids(25),
      heldSongs: held(ids(25), scan: "scan-1")
    )
    XCTAssertEqual(decision.songsToDelete, held(ids(25), scan: "scan-1"))
    XCTAssertTrue(decision.heldSongs.isEmpty)
  }

  func testDecision_RunWithTheSameScanDoesNotConfirm() {
    let decision = decide(
      run: run(scan: "scan-1"),
      candidateIDs: ids(25),
      heldSongs: held(ids(25), scan: "scan-1")
    )
    XCTAssertTrue(decision.songsToDelete.isEmpty)
    XCTAssertEqual(decision.heldSongs, held(ids(25), scan: "scan-1"))
  }

  func testDecision_RunWithoutScanInBetweenDoesNotConfirm() {
    let heldSongs = held(ids(25), scan: "scan-1")
    let withoutScan = decide(run: run(scan: nil), candidateIDs: ids(25), heldSongs: heldSongs)
    XCTAssertTrue(withoutScan.songsToDelete.isEmpty)
    XCTAssertEqual(withoutScan.heldSongs, heldSongs)
    let sameScanAgain = decide(
      run: run(scan: "scan-1"),
      candidateIDs: ids(25),
      heldSongs: withoutScan.heldSongs
    )
    XCTAssertTrue(sameScanAgain.songsToDelete.isEmpty)
    XCTAssertEqual(sameScanAgain.heldSongs, heldSongs)
  }

  func testDecision_ServerWithoutScanConfirmsAfterThirtyMinutes() {
    let heldSongs = held(ids(25), scan: nil)
    let early = decide(
      run: run(scan: nil),
      candidateIDs: ids(25),
      heldSongs: heldSongs,
      at: now.addingTimeInterval(29 * 60)
    )
    XCTAssertTrue(early.songsToDelete.isEmpty)
    XCTAssertEqual(early.heldSongs, heldSongs)
    let later = decide(
      run: run(scan: nil),
      candidateIDs: ids(25),
      heldSongs: heldSongs,
      at: now.addingTimeInterval(30 * 60)
    )
    XCTAssertEqual(later.songsToDelete, heldSongs)
    XCTAssertTrue(later.heldSongs.isEmpty)
  }

  func testDecision_HeldSongsWithoutScanWaitForTheNextScan() {
    let later = now.addingTimeInterval(60)
    let firstScan = decide(
      run: run(scan: "scan-1"),
      candidateIDs: ids(25),
      heldSongs: held(ids(25), scan: nil),
      at: later
    )
    XCTAssertTrue(firstScan.songsToDelete.isEmpty)
    XCTAssertEqual(firstScan.heldSongs, held(ids(25), scan: "scan-1", date: later))
    let nextScan = decide(
      run: run(scan: "scan-2"),
      candidateIDs: ids(25),
      heldSongs: firstScan.heldSongs
    )
    XCTAssertEqual(Set(nextScan.songsToDelete.keys), ids(25))
  }

  func testDecision_HeldSongNoLongerCandidateLeavesTheHeldSongs() {
    let decision = decide(
      run: run(scan: "scan-1"),
      candidateIDs: ids(24),
      heldSongs: held(ids(25), scan: "scan-1")
    )
    XCTAssertEqual(Set(decision.heldSongs.keys), ids(24))
    XCTAssertTrue(decision.songsToDelete.isEmpty)
  }

  func testDecision_PlayingSongIsNeitherDeletedNorCounted() {
    let fresh = decide(
      run: run(scan: "scan-1"),
      candidateIDs: ["song-0", "song-1"],
      cachedSongCount: 10,
      playingSongID: "song-0"
    )
    XCTAssertEqual(Set(fresh.songsToDelete.keys), ["song-1"])
    XCTAssertTrue(fresh.heldSongs.isEmpty)
    let confirmed = decide(
      run: run(scan: "scan-2"),
      candidateIDs: ["song-0"],
      heldSongs: held(["song-0"], scan: "scan-1"),
      playingSongID: "song-0"
    )
    XCTAssertTrue(confirmed.songsToDelete.isEmpty)
    XCTAssertEqual(confirmed.heldSongs, held(["song-0"], scan: "scan-1"))
  }

  func testDecision_UncheckedSongsAreHeldAgain() {
    let decision = decide(
      run: run(scan: "scan-2"),
      candidateIDs: ["song-0", "song-1", "song-2"],
      heldSongs: held(["song-0"], scan: "scan-1")
    )
    XCTAssertEqual(Set(decision.songsToDelete.keys), ["song-0", "song-1", "song-2"])
    let heldAgain = decision.heldSongs(addingUnchecked: ["song-0", "song-2"])
    XCTAssertEqual(heldAgain["song-0"], ServerDeletedDownloadEvidence(scan: "scan-1", date: now))
    XCTAssertEqual(heldAgain["song-2"], ServerDeletedDownloadEvidence(scan: "scan-2", date: now))
    XCTAssertNil(heldAgain["song-1"])
  }

  func testDeleteCache_OnlyOfDecidedCandidates() {
    let revivedAlbum = createAlbum(id: "album-revived", isDeleted: false)
    let decided = createSong(id: "decided")
    let notDecided = createSong(id: "not-decided")
    let ofRevivedAlbum = createSong(id: "of-revived-album", album: revivedAlbum)
    let playing = createSong(id: "playing")
    let duplicate = createSong(id: "duplicate")
    let availableDuplicate = createSong(id: "duplicate", isDeleted: false)
    library.saveContext()

    let deletedSongs = library.deleteCacheOfServerDeletedSongs(
      for: account,
      songIDs: ["decided", "of-revived-album", "playing", "duplicate"],
      playingSongID: "playing"
    )
    XCTAssertEqual(deletedSongs.map { $0.id }, ["decided"])
    XCTAssertNil(decided.relFilePath)
    XCTAssertFalse(decided.isCached)
    for keptSong in [notDecided, ofRevivedAlbum, playing, duplicate, availableDuplicate] {
      XCTAssertNotNil(keptSong.relFilePath)
    }
  }
}

// MARK: - UserSettingsDecodingTest

@MainActor
class UserSettingsDecodingTest: XCTestCase {
  func testSettingsWithoutDeleteDownloadsKey_DecodeWithTheSettingOff() throws {
    var settings = UserSettings()
    settings.isDeleteDownloadsOfServerDeletedSongs = true
    settings.isShowRating = true
    let data = try JSONEncoder().encode(settings)
    var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    // settings written before the key existed
    XCTAssertNotNil(json.removeValue(forKey: "_isDeleteDownloadsOfServerDeletedSongs"))
    let decoded = try JSONDecoder().decode(
      UserSettings.self,
      from: JSONSerialization.data(withJSONObject: json)
    )
    XCTAssertFalse(decoded.isDeleteDownloadsOfServerDeletedSongs)
    XCTAssertTrue(decoded.isShowRating)
  }

  func testDeleteDownloadsSetting_IsOffByDefaultAndKeepsItsValue() throws {
    XCTAssertFalse(UserSettings().isDeleteDownloadsOfServerDeletedSongs)
    var settings = UserSettings()
    settings.isDeleteDownloadsOfServerDeletedSongs = true
    let decoded = try JSONDecoder().decode(UserSettings.self, from: JSONEncoder().encode(settings))
    XCTAssertTrue(decoded.isDeleteDownloadsOfServerDeletedSongs)
  }
}

// MARK: - MOCK_RemoteDeletionLibrarySyncer

@MainActor
final class MOCK_RemoteDeletionLibrarySyncer: LibrarySyncer {
  var run = RemoteDeletionRun(scans: RemoteDeletionScans())
  var error: Error?
  var isHoldingNextCheck = false
  private(set) var songListingAllowances = [Bool]()
  private var heldCheck: CheckedContinuation<(), Never>?

  func releaseHeldCheck() {
    heldCheck?.resume()
    heldCheck = nil
  }

  func syncRemoteDeletions(
    checkedScans: RemoteDeletionScans,
    isSongListingAllowed: Bool
  ) async throws
    -> RemoteDeletionRun {
    songListingAllowances.append(isSongListingAllowed)
    if isHoldingNextCheck {
      isHoldingNextCheck = false
      await withCheckedContinuation { self.heldCheck = $0 }
    }
    if let error { throw error }
    return run
  }

  func verifyRemoteDeletion(ofSongsWithIDs songIDs: [String]) async
    -> RemoteSongDeletionVerification {
    RemoteSongDeletionVerification(uncheckedSongIDs: Set(songIDs))
  }

  func syncInitial(statusNotifyier: SyncCallbacks?) async throws {}
  func sync(genre: Genre) async throws {}
  func sync(artist: Artist) async throws {}
  func sync(album: Album) async throws {}
  func sync(song: Song) async throws {}
  func sync(podcast: Podcast) async throws {}
  func syncNewestAlbums(offset: Int, count: Int) async throws {}
  func syncRecentAlbums(offset: Int, count: Int) async throws {}
  func syncNewestPodcastEpisodes() async throws {}
  func syncFavoriteLibraryElements() async throws {}
  func syncRadios() async throws {}
  func syncDownPlaylistsWithoutSongs() async throws {}
  func syncDown(playlist: Playlist) async throws {}
  func syncUpload(playlistToUpdateName playlist: Playlist) async throws {}
  func syncUpload(playlistToAddSongs playlist: Playlist, songs: [Song]) async throws {}
  func syncUpload(playlistToDeleteSong playlist: Playlist, index: Int) async throws {}
  func syncUpload(playlistToUpdateOrder playlist: Playlist) async throws {}
  func syncUpload(playlistIdToDelete id: String) async throws {}
  func syncDownPodcastsWithoutEpisodes() async throws {}
  func searchArtists(searchText: String) async throws {}
  func searchAlbums(searchText: String) async throws {}
  func searchSongs(searchText: String) async throws {}
  func syncMusicFolders() async throws {}
  func syncIndexes(musicFolder: MusicFolder) async throws {}
  func sync(directory: Directory) async throws {}
  func requestRandomSongs(playlist: Playlist, count: Int) async throws {}
  func requestSimilarSongs(song: Song, count: Int) async throws -> [Song] { [] }
  func requestPodcastEpisodeDelete(podcastEpisode: PodcastEpisode) async throws {}
  func syncNowPlaying(song: Song, songPosition: NowPlayingSongPosition) async throws {}
  func scrobble(song: Song, date: Date?) async throws {}
  func setRating(song: Song, rating: Int) async throws {}
  func setRating(album: Album, rating: Int) async throws {}
  func setRating(artist: Artist, rating: Int) async throws {}
  func setFavorite(song: Song, isFavorite: Bool) async throws {}
  func setFavorite(album: Album, isFavorite: Bool) async throws {}
  func setFavorite(artist: Artist, isFavorite: Bool) async throws {}
  func parseLyrics(relFilePath: URL) async throws -> LyricsList { LyricsList() }
}

// MARK: - NotificationCounter

final class NotificationCounter: NSObject {
  private(set) var count = 0

  @objc
  func didReceive(_ notification: Notification) {
    count += 1
  }
}

// MARK: - TaskProgress

@MainActor
final class TaskProgress {
  var isFinished = false
}

// MARK: - RemoteDeletionSyncTest

@MainActor
class RemoteDeletionSyncTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var storage: PersistentStorage!
  var syncer: MOCK_RemoteDeletionLibrarySyncer!
  var meta: MetaManager!
  var songsRefreshCounter: NotificationCounter!

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    let library = cdHelper.createSeededStorage()
    storage = PersistentStorage(
      coreDataManager: MOCK_CoreDataManager(persistentContainer: cdHelper.persistentContainer)
    )
    if !storage.settings.user.isOnlineMode {
      storage.settings.user.isOfflineMode = false
    }
    meta = MetaManager(
      storage: storage,
      account: library.getAccount(info: TestAccountInfo.create1()),
      networkMonitor: MOCK_NetworkMonitor(),
      performanceMonitor: MOCK_PerformanceMonitor(),
      eventLogger: EventLogger(storage: storage),
      notificationHandler: EventNotificationHandler(),
      localNotificationManager: LocalNotificationManager(
        userStatistics: library.getUserStatistics(appVersion: ""),
        storage: storage
      )
    )
    syncer = MOCK_RemoteDeletionLibrarySyncer()
    meta.librarySyncer = syncer
    songsRefreshCounter = NotificationCounter()
    NotificationCenter.default.addObserver(
      songsRefreshCounter!,
      selector: #selector(NotificationCounter.didReceive(_:)),
      name: .librarySongsSynced,
      object: meta
    )
  }

  override func tearDown() async throws {
    syncer.releaseHeldCheck()
    NotificationCenter.default.removeObserver(songsRefreshCounter!)
  }

  /// Lets the waiting tasks run until the syncer was asked the given number of times
  private func waitForChecks(_ count: Int) async {
    for _ in 0 ..< 1000 where syncer.songListingAllowances.count < count {
      await Task.yield()
    }
  }

  private func letWaitingTasksRun() async {
    for _ in 0 ..< 100 {
      await Task.yield()
    }
  }

  func testPullRightAfterAppStartCheck_RunsItsOwnCheckWithSongListing() async {
    await meta.syncRemoteDeletions(isAppStart: true)
    await meta.syncRemoteDeletions()
    XCTAssertEqual(syncer.songListingAllowances, [false, true])
  }

  func testPullDuringAppStartCheck_WaitsThenRunsItsOwnCheck() async {
    let meta = meta!
    let pullProgress = TaskProgress()
    syncer.isHoldingNextCheck = true
    let appStart = Task { await meta.syncRemoteDeletions(isAppStart: true) }
    await waitForChecks(1)
    let pull = Task {
      await meta.syncRemoteDeletions()
      pullProgress.isFinished = true
    }
    await letWaitingTasksRun()
    XCTAssertEqual(syncer.songListingAllowances, [false])
    XCTAssertFalse(pullProgress.isFinished)
    syncer.releaseHeldCheck()
    await appStart.value
    await pull.value
    XCTAssertTrue(pullProgress.isFinished)
    XCTAssertEqual(syncer.songListingAllowances, [false, true])
  }

  func testSecondPullWithinAMinute_DoesNotCheckAgain() async {
    await meta.syncRemoteDeletions()
    await meta.syncRemoteDeletions()
    XCTAssertEqual(syncer.songListingAllowances, [true])
  }

  func testTwoPullsDuringAppStartCheck_StartOneCheck() async {
    let meta = meta!
    syncer.isHoldingNextCheck = true
    let appStart = Task { await meta.syncRemoteDeletions(isAppStart: true) }
    await waitForChecks(1)
    let firstPull = Task { await meta.syncRemoteDeletions() }
    let secondPull = Task { await meta.syncRemoteDeletions() }
    await letWaitingTasksRun()
    XCTAssertEqual(syncer.songListingAllowances.count, 1)
    syncer.releaseHeldCheck()
    await appStart.value
    await firstPull.value
    await secondPull.value
    XCTAssertEqual(syncer.songListingAllowances, [false, true])
  }

  func testCheckThatChangedTheLibrary_PostsSongsRefresh() async {
    syncer.run = RemoteDeletionRun(scans: RemoteDeletionScans(), isLibraryChanged: true)
    await meta.syncRemoteDeletions()
    XCTAssertEqual(songsRefreshCounter.count, 1)
  }

  func testCheckWithoutChanges_PostsNothing() async {
    await meta.syncRemoteDeletions()
    XCTAssertEqual(syncer.songListingAllowances.count, 1)
    XCTAssertEqual(songsRefreshCounter.count, 0)
  }

  func testFailedCheck_PostsSongsRefresh() async {
    syncer.error = BackendError.notSupported
    await meta.syncRemoteDeletions()
    XCTAssertEqual(syncer.songListingAllowances.count, 1)
    XCTAssertEqual(songsRefreshCounter.count, 1)
  }
}
