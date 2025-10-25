import SwiftUI

// MARK: - System Theme Implementation (Auto Dark/Light Mode)
struct SystemThemeColors: ThemeColors {
    // MARK: - Primary Colors (브랜드 칼라 유지)
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.3, green: 0.6, blue: 0.5), Color(red: 0.2, green: 0.5, blue: 0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var accentColor: Color {
        Color(red: 0.2, green: 0.7, blue: 0.4)
    }

    // MARK: - Background Colors (시스템 칼라 사용)
    var primaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color(uiColor: .systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var secondaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .secondarySystemBackground),
                Color(uiColor: .secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .secondarySystemGroupedBackground),
                Color(uiColor: .secondarySystemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var overlayBackground: Color {
        Color.black.opacity(0.4)
    }

    // MARK: - Text Colors (시스템 칼라 사용)
    var primaryText: Color {
        Color(uiColor: .label)
    }

    var secondaryText: Color {
        Color(uiColor: .secondaryLabel)
    }

    var accentText: LinearGradient {
        primaryGradient
    }

    // MARK: - Interactive Colors
    var buttonBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .tertiarySystemBackground),
                Color(uiColor: .tertiarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.7, blue: 0.4).opacity(0.3),
                Color(red: 0.1, green: 0.6, blue: 0.8).opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var favoriteActive: Color {
        .yellow
    }

    var favoriteInactive: Color {
        Color.yellow.opacity(0.4)
    }

    // MARK: - Status Colors (브랜드 칼라 유지)
    var saveColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.7, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var deleteColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.6, blue: 0.6), Color(red: 0.9, green: 0.4, blue: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Shadow Colors (시스템 적응형)
    var primaryShadow: Color {
        Color(uiColor: .systemGray3).opacity(0.3)
    }

    var secondaryShadow: Color {
        Color(uiColor: .systemGray4).opacity(0.2)
    }
}
