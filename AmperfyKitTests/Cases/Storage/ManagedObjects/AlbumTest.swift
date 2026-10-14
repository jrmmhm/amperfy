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

  func testSmallLibrary_TwoAbsentAlbumsAreNotTrusted() {
    let albums = createAlbums(count: 5)
    let check = library.checkRemoteAlbumListing(
      for: account,
      listing: listing(of: Array(albums.prefix(3)))
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
      fromListing: songListing(of: albums, without: ["album-0-song-0", "album-1-song-0"])
    ))
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
