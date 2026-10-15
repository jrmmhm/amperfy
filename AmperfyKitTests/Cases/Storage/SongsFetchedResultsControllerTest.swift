//
//  SongsFetchedResultsControllerTest.swift
//  AmperfyKitTests
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

@MainActor
class SongsFetchedResultsControllerTest: XCTestCase {
  var cdHelper: CoreDataHelper!
  var library: LibraryStorage!
  var account: Account!
  var coreDataCompanion: CoreDataCompanion!

  override func setUp() async throws {
    cdHelper = CoreDataHelper()
    library = cdHelper.createSeededStorage()
    account = library.getAccount(info: TestAccountInfo.create1())
    coreDataCompanion = CoreDataCompanion(context: cdHelper.persistentContainer.viewContext)
  }

  override func tearDown() {}

  func testShowAllResultsIncludesSongsSavedInBackgroundContext() {
    let songsController = SongsFetchedResultsController(
      coreDataCompanion: coreDataCompanion,
      account: account,
      sortType: .name,
      isGroupedInAlphabeticSections: true
    )
    songsController.showAllResults()
    let countBeforeSync = songsController.fetchedObjects?.count ?? 0

    let newSongIds = ["bg-song-1", "bg-song-2", "bg-song-3"]
    let backgroundContext = cdHelper.persistentContainer.newBackgroundContext()
    backgroundContext.performAndWait {
      let backgroundLibrary = LibraryStorage(context: backgroundContext)
      let backgroundAccount = backgroundLibrary.getAccount(info: TestAccountInfo.create1())
      let album = backgroundLibrary.createAlbum(account: backgroundAccount)
      album.id = "bg-album"
      for songId in newSongIds {
        let song = backgroundLibrary.createSong(account: backgroundAccount)
        song.id = songId
        song.title = "Background \(songId)"
        song.size = 1000
        song.album = album
      }
      backgroundLibrary.saveContext()
    }

    songsController.showAllResults()
    let fetchedIds = songsController.fetchedObjects?.map { $0.id } ?? []
    XCTAssertEqual(fetchedIds.count, countBeforeSync + newSongIds.count)
    for songId in newSongIds {
      XCTAssertTrue(fetchedIds.contains(songId))
    }
  }

  func testSongsControllerUsesNoPersistentCache() {
    let sortTypes: [SongElementSortType] = [.name, .rating, .addedDate, .duration, .starredDate]
    for sortType in sortTypes {
      let songsController = SongsFetchedResultsController(
        coreDataCompanion: coreDataCompanion,
        account: account,
        sortType: sortType,
        isGroupedInAlphabeticSections: sortType.hasSectionTitles
      )
      XCTAssertNil(songsController.fetchResultsController.cacheName)
    }
  }

  func testTrackingControllerKeepsPersistentCache() {
    let albumsController = AlbumFetchedResultsController(
      coreDataCompanion: coreDataCompanion,
      account: account,
      sortType: .name,
      isGroupedInAlphabeticSections: true
    )
    XCTAssertEqual(
      albumsController.fetchResultsController.cacheName,
      "AlbumFetchedResultsController-\(TestAccountInfo.test1ServerHash)-\(TestAccountInfo.test1UserHash)"
    )
  }
}
