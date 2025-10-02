import SwiftUI

// MARK: - Sleek Theme Implementation
struct SleekThemeColors: ThemeColors {
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)], // Gold gradient
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.8, green: 0.68, blue: 0.2), Color(red: 0.7, green: 0.58, blue: 0.1)], // Darker gold
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var accentColor: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
    }
    
    var primaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.0, green: 0.0, blue: 0.0),  // Pure black for photo focus
                Color(red: 0.02, green: 0.02, blue: 0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var secondaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.03, blue: 0.03),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.08),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var overlayBackground: Color {
        Color.black.opacity(0.85)  // Darker overlay for photo focus
    }
    
    var primaryText: Color {
        Color(red: 1.0, green: 0.9, blue: 0.5) // Golden text for high contrast
    }

    var secondaryText: Color {
        Color(red: 0.9, green: 0.8, blue: 0.4) // Softer gold
    }

    var accentText: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var buttonBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.1),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5),  // Gold border
                Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var favoriteActive: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0) // Bright gold
    }

    var favoriteInactive: Color {
        Color(red: 0.6, green: 0.5, blue: 0.2).opacity(0.4) // Dimmed gold
    }
    
    var saveColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.9, blue: 0.3), Color(red: 0.9, green: 0.8, blue: 0.2)],  // Gold save
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var deleteColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.9, green: 0.15, blue: 0.15)],  // Bright red for visibility
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var primaryShadow: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2)  // Golden shadow
    }

    var secondaryShadow: Color {
        Color.black.opacity(0.4)  // Dark shadow for depth
    }
}