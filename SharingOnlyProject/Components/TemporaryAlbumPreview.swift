import SwiftUI

/// 임시 앨범들의 미리보기 및 관리 뷰
struct TemporaryAlbumPreview: View {
    @ObservedObject var sharingViewModel: SharingViewModel
    @State private var selectedRecipient: ShareRecipient?  // Sheet item으로 사용

    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primaryBackground)
                .shadow(color: theme.primaryShadow.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 0) {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 16) {
                        // Header - now scrolls with content
                        headerView
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        // Albums preview
                        if !sharingViewModel.temporaryAlbums.isEmpty {
                            albumsPreviewView
                                .padding(.horizontal, 20)
                            
                            // Share readiness indicator (scrollable)
                            shareReadinessIndicator
                                .padding(.horizontal, 20)
                            
                            // Share controls (now in scrollable area)
                            shareButton
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        } else {
                            emptyStateView
                                .padding(.horizontal, 20)
                        }
                    }
                }
                
                // No fixed bottom actions - all content is now scrollable
            }
        }
        .sheet(item: $selectedRecipient) { recipient in
            AlbumDetailSheet(recipientId: recipient.id, sharingViewModel: sharingViewModel)
        }
        .alert(LocalizedString.Alert.shareStatus, isPresented: .constant(sharingViewModel.errorMessage != nil)) {
            Button(LocalizedString.General.confirm) {
                sharingViewModel.send(.clearError)
            }
        } message: {
            Text(sharingViewModel.errorMessage ?? "")
        }
        // 공유 성공 시 간단한 피드백
        .overlay(alignment: .top) {
            if sharingViewModel.currentSession?.status == .completed {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: sharingViewModel.currentSession?.status)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedString.Album.temporaryAlbum)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)

                if !sharingViewModel.temporaryAlbums.isEmpty {
                    Text(LocalizedString.photosDistributed(sharingViewModel.getTotalPhotosDistributed()))
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer()
            
            // Quick stats - 개선된 공유 상태 표시
            HStack(spacing: 8) {
                let totalPhotos = sharingViewModel.getTotalPhotosDistributed()
                let nonEmptyAlbums = sharingViewModel.temporaryAlbums.filter { !$0.isEmpty }.count
                let totalAlbums = sharingViewModel.temporaryAlbums.count
                
                Image(systemName: sharingViewModel.canStartSharing ? "checkmark.circle.fill" : "info.circle")
                    .foregroundColor(sharingViewModel.canStartSharing ? .green : theme.accentColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sharingViewModel.canStartSharing ? LocalizedString.Album.shareReady : LocalizedString.Album.someReady)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(sharingViewModel.canStartSharing ? .green : theme.primaryText)

                    Text(LocalizedString.albumPhotoCount(totalPhotos, nonEmptyAlbums, totalAlbums))
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(sharingViewModel.canStartSharing ? AnyShapeStyle(Color.green.opacity(0.1)) : AnyShapeStyle(theme.accentColor.opacity(0.1)))
            )
        }
    }
    
    // MARK: - Albums Preview
    private var albumsPreviewView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(sharingViewModel.temporaryAlbums) { album in
                AlbumPreviewCard(
                    album: album,
                    onTap: {
                        selectedRecipient = album.recipient
                    }
                )
            }
        }
    }
    
    // MARK: - Fixed Bottom Actions
    private var fixedBottomActions: some View {
        VStack(spacing: 0) {
            // Gradient overlay for smooth transition
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            VStack(spacing: 12) {
                // Share button
                shareButton
                
                // Reset button
                resetButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    private var shareReadinessIndicator: some View {
        HStack {
            ForEach(sharingViewModel.temporaryAlbums) { album in
                HStack(spacing: 4) {
                    Circle()
                        .fill(album.isEmpty ? .red : .green)
                        .frame(width: 8, height: 8)
                        .symbolEffect(.pulse, options: .repeat(.continuous).speed(1), value: album.isEmpty)
                    
                    Text(album.recipient.name)
                        .font(.caption2)
                        .foregroundColor(album.isEmpty ? .red : theme.secondaryText)
                        .fontWeight(album.isEmpty ? .medium : .regular)
                }
                .transition(.scale.combined(with: .opacity))
                
                if album.id != sharingViewModel.temporaryAlbums.last?.id {
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.secondaryBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            sharingViewModel.canStartSharing ? 
                            .green.opacity(0.3) : .red.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: sharingViewModel.canStartSharing)
    }
    
    private var shareButton: some View {
        Button(action: {
            Task {
                await sharingViewModel.sendAsync(.shareAlbums)
            }
        }) {
            HStack(spacing: 8) {
                if sharingViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.secondaryText)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                        .symbolEffect(.bounce, value: sharingViewModel.canStartSharing)
                }

                Text(sharingViewModel.isLoading ? LocalizedString.Album.sharing : LocalizedString.Album.shareAll)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(
                sharingViewModel.canStartSharing && !sharingViewModel.isLoading ?
                .green : theme.secondaryText
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground.opacity(0.6))
            )
        }
        .contentShape(Rectangle())
        .disabled(!sharingViewModel.canStartSharing || sharingViewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: sharingViewModel.canStartSharing)
        .animation(.easeInOut(duration: 0.2), value: sharingViewModel.isLoading)
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button(action: {
            Task {
                await sharingViewModel.sendAsync(.clearSession)
            }
        }) {
            Text(LocalizedString.Button.startOver)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.secondaryBackground.opacity(0.6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(LocalizedString.Album.noAlbums)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Text(LocalizedString.Album.noAlbumsMessage)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondaryBackground.opacity(0.3))
                .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Success Toast
    private var successToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedString.Album.shareSuccess)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)

                Text(LocalizedString.Album.shareSuccessMessage)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Album Preview Card
struct AlbumPreviewCard: View {
    let album: TemporaryAlbum
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Recipient info with direction
                HStack(spacing: 8) {
                    // Direction indicator
                    ZStack {
                        Circle()
                            .fill(album.recipient.swiftUIColor)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: album.recipient.direction.systemIcon)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .rotationEffect(album.recipient.direction.angle)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(album.recipient.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text(album.recipient.direction.displayName)
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Photo count with badge style
                    ZStack {
                        Circle()
                            .fill(album.isEmpty ? .red.opacity(0.1) : theme.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Text("\(album.photoCount)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(album.isEmpty ? .red : theme.accentColor)
                    }
                    .scaleEffect(album.isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: album.isEmpty)
                }
                
                // Photos preview
                if !album.isEmpty {
                    photoPreviewGrid
                } else {
                    emptyAlbumIndicator
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                album.isEmpty ? .red.opacity(0.3) : album.recipient.swiftUIColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var photoPreviewGrid: some View {
        let maxPhotos = min(album.photos.count, 5)  // 5장까지 표시 (3×2에서 마지막 위치는 +숫자용)
        let photos = Array(album.photos.prefix(maxPhotos))

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                if index < 5 {  // 5번째(인덱스 4)까지만 사진 표시
                    if let image = photo.displayImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)  // 3열로 변경에 따라 크기 조정
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            // 6번째 위치(2행 3열)에 "+숫자" 표시
            if album.photos.count > 5 {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accentColor.opacity(0.8))
                        .frame(width: 35, height: 35)

                    Text("+\(album.photos.count - 5)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 72)  // 2행에 맞게 높이 조정
    }
    
    private var emptyAlbumIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.title2)
                .foregroundColor(.red.opacity(0.6))
                .symbolEffect(.pulse, options: .repeat(.continuous).speed(2))
            
            Text(LocalizedString.Album.addPhotos)
                .font(.caption)
                .foregroundColor(.red)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 72)  // 새로운 그리드 높이와 일치
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.1))
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Album Detail Sheet
struct AlbumDetailSheet: View {
    let recipientId: UUID  // album 대신 recipientId로 참조
    @ObservedObject var sharingViewModel: SharingViewModel

    @State private var showingFullscreenPhoto = false
    @State private var selectedPhotoIndex = 0
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: PhotoItem?

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    // 실시간으로 앨범 가져오기
    private var currentAlbum: TemporaryAlbum? {
        sharingViewModel.temporaryAlbums.first { $0.recipient.id == recipientId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let album = currentAlbum {
                    VStack(spacing: 0) {
                        // Album info header
                        albumInfoHeader(for: album)
                            .padding()

                        Divider()

                        // Photos grid
                        if !album.isEmpty {
                            photosGridView(for: album)
                        } else {
                            emptyAlbumView(for: album)
                        }
                    }
                    .navigationTitle(album.recipient.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(LocalizedString.General.close) {
                                dismiss()
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            shareAlbumButton(for: album)
                        }
                    }
                } else {
                    // 로딩 중이거나 앨범을 찾을 수 없는 경우
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(theme.accentColor)

                        Text(LocalizedString.Album.loading)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(LocalizedString.General.close) {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .background(theme.primaryBackground)
        }
    }
    
    private func albumInfoHeader(for album: TemporaryAlbum) -> some View {
        HStack(spacing: 16) {
            // Direction indicator
            ZStack {
                Circle()
                    .fill(album.recipient.swiftUIColor)
                    .frame(width: 50, height: 50)

                Image(systemName: album.recipient.direction.systemIcon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .rotationEffect(album.recipient.direction.angle)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.recipient.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)

                Text("\(album.recipient.direction.displayName) 방향")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)

                Text("\(album.photoCount)장의 사진")
                    .font(.caption)
                    .foregroundColor(album.isEmpty ? .red : theme.accentColor)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
    
    private func photosGridView(for album: TemporaryAlbum) -> some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(Array(album.photos.enumerated()), id: \.element.id) { index, photo in
                        if let image = photo.displayImage {
                            Button(action: {
                                selectedPhotoIndex = index
                                showingFullscreenPhoto = true
                            }) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)  // 원본 비율 유지
                                    .frame(width: 110, height: 110)  // 고정 프레임
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()
                                    .overlay(
                                        // 삭제 버튼
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    photoToDelete = photo
                                                    showingDeleteConfirmation = true
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.white)
                                                        .background(
                                                            Circle()
                                                                .fill(Color.red.opacity(0.8))
                                                                .frame(width: 24, height: 24)
                                                        )
                                                }
                                                .padding(6)
                                            }
                                            Spacer()
                                        }
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }

            // Fullscreen Photo Viewer
            if showingFullscreenPhoto {
                FullscreenPhotoViewer(
                    photos: album.photos,
                    initialIndex: selectedPhotoIndex,
                    isPresented: $showingFullscreenPhoto,
                    photoService: PhotoService()
                )
                .zIndex(1000)
            }
        }
        .alert(LocalizedString.Alert.removeFromAlbum, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedString.General.cancel, role: .cancel) {
                photoToDelete = nil
            }
            Button(LocalizedString.General.delete, role: .destructive) {
                if let photo = photoToDelete {
                    Task {
                        await sharingViewModel.sendAsync(.removePhotoFromAlbum(photo, album.recipient.direction))
                    }
                }
                photoToDelete = nil
            }
        } message: {
            Text(LocalizedString.Alert.removeFromAlbumMessage)
        }
    }
    
    private func emptyAlbumView(for album: TemporaryAlbum) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(theme.accentColor.opacity(0.6))

            VStack(spacing: 8) {
                Text(LocalizedString.Album.empty)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Text(String(format: NSLocalizedString("album_empty_message", comment: ""), album.recipient.direction.displayName))
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func shareAlbumButton(for album: TemporaryAlbum) -> some View {
        Button {
            // Individual album sharing
            Task {
                await sharingViewModel.sendAsync(.shareIndividualAlbum(album))
            }
            dismiss()
        } label: {
            HStack(spacing: 8) {
                if sharingViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.secondaryText)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                }

                Text(sharingViewModel.isLoading ? LocalizedString.Album.sharing : LocalizedString.Button.shareAlbum)
                    .fontWeight(.semibold)
            }
            .foregroundColor(
                !album.isEmpty && !sharingViewModel.isLoading ?
                .green : theme.secondaryText
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .disabled(album.isEmpty || sharingViewModel.isLoading)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TemporaryAlbumPreview(
            sharingViewModel: {
                let vm = SharingViewModel()
                Task {
                    await vm.sendAsync(.createSession(Date()))
                    await vm.sendAsync(.addRecipient("친구1", .top))
                    await vm.sendAsync(.addRecipient("친구2", .right))
                    await vm.sendAsync(.addRecipient("친구3", .bottom))
                }
                return vm
            }()
        )
        .padding()
        
        Spacer()
    }
    .environment(\.theme, SpringThemeColors())
}
