//
//  SceneDelegate.swift
//  test111
//
//  Created by Дмитрий Цепилов on 02.12.2024.
//

import UIKit
import QuartzCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Применяем тему к окну ДО того, как оно станет видимым
        // Это влияет на отображение Launch Screen и named colors
        if #available(iOS 13.0, *) {
            let style: UIUserInterfaceStyle
            switch ThemeManager.current {
            case .light:
                style = .light
            case .dark:
                style = .dark
            case .system:
                style = .unspecified // Следуем системной теме
            }
            window.overrideUserInterfaceStyle = style
        }

        func setRoot(_ vc: UIViewController) {
            // Плавная смена root после сплэша
            if let window = self.window {
                window.rootViewController = vc
                window.makeKeyAndVisible()
                let transition = CATransition()
                transition.type = .fade
                transition.duration = 0.25
                window.layer.add(transition, forKey: kCATransition)
            }
        }

        let showMain: () -> Void = {
            let main = MainViewController()
            setRoot(UINavigationController(rootViewController: main))
        }

        let showOnboarding: () -> Void = {
            let onboarding = OnboardingViewController()
            onboarding.completionHandler = {
                showMain()
            }
            setRoot(onboarding)
        }

        // Выбираем анимацию splash в зависимости от темы
        let splashAnimationName: String
        if ThemeManager.current == .dark {
            splashAnimationName = "splash-light-min"
        } else if ThemeManager.current == .system {
            // Для системной темы проверяем текущую тему интерфейса через windowScene
            let isDark = windowScene.traitCollection.userInterfaceStyle == .dark
            splashAnimationName = isDark ? "splash-light-min" : "splash"
        } else {
            splashAnimationName = "splash"
        }
        
        // Применяем сохраненную тему ко всем окнам (после выбора анимации)
        ThemeManager.applyInitialTheme()
        
        let splash = SplashViewController(animationName: splashAnimationName) { [weak self] in
            // Онбординг отключен: всегда показываем главный экран
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            DispatchQueue.main.async {
                showMain()
            }
        }

        window.rootViewController = splash
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Здесь код для обработки отключения сцены, если нужно
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Проверка обновлений при возврате приложения в активное состояние
        // (проверка выполнится только если прошло достаточно времени с последней проверки)
        AppUpdateChecker.shared.checkForUpdate()
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



