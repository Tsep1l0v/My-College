//
//  CustomSelectionCardView.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import UIKit

class CustomSelectionCardView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tapGesture = UITapGestureRecognizer()

    var onTap: (() -> Void)?

    init(title: String, iconName: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 15
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 6

        // Настройка иконки
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Заголовок
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Подзаголовок
        subtitleLabel.text = "Не выбрано"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        // Ограничения
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(didTap))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTap() {
        UIView.animate(withDuration: 0.1,
                       animations: { self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) },
                       completion: { _ in
                           UIView.animate(withDuration: 0.1) {
                               self.transform = CGAffineTransform.identity
                           }
                       })
        onTap?()
    }

    func updateSubtitle(_ subtitle: String?) {
        subtitleLabel.text = subtitle
    }
}
