//
//  SettingsViewController.swift
//  raspisanie1
//
//  Created by Дмитрий Цепилов on 01.12.2024.
//

import UIKit

class SettingsViewController: UIViewController {

    let showFullScheduleSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return switchControl
    }()

    let removeGroupSelectionSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return switchControl
    }()

    let customCardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    let customCardView2: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    let customCardView3: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Показать всю неделю"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    let removeGroupSelectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Убрать выбор группы"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    let changeWeekLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Сменить неделю"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center

        // Создаем текст
        let text = NSMutableAttributedString(string: "По всем проблемам и предложениям пишите разработчику  ")

        // Добавляем изображение Telegram
        if let telegramLogo = UIImage(named: "telegram") {
            let textAttachment = NSTextAttachment()
            textAttachment.image = telegramLogo

            // Настраиваем размер изображения
            let logoHeight: CGFloat = 16
            let logoRatio = telegramLogo.size.width / telegramLogo.size.height
            textAttachment.bounds = CGRect(x: 0, y: -4, width: logoHeight * logoRatio, height: logoHeight)

            let imageString = NSAttributedString(attachment: textAttachment)
            text.append(imageString)
        }

        // Добавляем текст с @tsepilo_v
        text.append(NSAttributedString(string: " @tsep1lov"))

        // Применяем атрибутированную строку к метке
        label.attributedText = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray

        return label
    }()

    let changeWeekSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Неделя 1", "Неделя 2"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = UserDefaults.standard.bool(forKey: "isOddWeek") ? 0 : 1
        segmentedControl.addTarget(self, action: #selector(changeWeek), for: .valueChanged)
        return segmentedControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        overrideUserInterfaceStyle = .light

        title = "Настройки"

        // Изменение цвета текста заголовка
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]

        // Настройка кастомной ячейки
        view.addSubview(customCardView)
        customCardView.addSubview(titleLabel)
        customCardView.addSubview(showFullScheduleSwitch)

        // Настройка второй кастомной ячейки
        view.addSubview(customCardView2)
        customCardView2.addSubview(removeGroupSelectionLabel)
        customCardView2.addSubview(removeGroupSelectionSwitch)

        // Настройка третьей кастомной ячейки
        view.addSubview(customCardView3)
        customCardView3.addSubview(changeWeekLabel)
        customCardView3.addSubview(changeWeekSegmentedControl)

        // Добавление footerLabel внизу представления
        view.addSubview(footerLabel)

        NSLayoutConstraint.activate([
            customCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            customCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            customCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            customCardView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: customCardView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: customCardView.centerYAnchor),

            showFullScheduleSwitch.trailingAnchor.constraint(equalTo: customCardView.trailingAnchor, constant: -16),
            showFullScheduleSwitch.centerYAnchor.constraint(equalTo: customCardView.centerYAnchor),

            customCardView2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            customCardView2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            customCardView2.topAnchor.constraint(equalTo: customCardView.bottomAnchor, constant: 20),
            customCardView2.heightAnchor.constraint(equalToConstant: 60),

            removeGroupSelectionLabel.leadingAnchor.constraint(equalTo: customCardView2.leadingAnchor, constant: 16),
            removeGroupSelectionLabel.centerYAnchor.constraint(equalTo: customCardView2.centerYAnchor),

            removeGroupSelectionSwitch.trailingAnchor.constraint(equalTo: customCardView2.trailingAnchor, constant: -16),
            removeGroupSelectionSwitch.centerYAnchor.constraint(equalTo: customCardView2.centerYAnchor),

            customCardView3.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            customCardView3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            customCardView3.topAnchor.constraint(equalTo: customCardView2.bottomAnchor, constant: 20),
            customCardView3.heightAnchor.constraint(equalToConstant: 60),

            changeWeekLabel.leadingAnchor.constraint(equalTo: customCardView3.leadingAnchor, constant: 16),
            changeWeekLabel.centerYAnchor.constraint(equalTo: customCardView3.centerYAnchor),

            changeWeekSegmentedControl.trailingAnchor.constraint(equalTo: customCardView3.trailingAnchor, constant: -16),
            changeWeekSegmentedControl.centerYAnchor.constraint(equalTo: customCardView3.centerYAnchor),

            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Загрузка состояния переключателей из UserDefaults
        let isFullScheduleEnabled = UserDefaults.standard.bool(forKey: "showFullSchedule")
        showFullScheduleSwitch.isOn = isFullScheduleEnabled

        let isGroupSelectionRemoved = UserDefaults.standard.bool(forKey: "removeGroupSelection")
        removeGroupSelectionSwitch.isOn = isGroupSelectionRemoved

        // Настройка кастомной кнопки "Назад"
        let backButton = UIBarButtonItem(title: "Назад", style: .plain, target: self, action: #selector(backButtonTapped))
        self.navigationItem.leftBarButtonItem = backButton
    }

    @objc func changeWeek() {
        // Переключаем неделю
        let currentWeek = UserDefaults.standard.bool(forKey: "isOddWeek")
        let newWeek = !currentWeek
        UserDefaults.standard.set(newWeek, forKey: "isOddWeek")

        // Обновляем состояние сегментного контрола
        changeWeekSegmentedControl.selectedSegmentIndex = newWeek ? 0 : 1

        // Отправляем нотификацию для обновления расписания
        NotificationCenter.default.post(name: Notification.Name("reloadSchedule"), object: nil)
    }

    @objc func switchChanged(_ sender: UISwitch) {
        if sender == showFullScheduleSwitch {
            // Save the switch state to UserDefaults
            UserDefaults.standard.set(sender.isOn, forKey: "showFullSchedule")
        } else if sender == removeGroupSelectionSwitch {
            // Save the switch state to UserDefaults
            UserDefaults.standard.set(sender.isOn, forKey: "removeGroupSelection")

            // Update the tab bar access in MainViewController
            if let mainVC = self.navigationController?.viewControllers.first as? MainViewController {
                mainVC.updateTabBarAccess(isGroupSelectionRemoved: sender.isOn)
            }
        }
    }

    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}









