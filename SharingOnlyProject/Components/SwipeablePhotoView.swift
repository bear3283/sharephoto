import SwiftUI

/// 재사용 가능한 스와이프 가능한 사진 뷰 컴포넌트
struct SwipeablePhotoView: View {
    let image: UIImage
    @Binding var dragOffset: CGSize
    let onSwipeComplete: (SwipeDirection) -> Void
    
    @Environment(\.theme) private var theme
    
    enum SwipeDirection {
        case left  // Delete
        case right // Save
    }
    
    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                // Photo content
                GeometryReader { geometry in
                    let finalSize = calculateImageSize(for: image, in: geometry)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: finalSize.width, height: finalSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: theme.primaryShadow, radius: 4, x: 0, y: 2)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Swipe indicators overlay
                SwipeIndicatorsOverlay(dragOffset: dragOffset)
            }
            .offset(dragOffset)
            .scaleEffect(dragOffset == .zero ? 1.0 : 0.98)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        handleSwipeEnd(translation: value.translation)
                    }
            )
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        }
        .frame(height: calculatePhotoViewHeight())
    }
    
    private func handleSwipeEnd(translation: CGSize) {
        if translation.width > 100 {
            // Right swipe - Save
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: 300, height: 0)
            }
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                onSwipeComplete(.right)
                dragOffset = .zero
            }
        } else if translation.width < -100 {
            // Left swipe - Delete
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: -300, height: 0)
            }
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                onSwipeComplete(.left)
                dragOffset = .zero
            }
        } else {
            // Return to center
            withAnimation(.easeInOut) {
                dragOffset = .zero
            }
        }
    }
    
    private func calculateImageSize(for image: UIImage, in geometry: GeometryProxy) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let containerWidth = geometry.size.width - 16
        let containerHeight = geometry.size.height - 16
        let containerAspectRatio = containerWidth / containerHeight
        
        if imageAspectRatio > containerAspectRatio {
            return CGSize(width: containerWidth, height: containerWidth / imageAspectRatio)
        } else {
            return CGSize(width: containerHeight * imageAspectRatio, height: containerHeight)
        }
    }
    
    private func calculatePhotoViewHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaTop: CGFloat = 50
        let safeAreaBottom: CGFloat = 34
        let tabBarHeight: CGFloat = 83
        let dateInfoHeight: CGFloat = 50
        let counterHeight: CGFloat = 50
        let navigationHeight: CGFloat = 70
        let additionalSpacing: CGFloat = 50
        
        let calculatedHeight = screenHeight - safeAreaTop - safeAreaBottom - tabBarHeight - dateInfoHeight - counterHeight - navigationHeight - additionalSpacing
        
        return max(300, min(calculatedHeight, screenHeight * 0.6))
    }
}

/// 스와이프 인디케이터 오버레이 컴포넌트
struct SwipeIndicatorsOverlay: View {
    let dragOffset: CGSize
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        if abs(dragOffset.width) > 50 {
            HStack {
                if dragOffset.width < -50 {
                    // Delete indicator
                    SwipeIndicator(
                        icon: "trash.fill",
                        text: "삭제",
                        color: theme.deleteColor
                    )
                    .padding(.leading, 40)
                    
                    Spacer()
                }
                
                if dragOffset.width > 50 {
                    Spacer()
                    
                    // Save indicator
                    SwipeIndicator(
                        icon: "heart.fill",
                        text: "즐겨찾기",
                        color: theme.saveColor
                    )
                    .padding(.trailing, 40)
                }
            }
            .zIndex(10)
        }
    }
}

/// 개별 스와이프 인디케이터 컴포넌트
struct SwipeIndicator: View {
    let icon: String
    let text: String
    let color: LinearGradient
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(20)
        .background(
            Circle()
                .fill(color)
                .shadow(color: .black.opacity(0.3), radius: 15)
        )
    }
}

#Preview {
    SwipeablePhotoView(
        image: UIImage(systemName: "photo.fill") ?? UIImage(),
        dragOffset: .constant(.zero),
        onSwipeComplete: { direction in
            print("Swiped \(direction)")
        }
    )
    .environment(\.theme, SpringThemeColors())
    .padding()
}