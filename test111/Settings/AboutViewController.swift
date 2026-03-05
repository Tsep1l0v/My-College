//
//  AboutViewController.swift
//
//  Created by Assistant on 20.10.2025.
//

import UIKit
import MyTrackerSDK

final class AboutViewController: UIViewController {

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let appIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.bundleIdentifier
        return label
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        label.text = "Версия: \(version)"
        return label
    }()

    private let copyrightLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Copyright © 2024 - 2025"
        return label
    }()

    private lazy var telegramButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Адаптивный фон для светлой и темной темы
        button.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1.0) // темный фон для темной темы
            } else {
                return UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0) // светлый фон для светлой темы
            }
        }
        button.layer.cornerRadius = 16
        button.setTitle("", for: .normal)
        if let icon = UIImage(named: "telega") ?? UIImage(named: "telegram") {
            button.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.40, green: 0.65, blue: 1.0, alpha: 1.0) // более яркий синий для темной темы
            } else {
                return UIColor(red: 0.18, green: 0.44, blue: 0.85, alpha: 1.0) // тёмно-нежный синий для светлой темы
            }
        }
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        MRMyTracker.trackEvent(name: "Открыть вкладку авторское право")
        view.backgroundColor = .systemBackground

        if let icon = Self.loadAppIcon() {
            appIconImageView.image = icon
        }

        view.addSubview(stackView)

        // Горизонтальный ряд: иконка слева, справа — название и версия
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 8
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        let rightColStack = UIStackView(arrangedSubviews: [titleLabel, versionLabel])
        rightColStack.axis = .vertical
        rightColStack.alignment = .leading
        rightColStack.spacing = 2
        rightColStack.translatesAutoresizingMaskIntoConstraints = false

        rowStack.addArrangedSubview(appIconImageView)
        rowStack.addArrangedSubview(rightColStack)

        stackView.addArrangedSubview(rowStack)
        stackView.addArrangedSubview(copyrightLabel)
        stackView.addArrangedSubview(telegramButton)

        telegramButton.addTarget(self, action: #selector(openTelegram), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -0),

            appIconImageView.heightAnchor.constraint(equalToConstant: 64),
            appIconImageView.widthAnchor.constraint(equalToConstant: 64),

            telegramButton.heightAnchor.constraint(equalToConstant: 52),
            telegramButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            telegramButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])

        // Sheet style (iOS 15+), на iOS 16 уменьшаем высоту через кастомный detent
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [
                        .custom(resolver: { _ in
                            return 240 // уменьшена высота после удаления логотипа
                        })
                    ]
                } else {
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
            }
        }
    }

    @objc private func openTelegram() {
        guard let url = URL(string: "https://t.me/+oIslJtlz52cxYzZi") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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


