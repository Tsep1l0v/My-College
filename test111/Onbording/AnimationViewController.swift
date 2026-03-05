//
//  AnimationViewController.swift
//  group schedule
//
//  Created by Дмитрий Цепилов on 10.12.2024.
//

import UIKit
import Lottie

class AnimationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Добавьте анимацию Lottie
        let animationView = LottieAnimationView(name: "focus")
        animationView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        animationView.center = CGPoint(x: view.center.x, y: view.center.y - 100) // Поднимите анимацию выше
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        view.addSubview(animationView)

        // Добавьте текст с заголовком и основным текстом
               let textLabel = UILabel()
               textLabel.numberOfLines = 0
               textLabel.textAlignment = .center
               textLabel.translatesAutoresizingMaskIntoConstraints = false

               let titleText = "Внимание!\n"
               let mainText = "Расписание в приложении загружается с сайта. Если данные некорректны, проблема в информации на сайте, а не в приложении"

               let attributedText = NSMutableAttributedString(string: titleText, attributes: [
                   .font: UIFont.boldSystemFont(ofSize: 30),
                   .foregroundColor: UIColor.label
               ])

               attributedText.append(NSAttributedString(string: mainText, attributes: [
                   .font: UIFont.systemFont(ofSize: 16),
                   .foregroundColor: UIColor.label
               ]))

               textLabel.attributedText = attributedText

               view.addSubview(textLabel)

               NSLayoutConstraint.activate([
                   textLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: -250), // Уменьшите расстояние
                   textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                   textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                   textLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
               ])
    }
}

