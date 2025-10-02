import SwiftUI

struct ThemeSwitcher: View {
    @ObservedObject var themeViewModel: ThemeViewModel
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Text("테마")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(theme.secondaryGradient)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.self) { appTheme in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeViewModel.send(.setTheme(appTheme))
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(themePreviewColor(for: appTheme))
                                .frame(width: 12, height: 12)
                            
                            if themeViewModel.currentTheme == appTheme {
                                Text(appTheme.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.primaryText)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    themeViewModel.currentTheme == appTheme ?
                                    theme.buttonBackground :
                                    LinearGradient(colors: [Color.clear], startPoint: .center, endPoint: .center)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            themeViewModel.currentTheme == appTheme ?
                                            theme.buttonBorder :
                                            LinearGradient(colors: [Color.clear], startPoint: .center, endPoint: .center),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.primaryBackground)
                .shadow(color: theme.secondaryShadow, radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    private func themePreviewColor(for theme: AppTheme) -> LinearGradient {
        switch theme {
        case .spring:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleek:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.0, green: 0.48, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .auto:
            return LinearGradient(
                colors: [Color(red: 0.5, green: 0.5, blue: 0.5), Color(red: 0.3, green: 0.3, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    ThemeSwitcher(themeViewModel: ThemeViewModel())
        .environment(\.theme, SpringThemeColors())
}