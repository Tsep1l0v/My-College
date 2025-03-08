//
//  reklama.swift
//  My Сollege
//
//  Created by Дмитрий Цепилов on 02.03.2025.
//

//import UIKit
//import SwiftSoup
//import YandexMobileAds
//
//class ViewController: UIViewController, UITabBarDelegate, AdViewDelegate {
//    private var tabBar: UITabBar!
//    private var indicatorView: UIView!
//    private var currentItemIndex: Int = 0
//    weak var delegate: GroupSelectionDelegate?
//
//    private let courseCard = CustomSelectionCardView(title: "Курс", iconName: "graduationcap")
//    private let specialtyCard = CustomSelectionCardView(title: "Специальность", iconName: "books.vertical")
//    private let groupCard = CustomSelectionCardView(title: "Группа", iconName: "person.3")
//
//    private var groups: [(name: String, url: String)] = []
//    private var selectedCourse: String?
//    private var selectedSpecialty: String?
//    var selectedGroup: String?
//
//    let button: UIButton = createButton(title: " Выбрать", imageName: "icons8")
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Выбор группы"
//        label.textAlignment = .center
//        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private var groupsByCourseAndSpecialty: [String: [String: [String]]] = [:]
//    private lazy var adView: AdView = {
//        let width = view.safeAreaLayoutGuide.layoutFrame.width
//        let adSize = BannerAdSize.stickySize(withContainerWidth: width)
//        let adView = AdView(adUnitID: "R-M-14326663-2", adSize: adSize)
//        adView.delegate = self
//        adView.translatesAutoresizingMaskIntoConstraints = false
//        return adView
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.navigationItem.title = nil
//
//        view.addSubview(titleLabel)
//        NSLayoutConstraint.activate([
//            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//
//        view.backgroundColor = .systemGroupedBackground
//        overrideUserInterfaceStyle = .light
//        setupUI()
//        view.addSubview(button)
//
//        let buttonWidth: CGFloat = UIScreen.main.bounds.width * 0.9
//        let buttonHeight: CGFloat = 65.0
//        let buttonTopOffset: CGFloat = UIScreen.main.bounds.height * 0.35
//
//        NSLayoutConstraint.activate([
//            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonTopOffset),
//            button.heightAnchor.constraint(equalToConstant: buttonHeight),
//            button.widthAnchor.constraint(equalToConstant: buttonWidth)
//        ])
//
//        button.addTarget(self, action: #selector(buttonTouchDown), for: [.touchDown, .touchDragEnter])
//        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
//
//        button.addTarget(self, action: #selector(saveSelection), for: .touchUpInside)
//
//        // Загрузка рекламы
//        loadAd()
//
//        loadSavedSelection()
//        updateButtonState()
//
//        loadGroupsFromJSON()
//    }
//
//    // Метод для загрузки рекламы
//    func loadAd() {
//        adView.loadAd()
//    }
//
//    // Метод для отображения рекламы
//    func showAd() {
//        view.addSubview(adView)
//        NSLayoutConstraint.activate([
//            adView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            adView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//    }
//
//    // Реализация методов делегата AdViewDelegate
//    func adViewDidLoad(_ adView: AdView) {
//        print("Ad loaded successfully.")
//        showAd()
//    }
//
//    func adViewDidFailLoading(_ adView: AdView, error: Error) {
//        print("Failed to load ad: \(error.localizedDescription)")
//    }
//
//    @objc func buttonTouchDown() {
//        if let darkerColor = button.backgroundColor?.darker(by: 10.0) {
//            UIView.animate(withDuration: 0.1) {
//                self.button.backgroundColor = darkerColor
//            }
//        }
//    }
//
//    @objc func buttonTouchUp() {
//        UIView.animate(withDuration: 0.1) {
//            self.button.backgroundColor = UIColor.systemBlue
//        }
//    }
//
//    private func setupUI() {
//        let stackView = UIStackView(arrangedSubviews: [courseCard, specialtyCard, groupCard])
//        stackView.axis = .vertical
//        stackView.spacing = 20
//        stackView.alignment = .fill
//        stackView.distribution = .fill
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100)
//        ])
//
//        courseCard.onTap = { [weak self] in
//            guard let self = self else { return }
//            let sortedCourses = self.groupsByCourseAndSpecialty.keys.sorted { (course1, course2) -> Bool in
//                let courseOrder: [String: Int] = [
//                    "1 курс": 1,
//                    "2 курс": 2,
//                    "3 курс": 3,
//                    "4 курс": 4,
//                    "5 курс": 5
//                ]
//                return courseOrder[course1, default: Int.max] < courseOrder[course2, default: Int.max]
//            }
//            self.showPicker(title: "Выберите курс", items: sortedCourses) { selected in
//                self.selectedCourse = selected
//                self.courseCard.updateSubtitle(selected)
//                self.updateGroups()
//                self.didSelectCourse(self.selectedCourse ?? "Default Course")
//            }
//        }
//
//        specialtyCard.onTap = { [weak self] in
//            guard let self = self else { return }
//            let specialties = self.selectedCourse.flatMap { course in
//                self.groupsByCourseAndSpecialty[course]?.keys.map { String($0) }
//            } ?? []
//            let bachelor = specialties.filter { $0.lowercased().contains("бакалавриат") }
//            let master = specialties.filter { $0.lowercased().contains("магистратура") }
//            let spo = specialties.filter { $0.lowercased().contains("спо") }
//            let allSpecialties = specialties.filter { !$0.lowercased().contains("бакалавриат") && !$0.lowercased().contains("магистратура") && !$0.lowercased().contains("спо") }
//            let sortedSpecialties = allSpecialties + bachelor + master + spo
//            self.showPicker(title: "Выберите специальность", items: sortedSpecialties) { selected in
//                self.selectedSpecialty = selected
//                self.specialtyCard.updateSubtitle(selected)
//                self.updateGroups()
//                self.didSelectSpecialty(self.selectedSpecialty ?? "Default Specialty")
//            }
//        }
//
//        groupCard.onTap = { [weak self] in
//            guard let self = self, !self.groups.isEmpty else { return }
//            self.showPicker(title: "Выберите группу", items: self.groups.map { $0.name }) { selected in
//                if let group = self.groups.first(where: { $0.name == selected }) {
//                    print("Выбрано: \(self.selectedCourse ?? "") -> \(self.selectedSpecialty ?? "") -> \(group.name)")
//                    print("Ссылка на расписание: \(group.url)")
//                    self.groupCard.updateSubtitle(group.name)
//                    self.didSelectGroup(group.name)
//                }
//            }
//        }
//    }
//
//    private func updateGroups() {
//        guard let course = selectedCourse, let specialty = selectedSpecialty else {
//            groups = []
//            groupCard.updateSubtitle("Не выбрано")
//            return
//        }
//
//        fetchGroups(forCourse: course, specialty: specialty) { [weak self] result in
//            switch result {
//            case .success(let fetchedGroups):
//                if let allowedGroups = self?.groupsByCourseAndSpecialty[course]?[specialty] {
//                    self?.groups = fetchedGroups.filter { allowedGroups.contains($0.name) }
//                } else {
//                    self?.groups = []
//                }
//                DispatchQueue.main.async {
//                    if let selectedGroup = self?.selectedGroup,
//                       let group = self?.groups.first(where: { $0.name == selectedGroup }) {
//                        self?.groupCard.updateSubtitle(group.name)
//                    } else {
//                        self?.groupCard.updateSubtitle("Выберите группу")
//                    }
//                }
//            case .failure(let error):
//                print("Ошибка загрузки групп: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self?.groups = []
//                    self?.groupCard.updateSubtitle("Ошибка загрузки")
//                }
//            }
//        }
//    }
//
//    private func showPicker(title: String, items: [String], onSelect: @escaping (String) -> Void) {
//        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
//        items.forEach { item in
//            alert.addAction(UIAlertAction(title: item, style: .default) { _ in
//                onSelect(item)
//            })
//        }
//        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
//        present(alert, animated: true)
//    }
//
//    private func updateButtonState() {
//        let allSelected = selectedCourse != nil && selectedSpecialty != nil && selectedGroup != nil
//        button.isEnabled = allSelected
//        button.backgroundColor = allSelected ? UIColor.systemBlue : UIColor.systemGray
//    }
//
//    func didSelectCourse(_ course: String) {
//        selectedCourse = course
//        updateButtonState()
//    }
//
//    func didSelectSpecialty(_ specialty: String) {
//        selectedSpecialty = specialty
//        updateButtonState()
//    }
//
//    func didSelectGroup(_ group: String) {
//        selectedGroup = group
//        updateButtonState()
//    }
//
//    @objc func saveSelection() {
//        let defaults = UserDefaults.standard
//        defaults.set(selectedSpecialty, forKey: "selectedSpecialty")
//        defaults.set(selectedCourse, forKey: "selectedCourse")
//        defaults.set(selectedGroup, forKey: "selectedGroup")
//
//        print("Выбор сохранён: \(selectedSpecialty ?? "Нет специальности"), \(selectedCourse ?? "Нет курса"), \(selectedGroup ?? "Нет группы")")
//
//        if let groupURL = groups.first(where: { $0.name == selectedGroup })?.url {
//            defaults.set(groupURL, forKey: "selectedGroupURL")
//            delegate?.didSelectGroup(withURL: groupURL)
//        }
//    }
//
//    func loadSavedSelection() {
//        let defaults = UserDefaults.standard
//        selectedSpecialty = defaults.string(forKey: "selectedSpecialty")
//        selectedCourse = defaults.string(forKey: "selectedCourse")
//        selectedGroup = defaults.string(forKey: "selectedGroup")
//        print("Загружено: \(selectedSpecialty ?? "Нет специальности"), \(selectedCourse ?? "Нет курса"), \(selectedGroup ?? "Нет группы")")
//
//        if let selectedCourse = selectedCourse {
//            self.courseCard.updateSubtitle(selectedCourse)
//        } else {
//            self.courseCard.updateSubtitle("Не выбрано")
//        }
//
//        if let selectedSpecialty = selectedSpecialty {
//            self.specialtyCard.updateSubtitle(selectedSpecialty)
//        } else {
//            self.specialtyCard.updateSubtitle("Не выбрано")
//        }
//
//        updateGroups()
//
//        if let selectedGroup = selectedGroup, groups.contains(where: { $0.name == selectedGroup }) {
//            self.groupCard.updateSubtitle(selectedGroup)
//        } else {
//            self.groupCard.updateSubtitle("Не выбрано")
//        }
//
//        updateButtonState()
//    }
//
//    func resizeAndTintImage(named imageName: String, size: CGSize, color: UIColor) -> UIImage? {
//        if let originalImage = UIImage(named: imageName) {
//            let resizedImage = UIGraphicsImageRenderer(size: size).image { _ in
//                originalImage.draw(in: CGRect(origin: .zero, size: size))
//            }
//            return resizedImage.withTintColor(color, renderingMode: .alwaysTemplate)
//        }
//        return nil
//    }
//
//    func simulateUserSelection(specialty: String?, course: String?, group: String?) {
//        selectedSpecialty = specialty
//        selectedCourse = course
//        selectedGroup = group
//        updateButtonState()
//    }
//
//    private func loadGroupsFromJSON() {
//        if let url = Bundle.main.url(forResource: "groups", withExtension: "json") {
//            do {
//                let data = try Data(contentsOf: url)
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                if let dictionary = json as? [String: [String: [String]]] {
//                    self.groupsByCourseAndSpecialty = dictionary
//                    print("JSON успешно загружен и распарсен")
//                } else {
//                    print("Ошибка: JSON не соответствует ожидаемой структуре.")
//                }
//            } catch let error {
//                print("Ошибка загрузки JSON: \(error.localizedDescription)")
//            }
//        } else {
//            print("Ошибка: Файл groups.json не найден в основном бандле.")
//        }
//    }
//}
//
//extension UIColor {
//    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
//        return self.adjust(by: -1 * abs(percentage) )
//    }
//
//    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
//        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
//        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
//            return UIColor(red: min(red + percentage/100, 1.0),
//                          green: min(green + percentage/100, 1.0),
//                          blue: min(blue + percentage/100, 1.0),
//                          alpha: alpha)
//        } else {
//            return nil
//        }
//    }
//}
