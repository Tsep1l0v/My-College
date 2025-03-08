//
//  AppDelegate.swift
//  test111
//
//  Created by Дмитрий Цепилов on 02.12.2024.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Создаем окно с полным экраном
        let window = UIWindow(frame: UIScreen.main.bounds)
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

        return true
    }
}

