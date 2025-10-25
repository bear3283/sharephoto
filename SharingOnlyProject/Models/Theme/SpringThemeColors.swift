import SwiftUI

// MARK: - Golden Hour Theme Implementation
struct SpringThemeColors: ThemeColors {
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.722, blue: 0.302),  // #FFB84D Warm Gold
                Color(red: 1.0, green: 0.588, blue: 0.208)   // #FF9635 Amber
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.8, blue: 0.4),      // Lighter gold
                Color(red: 1.0, green: 0.7, blue: 0.35)      // Medium amber
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var accentColor: Color {
        Color(red: 1.0, green: 0.588, blue: 0.208)  // #FF9635 Amber
    }
    
    var primaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.98, blue: 0.94),    // Warm cream
                Color(red: 1.0, green: 0.96, blue: 0.88)     // Soft peach
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var secondaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.96, blue: 0.90),    // Light beige
                Color(red: 0.98, green: 0.94, blue: 0.86)    // Warm sand
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.97, blue: 0.92),    // Ivory
                Color(red: 0.99, green: 0.95, blue: 0.88)    // Cream
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var overlayBackground: Color {
        Color.black.opacity(0.4)
    }
    
    var primaryText: Color {
        Color(red: 0.6, green: 0.4, blue: 0.2)      // Warm brown
    }

    var secondaryText: Color {
        Color(red: 0.7, green: 0.5, blue: 0.3)      // Light brown
    }
    
    var accentText: LinearGradient {
        primaryGradient
    }
    
    var buttonBackground: LinearGradient {
        primaryBackground
    }
    
    var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.722, blue: 0.302).opacity(0.3),  // Gold with transparency
                Color(red: 1.0, green: 0.588, blue: 0.208).opacity(0.3)   // Amber with transparency
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
    
    var primaryShadow: Color {
        Color(red: 1.0, green: 0.588, blue: 0.208).opacity(0.15)  // Amber shadow
    }

    var secondaryShadow: Color {
        Color(red: 1.0, green: 0.722, blue: 0.302).opacity(0.1)   // Gold shadow
    }
}