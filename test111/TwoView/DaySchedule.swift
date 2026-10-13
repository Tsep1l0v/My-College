//
//  DaySchedule.swift
//  test111
//
//  Created by Дмитрий Цепилов on 04.12.2024.
//

import UIKit

// MARK: - Модель данных
struct DaySchedule: Codable {
    let day: String
    let date: String
    let lessons: [Lesson]
    /// Для расписания сессии (заочное): дата в формате yyyy-MM-dd
    let isoDate: String?

    init(day: String, date: String, lessons: [Lesson], isoDate: String? = nil) {
        self.day = day
        self.date = date
        self.lessons = lessons
        self.isoDate = isoDate
    }
}

