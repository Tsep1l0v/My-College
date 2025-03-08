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
    private let teacherLabel = UILabel()
    private let roomLabel = UILabel()
    private let typeLabel = UILabel()
    private let containerView = UIView()
    private let leftBorderView = UIView() // Синяя линия внутри контейнера
    private var lottieAnimationView: LottieAnimationView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        // Настройка контейнера
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Настройка синей линии
        leftBorderView.backgroundColor = UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1) // Цвет #017aff
        containerView.addSubview(leftBorderView)
        leftBorderView.translatesAutoresizingMaskIntoConstraints = false

        // Настройка меток
        [numberLabel, timeLabel, subjectLabel, teacherLabel, roomLabel, typeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .black
            $0.numberOfLines = 0
            containerView.addSubview($0)
        }

        numberLabel.font = .boldSystemFont(ofSize: 16)
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textAlignment = .right
        subjectLabel.font = .boldSystemFont(ofSize: 16)
        teacherLabel.font = .italicSystemFont(ofSize: 14)
        roomLabel.font = .italicSystemFont(ofSize: 14)
        typeLabel.font = .italicSystemFont(ofSize: 14)

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

            teacherLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            teacherLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 8),
            teacherLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),

            roomLabel.leadingAnchor.constraint(equalTo: leftBorderView.trailingAnchor, constant: 12),
            roomLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])

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
        if isPlaceholder {
            // Удаляем текстовые метки для анимации
            [numberLabel, timeLabel, subjectLabel, teacherLabel, roomLabel, typeLabel].forEach { $0.isHidden = true }

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
            [numberLabel, timeLabel, subjectLabel, teacherLabel, roomLabel, typeLabel].forEach { $0.isHidden = false }
            numberLabel.text = "№\(lesson.number)"
            timeLabel.text = lesson.time
            subjectLabel.text = lesson.subject
            teacherLabel.text = lesson.teacher
            roomLabel.text = lesson.room
            typeLabel.text = lesson.type
            containerView.backgroundColor = .white // Белый фон

            // Убираем Lottie, если она была добавлена
            lottieAnimationView?.removeFromSuperview()
            lottieAnimationView = nil
        }
    }
}
