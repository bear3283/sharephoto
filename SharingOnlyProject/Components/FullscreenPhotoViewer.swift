import SwiftUI
import Photos

// MARK: - Custom Button Styles
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 개선된 풀스크린 사진 뷰어 (자연스러운 스와이프, 줌, 햅틱 피드백 지원)
struct FullscreenPhotoViewer: View {
    // MARK: - Constants
    private enum Constants {
        static let maxCacheSize = 10
        static let uiHideDelay: TimeInterval = 3.0
        static let minZoomScale: CGFloat = 1.0
        static let maxZoomScale: CGFloat = 4.0
        static let doubleTapZoomScale: CGFloat = 2.0
        static let swipeThreshold: CGFloat = 50
        static let dismissSwipeThreshold: CGFloat = 100
        static let screenWidthRatio: CGFloat = 0.95
        static let screenHeightRatio: CGFloat = 0.85
    }

    let photos: [PhotoItem]
    let initialIndex: Int
    @Binding var isPresented: Bool
    let photoService: PhotoServiceProtocol

    @State private var currentIndex: Int
    @State private var backgroundOpacity: Double = 0.0
    @State private var photoScale: Double = 0.8
    @State private var photoOpacity: Double = 0.0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGPoint = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGPoint = .zero

    // 고화질 이미지 캐시 (크기 제한 추가)
    @State private var fullQualityImages: [String: UIImage] = [:]
    @State private var loadingFullQuality: Set<String> = []
    @State private var cacheAccessOrder: [String] = []

    // UI 표시 상태 (Timer 대신 Task 사용)
    @State private var showingUI = true
    @State private var uiHideTask: Task<Void, Never>?

    // 햅틱 피드백 재사용
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    @Environment(\.theme) private var theme
    
    init(photos: [PhotoItem], initialIndex: Int, isPresented: Binding<Bool>, photoService: PhotoServiceProtocol) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self.photoService = photoService
        self._currentIndex = State(initialValue: initialIndex)
        // 햅틱 피드백 제너레이터 준비
        self.hapticGenerator.prepare()
    }
    
    private var currentPhoto: PhotoItem {
        guard currentIndex >= 0 && currentIndex < photos.count else { 
            return photos.first ?? PhotoItem.createPreviewItem(image: nil, dateCreated: Date()) 
        }
        return photos[currentIndex]
    }
    
    var body: some View {
        ZStack {
            // 배경 오버레이
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    toggleUI()
                }
            
            // 메인 사진 뷰 (줌/팬/스와이프 지원)
            if let displayImage = getDisplayImage(for: currentPhoto) {
                GeometryReader { geometry in
                    let screenSize = geometry.size
                    let imageSize = displayImage.size
                    let imageAspectRatio = imageSize.width / imageSize.height

                    // 최대 사용 가능 영역 (안전 여백 포함)
                    let maxWidth = screenSize.width * Constants.screenWidthRatio
                    let maxHeight = screenSize.height * Constants.screenHeightRatio

                    // 이미지 비율에 따른 적응형 크기 계산
                    let (photoWidth, photoHeight) = calculateAdaptiveSize(
                        imageAspectRatio: imageAspectRatio,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight
                    )

                    Image(uiImage: displayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit) // 잘림 없이 전체 이미지 표시
                        .frame(width: photoWidth, height: photoHeight)
                        .position(x: screenSize.width / 2, y: screenSize.height / 2)
                        .scaleEffect(scale)
                        .offset(x: offset.x, y: offset.y)
                        .accessibilityLabel("사진 \(currentIndex + 1) / \(photos.count)")
                        .accessibilityHint("두 번 탭하여 확대/축소")
                        .accessibilityAddTraits(.isImage)
                        .gesture(
                            SimultaneousGesture(
                                // 줌 제스처
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                        resetUITimer()
                                    }
                                    .onEnded { value in
                                        // 줌 레벨 제한
                                        scale = max(Constants.minZoomScale, min(scale, Constants.maxZoomScale))
                                        lastScale = scale

                                        // 줌 아웃 시 중앙으로 리셋
                                        if scale == Constants.minZoomScale {
                                            withAnimation(.spring(response: 0.3)) {
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    },
                                
                                // 팬 및 스와이프 제스처
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            // 줌인 상태에서는 팬 허용
                                            offset = CGPoint(
                                                x: lastOffset.x + value.translation.width,
                                                y: lastOffset.y + value.translation.height
                                            )
                                        }
                                        resetUITimer()
                                    }
                                    .onEnded { value in
                                        if scale > 1.0 {
                                            // 줌인 상태에서 팬 제약 적용 (적응형 크기 반영)
                                            lastOffset = offset
                                            let maxOffsetX = (photoWidth * (scale - 1)) / 2
                                            let maxOffsetY = (photoHeight * (scale - 1)) / 2

                                            withAnimation(.spring(response: 0.3)) {
                                                offset.x = max(-maxOffsetX, min(maxOffsetX, offset.x))
                                                offset.y = max(-maxOffsetY, min(maxOffsetY, offset.y))
                                                lastOffset = offset
                                            }
                                        } else {
                                            // 줌 안된 상태에서 스와이프 네비게이션
                                            handleSwipeNavigation(value: value)
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // 더블탭 줌 토글
                            hapticGenerator.impactOccurred()

                            withAnimation(.spring(response: 0.3)) {
                                if scale > Constants.minZoomScale {
                                    resetZoomAndPan()
                                } else {
                                    scale = Constants.doubleTapZoomScale
                                    lastScale = scale
                                }
                            }
                        }
                }
                .ignoresSafeArea()
                .opacity(photoOpacity)
                .scaleEffect(photoScale)
            }
            
            // 상단 오버레이
            if showingUI {
                VStack {
                    HStack {
                        // 페이지 인디케이터
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                        
                        Spacer()
                        
                        // 완료 버튼
                        Button("완료") {
                            hapticGenerator.impactOccurred()
                            dismissViewer()
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                                .opacity(0.8)
                        )
                        .buttonStyle(PressedButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityLabel("완료")
                        .accessibilityHint("사진 뷰어 닫기")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .transition(.opacity)
                
                // 좌우 네비게이션 버튼
                HStack {
                    // 이전 사진 버튼
                    if currentIndex > 0 {
                        Button {
                            hapticGenerator.impactOccurred()
                            currentIndex -= 1
                            resetZoomAndPan()
                            loadFullQualityImage(for: currentPhoto)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(.regularMaterial)
                                        .opacity(0.8)
                                )
                        }
                        .padding(.leading, 20)
                        .buttonStyle(PressedButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityLabel("이전 사진")
                        .accessibilityHint("사진 \(currentIndex) / \(photos.count)로 이동")
                    }

                    Spacer()

                    // 다음 사진 버튼
                    if currentIndex < photos.count - 1 {
                        Button {
                            hapticGenerator.impactOccurred()
                            currentIndex += 1
                            resetZoomAndPan()
                            loadFullQualityImage(for: currentPhoto)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(.regularMaterial)
                                        .opacity(0.8)
                                )
                        }
                        .padding(.trailing, 20)
                        .buttonStyle(PressedButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityLabel("다음 사진")
                        .accessibilityHint("사진 \(currentIndex + 2) / \(photos.count)로 이동")
                    }
                }

                // 하단 메타데이터
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            let photo = currentPhoto
                            Text(DateFormatter.photoDetail.string(from: photo.dateCreated))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5))
                            
                            // 즐겨찾기 표시
                            if photo.isFavorite {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.4))
                                    
                                    Text("즐겨찾기")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5).opacity(0.8))
                                }
                            }

                            // 고화질 해상도 정보
                            if let fullQualityImage = fullQualityImages[photo.id.uuidString] {
                                Text("\(Int(fullQualityImage.size.width)) × \(Int(fullQualityImage.size.height))")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.5).opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .gesture(
            // 아래로 스와이프하면 닫기
            DragGesture()
                .onEnded { value in
                    if value.translation.height > Constants.dismissSwipeThreshold && scale == Constants.minZoomScale {
                        hapticGenerator.impactOccurred()
                        dismissViewer()
                    }
                }
        )
        .onTapGesture {
            toggleUI()
        }
        .onAppear {
            presentViewer()
            loadFullQualityImage(for: currentPhoto)
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                hideViewer()
            }
        }
        .onDisappear {
            // Task 정리
            uiHideTask?.cancel()
        }
    }
    
    // MARK: - Helper Methods
    private func resetZoomAndPan() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }

    /// 이미지 비율에 따른 적응형 크기 계산
    /// - Parameters:
    ///   - imageAspectRatio: 이미지의 가로/세로 비율
    ///   - maxWidth: 최대 허용 너비
    ///   - maxHeight: 최대 허용 높이
    /// - Returns: 계산된 (너비, 높이) 튜플
    private func calculateAdaptiveSize(imageAspectRatio: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> (CGFloat, CGFloat) {
        let screenAspectRatio = maxWidth / maxHeight

        var photoWidth: CGFloat
        var photoHeight: CGFloat

        if imageAspectRatio > screenAspectRatio {
            // 가로가 긴 사진 - 너비 기준으로 맞춤
            photoWidth = maxWidth
            photoHeight = maxWidth / imageAspectRatio

            // 높이가 최대치를 초과하는 경우 높이 기준으로 재조정
            if photoHeight > maxHeight {
                photoHeight = maxHeight
                photoWidth = maxHeight * imageAspectRatio
            }
        } else {
            // 세로가 긴 사진 또는 정사방형 - 높이 기준으로 맞춤
            photoHeight = maxHeight
            photoWidth = maxHeight * imageAspectRatio

            // 너비가 최대치를 초과하는 경우 너비 기준으로 재조정
            if photoWidth > maxWidth {
                photoWidth = maxWidth
                photoHeight = maxWidth / imageAspectRatio
            }
        }

        return (photoWidth, photoHeight)
    }
    
    private func handleSwipeNavigation(value: DragGesture.Value) {
        let velocity = value.predictedEndTranslation.width - value.translation.width

        if abs(value.translation.width) > Constants.swipeThreshold || abs(velocity) > 100 {
            hapticGenerator.impactOccurred()

            if value.translation.width > 0 {
                // 오른쪽으로 스와이프 - 이전 사진
                if currentIndex > 0 {
                    currentIndex -= 1
                    resetZoomAndPan()
                    loadFullQualityImage(for: currentPhoto)
                }
            } else {
                // 왼쪽으로 스와이프 - 다음 사진
                if currentIndex < photos.count - 1 {
                    currentIndex += 1
                    resetZoomAndPan()
                    loadFullQualityImage(for: currentPhoto)
                }
            }
        }
    }
    
    // MARK: - 고화질 이미지 로딩
    private func getDisplayImage(for photo: PhotoItem) -> UIImage? {
        // 사용자 추가 사진은 displayImage 사용
        if photo.isUserAdded {
            return photo.displayImage
        }

        // PHAsset 사진은 고화질 이미지가 있으면 우선 사용, 없으면 썸네일 사용
        guard let asset = photo.asset else {
            return photo.displayImage
        }
        return fullQualityImages[asset.localIdentifier] ?? photo.image
    }

    private func loadFullQualityImage(for photo: PhotoItem) {
        // 사용자 추가 사진은 고화질 로딩 불필요
        guard !photo.isUserAdded, let asset = photo.asset else {
            return
        }

        let assetId = asset.localIdentifier

        // 이미 로드된 것이거나 로딩 중인 경우 건너뛰기
        guard fullQualityImages[assetId] == nil && !loadingFullQuality.contains(assetId) else {
            return
        }

        // 로딩 중으로 표시
        loadingFullQuality.insert(assetId)

        Task {
            if let fullQualityImage = await photoService.loadImage(for: asset, context: .fullscreen) {
                await MainActor.run {
                    // 캐시 크기 제한 관리
                    manageCache(forNewAsset: assetId)
                    fullQualityImages[assetId] = fullQualityImage
                    cacheAccessOrder.append(assetId)
                    loadingFullQuality.remove(assetId)
                }
            } else {
                await MainActor.run {
                    loadingFullQuality.remove(assetId)
                }
            }
        }
    }

    // MARK: - Cache Management
    private func manageCache(forNewAsset assetId: String) {
        // LRU 캐시 정책: 캐시 크기가 제한을 초과하면 가장 오래된 항목 제거
        if fullQualityImages.count >= Constants.maxCacheSize {
            if let oldestAssetId = cacheAccessOrder.first {
                fullQualityImages.removeValue(forKey: oldestAssetId)
                cacheAccessOrder.removeFirst()
            }
        }
    }
    
    // MARK: - UI Management
    private func toggleUI() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingUI.toggle()
        }

        if showingUI {
            resetUITimer()
        } else {
            uiHideTask?.cancel()
        }
    }

    private func resetUITimer() {
        uiHideTask?.cancel()
        uiHideTask = Task {
            try? await Task.sleep(for: .seconds(Constants.uiHideDelay))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingUI = false
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    private func presentViewer() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.9
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            photoScale = 1.0
            photoOpacity = 1.0
        }
        
        // UI 자동 숨김 타이머 시작
        resetUITimer()
    }
    
    private func hideViewer() {
        uiHideTask?.cancel()

        withAnimation(.easeInOut(duration: 0.3)) {
            photoScale = 0.8
            photoOpacity = 0.0
        }

        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.0
        }
    }
    
    private func dismissViewer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    // 샘플 PhotoItem 생성 (실제 PHAsset 없이 테스트용)
    let samplePhotos: [PhotoItem] = [
        PhotoItem.createPreviewItem(
            image: UIImage(systemName: "photo")!.withTintColor(.blue, renderingMode: .alwaysOriginal),
            dateCreated: Date()
        )
    ]
    
    return FullscreenPhotoViewer(
        photos: samplePhotos,
        initialIndex: 0,
        isPresented: .constant(true),
        photoService: PhotoService()
    )
    .environment(\.theme, SpringThemeColors())
}
