import OSLog

// MARK: - App Logger Extensions
extension Logger {
    private static let subsystem = "com.photoflick.app"

    // MARK: - Service Loggers
    static let photoService = Logger(subsystem: subsystem, category: "PhotoService")
    static let sharingService = Logger(subsystem: subsystem, category: "SharingService")
    static let themeService = Logger(subsystem: subsystem, category: "ThemeService")

    // MARK: - ViewModel Loggers
    static let photoViewModel = Logger(subsystem: subsystem, category: "PhotoViewModel")
    static let sharingViewModel = Logger(subsystem: subsystem, category: "SharingViewModel")
    static let themeViewModel = Logger(subsystem: subsystem, category: "ThemeViewModel")
    static let albumViewModel = Logger(subsystem: subsystem, category: "AlbumViewModel")

    // MARK: - UI Loggers
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let userAction = Logger(subsystem: subsystem, category: "UserAction")
}

// MARK: - Logger Helper Methods
extension Logger {
    /// Debug 로그 (개발 환경에서만 출력)
    func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        self.debug("[\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Info 로그 (일반 정보)
    func logInfo(_ message: String) {
        self.info("\(message, privacy: .public)")
    }

    /// Warning 로그 (경고)
    func logWarning(_ message: String) {
        self.warning("⚠️ \(message, privacy: .public)")
    }

    /// Error 로그 (에러)
    func logError(_ message: String, error: Error? = nil) {
        if let error = error {
            self.error("❌ \(message): \(error.localizedDescription, privacy: .public)")
        } else {
            self.error("❌ \(message, privacy: .public)")
        }
    }

    /// 성공 로그
    func logSuccess(_ message: String) {
        self.info("✅ \(message, privacy: .public)")
    }

    /// 사용자 액션 로그
    func logUserAction(_ action: String, details: String = "") {
        if details.isEmpty {
            self.info("👤 User Action: \(action, privacy: .public)")
        } else {
            self.info("👤 User Action: \(action, privacy: .public) - \(details, privacy: .public)")
        }
    }
}
