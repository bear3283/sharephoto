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
    
    // 고화질 이미지 캐시
    @State private var fullQualityImages: [String: UIImage] = [:]
    @State private var loadingFullQuality: Set<String> = []
    
    // UI 표시 상태
    @State private var showingUI = true
    @State private var uiHideTimer: Timer?
    
    @Environment(\.theme) private var theme
    
    init(photos: [PhotoItem], initialIndex: Int, isPresented: Binding<Bool>, photoService: PhotoServiceProtocol) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self.photoService = photoService
        self._currentIndex = State(initialValue: initialIndex)
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
                    Image(uiImage: displayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(x: offset.x, y: offset.y)
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
                                        scale = max(1.0, min(scale, 4.0))
                                        lastScale = scale
                                        
                                        // 줌 아웃 시 중앙으로 리셋
                                        if scale == 1.0 {
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
                                            // 줌인 상태에서 팬 제약 적용
                                            lastOffset = offset
                                            let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                            let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                            
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
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            withAnimation(.spring(response: 0.3)) {
                                if scale > 1.0 {
                                    resetZoomAndPan()
                                } else {
                                    scale = 2.0
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
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                        
                        Spacer()
                        
                        // 완료 버튼
                        Button("완료") {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            dismissViewer()
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                                .opacity(0.8)
                        )
                        .buttonStyle(PressedButtonStyle())
                        .contentShape(Rectangle())
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
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex -= 1
                                resetZoomAndPan()
                                loadFullQualityImage(for: currentPhoto)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
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
                    }
                    
                    Spacer()
                    
                    // 다음 사진 버튼
                    if currentIndex < photos.count - 1 {
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex += 1
                                resetZoomAndPan()
                                loadFullQualityImage(for: currentPhoto)
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
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
                                .foregroundColor(.white)
                            
                            // 즐겨찾기 표시
                            if photo.isFavorite {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    
                                    Text("즐겨찾기")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            // 고화질 해상도 정보
                            if let fullQualityImage = fullQualityImages[photo.id.uuidString] {
                                Text("\(Int(fullQualityImage.size.width)) × \(Int(fullQualityImage.size.height))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
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
                    if value.translation.height > 100 && scale == 1.0 {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
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
    }
    
    // MARK: - Helper Methods
    private func resetZoomAndPan() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
    
    private func handleSwipeNavigation(value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 50
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        if abs(value.translation.width) > swipeThreshold || abs(velocity) > 100 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            if value.translation.width > 0 {
                // 오른쪽으로 스와이프 - 이전 사진
                if currentIndex > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex -= 1
                        resetZoomAndPan()
                        loadFullQualityImage(for: currentPhoto)
                    }
                }
            } else {
                // 왼쪽으로 스와이프 - 다음 사진
                if currentIndex < photos.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex += 1
                        resetZoomAndPan()
                        loadFullQualityImage(for: currentPhoto)
                    }
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
                    fullQualityImages[assetId] = fullQualityImage
                    loadingFullQuality.remove(assetId)
                }
            } else {
                await MainActor.run {
                    loadingFullQuality.remove(assetId)
                }
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
            uiHideTimer?.invalidate()
        }
    }
    
    private func resetUITimer() {
        uiHideTimer?.invalidate()
        uiHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showingUI = false
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
        uiHideTimer?.invalidate()
        
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
