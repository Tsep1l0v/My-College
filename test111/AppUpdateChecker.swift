//
//  AppUpdateChecker.swift
//  test111
//
//  Created by Assistant on 20.01.2025.
//

import UIKit

final class AppUpdateChecker {
    static let shared = AppUpdateChecker()
    
    private let bundleIdentifier = "com.tsep1l0v.myimsit"
    private let lastCheckKey = "lastUpdateCheckDate"
    private let updateCheckInterval: TimeInterval = 24 * 60 * 60 // Проверка раз в день
    
    private init() {}
    
    /// Проверяет наличие обновления в App Store
    /// - Parameters:
    ///   - force: Принудительная проверка, игнорируя интервал
    ///   - completion: Замыкание с результатом проверки (true если есть обновление)
    func checkForUpdate(force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        // Проверяем, нужно ли выполнять проверку (если не принудительная)
        if !force {
            if let lastCheckDate = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
                let timeSinceLastCheck = Date().timeIntervalSince(lastCheckDate)
                if timeSinceLastCheck < updateCheckInterval {
                    // Проверка уже выполнялась недавно
                    completion?(false)
                    return
                }
            }
        }
        
        // Получаем текущую версию приложения
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("⚠️ Не удалось получить текущую версию приложения")
            completion?(false)
            return
        }
        
        // Формируем URL для запроса к iTunes API
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&country=ru") else {
            print("⚠️ Неверный URL для проверки обновлений")
            completion?(false)
            return
        }
        
        // Выполняем запрос
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Ошибка при проверке обновлений: \(error.localizedDescription)")
                completion?(false)
                return
            }
            
            guard let data = data else {
                print("⚠️ Нет данных от iTunes API")
                completion?(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    
                    // Проверяем, что приложение найдено в App Store
                    guard let firstResult = results.first,
                          let appStoreVersion = firstResult["version"] as? String else {
                        print("ℹ️ Приложение не найдено в App Store или еще не опубликовано")
                        completion?(false)
                        return
                    }
                    
                    // Сохраняем дату последней проверки
                    UserDefaults.standard.set(Date(), forKey: self.lastCheckKey)
                    
                    print("📱 Текущая версия: \(currentVersion), версия в App Store: \(appStoreVersion)")
                    
                    // Сравниваем версии
                    let hasUpdate = self.compareVersions(current: currentVersion, store: appStoreVersion)
                    
                    if hasUpdate {
                        DispatchQueue.main.async {
                            let trackId = firstResult["trackId"] as? Int
                            self.showUpdateAlert(
                                appStoreVersion: appStoreVersion,
                                trackViewUrl: firstResult["trackViewUrl"] as? String,
                                trackId: trackId
                            )
                        }
                    }
                    
                    completion?(hasUpdate)
                } else {
                    print("⚠️ Не удалось распарсить ответ от iTunes API")
                    completion?(false)
                }
            } catch {
                print("❌ Ошибка парсинга JSON: \(error.localizedDescription)")
                completion?(false)
            }
        }
        
        task.resume()
    }
    
    /// Сравнивает версии приложения
    /// - Parameters:
    ///   - current: Текущая версия приложения
    ///   - store: Версия в App Store
    /// - Returns: true если версия в App Store новее
    private func compareVersions(current: String, store: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let storeComponents = store.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(currentComponents.count, storeComponents.count)
        
        for i in 0..<maxLength {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let storeValue = i < storeComponents.count ? storeComponents[i] : 0
            
            if storeValue > currentValue {
                return true
            } else if storeValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    /// Показывает кастомный bottom sheet с предложением обновиться
    private func showUpdateAlert(appStoreVersion: String, trackViewUrl: String?, trackId: Int?) {
        guard let topViewController = getTopViewController() else {
            print("⚠️ Не удалось найти top view controller для показа алерта")
            return
        }
        
        let updateVC = UpdateAvailableViewController(
            appStoreVersion: appStoreVersion,
            trackViewUrl: trackViewUrl,
            trackId: trackId
        )
        
        topViewController.present(updateVC, animated: true)
    }
    
    /// Получает top view controller для показа алерта
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        // Если это navigation controller, берем top view controller
        if let navigationController = topViewController as? UINavigationController {
            topViewController = navigationController.topViewController ?? topViewController
        }
        
        // Если это tab bar controller, берем selected view controller
        if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController ?? topViewController
        }
        
        return topViewController
    }
}








