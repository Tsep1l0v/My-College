//
//  WidgetInfoViewController.swift
//  test111
//
//  Created by GPT Assistant
//

import UIKit

class WidgetInfoViewController: UIViewController {
    
    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Preview")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Добавлены виджеты!"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Теперь вы можете добавить виджеты с расписанием на главный экран вашего iPhone для быстрого доступа к расписанию"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Добавляем изображение Preview на весь экран
        view.addSubview(previewImageView)
        
        // Добавляем текст поверх изображения
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        
        // Добавляем кнопку крестик
        view.addSubview(closeButton)
        
        // Настройка кнопки
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Preview на весь экран
            previewImageView.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Заголовок сверху
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Описание под заголовком
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Кнопка крестик справа сверху
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeButtonTapped() {
        // Сохраняем флаг, что окно уже было показано
        UserDefaults.standard.set(true, forKey: "hasSeenWidgetInfo")
        
        // Закрываем окно с анимацией
        dismiss(animated: true)
    }
    
}







