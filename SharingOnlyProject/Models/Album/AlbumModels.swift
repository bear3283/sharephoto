import Foundation
import Photos
import UIKit

// MARK: - Album Type
enum AlbumType: String, CaseIterable, Codable {
    case system = "system"
    case user = "user"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .system: return "시스템 앨범"
        case .user: return "사용자 앨범"
        case .personal: return "개인 앨범"
        }
    }
}

// MARK: - Album Photo Item
struct AlbumPhotoItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let assetLocalIdentifier: String
    let dateAdded: Date
    var image: UIImage?
    
    init(assetLocalIdentifier: String, dateAdded: Date) {
        self.assetLocalIdentifier = assetLocalIdentifier
        self.dateAdded = dateAdded
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: AlbumPhotoItem, rhs: AlbumPhotoItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Personal Album
struct PersonalAlbum: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let createdDate: Date
    var photoItems: [AlbumPhotoItem]
    var coverImage: UIImage?
    
    init(name: String, createdDate: Date, photoItems: [AlbumPhotoItem] = [], coverImage: UIImage? = nil) {
        self.name = name
        self.createdDate = createdDate
        self.photoItems = photoItems
        self.coverImage = coverImage
    }
    
    var isEmpty: Bool {
        return photoItems.isEmpty
    }
    
    var photoCount: Int {
        return photoItems.count
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: PersonalAlbum, rhs: PersonalAlbum) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Album
struct Album: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let type: AlbumType
    let assetCount: Int
    let coverImage: UIImage?
    let createdDate: Date
    let assetCollection: PHAssetCollection?
    let localIdentifier: String?
    let personalAlbum: PersonalAlbum?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: AlbumType,
        assetCount: Int,
        coverImage: UIImage? = nil,
        createdDate: Date,
        assetCollection: PHAssetCollection? = nil,
        localIdentifier: String? = nil,
        personalAlbum: PersonalAlbum? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.assetCount = assetCount
        self.coverImage = coverImage
        self.createdDate = createdDate
        self.assetCollection = assetCollection
        self.localIdentifier = localIdentifier
        self.personalAlbum = personalAlbum
    }
    
    // Convenience initializer from PersonalAlbum
    init(from personalAlbum: PersonalAlbum) {
        self.id = personalAlbum.id.uuidString
        self.name = personalAlbum.name
        self.type = .personal
        self.assetCount = personalAlbum.photoCount
        self.coverImage = personalAlbum.coverImage
        self.createdDate = personalAlbum.createdDate
        self.assetCollection = nil
        self.localIdentifier = nil
        self.personalAlbum = personalAlbum
    }
    
    // Convenience initializer from PHAssetCollection
    init(from assetCollection: PHAssetCollection, assetCount: Int, coverImage: UIImage? = nil) {
        self.id = assetCollection.localIdentifier
        self.name = assetCollection.localizedTitle ?? "Unknown Album"
        self.type = assetCollection.assetCollectionType == .smartAlbum ? .system : .user
        self.assetCount = assetCount
        self.coverImage = coverImage
        self.createdDate = assetCollection.startDate ?? Date()
        self.assetCollection = assetCollection
        self.localIdentifier = assetCollection.localIdentifier
        self.personalAlbum = nil
    }
    
    var isEmpty: Bool {
        return assetCount == 0
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Album Section
struct AlbumSection: Identifiable, Equatable {
    let id = UUID()
    let type: AlbumType
    let title: String
    let albums: [Album]
    
    init(type: AlbumType, title: String, albums: [Album]) {
        self.type = type
        self.title = title
        self.albums = albums
    }
    
    var isEmpty: Bool {
        return albums.isEmpty
    }
    
    var albumCount: Int {
        return albums.count
    }
    
    var totalPhotoCount: Int {
        return albums.reduce(0) { $0 + $1.assetCount }
    }
    
    // MARK: - Equatable
    static func == (lhs: AlbumSection, rhs: AlbumSection) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Preview Helpers
extension Album {
    static let samplePersonalAlbum: Album = {
        let personalAlbum = PersonalAlbum(
            name: "여행 사진",
            createdDate: Date(),
            photoItems: [],
            coverImage: DummyImageGenerator.generateAlbumCover(albumName: "여행 사진")
        )
        return Album(from: personalAlbum)
    }()
    
    static let sampleUserAlbum: Album = {
        Album(
            name: "내 앨범",
            type: .user,
            assetCount: 25,
            coverImage: DummyImageGenerator.generateAlbumCover(albumName: "내 앨범"),
            createdDate: Date()
        )
    }()
    
    static let sampleSystemAlbum: Album = {
        Album(
            name: "즐겨찾기",
            type: .system,
            assetCount: 15,
            coverImage: DummyImageGenerator.generateAlbumCover(albumName: "즐겨찾기"),
            createdDate: Date()
        )
    }()
}

extension AlbumSection {
    static let sampleSections: [AlbumSection] = [
        AlbumSection(type: .system, title: "시스템 앨범", albums: [Album.sampleSystemAlbum]),
        AlbumSection(type: .user, title: "사용자 앨범", albums: [Album.sampleUserAlbum]),
        AlbumSection(type: .personal, title: "개인 앨범", albums: [Album.samplePersonalAlbum])
    ]
}