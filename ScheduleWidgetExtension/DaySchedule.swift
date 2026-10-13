//
//  DaySchedule.swift
//  ScheduleWidgetExtension
//
//  Shared model for Widget Extension
//

import UIKit

// MARK: - Модель данных
struct DaySchedule: Codable {
    let day: String
    let date: String
    let lessons: [Lesson]
    let isoDate: String?

    init(day: String, date: String, lessons: [Lesson], isoDate: String? = nil) {
        self.day = day
        self.date = date
        self.lessons = lessons
        self.isoDate = isoDate
    }
}



