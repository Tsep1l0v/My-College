//
//  ButtonFactory.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

// ButtonFactory.swift
import UIKit

func createButton(title: String, imageName: String) -> UIButton {
    let btn = UIButton(type: .system)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.backgroundColor = UIColor.systemGray
    btn.layer.cornerRadius = 12
    btn.tintColor = .white
    btn.setTitle(title, for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

    if let originalImage = UIImage(named: imageName) {
        let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        }
        let whiteImage = resizedImage.withTintColor(.white, renderingMode: .alwaysTemplate)
        btn.setImage(whiteImage, for: .normal)
    }

    btn.isEnabled = false
    return btn
}


