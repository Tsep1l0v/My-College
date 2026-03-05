//
//  ViewController.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import UIKit
import SwiftSoup
import YandexMobileAds
import MyTrackerSDK

class ViewController: UIViewController, UITabBarDelegate {
    private var tabBar: UITabBar!
    private var indicatorView: UIView!
    private var currentItemIndex: Int = 0
    weak var delegate: GroupSelectionDelegate?

    private let courseCard = CustomSelectionCardView(title: "Курс", iconName: "graduationcap")
    private let specialtyCard = CustomSelectionCardView(title: "Специальность", iconName: "books.vertical")
    private let groupCard = CustomSelectionCardView(title: "Группа", iconName: "person.3")

    private var groups: [(name: String, url: String)] = []
    private var selectedCourse: String?
    private var selectedSpecialty: String?
    var selectedGroup: String?

    let button: UIButton = createButton(title: " Выбрать", imageName: "icons8")

    // Реклама: адаптивный inline-баннер
    private var yandexAdView: AdView?
    private var lastAdWidth: CGFloat = 0

    private let titleLabel: UILabel = {
            let label = UILabel()
            label.text = "Выбор группы"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

    private var apiLevels: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = nil

        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.backgroundColor = .systemGroupedBackground
        setupUI()
        view.addSubview(button)
        
        // Подписываемся на уведомление об изменении темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: Notification.Name("themeChanged"),
            object: nil
        )

        let buttonWidth: CGFloat = UIScreen.main.bounds.width * 0.9
        let buttonHeight: CGFloat = 65.0
        let buttonTopOffset: CGFloat = UIScreen.main.bounds.height * 0.35

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonTopOffset),
            button.heightAnchor.constraint(equalToConstant: buttonHeight),
            button.widthAnchor.constraint(equalToConstant: buttonWidth)
        ])

        button.addTarget(self, action: #selector(buttonTouchDown), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])

        button.addTarget(self, action: #selector(saveSelection), for: .touchUpInside)
        
        // Настраиваем адаптивный баннер под кнопкой, если разрешена реклама
        if AdManager.shared.shouldShowAds() {
            setupAdaptiveAdBanner()
        }
        
        loadSavedSelection()
        updateButtonState()

        preloadFiltersFromAPI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Трекинг события просмотра рекламы (независимо от того, включена реклама или нет)
        MRMyTracker.trackEvent(name: "Просмотр рекламы")
        refreshAdBannerIfNeeded()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Обновляем баннер при смене системной темы (если выбрана системная тема)
        if ThemeManager.current == .system,
           traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            refreshAdBannerIfNeeded()
        }
    }

    @objc func buttonTouchDown() {
        if let darkerColor = button.backgroundColor?.darker(by: 10.0) {
            UIView.animate(withDuration: 0.1) {
                self.button.backgroundColor = darkerColor
            }
        }
    }

    @objc func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.button.backgroundColor = UIColor.systemBlue
        }
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [courseCard, specialtyCard, groupCard])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100)
        ])

        courseCard.onTap = { [weak self] in
            guard let self = self else { return }
            ScheduleRepository.shared.courses { result in
                switch result {
                case .success(let courseInts):
                    let items = courseInts.sorted().map { "\($0) курс" }
                    DispatchQueue.main.async {
                        self.showPicker(title: "Выберите курс", items: items) { selected in
                            self.selectedCourse = selected
                            self.courseCard.updateSubtitle(selected)
                            self.updateGroups()
                            self.didSelectCourse(selected)
                        }
                    }
                case .failure:
                    // Если не удалось загрузить, но есть выбранное ранее значение — оставляем его
                    DispatchQueue.main.async {
                        let message = "Не удалось загрузить курсы. Проверьте соединение."
                        self.showErrorAlert(message: message)
                    }
                }
            }
        }

        specialtyCard.onTap = { [weak self] in
            guard let self = self else { return }
            let presentPicker: ([String]) -> Void = { levels in
                let items = ["Все специальности"] + levels
                self.showPicker(title: "Выберите специальность", items: items) { selected in
                    // Сохраняем буквальное значение, чтобы корректно отображалось после перезапуска
                    self.selectedSpecialty = selected
                    self.specialtyCard.updateSubtitle(selected)
                    self.updateGroups()
                    self.didSelectSpecialty(selected)
                }
            }
            if self.apiLevels.isEmpty {
                fetchLevels { result in
                    switch result {
                    case .success(let levels):
                        DispatchQueue.main.async {
                            self.apiLevels = levels
                            presentPicker(levels)
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            // Fallback-список уровней образования, если не удалось получить с сервера
                            presentPicker(["СПО", "Бакалавриат", "Специалитет", "Магистратура"])
                        }
                    }
                }
            } else {
                presentPicker(self.apiLevels)
            }
        }

        groupCard.onTap = { [weak self] in
            guard let self = self, !self.groups.isEmpty else { return }
            self.showPicker(title: "Выберите группу", items: self.groups.map { $0.name }) { selected in
                if let group = self.groups.first(where: { $0.name == selected }) {
                    print("Выбрано: \(self.selectedCourse ?? "") -> \(self.selectedSpecialty ?? "") -> \(group.name)")
                    print("Ссылка на расписание: \(group.url)")
                    self.groupCard.updateSubtitle(group.name)
                    self.didSelectGroup(group.name)
                }
            }
        }
    }

    private func updateGroups() {
        guard let course = selectedCourse else {
            groups = []
            groupCard.updateSubtitle("Не выбрано")
            return
        }

        // Новая загрузка через API: course -> Int, specialty -> level
        let courseNumber: Int = Int(course.components(separatedBy: " ").first ?? "") ?? 1
        // Для "Все специальности" не передаем уровень (nil)
        let levelParam: String? = (selectedSpecialty == "Все специальности") ? nil : selectedSpecialty
        ScheduleRepository.shared.searchGroups(course: courseNumber, level: levelParam) { [weak self] result in
            switch result {
            case .success(let apiGroups):
                DispatchQueue.main.async {
                    // Маппинг в старый формат только для UI выбора
                    self?.groups = apiGroups.map { ($0.name, $0.name) }
                    if apiGroups.isEmpty {
                        self?.selectedGroup = nil
                        self?.groupCard.updateSubtitle("Групп нет")
                        self?.updateButtonState()
                    } else if let selectedGroup = self?.selectedGroup,
                              let group = self?.groups.first(where: { $0.name == selectedGroup }) {
                        self?.groupCard.updateSubtitle(group.name)
                    } else {
                        self?.groupCard.updateSubtitle("Выберите группу")
                    }
                }
            case .failure:
                DispatchQueue.main.async {
                    // При офлайне не затираем выбранную группу; просто оставляем текущее значение
                    if let current = self?.selectedGroup, !current.isEmpty {
                        self?.groupCard.updateSubtitle(current)
                    } else {
                        self?.groups = []
                        self?.groupCard.updateSubtitle("Не выбрано")
                    }
                }
            }
        }
    }


    private func showPicker(title: String, items: [String], onSelect: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        items.forEach { item in
            alert.addAction(UIAlertAction(title: item, style: .default) { _ in
                onSelect(item)
            })
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    private func updateButtonState() {
        let allSelected = selectedCourse != nil && selectedSpecialty != nil && selectedGroup != nil
        button.isEnabled = allSelected
        button.backgroundColor = allSelected ? UIColor.systemBlue : UIColor.systemGray
    }

    func didSelectCourse(_ course: String) {
        selectedCourse = course
        MRMyTracker.trackEvent(name: "Выбрать курс")
        updateButtonState()
    }

    func didSelectSpecialty(_ specialty: String) {
        selectedSpecialty = specialty
        MRMyTracker.trackEvent(name: "Выбрать уровень образования")
        updateButtonState()
    }

    func didSelectGroup(_ group: String) {
        selectedGroup = group
        MRMyTracker.trackEvent(name: "Выбрать группу")
        updateButtonState()
    }

    @objc func saveSelection() {
        let defaults = UserDefaults.standard
        defaults.set(selectedCourse, forKey: "selectedCourse")
        defaults.set(selectedSpecialty, forKey: "selectedSpecialty")
        defaults.set(selectedGroup, forKey: "selectedGroup")

        if let selectedGroup = selectedGroup {
            // Сохраняем имя группы вместо URL
            defaults.set(selectedGroup, forKey: "selectedGroupURL")
            delegate?.didSelectGroup(withURL: selectedGroup)
            MRMyTracker.trackEvent(name: "Собрать или загрузить расписание")
            
            let isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
            if !isTeacherMode {
                NotificationManager.shared.removeAllNotifications()
            }
        }
    }


    func loadSavedSelection() {
        let defaults = UserDefaults.standard
        selectedSpecialty = defaults.string(forKey: "selectedSpecialty")
        selectedCourse = defaults.string(forKey: "selectedCourse")
        selectedGroup = defaults.string(forKey: "selectedGroup")
        print("Загружено: \(selectedSpecialty ?? "Нет специальности"), \(selectedCourse ?? "Нет курса"), \(selectedGroup ?? "Нет группы")")

        if let selectedCourse = selectedCourse {
            self.courseCard.updateSubtitle(selectedCourse)
        } else {
            self.courseCard.updateSubtitle("Не выбрано")
        }

        if let selectedSpecialty = selectedSpecialty {
            self.specialtyCard.updateSubtitle(selectedSpecialty)
        } else {
            self.specialtyCard.updateSubtitle("Не выбрано")
        }

        updateGroups()

        // Показываем название группы, если оно сохранено, даже если список групп не загружен (без сети)
        // Сначала пробуем selectedGroup, затем selectedGroupURL
        let groupName = selectedGroup ?? UserDefaults.standard.string(forKey: "selectedGroupURL")
        if let groupName = groupName {
            // Показываем название группы, даже если список не загружен или группа не найдена в списке
            // Это важно для работы без сети
            self.groupCard.updateSubtitle(groupName)
        } else {
            self.groupCard.updateSubtitle("Не выбрано")
        }

        updateButtonState()
    }

    func resizeAndTintImage(named imageName: String, size: CGSize, color: UIColor) -> UIImage? {
        if let originalImage = UIImage(named: imageName) {
            let resizedImage = UIGraphicsImageRenderer(size: size).image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: size))
            }
            return resizedImage.withTintColor(color, renderingMode: .alwaysTemplate)
        }
        return nil
    }

    func simulateUserSelection(specialty: String?, course: String?, group: String?) {
        selectedSpecialty = specialty
        selectedCourse = course
        selectedGroup = group
        updateButtonState()
    }

    private func preloadFiltersFromAPI() {
        fetchLevels { [weak self] result in
            switch result {
            case .success(let levels):
                DispatchQueue.main.async { self?.apiLevels = levels }
            case .failure(let error):
                print("Ошибка загрузки уровней: \(error.localizedDescription)")
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка загрузки", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.preloadFiltersFromAPI()
            self?.updateGroups()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Yandex Ads
    
    @objc private func themeDidChange() {
        // Обновляем баннер при изменении темы
        refreshAdBannerIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Явное обновление баннера – можно вызывать при появлении экрана
    /// или при переключении вкладок, чтобы всегда получать свежий баннер.
    func refreshAdBannerIfNeeded() {
        guard AdManager.shared.shouldShowAds() else { return }
        
        if let adView = yandexAdView {
            loadAdWithTheme(adView: adView)
        } else {
            setupAdaptiveAdBanner()
        }
    }
    
    /// Определяет текущую тему приложения
    private func getCurrentTheme() -> AdTheme {
        let isDarkMode: Bool
        switch ThemeManager.current {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            if #available(iOS 13.0, *) {
                isDarkMode = traitCollection.userInterfaceStyle == .dark
            } else {
                isDarkMode = false
            }
        }
        return isDarkMode ? .dark : .light
    }
    
    /// Загружает рекламу с учетом текущей темы
    private func loadAdWithTheme(adView: AdView) {
        let adRequest = MutableAdRequest()
        adRequest.adTheme = getCurrentTheme()
        adView.loadAd(with: adRequest)
    }
    
    private func setupAdaptiveAdBanner() {
        // Создаем контейнер баннера, если еще не создан
        guard yandexAdView == nil else { return }

        // Делаем баннер шире: оставляем небольшие отступы по краям
        let availableWidth = view.bounds.width - 32
        let adSize = BannerAdSize.inlineSize(withWidth: availableWidth, maxHeight: 100)
        let adView = AdView(adUnitID: "R-M-14326663-2", adSize: adSize)
        adView.delegate = self
        adView.translatesAutoresizingMaskIntoConstraints = false
        adView.backgroundColor = .clear
        view.addSubview(adView)

        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 16),
            adView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adView.widthAnchor.constraint(equalToConstant: availableWidth)
        ])

        self.yandexAdView = adView
        self.lastAdWidth = availableWidth
        loadAdWithTheme(adView: adView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Пересоздаем баннер при изменении доступной ширины
        let targetWidth = view.bounds.width - 32
        if abs(targetWidth - lastAdWidth) > 0.5 {
            yandexAdView?.removeFromSuperview()
            yandexAdView = nil
            setupAdaptiveAdBanner()
        }
    }
}

extension UIColor {
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                          green: min(green + percentage/100, 1.0),
                          blue: min(blue + percentage/100, 1.0),
                          alpha: alpha)
        } else {
            return nil
        }
    }
}

// MARK: - YandexMobileAds AdViewDelegate
extension ViewController: AdViewDelegate {
    func adViewDidLoad(_ adView: AdView) {
        // Реклама загружена
    }

    func adViewDidFailLoading(_ adView: AdView, error: Error) {
        // Ошибка загрузки рекламы
        print("Yandex Ad failed: \(error.localizedDescription)")
    }
}


