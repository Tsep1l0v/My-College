import UIKit

enum AppTheme: Int {
    case light = 0
    case dark = 1
    case system = 2
}

final class ThemeManager {
    private static let themeKey = "appTheme"

    static var current: AppTheme {
        get {
            let defaults = UserDefaults.standard
            // Если пользователь ещё не выбирал тему — следуем за системой
            guard defaults.object(forKey: themeKey) != nil else {
                return .system
            }
            let raw = defaults.integer(forKey: themeKey)
            return AppTheme(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            applyThemeToAllWindows()
            // Отправляем уведомление об изменении темы
            NotificationCenter.default.post(name: Notification.Name("themeChanged"), object: nil)
        }
    }

    static func applyInitialTheme() {
        applyThemeToAllWindows()
    }

    private static func applyThemeToAllWindows() {
        if #available(iOS 13.0, *) {
            let style: UIUserInterfaceStyle
            switch current {
            case .light:
                style = .light
            case .dark:
                style = .dark
            case .system:
                style = .unspecified // Следуем системной теме
            }

            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { window in
                    window.overrideUserInterfaceStyle = style
                }
        } else {
            // До iOS 13 тёмной темы нет, оставляем светлую
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .light
        }
    }
}

