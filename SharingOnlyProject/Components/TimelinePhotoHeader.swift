import SwiftUI
import Photos

/// Timeline 스타일 사진 헤더 (인스타그램 스토리 형태)
struct TimelinePhotoHeader: View {
    let photo: PhotoItem
    let currentIndex: Int
    let totalCount: Int
    let onFavoriteToggle: () -> Void
    let onAddToAlbum: (() -> Void)?
    
    @Environment(\.theme) private var theme
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Top section with progress bars
            topProgressSection
            
            // Content section with minimal info
            contentSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - Progress Section
    private var topProgressSection: some View {
        VStack(spacing: 8) {
            // Timeline progress bars
            HStack(spacing: 2) {
                ForEach(0..<totalCount, id: \.self) { index in
                    ProgressSegment(
                        isCompleted: index < currentIndex,
                        isActive: index == currentIndex,
                        animate: animateProgress
                    )
                }
            }
            .frame(height: 3)
            
            // Date with subtle styling
            HStack {
                Text(photo.dateCreated.timelineDisplayString)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                Text("\(currentIndex + 1) of \(totalCount)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Status indicator with subtle animation
            statusIndicator
            
            Spacer()
            
            // Action buttons - floating style
            actionButtons
        }
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            // Favorite status with glow effect
            if photo.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.5), radius: 2, x: 0, y: 0)
            }
            
            // Status badges
            if photo.isMarkedForSaving {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 2, x: 0, y: 0)
            }
            
            if photo.isMarkedForDeletion {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.5), radius: 2, x: 0, y: 0)
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Album button (if provided)
            if let onAddToAlbum = onAddToAlbum {
                FloatingActionButton(
                    icon: "plus.rectangle.on.folder",
                    action: onAddToAlbum
                )
            }
            
            // Favorite toggle button
            FloatingActionButton(
                icon: photo.isFavorite ? "heart.fill" : "heart",
                iconColor: photo.isFavorite ? .red : .white,
                action: onFavoriteToggle
            )
        }
    }
}

// MARK: - Progress Segment Component
struct ProgressSegment: View {
    let isCompleted: Bool
    let isActive: Bool
    let animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.3))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white)
                    .frame(width: progressWidth(geometry.size.width))
                    .animation(
                        isActive ? .easeInOut(duration: 3.0) : .easeInOut(duration: 0.3),
                        value: animate
                    )
            }
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        if isCompleted {
            return totalWidth
        } else if isActive && animate {
            return totalWidth
        } else {
            return 0
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    init(icon: String, iconColor: Color = .white, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Date Extension for Timeline Display
extension Date {
    var timelineDisplayString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
            return "오늘 \(formatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            formatter.dateFormat = "HH:mm"
            return "어제 \(formatter.string(from: self))"
        } else {
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: self)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background image simulation
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
        
        VStack {
            // Timeline header at top
            let dummyAsset = PHAsset()
            let dummyPhoto = PhotoItem(
                asset: dummyAsset,
                image: UIImage(systemName: "photo"),
                dateCreated: Date()
            )
            
            TimelinePhotoHeader(
                photo: dummyPhoto,
                currentIndex: 2,
                totalCount: 8,
                onFavoriteToggle: {
                    print("Favorite toggled")
                },
                onAddToAlbum: {
                    print("Add to album")
                }
            )
            
            Spacer()
        }
    }
    .environment(\.theme, SpringThemeColors())
}