import Foundation
import Combine
import SwiftUI

// MARK: - ThemeViewModel State
struct ThemeViewModelState {
    var currentTheme: AppTheme = .spring
    var availableThemes: [AppTheme] = []
    var colorScheme: ColorScheme?
    var effectiveTheme: AppTheme = .spring
}

// MARK: - ThemeViewModel Actions
enum ThemeViewModelAction {
    case loadTheme
    case setTheme(AppTheme)
    case loadAvailableThemes
    case updateColorScheme(ColorScheme)
}

// MARK: - ThemeViewModel
@MainActor
final class ThemeViewModel: ViewModelProtocol {
    typealias State = ThemeViewModelState
    typealias Action = ThemeViewModelAction
    
    @Published private(set) var state = ThemeViewModelState()
    
    private let themeService: ThemeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentTheme: AppTheme { state.currentTheme }
    var availableThemes: [AppTheme] { state.availableThemes }

    var colors: ThemeColors {
        switch state.effectiveTheme {
        case .spring:
            return SpringThemeColors()
        case .auto:
            return SystemThemeColors()
        }
    }
    
    // MARK: - Initialization
    init(themeService: ThemeServiceProtocol = ThemeService()) {
        self.themeService = themeService
        setupBindings()
    }
    
    // MARK: - Public Interface
    func send(_ action: Action) {
        Task { @MainActor in
            await handleAction(action)
        }
    }
    
    func sendAsync(_ action: Action) async {
        await handleAction(action)
    }
    
    // MARK: - Convenience Methods
    func setTheme(_ theme: AppTheme) {
        send(.setTheme(theme))
    }
    
    // MARK: - Action Handling
    private func handleAction(_ action: Action) async {
        switch action {
        case .loadTheme:
            await loadSavedTheme()

        case .setTheme(let theme):
            await setCurrentTheme(theme)

        case .loadAvailableThemes:
            await loadAvailableThemes()

        case .updateColorScheme(let colorScheme):
            await updateColorScheme(colorScheme)
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Load theme and available themes on initialization
        Task {
            await loadSavedTheme()
            await loadAvailableThemes()
        }
    }
    
    private func loadSavedTheme() async {
        let savedTheme = themeService.loadSavedTheme()
        state.currentTheme = savedTheme
        updateEffectiveTheme()
    }

    private func setCurrentTheme(_ theme: AppTheme) async {
        state.currentTheme = theme
        themeService.saveTheme(theme)
        updateEffectiveTheme()
    }

    private func loadAvailableThemes() async {
        let themes = themeService.getAvailableThemes()
        state.availableThemes = themes
    }

    private func updateColorScheme(_ colorScheme: ColorScheme) async {
        state.colorScheme = colorScheme
        updateEffectiveTheme()
    }

    private func updateEffectiveTheme() {
        // 사용자가 선택한 테마를 그대로 사용
        // .spring: 고정 봄 테마
        // .auto: 시스템 다크/라이트 모드에 자동 적응
        state.effectiveTheme = state.currentTheme
    }
}