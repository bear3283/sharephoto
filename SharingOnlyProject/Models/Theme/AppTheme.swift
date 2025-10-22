import Foundation

// MARK: - AppTheme Enum
enum AppTheme: String, CaseIterable {
    case spring = "golden"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .spring: return "골든 아워"
        case .auto: return "자동 (시스템 설정)"
        }
    }

    var isSystemBased: Bool {
        self == .auto
    }
}