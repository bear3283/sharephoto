import SwiftUI

/// 재사용 가능한 사진 카운터 컴포넌트
struct PhotoCounter: View {
    let currentIndex: Int
    let totalCount: Int
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Text("\(currentIndex + 1) / \(totalCount)")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(theme.primaryGradient)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(theme.primaryBackground)
                    .overlay(
                        Capsule()
                            .stroke(theme.buttonBorder, lineWidth: 1)
                    )
            )
            .shadow(color: theme.primaryShadow, radius: 6, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        PhotoCounter(currentIndex: 0, totalCount: 1)
        PhotoCounter(currentIndex: 4, totalCount: 25)
        PhotoCounter(currentIndex: 99, totalCount: 100)
    }
    .environment(\.theme, SpringThemeColors())
    .padding()
}