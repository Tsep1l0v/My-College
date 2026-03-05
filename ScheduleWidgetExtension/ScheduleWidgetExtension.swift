//
//  ScheduleWidgetExtension.swift
//  ScheduleWidgetExtension
//
//  Created for Widget Extension
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - UIColor Extension for Widget
extension UIColor {
    convenience init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

struct ScheduleWidgetExtension: Widget {
    let kind: String = "ScheduleWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Следующая пара")
        .description("Показывает следующую пару из вашего расписания")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            currentLesson: Lesson(
                number: 1,
                time: "08:00-09:30",
                subject: "Математика",
                teacher: "Иванов И.И.",
                room: "101",
                type: "Лекция",
                color: .systemBlue,
                eiosLink: nil
            ),
            nextLesson: Lesson(
                number: 2,
                time: "09:40-11:10",
                subject: "Программирование",
                teacher: "Петров П.П.",
                room: "205",
                type: "Практика",
                color: .systemGreen,
                eiosLink: nil
            ),
            dayName: "Понедельник",
            isWeekend: false,
            currentLessonProgress: 0.5,
            isNextLessonInAnotherDay: false,
            nextLessonDayName: nil,
            isTomorrowWeekend: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> ()) {
        let entry = getNextLesson(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> ()) {
        var entries: [ScheduleEntry] = []
        let now = Date()
        
        // Создаём entries на каждую минуту следующего часа для плавного обновления прогресса
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
            let entry = getNextLesson(for: entryDate)
            entries.append(entry)
        }
        
        // Следующее обновление через час
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getNextLesson(for date: Date = Date()) -> ScheduleEntry {
        print("📅 Widget: getNextLesson() called at \(date)")
        
        // Загружаем расписание из общего хранилища
        let schedule = ScheduleStorage.loadSchedule()
        
        guard let schedule = schedule else {
            print("⚠️ Widget: No schedule available, returning empty entry")
            return ScheduleEntry(
                date: date,
                currentLesson: nil,
                nextLesson: nil,
                dayName: nil,
                isWeekend: false,
                currentLessonProgress: nil,
                isNextLessonInAnotherDay: false,
                nextLessonDayName: nil,
                isTomorrowWeekend: false
            )
        }
        
        print("📅 Widget: Processing schedule with \(schedule.count) days")
        
        let calendar = Calendar.current
        let now = date
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Преобразуем день недели: 1=воскресенье, 2=понедельник, ..., 7=суббота
        // В нашем расписании: 0=понедельник, 1=вторник, ..., 6=воскресенье
        let scheduleIndex: Int
        if currentWeekday == 1 { // Воскресенье
            scheduleIndex = 6
        } else {
            scheduleIndex = currentWeekday - 2 // Понедельник = 0
        }
        
        // Проверяем, является ли сегодня выходным днем
        if scheduleIndex < schedule.count {
            let todaySchedule = schedule[scheduleIndex]
            // Проверяем, есть ли только placeholder уроки (выходной день)
            let isTodayWeekend = !todaySchedule.lessons.isEmpty && 
                                 todaySchedule.lessons.allSatisfy { 
                                     $0.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" 
                                 }
            
            if isTodayWeekend {
                return ScheduleEntry(
                    date: date,
                    currentLesson: nil,
                    nextLesson: nil,
                    dayName: todaySchedule.day,
                    isWeekend: true,
                    currentLessonProgress: nil,
                    isNextLessonInAnotherDay: false,
                    nextLessonDayName: nil,
                    isTomorrowWeekend: false
                )
            }
        }
        
        // Получаем текущее время
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTimeMinutes = hour * 60 + minute
        
        print("🔎 Widget: Searching for current and next lessons. Schedule index today = \(scheduleIndex)")
        
        // Сначала ищем текущую пару сегодня
        var currentLesson: Lesson?
        var currentProgress: Double?
        
        if scheduleIndex < schedule.count {
            let todaySchedule = schedule[scheduleIndex]
            
            for lesson in todaySchedule.lessons {
                // Пропускаем placeholder уроки
                if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" {
                    continue
                }
                
                // Парсим время начала и конца пары
                if let (startMinutes, endMinutes) = parseFullLessonTime(lesson.time) {
                    // Проверяем, идет ли пара сейчас
                    if currentTimeMinutes >= startMinutes && currentTimeMinutes < endMinutes {
                        currentLesson = lesson
                        // Вычисляем прогресс (от 0.0 до 1.0)
                        let duration = Double(endMinutes - startMinutes)
                        let elapsed = Double(currentTimeMinutes - startMinutes)
                        currentProgress = min(1.0, max(0.0, elapsed / duration))
                        print("✅ Widget: Current lesson found -> '\(lesson.subject)' progress: \(String(format: "%.1f%%", currentProgress! * 100))")
                        break
                    }
                }
            }
        }
        
        // Теперь ищем следующую пару
        var nextLesson: Lesson?
        var isNextInAnotherDay = false
        var nextLessonDayName: String?
        var daysUntilNextLesson: Int = 0
        
        // Сначала проверяем оставшиеся дни текущей недели
        for dayOffset in 0..<7 {
            let dayIndex = (scheduleIndex + dayOffset) % 7
            guard dayIndex < schedule.count else { continue }
            
            let daySchedule = schedule[dayIndex]
            let isToday = dayOffset == 0
            
            for lesson in daySchedule.lessons {
                // Пропускаем placeholder уроки
                if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" {
                    continue
                }
                
                // Пропускаем текущую пару
                if let current = currentLesson, lesson.number == current.number && isToday {
                    continue
                }
                
                // Парсим время начала пары
                if let lessonTime = parseLessonTime(lesson.time) {
                    let lessonStartMinutes = lessonTime.hour * 60 + lessonTime.minute
                    
                    // Если это сегодня и пара еще не началась, или это будущий день
                    if (isToday && lessonStartMinutes > currentTimeMinutes) || !isToday {
                        nextLesson = lesson
                        isNextInAnotherDay = !isToday
                        daysUntilNextLesson = dayOffset
                        
                        // Определяем название дня: если завтра - "Завтра", иначе - день недели
                        if dayOffset == 1 {
                            nextLessonDayName = "Завтра"
                    } else {
                            nextLessonDayName = daySchedule.day
                        }
                        
                        print("✅ Widget: Next lesson found -> '\(lesson.subject)' at \(lesson.time) (another day: \(isNextInAnotherDay), day: \(daySchedule.day), days: \(dayOffset))")
                        break
                    }
                }
            }
            
            if nextLesson != nil {
                break
            }
        }
        
        // Если не нашли на текущей неделе, ищем на следующей неделе
        if nextLesson == nil {
            // Вычисляем количество дней до следующего понедельника
            // Если сегодня понедельник (0), то до следующего понедельника 7 дней
            // Если сегодня вторник (1), то до следующего понедельника 6 дней
            // И так далее: daysUntilNextMonday = 7 - scheduleIndex
            let daysUntilNextMonday = 7 - scheduleIndex
            
            for weekOffset in 1..<3 { // Проверяем до 2 недель вперед
                for dayOffset in 0..<7 {
                    let dayIndex = dayOffset // На следующей неделе начинаем с понедельника
                    guard dayIndex < schedule.count else { continue }
                    
                    let daySchedule = schedule[dayIndex]
                    
                    for lesson in daySchedule.lessons {
                        // Пропускаем placeholder уроки
                        if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" {
                            continue
                        }
                        
                        // Парсим время начала пары
                        if let lessonTime = parseLessonTime(lesson.time) {
                            nextLesson = lesson
                            isNextInAnotherDay = true
                            // Правильно вычисляем дни: дни до следующего понедельника + дни на следующей неделе
                            daysUntilNextLesson = daysUntilNextMonday + (weekOffset - 1) * 7 + dayOffset
                            
                            // Определяем название дня: если завтра - "Завтра", иначе - день недели
                            if daysUntilNextLesson == 1 {
                                nextLessonDayName = "Завтра"
                } else {
                                nextLessonDayName = daySchedule.day
                            }
                            
                            print("✅ Widget: Next lesson found on next week -> '\(lesson.subject)' at \(lesson.time) (day: \(daySchedule.day), days: \(daysUntilNextLesson))")
                            break
                        }
                    }
                    
                    if nextLesson != nil {
                        break
                    }
                }
                
                if nextLesson != nil {
                    break
                }
            }
        }
        
        // Проверяем, выходной ли завтра (если следующая пара не завтра)
        var isTomorrowWeekend = false
        if nextLesson != nil && isNextInAnotherDay && daysUntilNextLesson > 1 {
            // Проверяем завтрашний день
            let tomorrowIndex = (scheduleIndex + 1) % 7
            if tomorrowIndex < schedule.count {
                let tomorrowSchedule = schedule[tomorrowIndex]
                // Проверяем, есть ли только placeholder уроки (выходной день)
                isTomorrowWeekend = tomorrowSchedule.lessons.isEmpty || 
                                    tomorrowSchedule.lessons.allSatisfy { 
                                        $0.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" 
                                    }
            }
        }
        
        // Возвращаем результат
        return ScheduleEntry(
            date: date,
            currentLesson: currentLesson,
            nextLesson: nextLesson,
            dayName: scheduleIndex < schedule.count ? schedule[scheduleIndex].day : nil,
            isWeekend: false,
            currentLessonProgress: currentProgress,
            isNextLessonInAnotherDay: isNextInAnotherDay,
            nextLessonDayName: nextLessonDayName,
            isTomorrowWeekend: isTomorrowWeekend
        )
    }
    
    private func parseFullLessonTime(_ timeString: String) -> (start: Int, end: Int)? {
        // Форматы времени: "08:00-09:30", "08.00-09.30"
        var raw = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
        raw = raw.replacingOccurrences(of: ".", with: ":")
        
        let separators: [Character] = ["-", "–", "—", "―"]
        guard let separatorChar = separators.first(where: { raw.contains($0) }),
              let separatorIndex = raw.firstIndex(of: separatorChar) else {
            return nil
        }
        
        let startStr = String(raw[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let endStr = String(raw[raw.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let startComponents = startStr.split(separator: ":")
        let endComponents = endStr.split(separator: ":")
        
        guard startComponents.count == 2, endComponents.count == 2,
              let startHour = Int(startComponents[0]),
              let startMinute = Int(startComponents[1]),
              let endHour = Int(endComponents[0]),
              let endMinute = Int(endComponents[1]) else {
            return nil
        }
        
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        return (startMinutes, endMinutes)
    }
    
    private func parseLessonTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        // Форматы времени: "08:00-09:30", "08.00-09.30", "08:00 – 09:30", "08:00"
        let separators: [Character] = ["-", "–", "—", "―"]
        var raw = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return nil }
        
        // Заменяем точки на двоеточия, так как в расписании время приходит вида "13.10-14.40"
        raw = raw.replacingOccurrences(of: ".", with: ":")
        
        // Находим первую часть времени до разделителя
        if let separatorChar = separators.first(where: { raw.contains($0) }) {
            if let separatorIndex = raw.firstIndex(of: separatorChar) {
                raw = String(raw[..<separatorIndex])
            }
        }
        
        // Убираем лишние слова/символы (например, "08:00 " или "08:00 ")
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Извлекаем цифры времени
        let components = raw.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0].trimmingCharacters(in: .whitespaces)),
              let minute = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
            print("⚠️ Widget: Failed to parse time string '\(timeString)' -> '\(raw)'")
            return nil
        }
        
        return (hour: hour, minute: minute)
    }
}

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let currentLesson: Lesson?
    let nextLesson: Lesson?
    let dayName: String?
    let isWeekend: Bool
    let currentLessonProgress: Double? // Прогресс текущей пары (0.0 - 1.0)
    let isNextLessonInAnotherDay: Bool // Следующая пара в другой день
    let nextLessonDayName: String? // Название дня следующей пары
    let isTomorrowWeekend: Bool // Завтра выходной (нет пар)
}

struct ScheduleWidgetEntryView: View {
    var entry: ScheduleProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: ScheduleProvider.Entry
    
    var body: some View {
            if entry.isWeekend {
                // Выходной день
            ZStack(alignment: .topLeading) {
                // Вертикальная полоска
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.top, -18)
                    .padding(.bottom, -18)
                
                // Контент
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    HStack(alignment: .top, spacing: 0) {
                        // Белый неоновый кружочек на полоске
                    ZStack {
                        Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .shadow(color: Color.white.opacity(0.8), radius: 3, x: 0, y: 0)
                                .shadow(color: Color.blue.opacity(0.6), radius: 4, x: 0, y: 0)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 7, height: 7)
                        }
                        .offset(x: -3, y: 8)
                        
                        VStack(alignment: .leading, spacing: 3) {
                    Text("Выходной")
                                .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                            Text("Отдыхай, сегодня можно выспаться")
                                .font(.system(size: 9))
                            .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 6)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        } else if entry.currentLesson == nil && entry.nextLesson == nil {
            // Нет расписания
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                
                Text("Нет\nрасписания")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        } else {
            let isOnlyNextLesson = entry.currentLesson == nil && entry.nextLesson != nil
            
            ZStack(alignment: .topLeading) {
                // Вертикальная полоска
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.top, -18)
                    .padding(.bottom, -18)
                
                // Контент
                if isOnlyNextLesson {
                    // Когда только следующая пара - центрируем вертикально
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        
                        if entry.isTomorrowWeekend {
                            // Показываем сообщение, что завтра выходной
                            HStack(alignment: .top, spacing: 0) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: Color.white.opacity(0.8), radius: 3, x: 0, y: 0)
                                        .shadow(color: Color.blue.opacity(0.6), radius: 4, x: 0, y: 0)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 7, height: 7)
                                }
                                .offset(x: -3, y: 8)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Завтра пар нет")
                                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                                    
                                    Text("Отдыхаем")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                                .padding(.trailing, 8)
                                .padding(.vertical, 6)
                            }
                        } else if let next = entry.nextLesson {
                            SmallLessonCardView(
                                lesson: next,
                                title: "Следующая пара",
                                progress: nil,
                                showTitle: true,
                                isNextLesson: true,
                                dayName: entry.isNextLessonInAnotherDay ? entry.nextLessonDayName : nil
                            )
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        // Текущая пара (если есть)
                        if let current = entry.currentLesson, let progress = entry.currentLessonProgress {
                            SmallLessonCardView(
                                lesson: current,
                                title: "Сейчас идет",
                                progress: progress,
                                showTitle: true,
                                isNextLesson: false,
                                dayName: nil
                            )
                            .padding(.top, -4)
                        }
                        
                        // Следующая пара или сообщение
                        if entry.currentLesson != nil && entry.isNextLessonInAnotherDay {
                            // Показываем сообщение, что пары закончились
                            HStack(alignment: .top, spacing: 0) {
                            ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: Color.white.opacity(0.8), radius: 3, x: 0, y: 0)
                                        .shadow(color: Color.blue.opacity(0.6), radius: 4, x: 0, y: 0)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 7, height: 7)
                                }
                                .offset(x: -3, y: 6)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Пары закончились")
                                        .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                                    
                                    Text("Домой 🏠")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                                .padding(.trailing, 8)
                                .padding(.vertical, 5)
                            }
                            .padding(.top, -3)
                        } else if let next = entry.nextLesson {
                            SmallLessonCardView(
                                lesson: next,
                                title: "Следующая пара",
                                progress: nil,
                                showTitle: true,
                                isNextLesson: true,
                                dayName: entry.isNextLessonInAnotherDay ? entry.nextLessonDayName : nil
                            )
                            .padding(.top, entry.currentLesson == nil ? 0 : -3)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    // Если есть текущая пара, поднимаем блок выше, если только следующая — оставляем отступ
                    .padding(.top, entry.currentLesson == nil ? 6 : -2)
                }
            }
        }
    }
}

// Компактная карточка пары для small виджета
struct SmallLessonCardView: View {
    let lesson: Lesson
    let title: String
    let progress: Double?
    let showTitle: Bool
    let isNextLesson: Bool
    let dayName: String? // Название дня для следующей пары в другой день
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Белый неоновый кружочек на голубой полоске
                                ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.white.opacity(0.8), radius: 3, x: 0, y: 0)
                    .shadow(color: Color.blue.opacity(0.6), radius: 4, x: 0, y: 0)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
            }
            .offset(
                x: -3,
                y: {
                    // Для следующей пары кружок опускаем еще ниже,
                    // для текущей пары тоже чуть ниже, чем было
                    if isNextLesson {
                        return showTitle ? 19 : 20
                    } else {
                        return showTitle ? 19 : 20
                    }
                }()
            )
            
            VStack(alignment: .leading, spacing: 2) {
                // Название предмета и заголовок
                if showTitle {
                    // Для текущей и следующей пары одинаковый стиль:
                    // заголовок наверху справа, ниже — название пары
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Spacer()
                            HStack(spacing: 3) {
                                Text(title)
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                
                                if let dayName = dayName {
                                    Text(dayName)
                                        .font(.system(size: 8))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Text(lesson.subject)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    .frame(height: 26, alignment: .topLeading)
                } else {
                    Text(lesson.subject)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(height: 28)
                }
                
                // Преподаватель
                if !lesson.teacher.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.blue)
                        
                        Text(lesson.teacher)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(height: 10)
                }
                
                // Время и кабинет
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 7))
                            .foregroundColor(.blue)
                        
                        Text(lesson.time)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    if !lesson.room.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 7))
                                .foregroundColor(.blue)
                            
                            Text(lesson.room)
                                .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                    }
                }
                .frame(height: 10)
                
                // Индикатор прогресса (только для текущей пары)
                if let progress = progress {
                    VStack(alignment: .leading, spacing: 1) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(height: 3)
                                
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 3)
                            }
                        }
                        .frame(height: 3)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 1)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.vertical, 5)
        }
    }
}

struct MediumWidgetView: View {
    var entry: ScheduleProvider.Entry
    
    var body: some View {
            if entry.isWeekend {
                // Выходной день
            ZStack(alignment: .topLeading) {
                // Вертикальная полоска
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.top, -20)
                    .padding(.bottom, -20)
                
                // Контент
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    HStack(alignment: .top, spacing: 0) {
                        // Белый неоновый кружочек на полоске
                    ZStack {
                        Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: Color.white.opacity(0.8), radius: 4, x: 0, y: 0)
                                .shadow(color: Color.blue.opacity(0.6), radius: 6, x: 0, y: 0)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                        }
                        .offset(x: -5, y: 12)
                        
                        VStack(alignment: .leading, spacing: 5) {
                    Text("Выходной")
                                .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                            Text("Отдыхай, сегодня можно выспаться")
                                .font(.system(size: 12))
                            .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        .padding(.vertical, 10)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        } else if entry.currentLesson == nil && entry.nextLesson == nil {
            // Нет расписания
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 28))
                        .foregroundColor(.secondary)
                
                Text("Нет расписания")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let isOnlyNextLesson = entry.currentLesson == nil && entry.nextLesson != nil
            
            ZStack(alignment: .topLeading) {
                // Единая вертикальная полоска (растянута за края сверху и снизу)
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.top, -20)
                    .padding(.bottom, -20)
                
                // Заголовок "Следующая пара" в верхнем правом углу (только для одной пары)
                if isOnlyNextLesson && !entry.isTomorrowWeekend {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Следующая пара")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            if entry.isNextLessonInAnotherDay, let dayName = entry.nextLessonDayName {
                                Text(dayName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 6)
                        .padding(.trailing, 10)
                    }
                }
                
                // Контент с парами
                if isOnlyNextLesson {
                    // Когда только следующая пара - центрируем вертикально, но слева
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        
                        if entry.isTomorrowWeekend {
                            // Показываем сообщение, что завтра выходной
                            HStack(alignment: .top, spacing: 0) {
                                // Белый неоновый кружочек на голубой полоске
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 14, height: 14)
                                        .shadow(color: Color.white.opacity(0.8), radius: 4, x: 0, y: 0)
                                        .shadow(color: Color.blue.opacity(0.6), radius: 6, x: 0, y: 0)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 10, height: 10)
                                }
                                .offset(x: -5, y: 12)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Завтра пар нет")
                                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                                    
                                    Text("Отдыхаем")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                        .padding(.vertical, 10)
                            }
                        } else if let next = entry.nextLesson {
                            LessonCardView(
                                lesson: next,
                                title: "Следующая пара",
                                progress: nil,
                                showLine: false,
                                isLarge: true,
                                showTitle: false,
                                isNextLesson: false
                            )
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 0)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        // Текущая пара (если есть)
                        if let current = entry.currentLesson, let progress = entry.currentLessonProgress {
                            LessonCardView(
                                lesson: current,
                                title: "Сейчас идет",
                                progress: progress,
                                showLine: false,
                                isLarge: false,
                                showTitle: true,
                                isNextLesson: false
                            )
                            .padding(.top, 2)
                        }
                        
                        // Следующая пара (если есть)
                        if entry.currentLesson != nil && entry.isNextLessonInAnotherDay {
                            // Всегда показываем сообщение, что пары закончились, даже если завтра выходной
                            HStack(alignment: .top, spacing: 0) {
                                // Белый неоновый кружочек на голубой полоске
                                    ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: Color.white.opacity(0.8), radius: 4, x: 0, y: 0)
                                        .shadow(color: Color.blue.opacity(0.6), radius: 6, x: 0, y: 0)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                }
                                .offset(x: -4, y: 10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Пары закончились")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Можно идти домой 🏠")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                                .padding(.vertical, 8)
                            }
                            .padding(.top, -6)
                        } else if let next = entry.nextLesson {
                            LessonCardView(
                                lesson: next,
                                title: "Следующая пара",
                                progress: nil,
                                showLine: false,
                                isLarge: false,
                                showTitle: true,
                                isNextLesson: true
                            )
                            .padding(.top, -6)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 0)
                }
            }
        }
    }
}

// Компонент карточки пары
struct LessonCardView: View {
    let lesson: Lesson
    let title: String
    let progress: Double?
    let showLine: Bool
    let isLarge: Bool
    let showTitle: Bool
    let isNextLesson: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Белый неоновый кружочек на голубой полоске
                                ZStack {
                // Неоновое свечение
                Circle()
                    .fill(Color.white)
                    .frame(width: isLarge ? 14 : 12, height: isLarge ? 14 : 12)
                    .shadow(color: Color.white.opacity(0.8), radius: 4, x: 0, y: 0)
                    .shadow(color: Color.blue.opacity(0.6), radius: 6, x: 0, y: 0)
                
                // Внутренний белый круг
                Circle()
                    .fill(Color.white)
                    .frame(width: isLarge ? 10 : 8, height: isLarge ? 10 : 8)
            }
            .offset(x: isLarge ? -5 : -4, y: isLarge ? 12 : (isNextLesson ? 10 : 10)) // Кружочки на уровне названий
            
            VStack(alignment: .leading, spacing: isLarge ? 5 : 4) {
                // Название предмета и заголовок на одной линии (заголовок показываем только если showTitle = true)
                HStack(alignment: .center, spacing: 4) {
                    Text(lesson.subject)
                        .font(.system(size: isLarge ? 16 : 14, weight: .semibold))
                                    .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    
                    if showTitle {
                        Spacer(minLength: 4)
                        
                        Text(title)
                            .font(.system(size: isLarge ? 12 : 11))
                            .foregroundColor(.secondary)
                            .fixedSize()
                    }
                }
                .frame(height: isLarge ? 19 : 17)
                
                // Преподаватель
                if !lesson.teacher.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .font(.system(size: isLarge ? 11 : 10))
                            .foregroundColor(.blue)
                        
                        Text(lesson.teacher)
                            .font(.system(size: isLarge ? 12 : 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(height: isLarge ? 16 : 14)
                }
                
                // Время и кабинет с иконками
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: isLarge ? 11 : 10))
                            .foregroundColor(.blue)
                        
                        Text(lesson.time)
                            .font(.system(size: isLarge ? 12 : 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if !lesson.room.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: isLarge ? 11 : 10))
                                .foregroundColor(.blue)
                            
                            Text(lesson.room)
                                .font(.system(size: isLarge ? 12 : 11))
                        .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: isLarge ? 16 : 14)
                
                // Индикатор прогресса (только для текущей пары)
                if let progress = progress {
                    VStack(alignment: .leading, spacing: 2) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Фон прогресс-бара
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(height: 4)
                                
                                // Заполненная часть
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, isLarge ? 10 : 8)
        }
    }
}

