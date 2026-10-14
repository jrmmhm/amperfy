//
//  SsIDsParserDelegate.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 22.03.25.
//  Copyright (c) 2025 Maximilian Bauer. All rights reserved.
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
import Foundation
import os.log
import UIKit

// MARK: - SsIDsParserDelegate

class SsIDsParserDelegate: SsNotifiableXmlParser {
  public private(set) var prefetchIDs = LibraryStorage.PrefetchIdContainer()
  private var isIndex = false

  override func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String]
  ) {
    super.parser(
      parser,
      didStartElement: elementName,
      namespaceURI: namespaceURI,
      qualifiedName: qName,
      attributes: attributeDict
    )

    if elementName == "indexes" {
      isIndex = true
    }

    var isDirectory = false
    if elementName == "child", let isDir = attributeDict["isDir"], let isDirBool = Bool(isDir),
       isDirBool {
      isDirectory = true
    }

    if let id = attributeDict["id"] {
      if elementName == "song" || elementName == "entry" || elementName == "child" || elementName ==
        "episode" {
        if isDirectory {
          prefetchIDs.directoryIDs.insert(id)
        } else if elementName == "episode" {
          prefetchIDs.podcastEpisodeIDs.insert(id)
        } else {
          prefetchIDs.songIDs.insert(id)
        }
      } else if elementName == "album" {
        prefetchIDs.albumIDs.insert(id)
      } else if elementName == "artist" {
        if isIndex {
          prefetchIDs.directoryIDs.insert(id)
        } else {
          prefetchIDs.artistIDs.insert(id)
        }
      } else if elementName == "musicFolder" {
        prefetchIDs.musicFolderIDs.insert(id)
      } else if elementName == "channel" {
        prefetchIDs.podcastIDs.insert(id)
      } else if elementName == "internetRadioStation" {
        prefetchIDs.radioIDs.insert(id)
      }
    }

    if let artistId = attributeDict["artistId"] {
      prefetchIDs.artistIDs.insert(artistId)
    } else if !isIndex || elementName == "child", !isDirectory,
              let artistName = attributeDict["artist"] {
      prefetchIDs.localArtistNames.insert(artistName)
    }

    if let albumId = attributeDict["albumId"] {
      prefetchIDs.albumIDs.insert(albumId)
    }

    if let coverArtId = attributeDict["coverArt"] {
      let remoteInfo = ArtworkRemoteInfo(id: coverArtId, type: "")
      prefetchIDs.artworkIDs.insert(remoteInfo)
    }

    if elementName != "episode", let genreName = attributeDict["genre"] {
      // ignore podcast episode genre
      prefetchIDs.genreNames.insert(genreName)
    }
  }

  override func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if elementName == "indexes" {
      isIndex = false
    } else if elementName == "genre" {
      prefetchIDs.genreNames.insert(buffer)
    }

    super.parser(
      parser,
      didEndElement: elementName,
      namespaceURI: namespaceURI,
      qualifiedName: qName
    )
  }
}

// MARK: - RemoteListingPage

struct RemoteListingPage: Sendable {
  var listing = RemoteListing()
  var entryCount = 0
}

// MARK: - RemoteAlbumVerdict

enum RemoteAlbumVerdict: Sendable {
  case available
  case deleted
  case unknown
}

// MARK: - RemoteSongAnswer

/// What a getSong request says about one song
enum RemoteSongAnswer: Sendable, Equatable {
  /// no Subsonic answer arrived (transport error, proxy error page)
  case noAnswer
  case deleted
  /// the server still has the song in this album
  case inAlbum(String)
  case unknown
}

// MARK: - RemoteAlbumAnswer

/// What a getAlbum request says about the songs of one album
enum RemoteAlbumAnswer: Sendable, Equatable {
  /// no Subsonic answer arrived (transport error, proxy error page)
  case noAnswer
  case deleted
  /// the complete song list of the album
  case songs(Set<String>)
  case unknown
}

// MARK: - SsRemoteListingParserDelegate

/// Reads only ids and counts of a listing response and never touches the library
class SsRemoteListingParserDelegate: SsXmlParser {
  private(set) var page = RemoteListingPage()
  private(set) var isStatusOk = false
  private(set) var songElementCount = 0
  private(set) var serverScan = RemoteServerScan()
  /// album id per song id of the song elements
  private(set) var songAlbumIDs = [String: String]()
  private var isParsed = false
  private var isSubsonicResponse = false

  /// Returns false if the data is no well-formed XML
  @discardableResult
  func parse(data: Data) -> Bool {
    let parser = XMLParser(data: data)
    parser.delegate = self
    isParsed = parser.parse()
    return isParsed
  }

  /// A listing page counts only if it is a well-formed Subsonic answer without an error
  var isValidPage: Bool {
    isParsed && isStatusOk && error == nil
  }

  /// getAlbum answer: an album without songs (Navidrome keeps deleted albums as "missing")
  /// or "data not found" means deleted; everything else is no evidence
  var albumVerdict: RemoteAlbumVerdict {
    guard isParsed else { return .unknown }
    if let error {
      return error.subsonicError == .requestedDataNotFound ? .deleted : .unknown
    }
    guard isStatusOk, !page.listing.albumIDs.isEmpty else { return .unknown }
    return songElementCount == 0 ? .deleted : .available
  }

  /// Only a well-formed Subsonic answer counts; anything else is treated like a failed request
  private var isSubsonicAnswer: Bool {
    isParsed && isSubsonicResponse && (isStatusOk || error != nil)
  }

  /// getSong answer: "data not found" means deleted. Navidrome still answers with songs whose
  /// file is missing, so a found song only names the album to check next.
  func songAnswer(songID: String) -> RemoteSongAnswer {
    guard isSubsonicAnswer else { return .noAnswer }
    if let error {
      return error.subsonicError == .requestedDataNotFound ? .deleted : .unknown
    }
    guard let albumID = songAlbumIDs[songID], !albumID.isEmpty else { return .unknown }
    return .inAlbum(albumID)
  }

  /// getAlbum answer: "data not found" means deleted. Otherwise only the requested album with
  /// an id for every song element counts; Navidrome leaves out songs whose file is missing.
  func albumAnswer(albumID: String) -> RemoteAlbumAnswer {
    guard isSubsonicAnswer else { return .noAnswer }
    if let error {
      return error.subsonicError == .requestedDataNotFound ? .deleted : .unknown
    }
    guard page.listing.albumIDs == [albumID],
          songElementCount == page.listing.songIDs.count else { return .unknown }
    return .songs(page.listing.songIDs)
  }

  override func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String]
  ) {
    super.parser(
      parser,
      didStartElement: elementName,
      namespaceURI: namespaceURI,
      qualifiedName: qName,
      attributes: attributeDict
    )

    switch elementName {
    case "subsonic-response":
      isSubsonicResponse = true
      isStatusOk = attributeDict["status"] == "ok"
    case "album":
      guard let id = attributeDict["id"] else { return }
      page.entryCount += 1
      page.listing.albumIDs.insert(id)
      if let songCount = Int(attributeDict["songCount"] ?? "") {
        page.listing.albumSongCounts[id] = songCount
      }
    case "song":
      songElementCount += 1
      guard let id = attributeDict["id"] else { return }
      page.entryCount += 1
      page.listing.songIDs.insert(id)
      if let albumID = attributeDict["albumId"] {
        songAlbumIDs[id] = albumID
      }
    case "scanStatus":
      serverScan = RemoteServerScan(
        lastScan: attributeDict["lastScan"],
        isScanning: attributeDict["scanning"] == "true"
      )
    default:
      break
    }
  }
}
