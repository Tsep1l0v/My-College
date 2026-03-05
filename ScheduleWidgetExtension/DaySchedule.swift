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
}



