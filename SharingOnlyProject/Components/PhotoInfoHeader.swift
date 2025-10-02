import SwiftUI
import Photos

/// 사진 정보 헤더 컴포넌트 (날짜, 시간, 즐겨찾기, 상태, 사진 카운터)
struct PhotoInfoHeader: View {
    let photo: PhotoItem
    let currentIndex: Int
    let totalCount: Int
    let onFavoriteToggle: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Favorite heart toggle - leftmost
            Button(action: onFavoriteToggle) {
                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(photo.isFavorite ? theme.favoriteActive : theme.primaryText)
                    .frame(width: 32, height: 32)
                    .scaleEffect(photo.isFavorite ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: photo.isFavorite)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Date and time - center left
            Text(photo.dateCreated.photoDisplayString)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.primaryText)
            
            Spacer()
            
            // Photo counter (현재/전체) - center right
            Text("\(currentIndex + 1)/\(totalCount)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.primaryGradient)
                        .shadow(color: theme.primaryShadow.opacity(0.3), radius: 3, x: 0, y: 1)
                )
            
            // Album/Status badges - rightmost
            HStack(spacing: 8) {
                // Status badges inline
                if photo.isMarkedForDeletion {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                        Text("삭제")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(theme.overlayBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(theme.deleteColor.opacity(0.8))
                    )
                }
                
                // Album button - positioned on far right
                Button {
                    print("Album button tapped")
                } label: {
                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accentColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(theme.secondaryBackground.opacity(0.8))
                                .overlay(
                                    Circle()
                                        .stroke(theme.buttonBorder.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.primaryBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: theme.secondaryShadow.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // 제거됨 - DateFormatter+Photo 확장 사용
}


#Preview {
    // Preview용 더미 데이터
    let dummyAsset = PHAsset()
    var dummyPhoto = PhotoItem.createPreviewItem(
        image: UIImage(systemName: "photo"),
        dateCreated: Date()
    )
    // Set properties after initialization
    dummyPhoto.isMarkedForDeletion = true
    dummyPhoto.isMarkedForSaving = false
    
    return PhotoInfoHeader(
        photo: dummyPhoto,
        currentIndex: 4,
        totalCount: 25
    ) {
        print("Favorite toggled")
    }
    .environment(\.theme, SpringThemeColors())
    .padding()
}
