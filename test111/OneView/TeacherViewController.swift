//
//  TeacherViewController.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import UIKit
import SwiftSoup
import YandexMobileAds
import MyTrackerSDK

class TeacherViewController: UIViewController, UITabBarDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    private var tabBar: UITabBar!
    private var indicatorView: UIView!
    private var currentItemIndex: Int = 0
    weak var delegate: TeacherSelectionDelegate?

    private let departmentCard = CustomSelectionCardView(title: "Кафедра", iconName: "building.2")
    private let teacherCard = CustomSelectionCardView(title: "Преподаватель", iconName: "person.circle")
    private let searchCard = CustomSelectionCardView(title: "Поиск по фамилии", iconName: "magnifyingglass")

    private var teachers: [Teacher] = []
    private var allTeachers: [Teacher] = []
    private var selectedDepartment: String?
    var selectedTeacher: String?
    
    // Поиск
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredTeachers: [Teacher] = []

    let button: UIButton = createButton(title: " Выбрать", imageName: "icons8")

    // Реклама: адаптивный inline-баннер
    private var yandexAdView: AdView?
    private var lastAdWidth: CGFloat = 0

    private let titleLabel: UILabel = {
            let label = UILabel()
            label.text = "Выбор преподавателя"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

    private var teachersByDepartment: [String: [String]] = [:]
    private let teacherParser = TeacherParser.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = nil

        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.backgroundColor = .systemGroupedBackground
        
        setupSearchController()
        setupUI()
        view.addSubview(button)

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
        
        loadSavedSelection()
        updateButtonState()

        loadTeachersFromJSON()
        loadAllTeachers() // Загружаем всех преподавателей для поиска
        
        // Инициализируем карточку поиска
        searchCard.updateSubtitle("Нажмите для поиска")
        
        // Тестируем парсер (можно убрать в продакшене)
        #if DEBUG
        TeacherParserSimpleTest.testWithMockHTML()
        TeacherParserConsoleTest.runTest()
        #endif

        // Настраиваем адаптивный баннер под кнопкой, если разрешена реклама
        if AdManager.shared.shouldShowAds() {
            setupAdaptiveAdBanner()
        }
        
        // Подписываемся на уведомление об изменении темы
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: Notification.Name("themeChanged"),
            object: nil
        )
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
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Введите фамилию"
        searchController.searchBar.delegate = self
        
        // Делаем фон поиска системным (адаптивным)
        searchController.searchBar.backgroundColor = .secondarySystemBackground
        searchController.searchBar.barTintColor = .secondarySystemBackground
        searchController.searchBar.tintColor = .systemBlue
        
        // Дополнительные настройки для лучшего отображения
        searchController.searchBar.searchBarStyle = .default // Изменяем на default для полного фона
        searchController.searchBar.isTranslucent = false
        
        // Убираем тень и границы
        searchController.searchBar.layer.shadowOpacity = 0
        searchController.searchBar.layer.borderWidth = 0
        
        // Дополнительные настройки для полного белого фона
        if let searchBarTextField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            searchBarTextField.backgroundColor = .secondarySystemBackground
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
        let stackView = UIStackView(arrangedSubviews: [searchCard, departmentCard, teacherCard])
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

        searchCard.onTap = { [weak self] in
            guard let self = self else { return }
            self.present(self.searchController, animated: true)
        }

        // Убираем возможность выбора кафедры - просто показываем "Все кафедры"
        departmentCard.onTap = nil

        teacherCard.onTap = { [weak self] in
            guard let self = self, !self.teachers.isEmpty else { return }
            self.showPicker(title: "Выберите преподавателя", items: self.teachers.map { $0.name }) { selected in
                if let teacher = self.teachers.first(where: { $0.name == selected }) {
                    print("Выбрано: \(self.selectedDepartment ?? "") -> \(teacher.name)")
                    print("Ссылка на расписание: \(teacher.url)")
                    self.teacherCard.updateSubtitle(teacher.name)
                    self.didSelectTeacher(teacher.name)
                }
            }
        }
    }

    private func updateTeachers() {
        print("🌐 Загружаем всех преподавателей (без фильтра по кафедре)")
        
        ScheduleRepository.shared.searchTeachers(department: nil) { [weak self] result in
            switch result {
            case .success(let allTeachers):
                let teachers: [Teacher] = allTeachers.map { dto in
                    Teacher(name: dto.label, department: dto.department ?? "Без кафедры", url: dto.label)
                }
                
                DispatchQueue.main.async {
                    self?.teachers = teachers
                    if let selectedTeacher = self?.selectedTeacher,
                       let teacher = self?.teachers.first(where: { $0.name == selectedTeacher }) {
                        self?.teacherCard.updateSubtitle(teacher.name)
                    } else {
                        self?.teacherCard.updateSubtitle("Выберите преподавателя")
                    }
                }
            case .failure(let error):
                print("❌ Ошибка загрузки всех преподавателей: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.teachers = []
                    // При офлайне показываем ранее выбранного преподавателя, если он есть
                    if let saved = self?.selectedTeacher, !saved.isEmpty {
                        self?.teacherCard.updateSubtitle(saved)
                    } else {
                        self?.teacherCard.updateSubtitle("Не выбрано")
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
        let allSelected = selectedDepartment != nil && selectedTeacher != nil
        button.isEnabled = allSelected
        button.backgroundColor = allSelected ? UIColor.systemBlue : UIColor.systemGray
    }

    func didSelectDepartment(_ department: String) {
        selectedDepartment = department
        updateButtonState()
    }

    func didSelectTeacher(_ teacher: String) {
        selectedTeacher = teacher
        MRMyTracker.trackEvent(name: "Выбрать преподавателя")
        updateButtonState()
    }

    @objc func saveSelection() {
        let defaults = UserDefaults.standard
        defaults.set(selectedDepartment, forKey: "selectedTeacherDepartment")
        defaults.set(selectedTeacher, forKey: "selectedTeacher")
        MRMyTracker.trackEvent(name: "Выбрать кафедру")
        MRMyTracker.trackEvent(name: "Собрать или загрузить расписание")

        print("Выбор сохранён: \(selectedDepartment ?? "Нет кафедры"), \(selectedTeacher ?? "Нет преподавателя")")

        // Ищем преподавателя в текущем списке или в общем списке
        var teacherURL: String?
        if let selectedTeacher = selectedTeacher {
            // Сначала ищем в текущем списке преподавателей
            if let teacher = teachers.first(where: { $0.name == selectedTeacher }) {
                teacherURL = teacher.url
            } else {
                // Если не найден в текущем списке, ищем в общем списке
                if let teacher = allTeachers.first(where: { $0.name == selectedTeacher }) {
                    teacherURL = teacher.url
                }
            }
        }

        if let url = teacherURL {
            defaults.set(url, forKey: "selectedTeacherURL")
            delegate?.didSelectTeacher(withURL: url)
            print("URL преподавателя: \(url)")
            
            // Удаляем старые уведомления при смене преподавателя (хотя уведомления не планируются для преподавателей)
            NotificationManager.shared.removeAllNotifications()
            print("🗑️ Удалены старые уведомления при смене преподавателя")
        } else {
            print("❌ Не удалось найти URL для преподавателя: \(selectedTeacher ?? "неизвестно")")
        }
    }

    func loadSavedSelection() {
        let defaults = UserDefaults.standard
        selectedDepartment = "Все кафедры" // Всегда "Все кафедры"
        selectedTeacher = defaults.string(forKey: "selectedTeacher")
        print("Загружено: \(selectedDepartment ?? "Нет кафедры"), \(selectedTeacher ?? "Нет преподавателя")")

        // Всегда показываем "Все кафедры" как серый текст
        self.departmentCard.updateSubtitle("Все кафедры")

        updateTeachers()

        // Показываем название преподавателя, если оно сохранено, даже если список преподавателей не загружен (без сети)
        // Сначала пробуем selectedTeacher, затем selectedTeacherURL
        let teacherName = selectedTeacher ?? UserDefaults.standard.string(forKey: "selectedTeacherURL")
        if let teacherName = teacherName {
            // Показываем название преподавателя, даже если список не загружен или преподаватель не найден в списке
            // Это важно для работы без сети
            self.teacherCard.updateSubtitle(teacherName)
        } else {
            self.teacherCard.updateSubtitle("Не выбрано")
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

    func simulateUserSelection(department: String?, teacher: String?) {
        selectedDepartment = department
        selectedTeacher = teacher
        updateButtonState()
    }

    private func loadTeachersFromJSON() {
        // Просто загружаем всех преподавателей, группировка по кафедрам не нужна
        print("🔄 Загружаем всех преподавателей с API...")
        ScheduleRepository.shared.searchTeachers(department: nil) { [weak self] result in
            switch result {
            case .success(let allTeachers):
                print("📚 Получено преподавателей с API: \(allTeachers.count)")
                
                DispatchQueue.main.async {
                    // Просто сохраняем пустую группировку, так как фильтр кафедры отключен
                    self?.teachersByDepartment = ["Все кафедры": []]
                    print("✅ Данные о преподавателях успешно загружены с API")
                    
                    // Всегда показываем "Все кафедры"
                    self?.departmentCard.updateSubtitle("Все кафедры")
                }
            case .failure(let error):
                print("❌ Ошибка загрузки данных о преподавателях: \(error.localizedDescription)")
                // В случае ошибки загружаем данные из JSON как fallback
                self?.loadFallbackData()
            }
        }
    }
    
    private func loadFallbackData() {
        if let url = Bundle.main.url(forResource: "teachers", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = json as? [String: [String]] {
                    self.teachersByDepartment = dictionary
                    print("Загружены fallback данные из JSON")
                }
            } catch let error {
                print("Ошибка загрузки fallback JSON: \(error.localizedDescription)")
            }
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredTeachers = []
            searchCard.updateSubtitle("Введите фамилию для поиска")
            return
        }
        
        filteredTeachers = allTeachers.filter { teacher in
            teacher.name.lowercased().contains(searchText.lowercased())
        }
        
        // Обновляем subtitle карточки поиска
        if filteredTeachers.isEmpty {
            searchCard.updateSubtitle("Ничего не найдено")
        } else {
            searchCard.updateSubtitle("Найдено: \(filteredTeachers.count) преподавателей")
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.dismiss(animated: true) {
            self.showSearchResults()
        }
    }
    
    private func showSearchResults() {
        guard !filteredTeachers.isEmpty else {
            let alert = UIAlertController(title: "Результаты поиска", message: "Преподаватель не найден", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let teacherNames = filteredTeachers.map { $0.name }
        showPicker(title: "Результаты поиска", items: teacherNames) { selected in
            if let teacher = self.filteredTeachers.first(where: { $0.name == selected }) {
                // Устанавливаем выбранного преподавателя
                self.selectedTeacher = teacher.name
                self.teacherCard.updateSubtitle(teacher.name)
                self.searchCard.updateSubtitle("Найден: \(teacher.name)")
                
                // Кафедра всегда остается "Все кафедры"
                self.selectedDepartment = "Все кафедры"
                self.departmentCard.updateSubtitle("Все кафедры")
                
                // Сохраняем выбор
                UserDefaults.standard.set(teacher.name, forKey: "selectedTeacher")
                UserDefaults.standard.set(teacher.url, forKey: "selectedTeacherURL")
                
                // Обновляем состояние кнопки
                self.updateButtonState()
                
                print("✅ Выбран преподаватель через поиск: \(teacher.name) - \(teacher.department)")
                print("🔗 URL расписания: \(teacher.url)")
            }
        }
    }
    
    private func loadAllTeachers() {
        ScheduleRepository.shared.searchTeachers(department: nil) { [weak self] result in
            switch result {
            case .success(let teachers):
                DispatchQueue.main.async {
                    let realTeachers = teachers.map { Teacher(name: $0.label, department: $0.department ?? "", url: $0.label) }
                    self?.allTeachers = realTeachers
                    print("📚 Загружено для поиска: \(realTeachers.count) преподавателей")
                }
            case .failure(let error):
                print("Ошибка загрузки всех преподавателей: \(error)")
            }
        }
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
        let targetWidth = view.bounds.width - 32
        if abs(targetWidth - lastAdWidth) > 0.5 {
            yandexAdView?.removeFromSuperview()
            yandexAdView = nil
            setupAdaptiveAdBanner()
        }
    }
}

// MARK: - YandexMobileAds AdViewDelegate
extension TeacherViewController: AdViewDelegate {
    func adViewDidLoad(_ adView: AdView) {
        // Реклама загружена
    }

    func adViewDidFailLoading(_ adView: AdView, error: Error) {
        print("Yandex Ad failed: \(error.localizedDescription)")
    }
} 