import SwiftUI
import Foundation
import Photos


/// 8방향 드래그 시스템의 핵심 컴포넌트 - 원형 오버레이 UI
struct DirectionalDragView: View {
    @ObservedObject var sharingViewModel: SharingViewModel
    @ObservedObject var photoViewModel: PhotoViewModel
    
    @Environment(\.theme) private var theme
    @State private var selectedPhotoIndex = 0
    
    // 세그먼트된 도넛형 오버레이 설정 - 화면에 맞는 크기로 조정
    private let donutOuterRadius: CGFloat = 170  // 화면 안에 잘 들어오도록 축소
    private let donutInnerRadius: CGFloat = 140  // 중앙 사진 크기 최적화
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (깔끔한 배경)
                backgroundView
                
                // Center photo area (더 큰 사진 뷰 - 전체 공간 최적화)
                centerPhotoView(in: geometry)
                    .offset(y: -10)  // 적당한 위치 조정으로 균형 유지
                
                // 원형 드래그 오버레이 (드래그 시에만 표시)
                if sharingViewModel.dragState.isDragging {
                    circularDragOverlay(in: geometry)
                        .offset(y: -10)  // 사진과 일치하는 오프셋
                }
                
                // 대상자가 없을 때 안내 메시지
                if sharingViewModel.recipients.isEmpty {
                    noRecipientsGuideView
                }
                
                // Bottom photo navigation buttons - 더 아래로 이동하여 하단 공간 활용
                VStack {
                    Spacer()
                    bottomPhotoNavigationView
                        .padding(.bottom, 10)  // 기존 20에서 10으로 감소
                        .padding(.horizontal, 20)
                        .offset(y: 15)  // 추가로 15px 아래로 이동
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Background (깔끔한 배경)
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(theme.primaryBackground)
            .shadow(color: theme.primaryShadow.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 세그먼트된 도넛형 드래그 오버레이
    private func circularDragOverlay(in geometry: GeometryProxy) -> some View {
        let centerPoint = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        return ZStack {
            // 세그먼트된 도넛 오버레이
            segmentedDonutOverlay(centerPoint: centerPoint)

            // 연결선 효과 (중앙에서 모든 세그먼트로)
            if sharingViewModel.dragState.isTargetingAll && !sharingViewModel.recipients.isEmpty {
                connectionLines(centerPoint: centerPoint)
            }

            // 중앙 공유 존 (모든 사람에게)
            centralShareZone(centerPoint: centerPoint)
        }
    }
    
    // MARK: - 세그먼트된 도넛 오버레이
    private func segmentedDonutOverlay(centerPoint: CGPoint) -> some View {
        ZStack {
            // 8개 방향 세그먼트들
            ForEach(ShareDirection.allCases, id: \.self) { direction in
                let recipient = sharingViewModel.recipients.first { $0.direction == direction }
                let isDirectionActive = sharingViewModel.dragState.targetDirection == direction
                let isAllActive = sharingViewModel.dragState.isTargetingAll && recipient != nil
                let isActive = isDirectionActive || isAllActive

                donutSegment(
                    direction: direction,
                    recipient: recipient,
                    centerPoint: centerPoint,
                    isActive: isActive
                )
            }
            
            // 세그먼트 구분선들 (도넛 안쪽으로 이동)
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * 45.0 - 22.5 // 각 세그먼트 경계선
                let radians = angle * .pi / 180
                let innerX = centerPoint.x + Foundation.cos(radians) * (donutInnerRadius + 10) // 안쪽으로 10pt 이동
                let innerY = centerPoint.y + Foundation.sin(radians) * (donutInnerRadius + 10)
                let outerX = centerPoint.x + Foundation.cos(radians) * (donutOuterRadius - 10) // 바깥쪽에서 10pt 안으로
                let outerY = centerPoint.y + Foundation.sin(radians) * (donutOuterRadius - 10)

                Path { path in
                    path.move(to: CGPoint(x: innerX, y: innerY))
                    path.addLine(to: CGPoint(x: outerX, y: outerY))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2.0) // 약간 더 굵고 진하게
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sharingViewModel.dragState.isDragging)
    }
    
    // MARK: - 도넛 세그먼트
    private func donutSegment(direction: ShareDirection, recipient: ShareRecipient?, centerPoint: CGPoint, isActive: Bool) -> some View {
        let angle = getAngleForDirection(direction)
        let startAngle = Angle.degrees(angle - 22.5)
        let endAngle = Angle.degrees(angle + 22.5)
        
        return ZStack {
            // 세그먼트 배경
            DonutSegmentShape(
                innerRadius: donutInnerRadius,
                outerRadius: donutOuterRadius,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .fill(
                recipient != nil ?
                LinearGradient(
                    colors: [
                        // 모든 사람 공유 모드일 때 특별한 색상 효과
                        sharingViewModel.dragState.isTargetingAll ?
                        theme.accentColor.opacity(isActive ? 0.9 : 0.7) :
                        recipient!.swiftUIColor.opacity(isActive ? 0.9 : 0.6),

                        sharingViewModel.dragState.isTargetingAll ?
                        theme.accentColor.opacity(isActive ? 0.7 : 0.5) :
                        recipient!.swiftUIColor.opacity(isActive ? 0.7 : 0.4)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .position(centerPoint)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            // 세그먼트 내 정보 표시
            if let recipient = recipient {
                segmentInfo(
                    recipient: recipient,
                    direction: direction,
                    centerPoint: centerPoint,
                    isActive: isActive
                )
            }
        }
    }
    
    // MARK: - 세그먼트 정보 표시
    private func segmentInfo(recipient: ShareRecipient, direction: ShareDirection, centerPoint: CGPoint, isActive: Bool) -> some View {
        let angle = getAngleForDirection(direction)
        let radians = angle * .pi / 180
        let segmentMidRadius = (donutInnerRadius + donutOuterRadius) / 2
        let x = centerPoint.x + Foundation.cos(radians) * segmentMidRadius
        let y = centerPoint.y + Foundation.sin(radians) * segmentMidRadius
        
        let album = sharingViewModel.getAlbumFor(direction: direction)
        let photoCount = album?.photoCount ?? 0
        
        return VStack(spacing: 4) {
            // 방향 아이콘
            Image(systemName: direction.systemIcon)
                .font(.system(size: isActive ? 20 : 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            // 이름
            Text(recipient.name)
                .font(.system(size: isActive ? 11 : 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                .lineLimit(1)
            
            // 사진 개수 (있을 때만)
            if photoCount > 0 {
                Text("\(photoCount)")
                    .font(.system(size: isActive ? 12 : 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
        .position(x: x, y: y)
        .scaleEffect(isActive ? 1.2 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: photoCount)
    }

    // MARK: - 중앙 공유 존 (모든 사람에게)
    private func centralShareZone(centerPoint: CGPoint) -> AnyView {
        let isActive = sharingViewModel.dragState.isTargetingAll
        let hasRecipients = !sharingViewModel.recipients.isEmpty
        let zoneRadius: CGFloat = 60

        // 중앙 원형 배경
        return AnyView(Circle()
            .fill(
                isActive && hasRecipients ?
                LinearGradient(
                    colors: [
                        theme.accentColor.opacity(0.9),
                        theme.accentColor.opacity(0.7)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    colors: [
                        Color.gray.opacity(hasRecipients ? 0.7 : 0.3),
                        Color.gray.opacity(hasRecipients ? 0.5 : 0.2)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .frame(width: zoneRadius * 2, height: zoneRadius * 2)
            .overlay(
                Circle()
                    .stroke(
                        isActive && hasRecipients ?
                        Color.white.opacity(0.9) :
                        Color.gray.opacity(hasRecipients ? 0.4 : 0.2),
                        lineWidth: isActive ? 3 : 2
                    )
            )
            .overlay(
                // 중앙 콘텐츠
                VStack(spacing: 6) {
                    // 아이콘
                    Image(systemName: hasRecipients ? "person.3.fill" : "person.3")
                        .font(.system(size: isActive ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(
                            isActive && hasRecipients ? .white :
                            hasRecipients ? theme.accentColor : theme.secondaryText
                        )
                        .shadow(color: .black.opacity(isActive ? 0.5 : 0), radius: 2, x: 0, y: 1)

                    // 텍스트
                    Text(hasRecipients ? LocalizedString.Distribution.allPeople : LocalizedString.Distribution.noRecipientStatus)
                        .font(.system(size: isActive ? 11 : 10, weight: .bold, design: .rounded))
                        .foregroundColor(
                            isActive && hasRecipients ? .white :
                            hasRecipients ? theme.primaryText : theme.secondaryText
                        )
                        .shadow(color: .black.opacity(isActive ? 0.7 : 0), radius: 1, x: 0, y: 1)
                        .lineLimit(1)

                    // 수신자 수 표시
                    if hasRecipients {
                        Text(LocalizedString.recipientCount(sharingViewModel.recipients.count))
                            .font(.system(size: isActive ? 10 : 9, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                isActive ? .white.opacity(0.9) : theme.secondaryText
                            )
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        isActive ?
                                        Color.black.opacity(0.3) :
                                        theme.accentColor.opacity(0.2)
                                    )
                            )
                            .shadow(color: .black.opacity(isActive ? 0.5 : 0), radius: 2, x: 0, y: 1)
                    }
                }
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasRecipients)
            )
            .scaleEffect(isActive ? 1.15 : 1.0)
            .position(centerPoint))
    }

    // MARK: - 연결선 효과 (중앙에서 모든 세그먼트로)
    private func connectionLines(centerPoint: CGPoint) -> some View {
        ZStack {
            ForEach(sharingViewModel.recipients, id: \.id) { recipient in
                let angle = getAngleForDirection(recipient.direction)
                let radians = angle * .pi / 180
                let lineLength: CGFloat = 80
                let endX = centerPoint.x + Foundation.cos(radians) * lineLength
                let endY = centerPoint.y + Foundation.sin(radians) * lineLength

                Path { path in
                    path.move(to: centerPoint)
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.accentColor.opacity(0.8),
                            recipient.swiftUIColor.opacity(0.6)
                        ],
                        startPoint: .center,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        dash: [8, 4]
                    )
                )
                .shadow(color: theme.accentColor.opacity(0.3), radius: 2, x: 0, y: 0)
            }
        }
        .opacity(0.7)
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - 헬퍼 함수
    private func getAngleForDirection(_ direction: ShareDirection) -> Double {
        switch direction {
        case .top: return -90
        case .topRight: return -45
        case .right: return 0
        case .bottomRight: return 45
        case .bottom: return 90
        case .bottomLeft: return 135
        case .left: return 180
        case .topLeft: return -135
        }
    }
    
    // MARK: - Center Photo (확대된 크기)
    private func centerPhotoView(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            if !photoViewModel.photos.isEmpty {
                // 확대된 사진 드래그 뷰 - 더 큰 크기로 표시
                EnhancedPhotoDragView(
                    photo: photoViewModel.photos[selectedPhotoIndex],
                    sharingViewModel: sharingViewModel,
                    circularOverlayRadius: donutOuterRadius,
                    donutInnerRadius: donutInnerRadius
                )
            } else {
                EmptyPhotoView()
            }
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 10)  // 살짝 위로 이동
    }
    
    // MARK: - Bottom Photo Navigation
    private var bottomPhotoNavigationView: some View {
        Group {
            if !photoViewModel.photos.isEmpty {
                photoNavigationButtons
            } else {
                EmptyView()
            }
        }
    }
    
    private var photoNavigationButtons: some View {
        return AnyView(
            HStack(spacing: 16) {
                Button(action: previousPhoto) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedPhotoIndex == 0 ? theme.secondaryText : .white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(
                                selectedPhotoIndex == 0 
                                    ? AnyShapeStyle(theme.secondaryBackground.opacity(0.6))
                                    : AnyShapeStyle(theme.accentColor)
                            )
                        )
                        .shadow(color: theme.primaryShadow.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(selectedPhotoIndex == 0)
                
                Text("\(selectedPhotoIndex + 1) / \(photoViewModel.photos.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(theme.primaryBackground)
                            .shadow(color: theme.primaryShadow.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                
                Button(action: nextPhoto) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedPhotoIndex == photoViewModel.photos.count - 1 ? theme.secondaryText : .white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(
                                selectedPhotoIndex == photoViewModel.photos.count - 1
                                    ? AnyShapeStyle(theme.secondaryBackground.opacity(0.6))
                                    : AnyShapeStyle(theme.accentColor)
                            )
                        )
                        .shadow(color: theme.primaryShadow.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(selectedPhotoIndex == photoViewModel.photos.count - 1)
            }
        )
    }
    
    
    // MARK: - No Recipients Guide
    private var noRecipientsGuideView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor)
                .symbolEffect(.bounce, value: sharingViewModel.recipients.isEmpty)
            
            VStack(spacing: 8) {
                Text(LocalizedString.Distribution.noRecipients)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)

                Text(LocalizedString.Distribution.noRecipientsMessage)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            Button(LocalizedString.Distribution.goToRecipientSetup) {
                // This would need to be handled by the parent view
                // For now, just show the message
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    
    
    // MARK: - Actions
    private func previousPhoto() {
        if selectedPhotoIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPhotoIndex -= 1
            }
        }
    }
    
    private func nextPhoto() {
        if selectedPhotoIndex < photoViewModel.photos.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPhotoIndex += 1
            }
        }
    }
    
    // MARK: - Helper Methods (UI 숨김 기능 제거됨)
    // 더 이상 필요없는 UI 토글 기능들을 제거
}


// MARK: - Enhanced Photo Drag View (도넛형 오버레이용 사진 뷰)
struct EnhancedPhotoDragView: View {
    let photo: PhotoItem
    let sharingViewModel: SharingViewModel
    let circularOverlayRadius: CGFloat
    let donutInnerRadius: CGFloat
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var highQualityImage: UIImage?
    @State private var loadingHighQuality = false
    @State private var photoAspectRatio: CGFloat = 1.0
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            if let displayImage = highQualityImage ?? photo.image {
                let maxSize: CGFloat = 450  // 도넛 크기와 독립적인 사진 크기 (이전 442px와 유사)
                let photoWidth = maxSize
                let photoHeight = maxSize / photoAspectRatio
                
                // 컨테이너 경계를 허용하되 더 큰 크기로 설정
                let finalWidth = min(photoWidth, maxSize)
                let finalHeight = min(photoHeight, maxSize)
                
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(photoAspectRatio, contentMode: .fit)
                    .frame(width: finalWidth, height: finalHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: .black.opacity(isDragging ? 0.6 : 0.15), 
                        radius: isDragging ? 25 : 12, 
                        x: 0, 
                        y: isDragging ? 10 : 6
                    )
                    .scaleEffect(isDragging ? 0.85 : 1.0)
                    .offset(dragOffset)
                    .overlay(
                        // High-quality loading indicator
                        Group {
                            if loadingHighQuality && highQualityImage == nil {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text(LocalizedString.Photo.highQualityLoading)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.7))
                                )
                            }
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    Task {
                                        await sharingViewModel.sendAsync(.startDrag(photo, value.startLocation))
                                    }
                                }
                                
                                dragOffset = value.translation
                                Task {
                                    await sharingViewModel.sendAsync(.updateDrag(value.translation, value.location))
                                }
                            }
                            .onEnded { value in
                                isDragging = false

                                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))

                                Task {
                                    // 중앙 공유 존 또는 방향별 드래그 존에서 분배
                                    if distance <= 50 && !sharingViewModel.recipients.isEmpty {
                                        // 중앙 공유 존에서 끝남 - 모든 사람에게 분배
                                        await sharingViewModel.sendAsync(.endDrag(nil))
                                    } else if distance > 80 {
                                        // 방향별 드래그 존에서 끝남
                                        await sharingViewModel.sendAsync(.endDrag(sharingViewModel.dragState.targetDirection))
                                    } else {
                                        // 드래그 취소
                                        await sharingViewModel.sendAsync(.endDrag(nil))
                                    }
                                }
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    dragOffset = .zero
                                }
                            }
                    )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragging)
        .onAppear {
            calculateAspectRatio()
            loadHighQualityImage()
        }
        .onChange(of: photo.id) { _, _ in
            highQualityImage = nil
            loadingHighQuality = false
            calculateAspectRatio()
            loadHighQualityImage()
        }
    }
    
    // MARK: - Helper Methods
    private func calculateAspectRatio() {
        // 사용자 추가 사진의 경우 이미지에서 직접 계산
        if photo.isUserAdded {
            if let image = photo.displayImage {
                let width = image.size.width
                let height = image.size.height

                if height > 0 {
                    photoAspectRatio = width / height
                } else {
                    photoAspectRatio = 1.0
                }
            } else {
                photoAspectRatio = 1.0
            }
        } else if let asset = photo.asset {
            // PHAsset 사진의 경우 asset에서 계산
            let width = CGFloat(asset.pixelWidth)
            let height = CGFloat(asset.pixelHeight)

            if height > 0 {
                photoAspectRatio = width / height
            } else {
                photoAspectRatio = 1.0
            }
        } else {
            photoAspectRatio = 1.0
        }

        photoAspectRatio = max(0.5, min(photoAspectRatio, 2.0))
    }
    
    private func loadHighQualityImage() {
        guard !loadingHighQuality else { return }
        
        loadingHighQuality = true
        
        Task {
            // 사용자 추가 사진은 이미 고화질 이미지를 가지고 있음
            if photo.isUserAdded {
                await MainActor.run {
                    loadingHighQuality = false
                    if let image = photo.displayImage {
                        highQualityImage = image
                    }
                }
                return
            }

            // PHAsset 사진만 고화질 로딩
            guard let asset = photo.asset else {
                await MainActor.run {
                    loadingHighQuality = false
                }
                return
            }

            let photoService = PhotoService()
            let image = await photoService.loadImage(for: asset, context: .fullscreen)
            
            await MainActor.run {
                loadingHighQuality = false
                if let image = image {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        highQualityImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct EmptyPhotoView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            Text("선택한 날짜에 사진이 없습니다")
                .font(.headline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 240, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondaryBackground.opacity(0.3))
                .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Custom Shapes

/// 도넛 세그먼트를 그리는 커스텀 Shape
struct DonutSegmentShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // 외부 호 (시계방향)
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // 끝점에서 내부 원으로 직선
        let endRadians = endAngle.radians
        let innerEndPoint = CGPoint(
            x: center.x + Foundation.cos(endRadians) * innerRadius,
            y: center.y + Foundation.sin(endRadians) * innerRadius
        )
        path.addLine(to: innerEndPoint)
        
        // 내부 호 (반시계방향)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        // 시작점으로 닫기
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview("DirectionalDragView") {
    VStack {
        DirectionalDragView(
            sharingViewModel: {
                let vm = SharingViewModel()
                Task {
                    await vm.sendAsync(.createSession(Date()))
                    await vm.sendAsync(.addRecipient("친구1", .top))
                    await vm.sendAsync(.addRecipient("친구2", .right))
                    await vm.sendAsync(.addRecipient("친구3", .bottom))
                    await vm.sendAsync(.addRecipient("친구4", .left))
                }
                return vm
            }(),
            photoViewModel: PhotoViewModel()
        )
        .padding()
    }
    .environment(\.theme, SpringThemeColors())
}

