import SwiftUI

/// 재사용 가능한 컴팩트 테마 전환 버튼
struct CompactThemeButton: View {
    @ObservedObject var themeViewModel: ThemeViewModel
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                let nextTheme: AppTheme
                switch themeViewModel.currentTheme {
                case .spring:
                    nextTheme = .auto
                case .auto:
                    nextTheme = .spring
                }
                themeViewModel.setTheme(nextTheme)
            }
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(theme.buttonBackground)
                    .overlay(
                        Circle()
                            .stroke(theme.buttonBorder, lineWidth: 1)
                    )
                    .frame(width: 32, height: 32)
                
                // Theme indicator icon
                Image(systemName: themeIconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryGradient)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: theme.primaryShadow, radius: 3, x: 0, y: 1)
    }
    
    private var themeIconName: String {
        switch themeViewModel.currentTheme {
        case .spring:
            return "sparkles"          // 골든 아워 테마일 때는 반짝임
        case .auto:
            return "circle.lefthalf.filled"  // 자동 테마일 때는 반달 (라이트/다크 모드)
        }
    }
}

#Preview {
    CompactThemeButton(themeViewModel: ThemeViewModel())
        .environment(\.theme, SpringThemeColors())
        .padding()
}
