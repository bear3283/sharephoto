import Foundation

// MARK: - AppTheme Enum
enum AppTheme: String, CaseIterable {
    case spring = "spring"
    case sleek = "sleek"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .spring: return "봄 테마"
        case .sleek: return "시크 테마"
        case .auto: return "자동 (시스템 설정)"
        }
    }

    var isSystemBased: Bool {
        self == .auto
    }
}