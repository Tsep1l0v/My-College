//
//  SceneDelegate.swift
//  test111
//
//  Created by Дмитрий Цепилов on 02.12.2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Убедимся, что сцена является UIWindowScene
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Создаем окно
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Проверяем, был ли онбординг уже показан
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if hasSeenOnboarding {
            // Создаем главный контроллер
            let rootViewController = MainViewController() // Это ваш главный экран
            window.rootViewController = UINavigationController(rootViewController: rootViewController) // Используем навигационный контроллер
        } else {
            // Показываем онбординг
            let onboardingViewController = OnboardingViewController()
            onboardingViewController.completionHandler = {
                let rootViewController = MainViewController() // Это ваш главный экран
                window.rootViewController = UINavigationController(rootViewController: rootViewController) // Используем навигационный контроллер
            }
            window.rootViewController = onboardingViewController
        }

        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Здесь код для обработки отключения сцены, если нужно
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Здесь код для обработки активности сцены
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Код для обработки отказа от активности сцены
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Код для перехода из фона
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Код для перехода в фон
    }
}



