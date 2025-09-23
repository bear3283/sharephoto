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
    
    var body: some View {
        SharingView(photoViewModel: photoViewModel, themeViewModel: themeViewModel)
            .accentColor(themeViewModel.colors.accentColor)
            .environment(\.theme, themeViewModel.colors)
            .preferredColorScheme(themeViewModel.currentTheme == .sleek ? .dark : .light)
    }
}

#Preview {
    SharingMainView()
        .environment(\.theme, PreviewData.sampleThemeColors)
}
