//
//  SharingView.swift
//  SharingOnlyProject
//
//  Created by Claude on 8/5/25.
//

import SwiftUI
import Photos

/// 8방향 드래그 공유 시스템 메인 뷰
struct SharingView: View {
    @ObservedObject var photoViewModel: PhotoViewModel
    @ObservedObject var themeViewModel: ThemeViewModel
    @StateObject private var sharingViewModel = SharingViewModel()
    
    @State private var showingDatePicker = false
    @State private var currentStep: SharingStep = .dateSelection
    @State private var showingFullscreenPhoto = false
    @State private var selectedFullscreenPhoto: PhotoItem?
    @State private var selectedPhotoIndex = 0
    @State private var showingMultiPhotoPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingClearAllConfirmation = false
    @State private var photoToDelete: PhotoItem?

    // 배치 업로드 상태
    @State private var batchUploadProgress = 0
    @State private var batchUploadTotal = 0
    @State private var isBatchUploading = false
    
    @Environment(\.theme) private var theme
    
    enum SharingStep: CaseIterable {
        case dateSelection      // 1. 날짜 선택
        case recipientSetup     // 2. 공유 대상자 설정
        case photoDistribution  // 3. 사진 분배
        case albumPreview      // 4. 앨범 미리보기 및 공유
        
        var title: String {
            switch self {
            case .dateSelection: return "사진"
            case .recipientSetup: return "대상자 추가"
            case .photoDistribution: return "분배"
            case .albumPreview: return "공유"
            }
        }
        
        var subtitle: String {
            switch self {
            case .dateSelection: return "사진 확인"
            case .recipientSetup: return "사람 설정"
            case .photoDistribution: return "사진 분배"
            case .albumPreview: return "공유 실행"
            }
        }
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Content
                VStack(spacing: 0) {
                    // Progress Header
                    progressHeaderView
                    
                    Divider()
                        .opacity(0.3)
                    
                    // Step Content
                    stepContentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("PHOTO FLICK")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 16) {
                            // 달력 아이콘 (정리탭과 일관성) - 풀스크린에서 비활성화
                            Button(action: {
                                // 풀스크린 모드에서는 달력 선택 금지
                                if !showingFullscreenPhoto {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingDatePicker.toggle()
                                    }
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(showingFullscreenPhoto ? theme.secondaryText.opacity(0.5) : theme.accentColor)
                            }
                            .disabled(showingFullscreenPhoto)  // 풀스크린 모드에서 비활성화
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            // 모든 추가 사진 삭제 버튼 (필터가 userAddedOnly일 때만)
                            if !showingFullscreenPhoto && photoViewModel.currentFilter == .userAddedOnly &&
                               !photoViewModel.photos.isEmpty && currentStep == .dateSelection {
                                Button(action: {
                                    showingClearAllConfirmation = true
                                }) {
                                    Image(systemName: "trash.circle")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.red)
                                }
                            }

                            // 필터 토글 버튼
                            if !showingFullscreenPhoto {
                                Button(action: {
                                    let newFilter: PhotoFilterType = photoViewModel.currentFilter == .all ? .userAddedOnly : .all
                                    photoViewModel.send(.setFilter(newFilter))
                                }) {
                                    Image(systemName: photoViewModel.currentFilter == .all ? "photo.badge.plus.fill" : "calendar.and.person")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(theme.accentColor)
                                }
                            }

                            // 사진 추가 버튼
                            if !showingFullscreenPhoto && currentStep == .dateSelection {
                                Button(action: {
                                    showingMultiPhotoPicker = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(theme.accentColor)
                                }
                            }
                        }
                    }
                }
                .background(theme.primaryBackground.ignoresSafeArea())
                
                // Overlay Date Picker - 풀스크린 모드에서 비활성화
                if showingDatePicker && !showingFullscreenPhoto {
                    OverlayDatePicker(
                        selectedDate: $photoViewModel.selectedDate,
                        isPresented: $showingDatePicker,
                        onDateSelected: {
                            Task {
                                await sharingViewModel.sendAsync(.createSession(photoViewModel.selectedDate))
                            }
                        }
                    )
                    .zIndex(1000)
                }
                
                // Fullscreen Photo Viewer
                if showingFullscreenPhoto {
                    FullscreenPhotoViewer(
                        photos: photoViewModel.photos,
                        initialIndex: selectedPhotoIndex,
                        isPresented: $showingFullscreenPhoto,
                        photoService: PhotoService() // 고화질 로딩용
                    )
                    .zIndex(2000)
                }

                // Direct Multi Photo Picker
                if showingMultiPhotoPicker {
                    if #available(iOS 14.0, *) {
                        MultiPhotoPickerView(
                            isPresented: $showingMultiPhotoPicker,
                            selectionLimit: 0, // 무제한 선택
                            onPhotosSelected: { images in
                                handleMultiplePhotosSelected(images)
                            }
                        )
                    }
                }

                // Batch Upload Progress Toast
                VStack {
                    BatchProgressToast(
                        currentIndex: batchUploadProgress,
                        totalCount: batchUploadTotal,
                        isVisible: isBatchUploading
                    )
                    .padding(.top, 10)

                    Spacer()
                }
                .zIndex(1700)
            }
        }
        .alert("사진 삭제", isPresented: $showingDeleteConfirmation) {
            Button("취소", role: .cancel) {
                photoToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let photo = photoToDelete {
                    photoViewModel.send(.removeUserPhoto(photo))
                }
                photoToDelete = nil
            }
        } message: {
            Text("이 사진을 삭제하시겠습니까?")
        }
        .alert("모든 추가 사진 삭제", isPresented: $showingClearAllConfirmation) {
            Button("취소", role: .cancel) { }
            Button("모두 삭제", role: .destructive) {
                photoViewModel.send(.clearUserPhotos)
            }
        } message: {
            Text("추가한 모든 사진을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
        .onAppear {
            setupInitialState()
            // 공유 모드 활성화
            photoViewModel.send(.setSharingMode(true))
        }
        .onDisappear {
            // 공유 뷰에서 나갈 때 공유 모드 비활성화
            photoViewModel.send(.setSharingMode(false))
        }
        .onChange(of: photoViewModel.selectedDate) { oldValue, newValue in
            Task {
                // 사진 로딩
                await photoViewModel.sendAsync(.changeDate(newValue))
                // 공유 세션 생성
                await sharingViewModel.sendAsync(.createSession(newValue))
            }
        }
    }
    
    // MARK: - Progress Header (간소화됨)
    private var progressHeaderView: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(Array(SharingStep.allCases.enumerated()), id: \.offset) { index, step in
                    Circle()
                        .fill(index <= SharingStep.allCases.firstIndex(of: currentStep)! ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.buttonBorder.opacity(0.3)))
                        .frame(width: 8, height: 8)
                    
                    if index < SharingStep.allCases.count - 1 {
                        Rectangle()
                            .fill(index < SharingStep.allCases.firstIndex(of: currentStep)! ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.buttonBorder.opacity(0.3)))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Step info (간소화)
            HStack {
                Text(currentStep.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text(stepCompletionInfo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(canProceedToNext ? theme.accentColor : theme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(canProceedToNext ? AnyShapeStyle(theme.accentColor.opacity(0.1)) : AnyShapeStyle(theme.secondaryBackground))
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(theme.primaryBackground)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case .dateSelection:
            dateSelectionView
            
        case .recipientSetup:
            recipientSetupView
            
        case .photoDistribution:
            photoDistributionView
            
        case .albumPreview:
            albumPreviewView
        }
    }
    
    private var dateSelectionView: some View {
        VStack(spacing: 16) {
            // 사진 그리드 뷰 (상태 표시 제거, 상단 헤더에서 처리)
            if !photoViewModel.photos.isEmpty {
                photoGridView
            } else if photoViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(theme.accentColor)
                    
                    Text("사진 확인 중...")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 빈 상태 표시 (필터별 맞춤 메시지)
                emptyStateView
            }
            
            Spacer()
            
            // 하단 네비게이션 버튼
            bottomNavigationButtons
        }
    }
    
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5),
                spacing: 8
            ) {
                ForEach(Array(photoViewModel.photos.enumerated()), id: \.element.id) { index, photo in
                    photoGridItem(photo: photo, index: index)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func photoGridItem(photo: PhotoItem, index: Int) -> some View {
        Group {
            if let image = photo.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        // 사용자 추가 사진 삭제 버튼
                        Group {
                            if photo.isUserAdded {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            photoToDelete = photo
                                            showingDeleteConfirmation = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.red.opacity(0.6))
                                                        .frame(width: 20, height: 20)
                                                )
                                        }
                                        .padding(4)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                    .onTapGesture {
                        selectedPhotoIndex = index
                        selectedFullscreenPhoto = photo
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFullscreenPhoto = true
                        }
                    }
            } else {
                // 더미 이미지 또는 로딩 플레이스홀더
                if let dummyImage = DummyImageGenerator.generatePhoto(index: index, size: CGSize(width: 65, height: 65)) {
                    Image(uiImage: dummyImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 65, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(0.7) // Make it slightly transparent to indicate it's a placeholder
                        .overlay(
                            // Add a small indicator that this is dummy content
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("더미")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                        .padding(6)
                                }
                            }
                        )
                        .onTapGesture {
                            selectedPhotoIndex = index
                            selectedFullscreenPhoto = photo
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFullscreenPhoto = true
                            }
                        }
                } else {
                    // Fallback to loading placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.secondaryBackground)
                        .frame(width: 65, height: 65)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(theme.accentColor)
                        )
                        .onAppear {
                            // 이미지 로딩 트리거
                            Task {
                                await photoViewModel.sendAsync(.loadPhotos(for: photoViewModel.selectedDate))
                            }
                        }
                }
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var recipientSetupView: some View {
        VStack(spacing: 20) {
            // RecipientSetupView - 메인 컨텐츠 (상단 안내 제거, 헤더에서 처리)
            RecipientSetupView(sharingViewModel: sharingViewModel)
            
            Spacer()
            
            // 하단 네비게이션 버튼
            bottomNavigationButtons
        }
    }
    
    private var photoDistributionView: some View {
        VStack(spacing: 20) {
            // DirectionalDragView - 메인 컨텐츠 (부가설명 제거, 상단 헤더에서 처리)
            DirectionalDragView(
                sharingViewModel: sharingViewModel,
                photoViewModel: photoViewModel
            )
            
            Spacer()
            
            // 하단 네비게이션 버튼
            bottomNavigationButtons
        }
    }
    
    private var albumPreviewView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // TemporaryAlbumPreview - 메인 컨텐츠
            TemporaryAlbumPreview(sharingViewModel: sharingViewModel)
            
            Spacer()
            
            // Reset button - 하단 고정 (44pt 최소 높이 보장)
            Button("새로 시작하기") {
                resetSharingSession()
            }
            .fontWeight(.medium)
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 44) // HIG 기준 보장
            .padding(.vertical, 14) // 더 큰 패딩
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.buttonBorder.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .contentShape(Rectangle()) // 전체 영역 터치 가능
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigationButtons: some View {
        HStack(spacing: 16) {
            // 이전 버튼
            if currentStep != .dateSelection {
                Button(action: {
                    goToPreviousStep()
                }) {
                    Text("이전")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.secondaryBackground.opacity(1.5))
                        )
                }
                .buttonStyle(PlainButtonStyle()) // 버튼 스타일은 그대로 유지
            }
            
            // 다음 버튼 또는 기능별 버튼
            if canProceedToNext {
                Button(action: {
                    goToNextStep()
                }) {
                    Text(nextButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .dateSelection:
            return "다음"
        case .recipientSetup:
            return "사진 분배 시작"
        case .photoDistribution:
            return "공유 앨범 확인하기"
        case .albumPreview:
            return "완료"
        }
    }

    // MARK: - Navigation Logic
    private var canProceedToNext: Bool {
        switch currentStep {
        case .dateSelection:
            return !photoViewModel.photos.isEmpty
        case .recipientSetup:
            return !sharingViewModel.recipients.isEmpty
        case .photoDistribution:
            return sharingViewModel.getTotalPhotosDistributed() > 0
        case .albumPreview:
            return false
        }
    }
    
    private var stepCompletionInfo: String {
        switch currentStep {
        case .dateSelection:
            if photoViewModel.isLoading {
                return "확인 중..."
            } else if photoViewModel.photos.isEmpty {
                return "사진 없음"
            } else {
                return photoViewModel.photoCountInfo
            }
        case .recipientSetup:
            if sharingViewModel.recipients.isEmpty {
                return "대상자 없음"
            } else {
                return "\(sharingViewModel.recipients.count)명 설정됨"
            }
        case .photoDistribution:
            let distributed = sharingViewModel.getTotalPhotosDistributed()
            if distributed == 0 {
                return sharingViewModel.recipients.isEmpty ? "대상자 설정 필요" : "드래그로 분배"
            } else {
                return "\(distributed)장 완료"
            }
        case .albumPreview:
            return sharingViewModel.canStartSharing ? "준비 완료" : "분배 필요"
        }
    }
    
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dateSelection:
                currentStep = .recipientSetup
            case .recipientSetup:
                currentStep = .photoDistribution
            case .photoDistribution:
                currentStep = .albumPreview
            case .albumPreview:
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dateSelection:
                break
            case .recipientSetup:
                currentStep = .dateSelection
            case .photoDistribution:
                currentStep = .recipientSetup
            case .albumPreview:
                currentStep = .photoDistribution
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.5))

            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                Text(emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State Content
    private var emptyStateIcon: String {
        switch photoViewModel.currentFilter {
        case .all:
            return "photo.on.rectangle"
        case .userAddedOnly:
            return "calendar.and.person"
        }
    }

    private var emptyStateTitle: String {
        switch photoViewModel.currentFilter {
        case .all:
            return "선택한 날짜에 사진이 없습니다"
        case .userAddedOnly:
            return "추가된 사진이 없습니다"
        }
    }

    private var emptyStateSubtitle: String {
        switch photoViewModel.currentFilter {
        case .all:
            return "다른 날짜를 선택하거나\n새 사진을 추가해보세요"
        case .userAddedOnly:
            return "새 사진을 추가해보세요"
        }
    }

    private func setupInitialState() {
        Task {
            // 권한 요청 및 사진 로딩
            await photoViewModel.sendAsync(.requestPermission)
            // 공유 세션 생성
            await sharingViewModel.sendAsync(.createSession(photoViewModel.selectedDate))
        }
    }
    
    private func resetSharingSession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .dateSelection
        }
        
        Task {
            await sharingViewModel.sendAsync(.clearSession)
            await sharingViewModel.sendAsync(.createSession(photoViewModel.selectedDate))
        }
    }

    // MARK: - Multiple Photos Handling
    private func handleMultiplePhotosSelected(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        print("📷 다중 사진 선택됨: \(images.count)장")

        // 배치 업로드 상태 초기화
        batchUploadProgress = 0
        batchUploadTotal = images.count
        isBatchUploading = true

        // 진행 상태 콜백과 함께 배치 처리 시작
        photoViewModel.send(.processBatchPhotoUpload(images, photoViewModel.selectedDate) { progress, total in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    batchUploadProgress = progress
                    batchUploadTotal = total

                    // 완료 시 UI 상태 리셋
                    if progress >= total {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isBatchUploading = false
                                batchUploadProgress = 0
                                batchUploadTotal = 0
                            }
                        }
                    }
                }
            }
        })
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    // Create preview view models with dummy data
    let previewPhotoViewModel = PreviewData.createPreviewPhotoViewModel()
    let previewThemeViewModel = PreviewData.createPreviewThemeViewModel()
    
    return SharingView(
        photoViewModel: previewPhotoViewModel,
        themeViewModel: previewThemeViewModel
    )
    .environment(\.theme, PreviewData.sampleThemeColors)
    .onAppear {
        // Note: In actual implementation, you would inject preview photos
        // into the photo view model for better preview experience
    }
}
