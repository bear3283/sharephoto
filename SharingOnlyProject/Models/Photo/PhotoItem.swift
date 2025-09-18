import Foundation
import Photos
import UIKit

// MARK: - PhotoItem Model
struct PhotoItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let asset: PHAsset?  // Optional for user-added photos
    let image: UIImage?
    let dateCreated: Date
    var isMarkedForDeletion = false
    var isMarkedForSaving = false

    // 사용자 추가 사진 관련 속성
    let isUserAdded: Bool
    let userAddedImage: UIImage?  // 사용자가 직접 추가한 이미지
    let userAddedDate: Date?      // 사용자가 추가한 날짜

    // 로컬 즐겨찾기 상태 (낙관적 업데이트용)
    var localFavoriteState: Bool?
    
    // MARK: - Computed Properties
    var isFavorite: Bool {
        return localFavoriteState ?? asset?.isFavorite ?? false
    }

    /// 표시할 이미지 (사용자 추가 이미지 우선)
    var displayImage: UIImage? {
        return isUserAdded ? userAddedImage : image
    }

    /// 실제 생성 날짜 (사용자 추가 날짜 우선)
    var actualDate: Date {
        return isUserAdded ? (userAddedDate ?? dateCreated) : dateCreated
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
    
    // MARK: - Initializers
    /// PHAsset 기반 PhotoItem 생성 (기존 방식)
    init(asset: PHAsset, image: UIImage?, dateCreated: Date) {
        self.asset = asset
        self.image = image
        self.dateCreated = dateCreated
        self.isUserAdded = false
        self.userAddedImage = nil
        self.userAddedDate = nil
    }

    /// 사용자 추가 PhotoItem 생성 (새로운 방식)
    init(userAddedImage: UIImage, userAddedDate: Date = Date()) {
        self.asset = nil
        self.image = nil
        self.dateCreated = userAddedDate
        self.isUserAdded = true
        self.userAddedImage = userAddedImage
        self.userAddedDate = userAddedDate
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
    /// 프리뷰용 PhotoItem 생성 (PHAsset 기반)
    static func createPreviewItem(
        image: UIImage?,
        dateCreated: Date,
        isFavorite: Bool = false
    ) -> PhotoItem {
        let dummyAsset = createDummyAsset()
        var item = PhotoItem(asset: dummyAsset, image: image, dateCreated: dateCreated)
        item.localFavoriteState = isFavorite
        return item
    }

    /// 프리뷰용 사용자 추가 PhotoItem 생성
    static func createPreviewUserAddedItem(
        image: UIImage,
        dateCreated: Date = Date()
    ) -> PhotoItem {
        return PhotoItem(userAddedImage: image, userAddedDate: dateCreated)
    }
    
    private static func createDummyAsset() -> PHAsset {
        // This is a workaround - in a real scenario, you would need a proper mock
        // For preview purposes, we'll use a placeholder approach
        // Note: This might need adjustment based on how PHAsset is used in the app
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        return fetchResult.firstObject ?? PHAsset() // Fallback to empty PHAsset
    }
}