import Foundation
import SwiftUI
import Photos
import Combine

@MainActor
class EnhancedAlbumViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var albumSections: [AlbumSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedAlbum: Album?
    @Published var showingAlbumDetail = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let photoService = PhotoService()
    
    // MARK: - Initialization
    init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Load all albums from the Photos library
    func loadAlbums() {
        Task {
            await loadAlbumsAsync()
        }
    }
    
    /// Reload albums
    func reloadAlbums() {
        Task {
            await loadAlbumsAsync()
        }
    }
    
    /// Create a new personal album
    func createPersonalAlbum(name: String) {
        let personalAlbum = PersonalAlbum(
            name: name,
            createdDate: Date(),
            photoItems: [],
            coverImage: DummyImageGenerator.generateAlbumCover(albumName: name)
        )
        
        let album = Album(from: personalAlbum)
        
        // Add to personal albums section
        if let personalSectionIndex = albumSections.firstIndex(where: { $0.type == .personal }) {
            let updatedSection = albumSections[personalSectionIndex]
            var updatedAlbums = updatedSection.albums
            updatedAlbums.append(album)
            
            albumSections[personalSectionIndex] = AlbumSection(
                type: .personal,
                title: updatedSection.title,
                albums: updatedAlbums
            )
        } else {
            // Create new personal section
            let newSection = AlbumSection(
                type: .personal,
                title: "개인 앨범",
                albums: [album]
            )
            albumSections.append(newSection)
        }
    }
    
    /// Delete a personal album
    func deletePersonalAlbum(_ album: Album) {
        guard album.type == .personal else { return }
        
        if let personalSectionIndex = albumSections.firstIndex(where: { $0.type == .personal }) {
            let updatedSection = albumSections[personalSectionIndex]
            var updatedAlbums = updatedSection.albums
            updatedAlbums.removeAll { $0.id == album.id }
            
            if updatedAlbums.isEmpty {
                albumSections.remove(at: personalSectionIndex)
            } else {
                albumSections[personalSectionIndex] = AlbumSection(
                    type: .personal,
                    title: updatedSection.title,
                    albums: updatedAlbums
                )
            }
        }
    }
    
    /// Select an album for detail view
    func selectAlbum(_ album: Album) {
        selectedAlbum = album
        showingAlbumDetail = true
    }
    
    /// Clear selected album
    func clearSelectedAlbum() {
        selectedAlbum = nil
        showingAlbumDetail = false
    }
    
    /// Get albums by type
    func albums(for type: AlbumType) -> [Album] {
        return albumSections.first { $0.type == type }?.albums ?? []
    }
    
    /// Get total album count
    var totalAlbumCount: Int {
        return albumSections.reduce(0) { $0 + $1.albumCount }
    }
    
    /// Get total photo count across all albums
    var totalPhotoCount: Int {
        return albumSections.reduce(0) { $0 + $1.totalPhotoCount }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Monitor photo library changes
        // Note: PHPhotoLibraryDidChange is not available as a Notification.Name
        // In a real implementation, you would use PHPhotoLibraryChangeObserver
        // For preview purposes, we'll comment this out
        
        // NotificationCenter.default
        //     .publisher(for: PHPhotoLibrary.shared().register(self))
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] _ in
        //         self?.reloadAlbums()
        //     }
        //     .store(in: &cancellables)
    }
    
    private func loadAlbumsAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let sections = try await loadAlbumSections()
            await MainActor.run {
                self.albumSections = sections
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadAlbumSections() async throws -> [AlbumSection] {
        // Check photo library authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw AlbumError.noPhotoLibraryAccess
        }
        
        var sections: [AlbumSection] = []
        
        // Load system albums
        let systemAlbums = try await loadSystemAlbums()
        if !systemAlbums.isEmpty {
            sections.append(AlbumSection(
                type: .system,
                title: "시스템 앨범",
                albums: systemAlbums
            ))
        }
        
        // Load user albums
        let userAlbums = try await loadUserAlbums()
        if !userAlbums.isEmpty {
            sections.append(AlbumSection(
                type: .user,
                title: "사용자 앨범",
                albums: userAlbums
            ))
        }
        
        // Load personal albums (app-specific)
        let personalAlbums = loadPersonalAlbums()
        if !personalAlbums.isEmpty {
            sections.append(AlbumSection(
                type: .personal,
                title: "개인 앨범",
                albums: personalAlbums
            ))
        }
        
        return sections
    }
    
    private func loadSystemAlbums() async throws -> [Album] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var albums: [Album] = []
                
                // Fetch smart albums
                let smartAlbumTypes: [PHAssetCollectionSubtype] = [
                    .smartAlbumFavorites,
                    .smartAlbumRecentlyAdded,
                    .smartAlbumScreenshots,
                    .smartAlbumSelfPortraits,
                    .smartAlbumVideos
                ]
                
                for subtype in smartAlbumTypes {
                    let collections = PHAssetCollection.fetchAssetCollections(
                        with: .smartAlbum,
                        subtype: subtype,
                        options: nil
                    )
                    
                    collections.enumerateObjects { collection, _, _ in
                        let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                        if assetCount > 0 {
                            let album = Album(from: collection, assetCount: assetCount)
                            albums.append(album)
                        }
                    }
                }
                
                continuation.resume(returning: albums)
            }
        }
    }
    
    private func loadUserAlbums() async throws -> [Album] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var albums: [Album] = []
                
                // Fetch user albums
                let collections = PHAssetCollection.fetchAssetCollections(
                    with: .album,
                    subtype: .albumRegular,
                    options: nil
                )
                
                collections.enumerateObjects { collection, _, _ in
                    let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                    let album = Album(from: collection, assetCount: assetCount)
                    albums.append(album)
                }
                
                continuation.resume(returning: albums)
            }
        }
    }
    
    private func loadPersonalAlbums() -> [Album] {
        // In a real implementation, this would load from persistent storage
        // For now, return empty array as personal albums are created on-demand
        return []
    }
}

// MARK: - Album Error
enum AlbumError: LocalizedError {
    case noPhotoLibraryAccess
    case albumCreationFailed
    case albumDeletionFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotoLibraryAccess:
            return "사진 라이브러리 접근 권한이 필요합니다"
        case .albumCreationFailed:
            return "앨범 생성에 실패했습니다"
        case .albumDeletionFailed:
            return "앨범 삭제에 실패했습니다"
        }
    }
}

// MARK: - Preview Support
extension EnhancedAlbumViewModel {
    /// Create a preview instance with sample data
    static func createPreviewInstance() -> EnhancedAlbumViewModel {
        let viewModel = EnhancedAlbumViewModel()
        viewModel.albumSections = AlbumSection.sampleSections
        return viewModel
    }
}