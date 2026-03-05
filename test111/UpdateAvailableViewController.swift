//
//  UpdateAvailableViewController.swift
//  test111
//
//  Created by Assistant on 20.01.2025.
//

import UIKit

final class UpdateAvailableViewController: UIViewController {
    
    private let appStoreVersion: String
    private let trackViewUrl: String?
    private let trackId: Int?
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let appIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.text = "Доступно обновление"
        label.numberOfLines = 0
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Вышла новая версия приложения. Обновите приложение для получения новых функций и исправлений."
        label.numberOfLines = 0
        return label
    }()
    
    private let versionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let currentVersionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let arrowLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "→"
        return label
    }()
    
    private let newVersionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setTitle("Обновить", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        return button
    }()
    
    private let laterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Позже", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return button
    }()
    
    init(appStoreVersion: String, trackViewUrl: String?, trackId: Int?) {
        self.appStoreVersion = appStoreVersion
        self.trackViewUrl = trackViewUrl
        self.trackId = trackId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAppIcon()
        setupVersionLabels()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(stackView)
        
        // Настройка версий
        versionStackView.addArrangedSubview(currentVersionLabel)
        versionStackView.addArrangedSubview(arrowLabel)
        versionStackView.addArrangedSubview(newVersionLabel)
        
        // Добавляем элементы в stackView
        stackView.addArrangedSubview(appIconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(versionStackView)
        stackView.addArrangedSubview(updateButton)
        stackView.addArrangedSubview(laterButton)
        
        // Настройка кнопок
        updateButton.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        laterButton.addTarget(self, action: #selector(laterTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Stack view
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            
            // App icon
            appIconImageView.widthAnchor.constraint(equalToConstant: 80),
            appIconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Buttons
            updateButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            updateButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            
            laterButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            laterButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        
        // Настройка modal presentation как pageSheet
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [
                        .custom(resolver: { context in
                            // Вычисляем нужную высоту на основе контента
                            return 380
                        })
                    ]
                } else {
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        }
    }
    
    private func loadAppIcon() {
        if let icon = Self.loadAppIcon() {
            appIconImageView.image = icon
        }
    }
    
    private func setupVersionLabels() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        currentVersionLabel.text = "v\(currentVersion)"
        newVersionLabel.text = "v\(appStoreVersion)"
    }
    
    @objc private func updateTapped() {
        // Пытаемся открыть trackViewUrl (самый надежный способ)
        if let urlString = trackViewUrl, let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let trackId = trackId {
            // Fallback: используем trackId для прямого открытия страницы приложения
            if let url = URL(string: "https://apps.apple.com/ru/app/id\(trackId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        dismiss(animated: true)
    }
    
    @objc private func laterTapped() {
        dismiss(animated: true)
    }
    
    private static func loadAppIcon() -> UIImage? {
        // Try to fetch primary app icon from bundle
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let last = files.last
        else { return nil }
        
        return UIImage(named: last)
    }
}







