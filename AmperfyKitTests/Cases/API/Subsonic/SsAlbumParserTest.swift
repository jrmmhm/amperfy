//
//  SsAlbumParserTest.swift
//  AmperfyKitTests
//
//  Created by Maximilian Bauer on 01.06.21.
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

@testable import AmperfyKit
import XCTest

// MARK: - SsAlbumParserTest

class SsAlbumParserTest: AbstractSsParserTest {
  override func setUp() async throws {
    try await super.setUp()
    xmlData = getTestFileData(name: "artist_example_1")
  }

  override func createParserDelegate() {
    let prefetch = library.getElements(
      account: account,
      prefetchIDs: ssIdParserDelegate.prefetchIDs
    )
    ssParserDelegate = SsAlbumParserDelegate(
      performanceMonitor: MOCK_PerformanceMonitor(), prefetch: prefetch, account: account,
      library: library,
      parseNotifier: nil
    )
  }

  override func checkCorrectParsing() {
    prefetchIdTester.checkPrefetchIdCounts(
      artworkCount: 16,
      artistCount: 1,
      albumCount: 15,
      artworkFetchCount: 15 // artist artwork is not created
    )

    let albums = library.getAlbums(for: account).sorted(by: { Int($0.id)! < Int($1.id)! })
    XCTAssertEqual(albums.count, 15)

    var album = albums[1]
    XCTAssertEqual(album.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.id, "11047")
    XCTAssertEqual(album.name, "Back In Black")
    XCTAssertEqual(album.rating, 1)
    XCTAssertEqual(album.artist?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artist?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artist?.id, "5432") // Artist not pre created
    XCTAssertEqual(album.artist?.name, "AC/DC")
    XCTAssertEqual(album.year, 0)
    XCTAssertFalse(album.isCached)
    XCTAssertEqual(album.duration, 2534)
    XCTAssertEqual(album.remoteDuration, 2534)
    XCTAssertEqual(album.remoteSongCount, 10)
    XCTAssertNil(album.genre)
    XCTAssertEqual(album.artwork?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artwork?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artwork?.type, "")
    XCTAssertEqual(album.artwork?.id, "al-11047")

    album = albums[6]
    XCTAssertEqual(album.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.id, "11052")
    XCTAssertEqual(album.name, "For Those About To Rock")
    XCTAssertEqual(album.rating, 0)
    XCTAssertEqual(album.artist?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artist?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artist?.id, "5432")
    XCTAssertEqual(album.artist?.name, "AC/DC")
    XCTAssertEqual(album.year, 0)
    XCTAssertFalse(album.isCached)
    XCTAssertEqual(album.duration, 2403)
    XCTAssertEqual(album.remoteDuration, 2403)
    XCTAssertEqual(album.remoteSongCount, 10)
    XCTAssertNil(album.genre)
    XCTAssertEqual(album.artwork?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artwork?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artwork?.type, "")
    XCTAssertEqual(album.artwork?.id, "al-11052")

    album = albums[7]
    XCTAssertEqual(album.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.id, "11053")
    XCTAssertEqual(album.name, "High Voltage")
    XCTAssertEqual(album.rating, 0)
    XCTAssertEqual(album.artist?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artist?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artist?.id, "5432")
    XCTAssertEqual(album.artist?.name, "AC/DC")
    XCTAssertEqual(album.year, 0)
    XCTAssertFalse(album.isCached)
    XCTAssertEqual(album.duration, 2414)
    XCTAssertEqual(album.remoteDuration, 2414)
    XCTAssertEqual(album.remoteSongCount, 8)
    XCTAssertNil(album.genre)
    XCTAssertEqual(album.artwork?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artwork?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artwork?.type, "")
    XCTAssertEqual(album.artwork?.id, "al-11053")

    album = albums[14]
    XCTAssertEqual(album.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.id, "11061")
    XCTAssertEqual(album.name, "Who Made Who")
    XCTAssertEqual(album.rating, 5)
    XCTAssertEqual(album.artist?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artist?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artist?.id, "5432")
    XCTAssertEqual(album.artist?.name, "AC/DC")
    XCTAssertEqual(album.year, 0)
    XCTAssertFalse(album.isCached)
    XCTAssertEqual(album.duration, 2291)
    XCTAssertEqual(album.remoteDuration, 2291)
    XCTAssertEqual(album.remoteSongCount, 9)
    XCTAssertNil(album.genre)
    XCTAssertEqual(album.artwork?.account?.serverHash, TestAccountInfo.test1ServerHash)
    XCTAssertEqual(album.artwork?.account?.userHash, TestAccountInfo.test1UserHash)
    XCTAssertEqual(album.artwork?.type, "")
    XCTAssertEqual(album.artwork?.id, "al-11061")
  }
}

// MARK: - SsRemoteListingParserTest

@MainActor
class SsRemoteListingParserTest: XCTestCase {
  private func parse(_ data: Data) -> SsRemoteListingParserDelegate {
    let parserDelegate = SsRemoteListingParserDelegate(
      performanceMonitor: MOCK_PerformanceMonitor()
    )
    parserDelegate.parse(data: data)
    return parserDelegate
  }

  private func page(_ albumIDs: [String]) -> RemoteListingPage {
    var page = RemoteListingPage()
    page.entryCount = albumIDs.count
    page.listing.albumIDs = Set(albumIDs)
    return page
  }

  func testAlbumListingPage() {
    let parserDelegate = parse(getTestFileData(name: "albumList2_example_1"))
    XCTAssertTrue(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.page.entryCount, 3)
    XCTAssertEqual(parserDelegate.page.listing.albumIDs, ["al-1", "al-2", "al-3"])
    // al-3 comes without a song count
    XCTAssertEqual(parserDelegate.page.listing.albumSongCounts, ["al-1": 12, "al-2": 1])
  }

  func testScanStatus() {
    let parserDelegate = parse(getTestFileData(name: "scanStatus_example_1"))
    XCTAssertTrue(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.serverScan.lastScan, "2026-01-14T08:15:00Z")
    XCTAssertFalse(parserDelegate.serverScan.isScanning)
    XCTAssertEqual(parserDelegate.page.entryCount, 0)
  }

  func testErrorAnswerIsNoValidPage() {
    XCTAssertFalse(parse(getTestFileData(name: "error_example_1")).isValidPage)
    XCTAssertFalse(parse(getTestFileData(name: "error_not_found_example_1")).isValidPage)
  }

  func testTruncatedAnswerIsNoValidPage() {
    let data = getTestFileData(name: "albumList2_example_1")
    let parserDelegate = parse(data.prefix(data.count / 2))
    XCTAssertFalse(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.albumVerdict, .unknown)
  }

  func testNonSubsonicAnswerIsNoValidPage() {
    let parserDelegate = parse(Data("<html><body>Bad Gateway</body></html>".utf8))
    XCTAssertFalse(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.albumVerdict, .unknown)
  }

  func testAlbumVerdict_AlbumWithoutSongsIsDeleted() {
    XCTAssertEqual(parse(getTestFileData(name: "album_missing_example_1")).albumVerdict, .deleted)
  }

  func testAlbumVerdict_DataNotFoundIsDeleted() {
    XCTAssertEqual(
      parse(getTestFileData(name: "error_not_found_example_1")).albumVerdict,
      .deleted
    )
  }

  func testAlbumVerdict_AlbumWithSongsIsAvailable() {
    XCTAssertEqual(parse(getTestFileData(name: "album_example_1")).albumVerdict, .available)
  }

  func testAlbumVerdict_OtherErrorIsUnknown() {
    XCTAssertEqual(parse(getTestFileData(name: "error_example_1")).albumVerdict, .unknown)
  }

  func testCollectListing_PagesUntilEmptyPage() async throws {
    var offsets = [Int]()
    // the server returns at most two entries per page
    let pages = [0: page(["a", "b"]), 2: page(["c", "d"]), 4: page(["e"])]
    let listing = try await SubsonicLibrarySyncer.collectListing { offset in
      offsets.append(offset)
      return pages[offset] ?? RemoteListingPage()
    }
    XCTAssertEqual(offsets, [0, 2, 4, 5])
    XCTAssertEqual(listing.albumIDs, ["a", "b", "c", "d", "e"])
  }

  func testCollectListing_EmptyFirstPageGivesEmptyListing() async throws {
    let listing = try await SubsonicLibrarySyncer.collectListing { _ in RemoteListingPage() }
    XCTAssertTrue(listing.isEmpty)
  }

  func testCollectListing_FailingSecondPageThrows() async {
    do {
      _ = try await SubsonicLibrarySyncer.collectListing { offset in
        guard offset == 0 else { throw BackendError.notSupported }
        return self.page(["a", "b"])
      }
      XCTFail("a failing page must not give a listing")
    } catch {}
  }

  func testCollectListing_ServerIgnoringOffsetThrows() async {
    do {
      _ = try await SubsonicLibrarySyncer.collectListing { _ in self.page(["a", "b"]) }
      XCTFail("a repeated page must not give a listing")
    } catch {}
  }

  func testAlbumListingNeeded() {
    let scans = RemoteDeletionScans(albumListing: "scan-1")
    XCTAssertTrue(scans.isAlbumListingNeeded(serverScan: RemoteServerScan()))
    XCTAssertFalse(scans.isAlbumListingNeeded(serverScan: RemoteServerScan(lastScan: "scan-1")))
    XCTAssertTrue(scans.isAlbumListingNeeded(serverScan: RemoteServerScan(lastScan: "scan-2")))
    XCTAssertFalse(scans.isAlbumListingNeeded(
      serverScan: RemoteServerScan(lastScan: "scan-2", isScanning: true)
    ))
  }

  func testCheckAlbumListing_WithoutNewScanRequestsNothing() async throws {
    var requestedOffsets = [Int]()
    let scans = try await SubsonicLibrarySyncer.checkAlbumListing(
      checkedScans: RemoteDeletionScans(albumListing: "scan-1"),
      serverScan: RemoteServerScan(lastScan: "scan-1"),
      requestPage: { offset in
        requestedOffsets.append(offset)
        return RemoteListingPage()
      },
      checkListing: { _ in RemoteAlbumCandidates() },
      verifyDeletion: { _ in },
      resync: { _ in }
    )
    XCTAssertEqual(scans, RemoteDeletionScans(albumListing: "scan-1"))
    XCTAssertTrue(requestedOffsets.isEmpty)
  }

  func testCheckAlbumListing_FailingPageMarksNothingAndKeepsScan() async {
    var verifiedAlbumIDs = [String]()
    do {
      _ = try await SubsonicLibrarySyncer.checkAlbumListing(
        checkedScans: RemoteDeletionScans(albumListing: "scan-1"),
        serverScan: RemoteServerScan(lastScan: "scan-2"),
        requestPage: { offset in
          guard offset == 0 else { throw BackendError.notSupported }
          return self.page(["a", "b"])
        },
        checkListing: { _ in RemoteAlbumCandidates(absentAlbumIDs: ["c"]) },
        verifyDeletion: { verifiedAlbumIDs.append($0) },
        resync: { _ in }
      )
      XCTFail("a failing page must abort the check")
    } catch {}
    XCTAssertTrue(verifiedAlbumIDs.isEmpty)
  }

  func testCheckAlbumListing_UntrustedListingMarksNothingButAdvancesScan() async throws {
    var verifiedAlbumIDs = [String]()
    var resyncedAlbumIDs = [String]()
    let scans = try await SubsonicLibrarySyncer.checkAlbumListing(
      checkedScans: RemoteDeletionScans(albumListing: "scan-1"),
      serverScan: RemoteServerScan(lastScan: "scan-2"),
      requestPage: { _ in RemoteListingPage() },
      checkListing: { _ in RemoteAlbumCandidates() },
      verifyDeletion: { verifiedAlbumIDs.append($0) },
      resync: { resyncedAlbumIDs.append($0) }
    )
    XCTAssertEqual(scans, RemoteDeletionScans(albumListing: "scan-2"))
    XCTAssertTrue(verifiedAlbumIDs.isEmpty)
    XCTAssertTrue(resyncedAlbumIDs.isEmpty)
  }

  func testCheckAlbumListing_VerifiesAbsentAlbumsAndResyncsAlbums() async throws {
    var verifiedAlbumIDs = [String]()
    var resyncedAlbumIDs = [String]()
    let scans = try await SubsonicLibrarySyncer.checkAlbumListing(
      checkedScans: RemoteDeletionScans(),
      serverScan: RemoteServerScan(lastScan: "scan-2"),
      requestPage: { offset in offset == 0 ? self.page(["a", "b"]) : RemoteListingPage() },
      checkListing: { listing in
        XCTAssertEqual(listing.albumIDs, ["a", "b"])
        return RemoteAlbumCandidates(absentAlbumIDs: ["c"], resyncAlbumIDs: ["a"])
      },
      verifyDeletion: { verifiedAlbumIDs.append($0) },
      resync: { resyncedAlbumIDs.append($0) }
    )
    XCTAssertEqual(scans, RemoteDeletionScans(albumListing: "scan-2"))
    XCTAssertEqual(verifiedAlbumIDs, ["c"])
    XCTAssertEqual(resyncedAlbumIDs, ["a"])
  }

  func testSongListingPage() {
    let parserDelegate = parse(getTestFileData(name: "search3_songs_example_1"))
    XCTAssertTrue(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.page.entryCount, 3)
    XCTAssertEqual(parserDelegate.page.listing.songIDs, ["so-1", "so-2", "so-3"])
    XCTAssertTrue(parserDelegate.page.listing.albumIDs.isEmpty)
  }

  func testEmptySongListingPage() {
    let parserDelegate = parse(getTestFileData(name: "search3_empty_example_1"))
    XCTAssertTrue(parserDelegate.isValidPage)
    XCTAssertEqual(parserDelegate.page.entryCount, 0)
  }

  func testSongListingNeeded() {
    let scans = RemoteDeletionScans(songListing: "scan-1")
    let newScan = RemoteServerScan(lastScan: "scan-2")
    XCTAssertTrue(scans.isSongListingNeeded(serverScan: newScan, isSongListingAllowed: true))
    XCTAssertFalse(scans.isSongListingNeeded(serverScan: newScan, isSongListingAllowed: false))
    XCTAssertFalse(scans.isSongListingNeeded(
      serverScan: RemoteServerScan(lastScan: "scan-1"),
      isSongListingAllowed: true
    ))
    // a server that reports no scan never gets the song listing
    XCTAssertFalse(scans.isSongListingNeeded(
      serverScan: RemoteServerScan(),
      isSongListingAllowed: true
    ))
    XCTAssertFalse(scans.isSongListingNeeded(
      serverScan: RemoteServerScan(lastScan: "scan-2", isScanning: true),
      isSongListingAllowed: true
    ))
  }

  func testCheckSongListing_NotAllowedRequestsNothing() async throws {
    var requestedOffsets = [Int]()
    let scans = try await SubsonicLibrarySyncer.checkSongListing(
      checkedScans: RemoteDeletionScans(albumListing: "scan-2", songListing: "scan-1"),
      serverScan: RemoteServerScan(lastScan: "scan-2"),
      isSongListingAllowed: false,
      requestPage: { offset in
        requestedOffsets.append(offset)
        return RemoteListingPage()
      },
      checkListing: { _ in [String]() },
      resync: { _ in }
    )
    XCTAssertEqual(scans, RemoteDeletionScans(albumListing: "scan-2", songListing: "scan-1"))
    XCTAssertTrue(requestedOffsets.isEmpty)
  }

  func testCheckSongListing_FailingPageMarksNothingAndKeepsScan() async {
    var resyncedAlbumIDs = [String]()
    do {
      _ = try await SubsonicLibrarySyncer.checkSongListing(
        checkedScans: RemoteDeletionScans(songListing: "scan-1"),
        serverScan: RemoteServerScan(lastScan: "scan-2"),
        isSongListingAllowed: true,
        requestPage: { _ in throw BackendError.notSupported },
        checkListing: { _ in ["a"] },
        resync: { resyncedAlbumIDs.append($0) }
      )
      XCTFail("a failing page must abort the check")
    } catch {}
    XCTAssertTrue(resyncedAlbumIDs.isEmpty)
  }

  func testCheckSongListing_ResyncsAlbumsWithMissingSongs() async throws {
    var resyncedAlbumIDs = [String]()
    let scans = try await SubsonicLibrarySyncer.checkSongListing(
      checkedScans: RemoteDeletionScans(songListing: "scan-1"),
      serverScan: RemoteServerScan(lastScan: "scan-2"),
      isSongListingAllowed: true,
      requestPage: { offset in
        guard offset == 0 else { return RemoteListingPage() }
        var page = RemoteListingPage()
        page.entryCount = 2
        page.listing.songIDs = ["s1", "s2"]
        return page
      },
      checkListing: { listing in
        XCTAssertEqual(listing.songIDs, ["s1", "s2"])
        return ["a"]
      },
      resync: { resyncedAlbumIDs.append($0) }
    )
    XCTAssertEqual(scans, RemoteDeletionScans(songListing: "scan-2"))
    XCTAssertEqual(resyncedAlbumIDs, ["a"])
  }

  func testSongAnswer_FoundSongNamesItsAlbum() {
    let parserDelegate = parse(getTestFileData(name: "song_example_1"))
    XCTAssertEqual(parserDelegate.songAnswer(songID: "so-7"), .inAlbum("al-5"))
    XCTAssertEqual(parserDelegate.songAnswer(songID: "so-8"), .unknown)
  }

  func testSongAnswer_DataNotFoundIsDeleted() {
    let parserDelegate = parse(getTestFileData(name: "error_not_found_example_1"))
    XCTAssertEqual(parserDelegate.songAnswer(songID: "so-7"), .deleted)
  }

  func testSongAnswer_OtherErrorIsUnknown() {
    let parserDelegate = parse(getTestFileData(name: "error_example_1"))
    XCTAssertEqual(parserDelegate.songAnswer(songID: "so-7"), .unknown)
  }

  func testSongAnswer_NonSubsonicOrTruncatedAnswerIsNoAnswer() {
    let html = parse(Data("<html><body>Bad Gateway</body></html>".utf8))
    XCTAssertEqual(html.songAnswer(songID: "so-7"), .noAnswer)
    let data = getTestFileData(name: "song_example_1")
    XCTAssertEqual(parse(data.prefix(data.count / 2)).songAnswer(songID: "so-7"), .noAnswer)
  }

  func testAlbumAnswer_ListsTheSongsOfTheRequestedAlbum() {
    let parserDelegate = parse(getTestFileData(name: "album_example_1"))
    guard case let .songs(songIDs) = parserDelegate.albumAnswer(albumID: "11053") else {
      return XCTFail("the album answer must list its songs")
    }
    XCTAssertTrue(songIDs.contains("71463"))
    XCTAssertFalse(songIDs.contains("so-7"))
  }

  func testAlbumAnswer_AnotherAlbumIsUnknown() {
    let parserDelegate = parse(getTestFileData(name: "album_example_1"))
    XCTAssertEqual(parserDelegate.albumAnswer(albumID: "al-5"), .unknown)
  }

  func testAlbumAnswer_AlbumWithoutSongsListsNoSong() {
    let parserDelegate = parse(getTestFileData(name: "album_missing_example_1"))
    XCTAssertEqual(parserDelegate.albumAnswer(albumID: "al-9"), .songs([]))
  }

  func testAlbumAnswer_DataNotFoundIsDeleted() {
    let parserDelegate = parse(getTestFileData(name: "error_not_found_example_1"))
    XCTAssertEqual(parserDelegate.albumAnswer(albumID: "al-5"), .deleted)
  }

  func testAlbumAnswer_NonSubsonicAnswerIsNoAnswer() {
    let parserDelegate = parse(Data("<html><body>Bad Gateway</body></html>".utf8))
    XCTAssertEqual(parserDelegate.albumAnswer(albumID: "al-5"), .noAnswer)
  }

  func testVerifySongDeletions_DeletesOnlyOnAPositiveAnswer() async {
    var requestedAlbumIDs = [String]()
    let verification = await SubsonicLibrarySyncer.verifySongDeletions(
      songIDs: ["purged", "missing", "present", "unknown", "albumUnknown", "albumGone"],
      requestSong: { songID in
        switch songID {
        case "purged": return .deleted
        case "missing", "present": return .inAlbum("a1")
        case "albumUnknown": return .inAlbum("a2")
        case "albumGone": return .inAlbum("a3")
        default: return .unknown
        }
      },
      requestAlbum: { albumID in
        requestedAlbumIDs.append(albumID)
        switch albumID {
        case "a1": return .songs(["present"])
        case "a3": return .deleted
        default: return .unknown
        }
      }
    )
    XCTAssertEqual(verification.deletedSongIDs, ["purged", "missing", "albumGone"])
    XCTAssertTrue(verification.uncheckedSongIDs.isEmpty)
    // every album is requested once
    XCTAssertEqual(requestedAlbumIDs, ["a1", "a2", "a3"])
  }

  func testVerifySongDeletions_StopsAtTheFirstMissingAnswer() async {
    var requestedSongIDs = [String]()
    let verification = await SubsonicLibrarySyncer.verifySongDeletions(
      songIDs: ["s1", "s2", "s3", "s4"],
      requestSong: { songID in
        requestedSongIDs.append(songID)
        switch songID {
        case "s1": return .deleted
        case "s2": return .inAlbum("a1")
        default: return .deleted
        }
      },
      requestAlbum: { _ in .noAnswer }
    )
    XCTAssertEqual(verification.deletedSongIDs, ["s1"])
    XCTAssertEqual(verification.uncheckedSongIDs, ["s2", "s3", "s4"])
    XCTAssertEqual(requestedSongIDs, ["s1", "s2"])
  }

  func testVerifySongDeletions_TransportErrorOnGetSongDeletesNothingMore() async {
    let verification = await SubsonicLibrarySyncer.verifySongDeletions(
      songIDs: ["s1", "s2"],
      requestSong: { _ in .noAnswer },
      requestAlbum: { _ in .deleted }
    )
    XCTAssertTrue(verification.deletedSongIDs.isEmpty)
    XCTAssertEqual(verification.uncheckedSongIDs, ["s1", "s2"])
  }
}
