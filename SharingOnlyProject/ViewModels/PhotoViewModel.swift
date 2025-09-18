import Foundation
import Photos
import UIKit
import Combine

// MARK: - PhotoViewModel State
struct PhotoViewModelState: LoadableStateProtocol {
    var photos: [PhotoItem] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isSharingMode: Bool = false
    var currentFilter: PhotoFilterType = .all
}

// MARK: - PhotoViewModel Actions
enum PhotoViewModelAction {
    case loadPhotos(for: Date)
    case toggleFavorite(PhotoItem)
    case markForDeletion(PhotoItem)
    case markForSaving(PhotoItem)
    case changeDate(Date)
    case requestPermission
    case processMarkedPhotos
    case clearMarks(PhotoItem)
    case clearAllMarks
    case setSharingMode(Bool)

    // 새로운 기능
    case setFilter(PhotoFilterType)
    case addUserPhoto(UIImage, Date?)
    case removeUserPhoto(PhotoItem)
    case clearUserPhotos

    // 배치 처리 기능
    case addMultipleUserPhotos([UIImage], Date?)
    case processBatchPhotoUpload([UIImage], Date?, (Int, Int) -> Void)
}

// MARK: - PhotoViewModel
@MainActor
final class PhotoViewModel: ViewModelProtocol {
    typealias State = PhotoViewModelState
    typealias Action = PhotoViewModelAction
    
    @Published private(set) var state = PhotoViewModelState()
    @Published var selectedDate: Date = Date()
    
    private let photoService: PhotoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var photos: [PhotoItem] { state.photos }
    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var isSharingMode: Bool { state.isSharingMode }
    var currentFilter: PhotoFilterType { state.currentFilter }

    /// 현재 필터에 따른 사진 개수 정보
    var photoCountInfo: String {
        switch currentFilter {
        case .all:
            let userAddedCount = photos.filter { $0.isUserAdded }.count
            let deviceCount = photos.count - userAddedCount
            return "전체 \(photos.count)장 (기기: \(deviceCount), 추가: \(userAddedCount))"
        case .userAddedOnly:
            return "내가 추가한 \(photos.count)장"
        }
    }
    
    /// 공유 모드에서는 복제/삭제 등의 위험한 작업을 제한
    var canModifyPhotos: Bool { !state.isSharingMode }
    
    // MARK: - Initialization
    init(photoService: PhotoServiceProtocol = PhotoService()) {
        self.photoService = photoService
        setupBindings()
    }
    
    // MARK: - Public Interface
    func send(_ action: Action) {
        Task { @MainActor in
            await handleAction(action)
        }
    }
    
    func sendAsync(_ action: Action) async {
        await handleAction(action)
    }
    
    // MARK: - Action Handling
    private func handleAction(_ action: Action) async {
        switch action {
        case .requestPermission:
            await requestPhotoPermission()
            
        case .loadPhotos(let date):
            await loadPhotos(for: date)
            
        case .changeDate(let date):
            await changeSelectedDate(date)
            
        case .toggleFavorite(let photo):
            await toggleFavorite(photo)
            
        case .markForDeletion(let photo):
            await markPhotoForDeletion(photo)
            
        case .markForSaving(let photo):
            await markPhotoForSaving(photo)
            
        case .processMarkedPhotos:
            await processMarkedPhotos()
            
        case .clearMarks(let photo):
            await clearMarks(photo)
            
        case .clearAllMarks:
            await clearAllMarks()
            
        case .setSharingMode(let isSharing):
            await setSharingMode(isSharing)

        case .setFilter(let filter):
            await setFilter(filter)

        case .addUserPhoto(let image, let date):
            await addUserPhoto(image, date: date)

        case .removeUserPhoto(let photoItem):
            await removeUserPhoto(photoItem)

        case .clearUserPhotos:
            await clearUserPhotos()

        case .addMultipleUserPhotos(let images, let date):
            await addMultipleUserPhotos(images, date: date)

        case .processBatchPhotoUpload(let images, let date, let progressCallback):
            await processBatchPhotoUpload(images, date: date, progressCallback: progressCallback)
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Setup any additional bindings if needed
    }
    
    private func requestPhotoPermission() async {
        let hasPermission = await photoService.requestPhotoPermission()
        if hasPermission {
            await loadPhotos(for: selectedDate)
        } else {
            state.errorMessage = "사진 라이브러리 접근 권한이 필요합니다."
        }
    }
    
    private func loadPhotos(for date: Date) async {
        state.isLoading = true
        state.errorMessage = nil

        let photos = await photoService.loadPhotos(for: date, filter: state.currentFilter)
        state.photos = photos
        state.isLoading = false
    }
    
    private func changeSelectedDate(_ date: Date) async {
        selectedDate = date
        await loadPhotos(for: date)
    }
    
    private func toggleFavorite(_ photo: PhotoItem) async {
        print("💖 즐겨찾기 토글 시작: \(photo.id), 현재 상태: \(photo.isFavorite)")

        // 사용자 추가 사진은 즐겨찾기 기능을 지원하지 않음
        guard !photo.isUserAdded, let asset = photo.asset else {
            print("❌ 사용자 추가 사진은 즐겨찾기를 지원하지 않습니다")
            state.errorMessage = "사용자 추가 사진은 즐겨찾기를 지원하지 않습니다"
            return
        }

        // Find photo index
        guard let index = state.photos.firstIndex(where: { $0.id == photo.id }) else {
            print("❌ 사진을 찾을 수 없습니다: \(photo.id)")
            return
        }

        let originalState = photo.isFavorite
        let newState = !originalState

        // 1. Optimistic update with immediate UI feedback
        state.photos[index].localFavoriteState = newState
        print("⚡ 낙관적 업데이트: \(originalState) -> \(newState)")

        // 2. Perform actual PHAsset update
        let success = await photoService.toggleFavorite(for: asset)
        
        if success {
            print("✅ 즐겨찾기 성공: \(photo.id) -> \(newState)")
            
            // Wait a bit for PHAsset to update, then clear local state
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            if index < state.photos.count {
                state.photos[index].localFavoriteState = nil
                
                // Force a UI refresh by creating a new array
                let updatedPhotos = state.photos
                state.photos = updatedPhotos
                
                print("🔄 UI 새로 고침 완료")
            }
            
            // Clear any error messages
            state.errorMessage = nil
            
        } else {
            print("❌ 즐겨찾기 실패: \(photo.id)")
            
            // Rollback optimistic update
            if index < state.photos.count {
                state.photos[index].localFavoriteState = originalState
            }
            
            state.errorMessage = "즐겨찾기 변경에 실패했습니다. 다시 시도해 주세요."
            
            // Clear error message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if state.errorMessage?.contains("즐겨찾기") == true {
                    state.errorMessage = nil
                }
            }
        }
    }
    
    private func markPhotoForDeletion(_ photo: PhotoItem) async {
        // 공유 모드에서는 삭제 기능 제한
        guard !state.isSharingMode else {
            print("🔒 공유 모드에서는 사진을 삭제할 수 없습니다")
            state.errorMessage = "공유 모드에서는 사진을 삭제할 수 없습니다"
            return
        }
        
        // 순수하게 마킹만 수행 - 실제 삭제는 processMarkedPhotos에서
        if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
            state.photos[index].isMarkedForDeletion = true
            state.photos[index].isMarkedForSaving = false // 상호 배타적
            print("📋 사진 삭제 마킹: \(photo.id)")
        }
    }
    
    private func markPhotoForSaving(_ photo: PhotoItem) async {
        // 공유 모드에서는 보관(복제) 기능 제한
        guard !state.isSharingMode else {
            print("🔒 공유 모드에서는 사진을 보관할 수 없습니다")
            state.errorMessage = "공유 모드에서는 사진을 보관할 수 없습니다"
            return
        }
        
        // 실제 사진앱처럼 보관은 단순히 마킹만 (실제 작업 없음)
        if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
            state.photos[index].isMarkedForSaving = true
            state.photos[index].isMarkedForDeletion = false // 상호 배타적
            print("💚 사진 보관 마킹: \(photo.id) - 실제 복제 없음")
        }
    }
    
    // MARK: - Additional Actions
    private func processMarkedPhotos() async {
        print("🔄 배치 처리 시작...")
        
        let photosToDelete = state.photos.filter { $0.isMarkedForDeletion }
        let photosToSave = state.photos.filter { $0.isMarkedForSaving }
        
        var deletedCount = 0
        var savedCount = 0
        
        // 삭제 마킹된 사진들 실제 삭제
        for photo in photosToDelete {
            // 사용자 추가 사진은 직접 제거, PHAsset 사진은 시스템 삭제
            if photo.isUserAdded {
                let success = await photoService.removeUserPhoto(photo)
                if success {
                    state.photos.removeAll { $0.id == photo.id }
                    deletedCount += 1
                    print("🗑️ 사용자 사진 삭제 완료: \(photo.id)")
                } else {
                    // 실패 시 마킹 해제
                    if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
                        state.photos[index].isMarkedForDeletion = false
                    }
                    print("❌ 사용자 사진 삭제 실패: \(photo.id)")
                }
            } else if let asset = photo.asset {
                let success = await photoService.deletePhoto(asset)
                if success {
                    state.photos.removeAll { $0.id == photo.id }
                    deletedCount += 1
                    print("🗑️ 라이브러리 사진 삭제 완료: \(photo.id)")
                } else {
                    // 실패 시 마킹 해제
                    if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
                        state.photos[index].isMarkedForDeletion = false
                    }
                    print("❌ 라이브러리 사진 삭제 실패: \(photo.id)")
                }
            } else {
                print("❌ 삭제할 수 없는 사진: \(photo.id) - asset 없음")
                if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
                    state.photos[index].isMarkedForDeletion = false
                }
            }
        }
        
        // 보관 마킹된 사진들 - 실제로는 아무 작업도 하지 않음 (실제 사진앱처럼)
        for photo in photosToSave {
            if state.photos.firstIndex(where: { $0.id == photo.id }) != nil {
                // 마킹만 유지하고 실제 복제는 하지 않음
                savedCount += 1
                print("💚 사진 보관 처리 완료: \(photo.id) - 복제 없이 마킹만 유지")
            }
        }
        
        // 결과 메시지 설정
        var resultMessages: [String] = []
        if deletedCount > 0 { resultMessages.append("\(deletedCount)개 삭제") }
        if savedCount > 0 { resultMessages.append("\(savedCount)개 보관") }
        
        if !resultMessages.isEmpty {
            print("✅ 배치 처리 완료: \(resultMessages.joined(separator: ", "))")
        }
    }
    
    private func clearMarks(_ photo: PhotoItem) async {
        if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
            state.photos[index].isMarkedForDeletion = false
            state.photos[index].isMarkedForSaving = false
        }
    }
    
    private func clearAllMarks() async {
        for i in 0..<state.photos.count {
            state.photos[i].isMarkedForDeletion = false
            state.photos[i].isMarkedForSaving = false
        }
    }
    
    private func setSharingMode(_ isSharing: Bool) async {
        state.isSharingMode = isSharing
        
        if isSharing {
            print("🔒 공유 모드 활성화: 사진 조작 기능 제한됨")
            // 공유 모드에서는 기존 마킹된 사진들 초기화
            await clearAllMarks()
        } else {
            print("🔓 일반 모드 활성화: 사진 조작 기능 활성화됨")
        }
    }

    // MARK: - New Filter and User Photo Methods
    private func setFilter(_ filter: PhotoFilterType) async {
        let oldFilter = state.currentFilter
        state.currentFilter = filter

        print("🔍 필터 변경: \(oldFilter) -> \(filter)")

        // 필터가 변경되면 현재 날짜로 다시 로딩
        await loadPhotos(for: selectedDate)
    }

    private func addUserPhoto(_ image: UIImage, date: Date?) async {
        let photoDate = date ?? selectedDate
        let photoItem = await photoService.addUserPhoto(image, date: photoDate)

        print("📷 사용자 사진 추가: \(photoItem.id)")

        // 현재 필터와 날짜에 맞는 사진이면 목록에 추가
        let calendar = Calendar.current
        let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
        let photoStartDay = calendar.startOfDay(for: photoDate)

        if startOfSelectedDay == photoStartDay {
            // 같은 날짜이고, 현재 필터에 포함되는 사진이면 추가
            switch state.currentFilter {
            case .all, .userAddedOnly:
                // 최신 순으로 정렬하여 맨 앞에 삽입
                state.photos.insert(photoItem, at: 0)
            }
        }
    }

    private func removeUserPhoto(_ photoItem: PhotoItem) async {
        guard photoItem.isUserAdded else {
            print("❌ 기존 사진은 제거할 수 없습니다: \(photoItem.id)")
            return
        }

        let success = await photoService.removeUserPhoto(photoItem)
        if success {
            state.photos.removeAll { $0.id == photoItem.id }
            print("🗑️ 사용자 사진 제거 완료: \(photoItem.id)")
        } else {
            print("❌ 사용자 사진 제거 실패: \(photoItem.id)")
            state.errorMessage = "사진 제거에 실패했습니다."
        }
    }

    private func clearUserPhotos() async {
        await photoService.clearUserAddedPhotos()

        // 현재 표시된 사진 중 사용자 추가 사진들만 제거
        state.photos.removeAll { $0.isUserAdded }

        print("🧹 모든 사용자 사진 제거 완료")
    }

    // MARK: - Batch Processing Methods
    private func addMultipleUserPhotos(_ images: [UIImage], date: Date?) async {
        let photoDate = date ?? selectedDate

        print("📷 배치 사진 추가 시작: \(images.count)장")

        for (index, image) in images.enumerated() {
            let photoItem = await photoService.addUserPhoto(image, date: photoDate)

            // 현재 날짜와 필터에 맞는 사진이면 목록에 추가
            let calendar = Calendar.current
            let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
            let photoStartDay = calendar.startOfDay(for: photoDate)

            if startOfSelectedDay == photoStartDay {
                switch state.currentFilter {
                case .all, .userAddedOnly:
                    state.photos.insert(photoItem, at: 0)
                }
            }

            print("📷 사진 \(index + 1)/\(images.count) 추가됨: \(photoItem.id)")
        }

        print("🎉 배치 사진 추가 완료: \(images.count)장")
    }

    private func processBatchPhotoUpload(
        _ images: [UIImage],
        date: Date?,
        progressCallback: @escaping (Int, Int) -> Void
    ) async {
        let photoDate = date ?? selectedDate
        let batchSize = 3 // 메모리 관리를 위한 배치 크기

        print("📷 배치 업로드 시작: \(images.count)장 (배치 크기: \(batchSize))")

        var processedCount = 0

        // 배치 단위로 처리
        for batch in images.chunked(into: batchSize) {
            await withTaskGroup(of: PhotoItem?.self) { group in
                for image in batch {
                    group.addTask {
                        await self.photoService.addUserPhoto(image, date: photoDate)
                    }
                }

                for await photoItem in group {
                    if let item = photoItem {
                        // UI 업데이트
                        let calendar = Calendar.current
                        let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
                        let photoStartDay = calendar.startOfDay(for: photoDate)

                        if startOfSelectedDay == photoStartDay {
                            switch state.currentFilter {
                            case .all, .userAddedOnly:
                                state.photos.insert(item, at: 0)
                            }
                        }

                        processedCount += 1
                        progressCallback(processedCount, images.count)

                        print("📷 배치 처리: \(processedCount)/\(images.count)")
                    }
                }
            }

            // 메모리 압박 방지를 위한 짧은 지연
            if processedCount < images.count {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }
        }

        print("🎉 배치 업로드 완료: \(processedCount)장")
    }
}

// MARK: - Array Extension for Batch Processing
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}