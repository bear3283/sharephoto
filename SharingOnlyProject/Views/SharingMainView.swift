//
//  SharingMainView.swift
//  SharingOnlyProject
//
//  Created by Claude on 9/11/25.
//

import SwiftUI

struct SharingMainView: View {
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // Status Bar 스타일 계산
    private var preferredStatusBarStyle: ColorScheme {
        switch themeViewModel.currentTheme {
        case .spring:
            // Golden Hour 테마: 밝은 배경이므로 어두운 상태바 필요
            return .light
        case .auto:
            // 자동 테마: 시스템 설정 따름
            return colorScheme
        }
    }

    var body: some View {
        ZStack {
            // Background that responds to theme
            Rectangle()
                .fill(themeViewModel.colors.primaryBackground)
                .ignoresSafeArea()

            SharingView(photoViewModel: photoViewModel, themeViewModel: themeViewModel)
        }
        .accentColor(themeViewModel.colors.accentColor)
        .environment(\.theme, themeViewModel.colors)
        .preferredColorScheme(preferredStatusBarStyle)
        .onChange(of: colorScheme) { _, newColorScheme in
            themeViewModel.send(.updateColorScheme(newColorScheme))
        }
        .onAppear {
            themeViewModel.send(.updateColorScheme(colorScheme))
        }
    }
}

#Preview {
    SharingMainView()
        .environment(\.theme, PreviewData.sampleThemeColors)
}
