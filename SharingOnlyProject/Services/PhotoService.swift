import Foundation
import Photos
import UIKit
import OSLog

// MARK: - Photo Filter Type
enum PhotoFilterType {
    case all           // 모든 사진 (기존 + 사용자 추가)
    case userAddedOnly // 사용자가 추가한 사진만
}

// MARK: - Simple and Reliable PhotoService
protocol PhotoServiceProtocol {
    func requestPhotoPermission() async -> Bool
    func loadPhotos(for date: Date, filter: PhotoFilterType) async -> [PhotoItem]
    func loadImage(for asset: PHAsset, context: ImageLoadContext) async -> UIImage?
    func toggleFavorite(for asset: PHAsset) async -> Bool
    func savePhotoToCameraRoll(_ asset: PHAsset) async -> Bool
    func deletePhoto(_ asset: PHAsset) async -> Bool

    // 사용자 추가 사진 관리
    func addUserPhoto(_ image: UIImage, date: Date) async -> PhotoItem
    func removeUserPhoto(_ photoItem: PhotoItem) async -> Bool
    func clearUserAddedPhotos() async
    func getUserAddedPhotos() async -> [PhotoItem]
}

enum ImageLoadContext {
    case thumbnail
    case fullscreen
}

final class PhotoService: PhotoServiceProtocol {
    private let imageManager = PHImageManager.default()

    // 사용자 추가 사진 임시 저장소 (세션 기반)
    private var userAddedPhotos: [PhotoItem] = []
    private let userPhotosQueue = DispatchQueue(label: "com.sharingapp.userPhotos", attributes: .concurrent)
    
    // MARK: - Permission Management
    func requestPhotoPermission() async -> Bool {
        Logger.photoService.logInfo("권한 요청 시작")

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        Logger.photoService.logInfo("현재 권한 상태: \(status.rawValue)")

        switch status {
        case .authorized, .limited:
            Logger.photoService.logSuccess("권한 이미 승인됨")
            return true
        case .notDetermined:
            Logger.photoService.logInfo("권한 결정되지 않음, 요청 중...")
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            Logger.photoService.logInfo("새로운 권한 상태: \(newStatus.rawValue)")
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            Logger.photoService.logError("권한 거부됨")
            return false
        @unknown default:
            Logger.photoService.logWarning("알 수 없는 권한 상태")
            return false
        }
    }
    
    // MARK: - Simple Photo Loading
    func loadPhotos(for date: Date, filter: PhotoFilterType = .all) async -> [PhotoItem] {
        Logger.photoService.logInfo("사진 로딩 시작: \(DateFormatter.photoTitle.string(from: date))")

        // 날짜 범위 설정
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            Logger.photoService.logError("날짜 계산 실패")
            return []
        }

        Logger.photoService.logDebug("검색 범위: \(startOfDay) ~ \(endOfDay)")

        // PHAsset 가져오기
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        Logger.photoService.logInfo("발견된 PHAsset 수: \(assets.count)")

        guard assets.count > 0 else {
            Logger.photoService.logInfo("선택한 날짜에 사진 없음")
            return []
        }

        // 순차적으로 이미지 로딩 (안정성 우선)
        var photoItems: [PhotoItem] = []

        for i in 0..<assets.count {
            let asset = assets.object(at: i)
            Logger.photoService.logDebug("이미지 \(i+1)/\(assets.count) 로딩 중... ID: \(asset.localIdentifier)")

            let image = await loadImageSimple(for: asset)
            let photoItem = PhotoItem(
                asset: asset,
                image: image,
                dateCreated: asset.creationDate ?? date
            )

            photoItems.append(photoItem)
            Logger.photoService.logDebug("이미지 \(i+1) 로딩 완료 - 성공: \(image != nil)")
        }

        Logger.photoService.logSuccess("기존 사진 로딩 완료: \(photoItems.count)장")

        // 필터 타입에 따른 결과 반환
        switch filter {
        case .all:
            // 기존 사진 + 사용자 추가 사진 (날짜 필터링)
            let userPhotos = await getUserAddedPhotosForDate(date)
            let allPhotos = photoItems + userPhotos
            let sortedPhotos = allPhotos.sorted { $0.actualDate > $1.actualDate }
            Logger.photoService.logSuccess("전체 로딩 완료: 기존 \(photoItems.count)장 + 사용자 추가 \(userPhotos.count)장")
            return sortedPhotos

        case .userAddedOnly:
            // 사용자가 추가한 사진만 (날짜 필터링)
            let userPhotos = await getUserAddedPhotosForDate(date)
            Logger.photoService.logSuccess("사용자 추가 사진만 로딩 완료: \(userPhotos.count)장")
            return userPhotos
        }
    }
    
    // MARK: - Public Image Loading
    func loadImage(for asset: PHAsset, context: ImageLoadContext) async -> UIImage? {
        let targetSize: CGSize
        let deliveryMode: PHImageRequestOptionsDeliveryMode
        
        switch context {
        case .thumbnail:
            targetSize = CGSize(width: 200, height: 200)
            deliveryMode = .opportunistic
        case .fullscreen:
            targetSize = PHImageManagerMaximumSize
            deliveryMode = .highQualityFormat
        }
        
        return await loadImageWithSize(for: asset, targetSize: targetSize, deliveryMode: deliveryMode)
    }
    
    // MARK: - Simple Image Loading
    private func loadImageSimple(for asset: PHAsset) async -> UIImage? {
        return await loadImageWithSize(for: asset, targetSize: CGSize(width: 200, height: 200), deliveryMode: .opportunistic)
    }
    
    private func loadImageWithSize(for asset: PHAsset, targetSize: CGSize, deliveryMode: PHImageRequestOptionsDeliveryMode) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.deliveryMode = deliveryMode

            Logger.photoService.logDebug("이미지 요청: \(asset.localIdentifier), 크기: \(targetSize)")

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // 에러 체크
                if let error = info?[PHImageErrorKey] as? Error {
                    Logger.photoService.logError("이미지 로딩 에러", error: error)
                    continuation.resume(returning: nil)
                    return
                }

                // 취소 체크
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    Logger.photoService.logWarning("이미지 로딩 취소됨")
                    continuation.resume(returning: nil)
                    return
                }

                // 최종 이미지인지 확인 (중요!)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                if !isDegraded {
                    // 최종 고품질 이미지만 반환
                    if let image = image {
                        Logger.photoService.logDebug("이미지 로딩 성공: \(image.size)")
                    } else {
                        Logger.photoService.logWarning("이미지가 nil")
                    }
                    continuation.resume(returning: image)
                } else {
                    // 중간 품질 이미지는 무시 (continuation을 resume하지 않음)
                    Logger.photoService.logDebug("중간 품질 이미지 수신됨, 최종 이미지 대기 중...")
                }
            }
        }
    }
    
    // MARK: - Photo Operations
    func toggleFavorite(for asset: PHAsset) async -> Bool {
        // Check if we have write permissions
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authorizationStatus == .authorized else {
            Logger.photoService.logError("Insufficient permissions to toggle favorite: \(authorizationStatus)")
            return false
        }

        let originalState = asset.isFavorite
        Logger.photoService.logInfo("즐겨찾기 토글: \(asset.localIdentifier) \(originalState) -> \(!originalState)")

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.isFavorite = !originalState
            } completionHandler: { success, error in
                if let error = error {
                    Logger.photoService.logError("즐겨찾기 변경 실패", error: error)
                } else if success {
                    Logger.photoService.logSuccess("즐겨찾기 변경 성공")
                } else {
                    Logger.photoService.logError("즐겨찾기 변경 실패 - 알 수 없는 이유")
                }
                continuation.resume(returning: success)
            }
        }
    }

    func savePhotoToCameraRoll(_ asset: PHAsset) async -> Bool {
        // This would typically be used for saving edited images
        // For now, we'll just return true as a placeholder
        Logger.photoService.logInfo("사진 저장 (현재는 플레이스홀더): \(asset.localIdentifier)")
        return true
    }

    func deletePhoto(_ asset: PHAsset) async -> Bool {
        // Check if we have write permissions
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authorizationStatus == .authorized else {
            Logger.photoService.logError("Insufficient permissions to delete photo: \(authorizationStatus)")
            return false
        }

        Logger.photoService.logInfo("사진 삭제 시작: \(asset.localIdentifier)")

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            } completionHandler: { success, error in
                if let error = error {
                    Logger.photoService.logError("사진 삭제 실패", error: error)
                } else if success {
                    Logger.photoService.logSuccess("사진 삭제 성공")
                } else {
                    Logger.photoService.logError("사진 삭제 실패 - 알 수 없는 이유")
                }
                continuation.resume(returning: success)
            }
        }
    }

    // MARK: - User Added Photos Management
    func addUserPhoto(_ image: UIImage, date: Date = Date()) async -> PhotoItem {
        return await withCheckedContinuation { continuation in
            userPhotosQueue.async(flags: .barrier) {
                let photoItem = PhotoItem(userAddedImage: image, userAddedDate: date)
                self.userAddedPhotos.append(photoItem)
                Logger.photoService.logSuccess("사용자 사진 추가됨: \(photoItem.id)")
                continuation.resume(returning: photoItem)
            }
        }
    }

    func removeUserPhoto(_ photoItem: PhotoItem) async -> Bool {
        return await withCheckedContinuation { continuation in
            userPhotosQueue.async(flags: .barrier) {
                if let index = self.userAddedPhotos.firstIndex(where: { $0.id == photoItem.id }) {
                    self.userAddedPhotos.remove(at: index)
                    Logger.photoService.logInfo("사용자 사진 제거됨: \(photoItem.id)")
                    continuation.resume(returning: true)
                } else {
                    Logger.photoService.logError("제거할 사용자 사진을 찾을 수 없음: \(photoItem.id)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func clearUserAddedPhotos() async {
        await withCheckedContinuation { continuation in
            userPhotosQueue.async(flags: .barrier) {
                let count = self.userAddedPhotos.count
                self.userAddedPhotos.removeAll()
                Logger.photoService.logInfo("모든 사용자 사진 제거됨: \(count)장")
                continuation.resume(returning: ())
            }
        }
    }

    func getUserAddedPhotos() async -> [PhotoItem] {
        return await withCheckedContinuation { continuation in
            userPhotosQueue.async {
                continuation.resume(returning: self.userAddedPhotos)
            }
        }
    }

    // MARK: - Private Helper Methods
    private func getUserAddedPhotosForDate(_ date: Date) async -> [PhotoItem] {
        let allUserPhotos = await getUserAddedPhotos()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return allUserPhotos.filter { photo in
            let photoDate = photo.actualDate
            return photoDate >= startOfDay && photoDate < endOfDay
        }.sorted { $0.actualDate > $1.actualDate }
    }
}

