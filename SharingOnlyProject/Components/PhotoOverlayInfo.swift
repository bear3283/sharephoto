import SwiftUI
import Photos

/// 사진 위에 오버레이되는 정보 컴포넌트 (즐겨찾기 | 날짜/시간 | 현재사진/전체사진 | 폴더에추가)
struct PhotoOverlayInfo: View {
    let photo: PhotoItem
    let currentIndex: Int
    let totalCount: Int
    let onFavoriteToggle: () -> Void
    let onAddToAlbum: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. 즐겨찾기 (좌측)
            favoriteSection
            
            // 2. 날짜/시간 (중앙-좌)
            dateTimeSection
            
            Spacer()
            
            // 3. 현재사진/전체사진 (중앙-우)
            photoCounterSection
            
            // 4. 폴더에추가 (우측)
            albumActionSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - 1. 즐겨찾기 섹션 (개선됨)
    private var favoriteSection: some View {
        Button(action: onFavoriteToggle) {
            ZStack {
                // Background circle for better tap area
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                // Heart icon with enhanced feedback
                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(photo.isFavorite ? .pink : .white)
                    .shadow(
                        color: photo.isFavorite ? .pink.opacity(0.5) : .black.opacity(0.5), 
                        radius: photo.isFavorite ? 4 : 2, 
                        x: 0, 
                        y: 1
                    )
                    .scaleEffect(photo.isFavorite ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: photo.isFavorite)
            }
        }
        .buttonStyle(FavoriteButtonStyle())
        .accessibilityLabel(photo.isFavorite ? "즐겨찾기에서 제거" : "즐겨찾기에 추가")
        .accessibilityHint("두 번 탭하여 즐겨찾기 상태를 변경합니다")
    }
    
    // MARK: - 2. 날짜/시간 섹션
    private var dateTimeSection: some View {
        Text(formatDateTime(photo.dateCreated))
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 3. 현재사진/전체사진 섹션
    private var photoCounterSection: some View {
        Text("\(currentIndex + 1)/\(totalCount)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 4. 폴더에추가 섹션
    private var albumActionSection: some View {
        HStack(spacing: 8) {
            // Status badge if marked for deletion
            if photo.isMarkedForDeletion {
                HStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                    Text("삭제")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.8))
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            // Album/Folder button
            if let onAddToAlbum = onAddToAlbum {
                Button(action: onAddToAlbum) {
                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.6))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Button Styles
struct FavoriteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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
            .frame(height: 300)
        
        VStack {
            PhotoOverlayInfo(
                photo: {
                    var photo = PhotoItem.createPreviewItem(
                        image: UIImage(systemName: "photo"),
                        dateCreated: Date()
                    )
                    photo.isMarkedForSaving = true
                    return photo
                }(),
                currentIndex: 4,
                totalCount: 22,
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