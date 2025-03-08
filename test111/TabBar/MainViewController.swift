//
//  MainViewController.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import UIKit

protocol GroupSelectionDelegate: AnyObject {
    func didSelectGroup(withURL url: String)
}

class MainViewController: UIViewController, UITabBarDelegate, GroupSelectionDelegate {
    var firstVC: ViewController!
    var secondVC: TwoViewController!

    private var tabBar: UITabBar!
    private var currentItemIndex: Int = 0
    private var indicatorView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        overrideUserInterfaceStyle = .light

        // Инициализация контроллеров
        firstVC = ViewController()
        secondVC = TwoViewController()

        // Установка делегата для ViewController
        firstVC.delegate = self

        // Добавляем оба контроллера как дочерние
        addChild(firstVC)
        view.addSubview(firstVC.view)
        firstVC.didMove(toParent: self)

        addChild(secondVC)
        view.addSubview(secondVC.view)
        secondVC.didMove(toParent: self)

        secondVC.view.frame.origin.x = self.view.bounds.width // Начальная позиция второго контроллера (спрятан справа)

        // Настроим кастомный таббар
        setupTabBar()

        // Проверка состояния переключателя для удаления выбора группы
        let isGroupSelectionRemoved = UserDefaults.standard.bool(forKey: "removeGroupSelection")
        updateTabBarAccess(isGroupSelectionRemoved: isGroupSelectionRemoved)

        if let selectedGroupURL = UserDefaults.standard.string(forKey: "selectedGroupURL") {
            secondVC.selectedGroupURL = selectedGroupURL
            secondVC.loadTimetableData()
        }

        // Обновление индикатора таббара
        updateIndicatorPosition(animated: false)
    }

    // Реализация метода протокола
    func didSelectGroup(withURL url: String) {
        secondVC.selectedGroupURL = url
        secondVC.loadTimetableData()

        // Переход на вторую view
        UIView.animate(withDuration: 0.3, animations: {
            self.firstVC.view.frame.origin.x = -self.view.bounds.width
            self.secondVC.view.frame.origin.x = 0
        })

        // Обновление таб бара
        currentItemIndex = 1
        updateIndicatorPosition(animated: true)
        updateTabBar()
    }

    private func updateTabBar() {
        if let items = tabBar.items {
            items.forEach { $0.isEnabled = true }
            tabBar.selectedItem = items[currentItemIndex]
        }

        if currentItemIndex == 0 {
            // Плавное скольжение для первого контроллера
            UIView.animate(withDuration: 0.3, animations: {
                self.firstVC.view.frame.origin.x = 0
                self.secondVC.view.frame.origin.x = self.view.bounds.width
            })
        } else {
            // Плавное скольжение для второго контроллера
            UIView.animate(withDuration: 0.3, animations: {
                self.firstVC.view.frame.origin.x = -self.view.bounds.width
                self.secondVC.view.frame.origin.x = 0
            })
        }
    }


    private func setupTabBar() {
        let tabBarContainer = UIView()
        tabBarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tabBarContainer)

        NSLayoutConstraint.activate([
            tabBarContainer.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            tabBarContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            tabBarContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),
            tabBarContainer.heightAnchor.constraint(equalToConstant: 70)
        ])

        tabBarContainer.backgroundColor = .clear
        tabBarContainer.layer.shadowColor = UIColor.black.cgColor
        tabBarContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        tabBarContainer.layer.shadowOpacity = 0.2
        tabBarContainer.layer.shadowRadius = 10

        tabBar = UITabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBarContainer.addSubview(tabBar)

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: tabBarContainer.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: tabBarContainer.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: tabBarContainer.topAnchor),
            tabBar.bottomAnchor.constraint(equalTo: tabBarContainer.bottomAnchor)
        ])

        tabBar.backgroundColor = .white
        tabBar.layer.cornerRadius = 20
        tabBar.layer.masksToBounds = true

        let listImage = resizeAndTintImage(named: "list", size: CGSize(width: 35, height: 35), color: .white)
        let calendarImage = resizeAndTintImage(named: "calendar", size: CGSize(width: 35, height: 35), color: .white)

        let items = [
            UITabBarItem(title: nil, image: listImage, tag: 0),
            UITabBarItem(title: nil, image: calendarImage, tag: 1)
        ]

        tabBar.setItems(items, animated: false)
        tabBar.delegate = self

        tabBar.tintColor = UIColor(red: 13/255, green: 128/255, blue: 255/255, alpha: 1.0)
        tabBar.unselectedItemTintColor = .gray
        tabBar.selectedItem = items[currentItemIndex]

        addIndicatorView()
    }


    private func resizeAndTintImage(named imageName: String, size: CGSize, color: UIColor) -> UIImage? {
        guard let originalImage = UIImage(named: imageName) else {
            return nil
        }

        let resizedImage = UIGraphicsImageRenderer(size: size).image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: size))
        }

        return resizedImage.withTintColor(color, renderingMode: .alwaysTemplate)
    }

    private func addIndicatorView() {
        indicatorView = UIView()
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = UIColor(red: 13/255, green: 128/255, blue: 255/255, alpha: 1.0)
        indicatorView.layer.cornerRadius = 2
        tabBar.addSubview(indicatorView)

        NSLayoutConstraint.activate([
            indicatorView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: -13),
            indicatorView.widthAnchor.constraint(equalToConstant: 45),
            indicatorView.heightAnchor.constraint(equalToConstant: 4)
        ])

        // Сразу позиционируем индикатор под активной вкладкой
        indicatorView.alpha = 1
        indicatorView.frame.origin.x = calculateIndicatorXPosition()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async {
            // Убираем затухание и анимируем только перемещение индикатора
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.indicatorView.alpha = 1
                self.indicatorView.frame.origin.x = self.calculateIndicatorXPosition()
            })
        }
    }

    private func calculateIndicatorXPosition() -> CGFloat {
        let itemCount = tabBar.items?.count ?? 0
        let itemWidth = tabBar.frame.width / CGFloat(itemCount)
        return CGFloat(currentItemIndex) * itemWidth + itemWidth / 2 - indicatorView.frame.width / 2
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        currentItemIndex = item.tag
        updateTabBar()
        updateIndicatorPosition(animated: true)
    }

    private func updateIndicatorPosition(animated: Bool) {
        let targetX = calculateIndicatorXPosition()

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.indicatorView.frame.origin.x = targetX
            })
        } else {
            indicatorView.frame.origin.x = targetX
        }
    }

    func updateTabBarAccess(isGroupSelectionRemoved: Bool) {
        if isGroupSelectionRemoved {
            firstVC.view.isHidden = true
            tabBar.isHidden = true // Hide the tab bar
            if let items = tabBar.items {
                items[0].isEnabled = false
                tabBar.selectedItem = items[1] // Set the second tab as active
            }
            // Update the current tab index
            currentItemIndex = 1
            updateTabBar()
            updateIndicatorPosition(animated: false)
        } else {
            firstVC.view.isHidden = false
            tabBar.isHidden = false // Show the tab bar
            if let items = tabBar.items {
                items[0].isEnabled = true
                tabBar.selectedItem = items[0] // Set the first tab as active
            }
            // Update the current tab index
            currentItemIndex = 0
            updateTabBar()
            updateIndicatorPosition(animated: false)
        }
    }
}
