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
    // MARK: - Constants
    private enum Constants {
        static let gridSpacing: CGFloat = 4
        static let gridPadding: CGFloat = 16
        static let buttonSpacing: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
        static let buttonVerticalPadding: CGFloat = 16
        static let animationDuration: Double = 0.3
        static let batchCompleteDelay: Double = 1.0
    }

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
            case .dateSelection: return LocalizedString.Steps.dateSelection
            case .recipientSetup: return LocalizedString.Steps.recipientSetup
            case .photoDistribution: return LocalizedString.Steps.photoDistribution
            case .albumPreview: return LocalizedString.Steps.albumPreview
            }
        }

        var subtitle: String {
            switch self {
            case .dateSelection: return LocalizedString.Steps.dateSelectionSubtitle
            case .recipientSetup: return LocalizedString.Steps.recipientSetupSubtitle
            case .photoDistribution: return LocalizedString.Steps.photoDistributionSubtitle
            case .albumPreview: return LocalizedString.Steps.albumPreviewSubtitle
            }
        }
        
    }
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // iPad에서 더 많은 컬럼 표시
    private var gridColumnCount: Int {
        horizontalSizeClass == .regular ? 8 : 5
    }

    // iPad에서 더 큰 사진 크기
    private var photoItemSize: CGFloat {
        horizontalSizeClass == .regular ? 80 : 65
    }

    // 동적 네비게이션 타이틀 (현재 단계만 표시)
    private var dynamicNavigationTitle: String {
        switch currentStep {
        case .dateSelection:
            return "사진 선택"
        case .recipientSetup:
            return "공유 대상자"
        case .photoDistribution:
            return "사진 분배"
        case .albumPreview:
            return "미리보기"
        }
    }

    // 테마별 툴바 색상 설정
    private var toolbarColorScheme: ColorScheme {
        switch themeViewModel.currentTheme {
        case .spring:
            // Golden Hour: 밝은 배경이므로 어두운 텍스트
            return .light
        case .auto:
            // 자동 테마: 시스템 설정에 따라 반대로
            return .light
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                // Progress Header
                progressHeaderView

                Divider()
                    .opacity(0.3)

                // Step Content
                stepContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(themeViewModel.colors.primaryBackground)
            .navigationTitle(dynamicNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(showingFullscreenPhoto)
            .toolbarBackground(themeViewModel.colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(toolbarColorScheme, for: .navigationBar)
            .toolbar(showingFullscreenPhoto ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 16) {
                            // 달력 아이콘 (정리탭과 일관성) - 풀스크린에서 비활성화
                            Button(action: {
                                withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                                    showingDatePicker.toggle()
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .toolbarIconButton(theme: theme)
                            }
                            .accessibilityLabel(LocalizedString.Accessibility.selectDate)
                            .accessibilityHint(LocalizedString.Accessibility.selectDateHint)
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            // 모든 추가 사진 삭제 버튼 (필터가 userAddedOnly일 때만)
                            if photoViewModel.currentFilter == .userAddedOnly &&
                               !photoViewModel.photos.isEmpty && currentStep == .dateSelection {
                                Button(action: {
                                    showingClearAllConfirmation = true
                                }) {
                                    Image(systemName: "trash.circle")
                                        .toolbarIconButton(size: 16, theme: themeViewModel.colors)
                                }
                                .accessibilityLabel(LocalizedString.Accessibility.deleteAllPhotos)
                                .accessibilityHint(LocalizedString.Accessibility.deleteAllPhotosHint)
                            }

                            // 필터 토글 버튼
                                Button(action: {
                                    let newFilter: PhotoFilterType = photoViewModel.currentFilter == .all ? .userAddedOnly : .all
                                    photoViewModel.send(.setFilter(newFilter))
                                }) {
                                    Image(systemName: photoViewModel.currentFilter == .all ? "photo.badge.plus.fill" : "calendar.and.person")
                                        .toolbarIconButton(size: 16, theme: theme)
                                }
                                .accessibilityLabel(photoViewModel.currentFilter == .all ? LocalizedString.Accessibility.showAddedPhotos : LocalizedString.Accessibility.showAllPhotos)
                                .accessibilityHint(LocalizedString.Accessibility.toggleFilterHint)

                            // 사진 추가 버튼
                            if currentStep == .dateSelection {
                                Button(action: {
                                    showingMultiPhotoPicker = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .toolbarIconButton(theme: theme)
                                }
                                .accessibilityLabel(LocalizedString.Accessibility.addPhoto)
                                .accessibilityHint(LocalizedString.Accessibility.addPhotoHint)
                            }
                        }
                    }
                }

                // Overlay Date Picker
                if showingDatePicker {
                    OverlayDatePicker(
                        selectedDate: $photoViewModel.selectedDate,
                        isPresented: $showingDatePicker,
                        onDateSelected: {
                            Task {
                                // 사진 로딩
                                await photoViewModel.sendAsync(.changeDate(photoViewModel.selectedDate))
                                // 공유 세션 생성
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
        .alert(LocalizedString.Alert.deletePhoto, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedString.General.cancel, role: .cancel) {
                photoToDelete = nil
            }
            Button(LocalizedString.General.delete, role: .destructive) {
                if let photo = photoToDelete {
                    photoViewModel.send(.removeUserPhoto(photo))
                }
                photoToDelete = nil
            }
        } message: {
            Text(LocalizedString.Alert.deletePhotoMessage)
        }
        .alert(LocalizedString.Alert.deleteAllPhotos, isPresented: $showingClearAllConfirmation) {
            Button(LocalizedString.General.cancel, role: .cancel) { }
            Button(LocalizedString.Alert.deleteAllAction, role: .destructive) {
                photoViewModel.send(.clearUserPhotos)
            }
        } message: {
            Text(LocalizedString.Alert.deleteAllPhotosMessage)
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
                    
                    Text(LocalizedString.Photo.checking)
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
                columns: Array(repeating: GridItem(.flexible(), spacing: Constants.gridSpacing), count: gridColumnCount),
                spacing: Constants.gridSpacing * 2
            ) {
                ForEach(Array(photoViewModel.photos.enumerated()), id: \.element.id) { index, photo in
                    photoGridItem(photo: photo, index: index)
                }
            }
            .padding(.horizontal, Constants.gridPadding)
        }
    }
    
    @ViewBuilder
    private func photoGridItem(photo: PhotoItem, index: Int) -> some View {
        Group {
            if let image = photo.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoItemSize, height: photoItemSize)
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
                                                .foregroundColor(themeViewModel.colors.primaryText)
                                                .background(
                                                    Circle()
                                                        .fill(themeViewModel.colors.deleteColor)
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
                        .frame(width: photoItemSize, height: photoItemSize)
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
                                    Text(LocalizedString.Photo.dummy)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeViewModel.colors.primaryText)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(themeViewModel.colors.overlayBackground)
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
                        .frame(width: photoItemSize, height: photoItemSize)
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
        .shadow(color: themeViewModel.colors.secondaryShadow, radius: 4, x: 0, y: 2)
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
            
            // Navigation buttons - 하단 고정 (이전 스텝과 통일된 스타일)
            HStack(spacing: 16) {
                // Back button - 사진 분배로 돌아가기 (이전 버튼 스타일과 통일)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .photoDistribution
                    }
                }) {
                    Text(LocalizedString.Button.backToDistribution)
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
                .buttonStyle(PlainButtonStyle())

                // Reset button - 새로 시작하기 (다음 버튼 스타일과 통일)
                Button(action: {
                    resetSharingSession()
                }) {
                    Text(LocalizedString.Button.startOver)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.overlayBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primaryGradient)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigationButtons: some View {
        HStack(spacing: Constants.buttonSpacing) {
            // 이전 버튼
            if currentStep != .dateSelection {
                Button(action: {
                    goToPreviousStep()
                }) {
                    Text(LocalizedString.Button.previous)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Constants.buttonVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                                .fill(theme.secondaryBackground.opacity(1.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 다음 버튼 또는 기능별 버튼
            if canProceedToNext {
                Button(action: {
                    goToNextStep()
                }) {
                    Text(nextButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.overlayBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Constants.buttonVerticalPadding)
                        .background(theme.primaryGradient)
                        .cornerRadius(Constants.buttonCornerRadius)
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
            return LocalizedString.Button.next
        case .recipientSetup:
            return LocalizedString.Button.startDistribution
        case .photoDistribution:
            return LocalizedString.Button.checkAlbums
        case .albumPreview:
            return LocalizedString.Button.done
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
                return LocalizedString.Status.checking
            } else if photoViewModel.photos.isEmpty {
                return LocalizedString.Status.noPhotos
            } else {
                return photoViewModel.photoCountInfo
            }
        case .recipientSetup:
            if sharingViewModel.recipients.isEmpty {
                return LocalizedString.Status.noRecipients
            } else {
                return LocalizedString.statusRecipientsSet(sharingViewModel.recipients.count)
            }
        case .photoDistribution:
            let distributed = sharingViewModel.getTotalPhotosDistributed()
            if distributed == 0 {
                return sharingViewModel.recipients.isEmpty ? LocalizedString.Status.recipientSetupNeeded : LocalizedString.Status.dragToDistribute
            } else {
                return LocalizedString.statusPhotosCompleted(distributed)
            }
        case .albumPreview:
            return sharingViewModel.canStartSharing ? LocalizedString.Status.ready : LocalizedString.Status.distributionNeeded
        }
    }
    
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: Constants.animationDuration)) {
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
        withAnimation(.easeInOut(duration: Constants.animationDuration)) {
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
        EmptyStateView(
            icon: emptyStateConfig.icon,
            title: emptyStateConfig.title,
            subtitle: emptyStateConfig.subtitle,
            theme: theme
        )
    }

    // MARK: - Empty State Configuration
    private var emptyStateConfig: (icon: String, title: String, subtitle: String) {
        switch photoViewModel.currentFilter {
        case .all:
            return (
                icon: "photo.on.rectangle",
                title: LocalizedString.EmptyState.noPhotosTitle,
                subtitle: LocalizedString.EmptyState.noPhotosSubtitle
            )
        case .userAddedOnly:
            return (
                icon: "photo.badge.plus",
                title: LocalizedString.EmptyState.noAddedPhotosTitle,
                subtitle: LocalizedString.EmptyState.noAddedPhotosSubtitle
            )
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.batchCompleteDelay) {
                            withAnimation(.easeOut(duration: Constants.animationDuration)) {
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

// MARK: - Supporting Views & Modifiers
/// 툴바 아이콘 버튼 스타일
struct ToolbarIconButtonStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
            .frame(width: size * 2, height: size * 2)
    }
}

extension View {
    func toolbarIconButton(size: CGFloat = 18, theme: ThemeColors) -> some View {
        modifier(ToolbarIconButtonStyle(size: size, color: theme.primaryText))
    }

    func toolbarIconButton(size: CGFloat = 18, color: Color) -> some View {
        modifier(ToolbarIconButtonStyle(size: size, color: color))
    }
}

/// 빈 상태를 표시하는 재사용 가능한 컴포넌트
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: ThemeColors

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.5))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
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
