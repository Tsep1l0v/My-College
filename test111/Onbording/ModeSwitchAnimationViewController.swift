//
//  ModeSwitchAnimationViewController.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import UIKit

class ModeSwitchAnimationViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        return imageView
    }()
    
    private func setupImage() {
        // Выбираем картинку в зависимости от темы
        let imageName: String
        if ThemeManager.current == .dark {
            imageName = "mode_night"
        } else if ThemeManager.current == .system {
            // Для системной темы проверяем текущую тему интерфейса
            let isDark = traitCollection.userInterfaceStyle == .dark
            imageName = isDark ? "mode_night" : "mode"
        } else {
            imageName = "mode"
        }
        imageView.image = UIImage(named: imageName)
    }
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImage()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundView)
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 350), // 200 * 1.75 = 350
            imageView.heightAnchor.constraint(equalToConstant: 350) // 200 * 1.75 = 350
        ])
    }
    
    private func startAnimation() {
        // Анимация появления фона
        UIView.animate(withDuration: 0.4, animations: {
            self.backgroundView.alpha = 1
        }) { _ in
            // Анимация появления картинки
            UIView.animate(withDuration: 0.6, animations: {
                self.imageView.alpha = 1
                self.imageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { _ in
                // Длительная задержка для показа логотипа
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Анимация исчезновения картинки
                    UIView.animate(withDuration: 0.4, animations: {
                        self.imageView.alpha = 0
                        self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    }) { _ in
                        // Анимация исчезновения фона
                        UIView.animate(withDuration: 0.4, animations: {
                            self.backgroundView.alpha = 0
                        }) { _ in
                            // Вызываем completion и закрываем контроллер
                            self.completion?()
                            self.dismiss(animated: false)
                        }
                    }
                }
            }
        }
    }
} 