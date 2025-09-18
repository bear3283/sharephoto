//
//  PhotoPickerView.swift
//  SharingOnlyProject
//
//  Created by Claude on 9/18/25.
//

import SwiftUI
import UIKit
import PhotosUI

// MARK: - Photo Picker Wrapper for SwiftUI
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    let onPhotoPicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPhotoPicked(image)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Photo Add Action Sheet
struct PhotoAddActionSheet: View {
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.theme) private var theme

    let onPhotoPicked: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(theme.secondaryText.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 12)

            // Title
            Text("사진 추가")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 24)

            // Action buttons
            VStack(spacing: 16) {
                // Camera button
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    PhotoAddButton(
                        icon: "camera.fill",
                        title: "카메라로 촬영",
                        subtitle: "새 사진을 촬영합니다"
                    ) {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    }
                }

                // Photo library button
                PhotoAddButton(
                    icon: "photo.on.rectangle",
                    title: "갤러리에서 선택",
                    subtitle: "기존 사진을 선택합니다"
                ) {
                    imagePickerSource = .photoLibrary
                    showingImagePicker = true
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Cancel button
            Button("취소") {
                isPresented = false
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(theme.primaryBackground)
        .sheet(isPresented: $showingImagePicker) {
            PhotoPickerView(
                isPresented: $showingImagePicker,
                sourceType: imagePickerSource,
                onPhotoPicked: onPhotoPicked
            )
        }
    }
}

// MARK: - Photo Add Button Component
struct PhotoAddButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                    )

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Floating Add Button
struct FloatingAddButton: View {
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Multi-Photo Picker (iOS 14+)
@available(iOS 14.0, *)
struct MultiPhotoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let selectionLimit: Int // 0 = unlimited
    let onPhotosSelected: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = selectionLimit
        config.filter = .images
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiPhotoPickerView

        init(_ parent: MultiPhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard !results.isEmpty else { return }

            // Process selected photos asynchronously
            Task {
                await withTaskGroup(of: UIImage?.self) { group in
                    for result in results {
                        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                            group.addTask {
                                await withCheckedContinuation { continuation in
                                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                                        if let image = object as? UIImage {
                                            continuation.resume(returning: image)
                                        } else {
                                            print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                                            continuation.resume(returning: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    var images: [UIImage] = []
                    for await image in group {
                        if let image = image {
                            images.append(image)
                        }
                    }

                    await MainActor.run {
                        if !images.isEmpty {
                            parent.onPhotosSelected(images)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Photo Add Action Sheet
struct EnhancedPhotoAddActionSheet: View {
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var showingMultiPhotoPicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.theme) private var theme

    let onPhotoPicked: (UIImage) -> Void
    let onMultiplePhotosSelected: ([UIImage]) -> Void
    let maxSelectionCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(theme.secondaryText.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 12)

            // Title
            Text("사진 추가")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 24)

            // Action buttons
            VStack(spacing: 16) {
                // Multiple photos from gallery
                if #available(iOS 14.0, *) {
                    PhotoAddButton(
                        icon: "photo.stack",
                        title: "여러 사진 선택",
                        subtitle: maxSelectionCount == 0 ? "갤러리에서 여러 장을 선택합니다" : "최대 \(maxSelectionCount)장까지 선택 가능"
                    ) {
                        showingMultiPhotoPicker = true
                    }
                }

                // Camera button
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    PhotoAddButton(
                        icon: "camera.fill",
                        title: "카메라로 촬영",
                        subtitle: "새 사진을 촬영합니다"
                    ) {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    }
                }

                // Single photo from gallery
                PhotoAddButton(
                    icon: "photo.on.rectangle",
                    title: "갤러리에서 한 장 선택",
                    subtitle: "기존 사진 하나를 선택합니다"
                ) {
                    imagePickerSource = .photoLibrary
                    showingImagePicker = true
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Cancel button
            Button("취소") {
                isPresented = false
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(theme.primaryBackground)
        .sheet(isPresented: $showingImagePicker) {
            PhotoPickerView(
                isPresented: $showingImagePicker,
                sourceType: imagePickerSource,
                onPhotoPicked: onPhotoPicked
            )
        }
        .sheet(isPresented: $showingMultiPhotoPicker) {
            if #available(iOS 14.0, *) {
                MultiPhotoPickerView(
                    isPresented: $showingMultiPhotoPicker,
                    selectionLimit: maxSelectionCount,
                    onPhotosSelected: onMultiplePhotosSelected
                )
            }
        }
    }
}

// MARK: - Batch Upload Progress View
struct BatchUploadProgressView: View {
    let currentIndex: Int
    let totalCount: Int
    let isVisible: Bool
    @Environment(\.theme) private var theme

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var body: some View {
        if isVisible && totalCount > 0 {
            VStack(spacing: 12) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.accentColor))
                    .scaleEffect(y: 2)

                // Status text
                VStack(spacing: 4) {
                    Text("사진 추가 중...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)

                    Text("\(currentIndex)/\(totalCount) 완료")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.primaryBackground)
                    .shadow(color: theme.primaryShadow, radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Compact Batch Progress Toast
struct BatchProgressToast: View {
    let currentIndex: Int
    let totalCount: Int
    let isVisible: Bool
    @Environment(\.theme) private var theme

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var body: some View {
        if isVisible && totalCount > 0 {
            HStack(spacing: 12) {
                // Progress icon
                ZStack {
                    Circle()
                        .stroke(theme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.accentColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }

                // Status text
                VStack(alignment: .leading, spacing: 2) {
                    Text("사진 추가 중")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)

                    Text("\(currentIndex)/\(totalCount)")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(theme.secondaryBackground)
                    .shadow(color: theme.primaryShadow, radius: 4, x: 0, y: 2)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EnhancedPhotoAddActionSheet(
            isPresented: .constant(true),
            onPhotoPicked: { _ in },
            onMultiplePhotosSelected: { images in
                print("Selected \(images.count) photos")
            },
            maxSelectionCount: 10
        )
        .frame(height: 400)

        FloatingAddButton {
            print("Add button tapped")
        }
    }
    .environment(\.theme, PreviewData.sampleThemeColors)
}