//
//  SplashViewController.swift
//  test111
//
//  Created by GPT Assistant on 12.08.2025.
//

import UIKit
import Lottie

final class SplashViewController: UIViewController {
    private let animationName: String
    var onCompletion: (() -> Void)?

    private var animationView: LottieAnimationView?

    init(animationName: String = "splash", onCompletion: (() -> Void)? = nil) {
        self.animationName = animationName
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        // Устанавливаем цвет фона как можно раньше, чтобы он был виден сразу
        updateBackgroundColor()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playAnimation()
    }
    
    private func updateBackgroundColor() {
        // Используем цвет LaunchBackground из Assets, который автоматически адаптируется к теме
        // Если named color недоступен, используем fallback в зависимости от темы
        if let launchBackgroundColor = UIColor(named: "LaunchBackground") {
            view.backgroundColor = launchBackgroundColor
        } else {
            // Fallback: используем правильный цвет в зависимости от темы
            let theme = ThemeManager.current
            switch theme {
            case .dark:
                view.backgroundColor = .black
            case .light:
                view.backgroundColor = .white
            case .system:
                // Для системной темы проверяем текущую тему интерфейса
                // В loadView traitCollection может быть еще не готов, используем системную тему
                if #available(iOS 13.0, *) {
                    // Проверяем системную тему через UIScreen
                    if UITraitCollection.current.userInterfaceStyle == .dark {
                        view.backgroundColor = .black
                    } else {
                        view.backgroundColor = .white
                    }
                } else {
                    view.backgroundColor = .white
                }
            }
        }
    }

    private func playAnimation() {
        // Пытаемся загрузить анимацию по имени из бандла
        if let animation = LottieAnimation.named(animationName) {
            let animationView = LottieAnimationView(animation: animation)
            self.animationView = animationView

            animationView.translatesAutoresizingMaskIntoConstraints = false
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .playOnce

            view.addSubview(animationView)

            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: view.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            animationView.play { [weak self] _ in
                self?.finish()
            }
        } else {
            // Фолбэк: если файла нет, просто подождём чуть-чуть и продолжим
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.finish()
            }
        }
    }

    private func finish() {
        onCompletion?()
    }
}

