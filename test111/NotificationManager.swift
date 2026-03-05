//
//  NotificationManager.swift
//  test111
//
//  Created by Assistant on 08.12.2024.
//

import UIKit
import UserNotifications
import MyTrackerSDK

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Ключи для UserDefaults
    private let notificationsEnabledKey = "notificationsEnabled"
    private let notificationTimeKey = "notificationTimeMinutes"
    
    // Получаем настройки уведомлений
    var isNotificationsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey)
        }
    }
    
    var notificationTimeMinutes: Int {
        get {
            return UserDefaults.standard.integer(forKey: notificationTimeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: notificationTimeKey)
        }
    }
    
    // Инициализация с настройками по умолчанию
    func setupDefaultSettings() {
        if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil {
            isNotificationsEnabled = true
        }
        if UserDefaults.standard.object(forKey: notificationTimeKey) == nil {
            notificationTimeMinutes = 5
        }
    }
    
    // Запрос разрешения на уведомления
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Планирование уведомлений для расписания
    func scheduleNotifications(for schedule: [DaySchedule], isTeacherMode: Bool = false) {
        // Уведомления только для студентов, не для преподавателей
        guard !isTeacherMode else {
            print("ℹ️ Уведомления не планируются для режима преподавателя")
            return
        }
        
        // Трекинг события
        MRMyTracker.trackEvent(name: "Фоновый процесс доставки уведомления о начале пары")
        
        guard isNotificationsEnabled else {
            removeAllNotifications()
            return
        }
        
        // Удаляем все существующие уведомления перед планированием новых
        removeAllNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var scheduledCount = 0
        
        // Считаем, сколько дней осталось до субботы текущей недели (1 = вс, 7 = сб)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSaturday = max(0, 7 - weekday)
        
        // Планируем с сегодня и до субботы включительно
        for dayOffset in 0...daysToSaturday {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // 1 = воскресенье, 2 = понедельник ... 7 = суббота
            let targetWeekday = calendar.component(.weekday, from: targetDate)
            let scheduleIndex = (targetWeekday == 1) ? 6 : targetWeekday - 2
            
            guard schedule.indices.contains(scheduleIndex) else { continue }
            let daySchedule = schedule[scheduleIndex]
            
            for lesson in daySchedule.lessons {
                // Пропускаем пустые уроки и выходные
                if lesson.time.isEmpty { continue }
                if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" { continue }
                if lesson.subject.isEmpty { continue }
                
                guard let lessonStart = buildStartDate(on: targetDate, time: lesson.time) else { continue }
                guard let notifDate = calendar.date(byAdding: .minute, value: -notificationTimeMinutes, to: lessonStart), notifDate > now else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "Напоминание о паре"
                content.body = "До начала пары \"\(lesson.subject)\" осталось \(notificationTimeMinutes) \(getMinutesText(notificationTimeMinutes))"
                content.sound = .default
                
                let idFormatter = DateFormatter()
                idFormatter.dateFormat = "yyyyMMdd"
                let datePart = idFormatter.string(from: targetDate)
                let timeSanitized = lesson.time.replacingOccurrences(of: ":", with: "_").replacingOccurrences(of: "-", with: "_")
                let identifier = "lesson_\(datePart)_\(lesson.number)_\(timeSanitized)"
                
                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Ошибка планирования уведомления: \(error.localizedDescription)")
                    }
                }
                scheduledCount += 1
            }
        }
        
        print("✅ Запланировано \(scheduledCount) уведомлений до конца текущей недели (включая субботу)")
    }
    
    // Удаление всех уведомлений
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ Все уведомления удалены")
        
        // Трекинг события
        MRMyTracker.trackEvent(name: "Смахнуть уведомление о начале пары")
    }
    
    // Парсинг времени урока (например, "8:30-10:00")
    private func parseLessonTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.components(separatedBy: "-")
        guard let startTime = components.first else { return nil }
        
        let timeComponents = startTime.components(separatedBy: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else { return nil }
        
        return (hour: hour, minute: minute)
    }
    
    // Парсинг даты дня недели
    private func parseDayDate(_ day: String, _ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        return dateFormatter.date(from: dateString)
    }
    
    // Получение правильного склонения для слова "минут"
    private func getMinutesText(_ minutes: Int) -> String {
        let lastDigit = minutes % 10
        let lastTwoDigits = minutes % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "минут"
        }
        
        switch lastDigit {
        case 1:
            return "минута"
        case 2, 3, 4:
            return "минуты"
        default:
            return "минут"
        }
    }
    
    // Получение количества запланированных уведомлений
    func getPendingNotificationsCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
    
    // Отладочная информация о запланированных уведомлениях
    func debugNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📊 Отладка уведомлений:")
            print("   Всего запланировано: \(requests.count)")
            
            for (index, request) in requests.enumerated() {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    let nextTrigger = trigger.nextTriggerDate()
                    print("   \(index + 1). \(request.content.title) - \(request.content.body)")
                    print("      Следующий триггер: \(nextTrigger?.description ?? "нет")")
                }
            }
        }
    }
    
    // Проверка разрешений на уведомления
    func checkNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                print("🔔 Разрешения на уведомления: \(isAuthorized ? "✅ разрешены" : "❌ запрещены")")
                completion(isAuthorized)
            }
        }
    }
    
    // Строит дату начала пары на конкретный день недели на основе строки времени "HH:mm-HH:mm"
    private func buildStartDate(on date: Date, time: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        guard let startPart = time.split(separator: "-").first,
              let startDateOnlyTime = dateFormatter.date(from: String(startPart)) else { return nil }
        
        let calendar = Calendar.current
        let ymd = calendar.dateComponents([.year, .month, .day], from: date)
        var comps = DateComponents()
        comps.year = ymd.year
        comps.month = ymd.month
        comps.day = ymd.day
        comps.hour = calendar.component(.hour, from: startDateOnlyTime)
        comps.minute = calendar.component(.minute, from: startDateOnlyTime)
        return calendar.date(from: comps)
    }
    
    // Принудительное обновление уведомлений на всю неделю (для Background Fetch)
    func forceRescheduleNotificationsForWeek(schedule: [DaySchedule], isTeacherMode: Bool = false) {
        // Уведомления только для студентов, не для преподавателей
        guard !isTeacherMode else {
            print("ℹ️ Background Fetch: уведомления не планируются для режима преподавателя")
            return
        }
        
        guard isNotificationsEnabled else {
            removeAllNotifications()
            return
        }
        
        // Удаляем все существующие уведомления перед планированием новых
        removeAllNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var scheduledCount = 0
        
        // Планируем на всю неделю (7 дней)
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // 1 = воскресенье, 2 = понедельник ... 7 = суббота
            let targetWeekday = calendar.component(.weekday, from: targetDate)
            let scheduleIndex = (targetWeekday == 1) ? 6 : targetWeekday - 2
            
            guard schedule.indices.contains(scheduleIndex) else { continue }
            let daySchedule = schedule[scheduleIndex]
            
            for lesson in daySchedule.lessons {
                // Пропускаем пустые уроки и выходные
                if lesson.time.isEmpty { continue }
                if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" { continue }
                if lesson.subject.isEmpty { continue }
                
                guard let lessonStart = buildStartDate(on: targetDate, time: lesson.time) else { continue }
                guard let notifDate = calendar.date(byAdding: .minute, value: -notificationTimeMinutes, to: lessonStart), notifDate > now else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "Напоминание о паре"
                content.body = "До начала пары \"\(lesson.subject)\" осталось \(notificationTimeMinutes) \(getMinutesText(notificationTimeMinutes))"
                content.sound = .default
                
                let idFormatter = DateFormatter()
                idFormatter.dateFormat = "yyyyMMdd"
                let datePart = idFormatter.string(from: targetDate)
                let timeSanitized = lesson.time.replacingOccurrences(of: ":", with: "_").replacingOccurrences(of: "-", with: "_")
                let identifier = "lesson_\(datePart)_\(lesson.number)_\(timeSanitized)"
                
                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Ошибка планирования уведомления: \(error.localizedDescription)")
                    }
                }
                scheduledCount += 1
            }
        }
        
        print("✅ Background Fetch: запланировано \(scheduledCount) уведомлений на всю неделю")
    }
}
