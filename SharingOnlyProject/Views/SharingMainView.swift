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
