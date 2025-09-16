import Foundation
import Photos
import UIKit

// MARK: - PhotoItem Model
struct PhotoItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let asset: PHAsset
    let image: UIImage?
    let dateCreated: Date
    var isMarkedForDeletion = false
    var isMarkedForSaving = false
    
    // 로컬 즐겨찾기 상태 (낙관적 업데이트용)
    var localFavoriteState: Bool?
    
    // MARK: - Computed Properties
    var isFavorite: Bool {
        return localFavoriteState ?? asset.isFavorite
    }
    
    var isTemporarilyMarkedForSaving: Bool {
        return isMarkedForSaving
    }
    
    var hasStatusBadge: Bool {
        return isMarkedForDeletion || isMarkedForSaving
    }
    
    var displayFavoriteStatus: Bool {
        return isFavorite || isMarkedForSaving
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Support
extension PhotoItem {
    /// 프리뷰용 PhotoItem 생성 (PHAsset 없이)
    static func createPreviewItem(
        image: UIImage?,
        dateCreated: Date,
        isFavorite: Bool = false
    ) -> PhotoItem {
        // Create a dummy PHAsset-like object for preview purposes
        // This is a workaround since PHAsset is required but not available in previews
        let dummyAsset = createDummyAsset()
        
        return PhotoItem(
            asset: dummyAsset,
            image: image,
            dateCreated: dateCreated,
            isMarkedForDeletion: false,
            isMarkedForSaving: false,
            localFavoriteState: isFavorite
        )
    }
    
    private static func createDummyAsset() -> PHAsset {
        // This is a workaround - in a real scenario, you would need a proper mock
        // For preview purposes, we'll use a placeholder approach
        // Note: This might need adjustment based on how PHAsset is used in the app
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        return fetchResult.firstObject ?? PHAsset() // Fallback to empty PHAsset
    }
}