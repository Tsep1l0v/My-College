//
//  LessonTableViewCell.swift
//  test111
//
//  Created by Дмитрий Цепилов on 04.12.2024.
//

import UIKit
import Lottie

// MARK: - Кастомная ячейка

class LessonTableViewCell: UITableViewCell {

    private let numberLabel = UILabel()
    private let timeLabel = UILabel()
    private let subjectLabel = UILabel()
    private let groupLabel = UILabel()
    private let teacherLabel = UILabel()
    private let roomLabel = UILabel()
    private let typeLabel = UILabel()
    private let containerView = UIView()
    private let leftBorderView = UIView() // Синяя линия внутри контейнера
    private var lottieAnimationView: LottieAnimationView?
    private let eiosButton = UIButton(type: .system)
    private var currentEiosLink: String?
    
    // Констрейнты для динамического изменения
    private var roomToTeacherConstraint: NSLayoutConstraint?
    private var roomToGroupConstraint: NSLayoutConstraint?
    private var eiosButtonConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        // Настройка контейнера
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Настройка синей линии
        leftBorderView.backgroundColor = UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1) // Цвет #017aff
        containerView.addSubview(leftBorderView)
        leftBorderView.translatesAutoresizingMaskIntoConstraints = false

        // Настройка меток
        [numberLabel, timeLabel, subjectLabel, groupLabel, teacherLabel, roomLabel, typeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .label
            $0.numberOfLines = 0
            containerView.addSubview($0)
        }

        numberLabel.font = .boldSystemFont(ofSize: 16)
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textAlignment = .right
        subjectLabel.font = .boldSystemFont(ofSize: 16)
        groupLabel.font = .italicSystemFont(ofSize: 14)
        groupLabel.textColor = .secondaryLabel
        teacherLabel.font = .italicSystemFont(ofSize: 14)
        roomLabel.font = .italicSystemFont(ofSize: 14)
        typeLabel.font = .italicSystemFont(ofSize: 14)
        
        // Настройка кнопки EIOS
        eiosButton.translatesAutoresizingMaskIntoConstraints = false
        eiosButton.backgroundColor = UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1) // #017aff
        eiosButton.layer.cornerRadius = 8
        
        // Эффект нажатия - добавляем тень
        eiosButton.layer.shadowColor = UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 0.3).cgColor
        eiosButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        eiosButton.layer.shadowRadius = 4
        eiosButton.layer.shadowOpacity = 0.5
        
        // Настраиваем title и image
        eiosButton.setTitle("eios", for: .normal)
        eiosButton.setTitleColor(.white, for: .normal)
        eiosButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        
        // Добавляем иконку с правильным размером
        if let icon = UIImage(named: "copy_icon") {
            // Масштабируем иконку до нужного размера (16x16 точек)
            let iconSize = CGSize(width: 14, height: 14)
            let resizedIcon = icon.resized(to: iconSize)
            eiosButton.setImage(resizedIcon?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        }
        
        // Настраиваем отступы между иконкой и текстом
        eiosButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        eiosButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        eiosButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        // Добавляем эффект нажатия
        eiosButton.addTarget(self, action: #selector(eiosButtonTouchDown), for: .touchDown)
        eiosButton.addTarget(self, action: #selector(eiosButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        eiosButton.isHidden = true
        containerView.addSubview(eiosButton)
        
        // Настраиваем позиционирование контента кнопки
        eiosButton.contentVerticalAlignment = .center
        eiosButton.contentHorizontalAlignment = .left
        eiosButton.semanticContentAttribute = .forceLeftToRight

        // Расположение элементов
        NSLayoutConstraint.activate([
            // Контейнер
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Синяя линия внутри контейнера
            leftBorderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftBorderView.topAnchor.constraint(equalTo: containerView.topAnchor),
            leftBorderView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            leftBorderView.widthAnchor.constraint(equalToConstant: 4), // Ширина линии

            // Метки
            numberLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12), // Сдвигаем текст вправо от линии
            numberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),

            typeLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            typeLabel.centerYAnchor.constraint(equalTo: numberLabel.centerYAnchor),

            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),

            subjectLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            subjectLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 8),
            subjectLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),

            groupLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            groupLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 4),
            groupLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),

            teacherLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            teacherLabel.topAnchor.constraint(equalTo: groupLabel.bottomAnchor, constant: 8),
            teacherLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),

            roomLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            roomLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            // Кнопка EIOS (ширина и высота определяются контентом)
        ])
        
        // Отдельно активируем позиционирование кнопки с минимальными размерами
        NSLayoutConstraint.activate([
            eiosButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            eiosButton.heightAnchor.constraint(equalToConstant: 32),
            eiosButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            eiosButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Создаем динамические констрейнты для roomLabel
        roomToTeacherConstraint = roomLabel.topAnchor.constraint(equalTo: teacherLabel.bottomAnchor, constant: 8)
        roomToGroupConstraint = roomLabel.topAnchor.constraint(equalTo: groupLabel.bottomAnchor, constant: 8)
        
        // Добавляем констрейнт для нижней границы контейнера (с учетом кнопки)
        eiosButtonConstraint = roomLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8)
        eiosButtonConstraint?.isActive = true
        
        // По умолчанию используем констрейнт к teacherLabel
        roomToTeacherConstraint?.isActive = true

        // Настройка тени для ячейки
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4
        self.layer.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with lesson: Lesson, isPlaceholder: Bool) {
        // Управление видимостью кнопки EIOS - удаляем все старые действия и добавляем новое
        eiosButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if let eiosLink = lesson.eiosLink, !eiosLink.isEmpty {
            eiosButton.isHidden = false
            currentEiosLink = eiosLink
            eiosButton.removeTarget(nil, action: nil, for: .allEvents)
            eiosButton.addTarget(self, action: #selector(eiosButtonTapped), for: .touchUpInside)
            eiosButton.addTarget(self, action: #selector(eiosButtonTouchDown), for: .touchDown)
            eiosButton.addTarget(self, action: #selector(eiosButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            
            // Переустанавливаем иконку с правильным размером
            if let icon = UIImage(named: "copy_icon") {
                let iconSize = CGSize(width: 14, height: 14)
                let resizedIcon = icon.resized(to: iconSize)
                eiosButton.setImage(resizedIcon?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
            }
            
            // Обновляем констрейнт для roomLabel, чтобы он не перекрывался с кнопкой (добавляем высоту кнопки + отступ)
            eiosButtonConstraint?.constant = -52 // 32 (высота кнопки) + 12 (bottom) + 8 (отступ)
        } else {
            eiosButton.isHidden = true
            currentEiosLink = nil
            // Когда кнопка скрыта, roomLabel может быть ближе к низу
            eiosButtonConstraint?.constant = -8
        }
        
        if isPlaceholder {
            // Удаляем текстовые метки для анимации
            [numberLabel, timeLabel, subjectLabel, groupLabel, teacherLabel, roomLabel, typeLabel].forEach { $0.isHidden = true }

            // Добавляем анимацию Lottie
            if lottieAnimationView == nil {
                lottieAnimationView = LottieAnimationView(name: "weekend") // Замените на ваше имя файла Lottie
                guard let lottieAnimationView = lottieAnimationView else { return }

                lottieAnimationView.translatesAutoresizingMaskIntoConstraints = false
                lottieAnimationView.loopMode = .loop
                lottieAnimationView.contentMode = .scaleAspectFit
                containerView.addSubview(lottieAnimationView)

                // Добавляем ограничения для центрирования и уменьшения размера анимации
                NSLayoutConstraint.activate([
                    lottieAnimationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    lottieAnimationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    lottieAnimationView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.7),
                    lottieAnimationView.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor, multiplier: 0.7)
                ])

                lottieAnimationView.play()
            }
        } else {
            // Показываем текстовые метки для других дней
            [numberLabel, timeLabel, subjectLabel, groupLabel, teacherLabel, roomLabel, typeLabel].forEach { $0.isHidden = false }
            numberLabel.text = "№\(lesson.number)"
            timeLabel.text = lesson.time

            let (groupText, subjectText) = splitGroupAndSubject(from: lesson.subject)
            subjectLabel.text = subjectText
            
            // В режиме преподавателя lesson.teacher содержит группы, а не имя преподавателя
            // Поэтому показываем группы в groupLabel, а teacherLabel скрываем
            if !lesson.teacher.isEmpty {
                groupLabel.text = lesson.teacher // Группы из API
                teacherLabel.isHidden = true
                
                // Переключаем констрейнты: roomLabel привязываем к groupLabel
                roomToTeacherConstraint?.isActive = false
                roomToGroupConstraint?.isActive = true
            } else {
                groupLabel.text = groupText // Группы из парсинга subject
                teacherLabel.text = lesson.teacher
                teacherLabel.isHidden = false
                
                // Переключаем констрейнты: roomLabel привязываем к teacherLabel
                roomToGroupConstraint?.isActive = false
                roomToTeacherConstraint?.isActive = true
            }
            
            roomLabel.text = lesson.room
            typeLabel.text = lesson.type
            containerView.backgroundColor = .secondarySystemBackground

            // Убираем Lottie, если она была добавлена
            lottieAnimationView?.removeFromSuperview()
            lottieAnimationView = nil
        }
    }

    @objc private func eiosButtonTapped() {
        if let eiosLink = currentEiosLink {
            UIPasteboard.general.string = eiosLink
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Показываем alert
            showCopyAlert()
        }
    }
    
    @objc private func eiosButtonTouchDown() {
        // Эффект нажатия - уменьшаем кнопку
        UIView.animate(withDuration: 0.1) {
            self.eiosButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.eiosButton.layer.shadowOpacity = 0.3
        }
    }
    
    @objc private func eiosButtonTouchUp() {
        // Возвращаем кнопку в исходное состояние
        UIView.animate(withDuration: 0.1) {
            self.eiosButton.transform = .identity
            self.eiosButton.layer.shadowOpacity = 0.5
        }
    }
    
    private func showCopyAlert() {
        // Создаем простой alert с анимацией появления
        let alertView = UIView()
        alertView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        alertView.layer.cornerRadius = 12
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Ссылка скопирована"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        alertView.addSubview(label)
        
        // Добавляем на view controller, чтобы отображалось поверх всего
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(alertView)
            
            NSLayoutConstraint.activate([
                alertView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                alertView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
                alertView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                alertView.heightAnchor.constraint(equalToConstant: 50),
                
                label.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: alertView.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16)
            ])
            
            // Анимация появления
            alertView.alpha = 0
            alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
                alertView.alpha = 1
                alertView.transform = .identity
            }) { _ in
                // Анимация исчезновения
                UIView.animate(withDuration: 0.3, delay: 1.0) {
                    alertView.alpha = 0
                    alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                } completion: { _ in
                    alertView.removeFromSuperview()
                }
            }
        }
    }
    
    private func splitGroupAndSubject(from original: String) -> (group: String, subject: String) {
        // Ищем группу в начале строки (пример: 22-ДЗ-02 ...)
        // Поддержка нескольких групп через запятую: 23-СПО-СиСА-04,22-СПО-СиСА-01
        let pattern = "^\\s*([0-9]{2}-[A-Za-zА-Яа-яЁё-]+-[0-9]{2}(?:\\s*,\\s*[0-9]{2}-[A-Za-zА-Яа-яЁё-]+-[0-9]{2})*)\\s*(.*)$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: (original as NSString).length)
            if let match = regex.firstMatch(in: original, options: [], range: range), match.numberOfRanges >= 3 {
                let groupRange = match.range(at: 1)
                let subjectRange = match.range(at: 2)
                let ns = original as NSString
                let group = ns.substring(with: groupRange)
                let subject = ns.substring(with: subjectRange).trimmingCharacters(in: .whitespacesAndNewlines)
                return (group, subject.isEmpty ? original : subject)
            }
        }
        // Если шаблон не подошел — ничего не меняем
        return ("", original)
    }
}

// Расширение для изменения размера изображения
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
