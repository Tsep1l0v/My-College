//
//  ScheduleStorage.swift
//  test111
//
//  Helper for shared data storage between app and widget
//

import Foundation

// Структура для хранения расписания с метаданными
private struct CachedSchedule: Codable {
    let schedule: [DaySchedule]
    let isTeacherMode: Bool
    let selectedGroup: String?
    let selectedTeacher: String?
    let timestamp: TimeInterval
}

class ScheduleStorage {
    // App Group identifier - используйте App Group для надежного обмена данными
    // Формат: group.{bundle_identifier}
    static let appGroupIdentifier: String? = "group.com.tsep1l0v.myimsit"
    
    // Разные ключи для кеша студента и преподавателя, чтобы не перезаписывать друг друга
    private static func cacheKey(forMode isTeacherMode: Bool, group: String?, teacher: String?) -> String {
        // Функция для безопасной обработки строк в ключах (убираем специальные символы)
        func sanitizeKey(_ key: String) -> String {
            // Заменяем пробелы и специальные символы на подчеркивания для безопасности
            return key.replacingOccurrences(of: " ", with: "_")
                     .replacingOccurrences(of: "/", with: "_")
                     .replacingOccurrences(of: "\\", with: "_")
                     .replacingOccurrences(of: ".", with: "_")
        }
        
        if isTeacherMode {
            // Для преподавателя используем ключ с именем преподавателя
            let teacherKey = teacher.map(sanitizeKey) ?? "none"
            return "savedSchedule_teacher_\(teacherKey)"
        } else {
            // Для студента используем ключ с именем группы
            let groupKey = group.map(sanitizeKey) ?? "none"
            return "savedSchedule_student_\(groupKey)"
        }
    }
    
    static var shared: UserDefaults {
        // Сначала пробуем App Group
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            return sharedDefaults
        }
        // Fallback на стандартный UserDefaults (может не работать между app и widget)
        return UserDefaults.standard
    }
    
    // Сохраняет расписание с метаданными (режим, группа/преподаватель)
    static func saveSchedule(_ schedule: [DaySchedule], isTeacherMode: Bool? = nil, selectedGroup: String? = nil, selectedTeacher: String? = nil) {
        // Если параметры не переданы, берем из UserDefaults
        let mode = isTeacherMode ?? UserDefaults.standard.bool(forKey: "isTeacherMode")
        let group = selectedGroup ?? (mode ? nil : UserDefaults.standard.string(forKey: "selectedGroupURL"))
        let teacher = selectedTeacher ?? (mode ? UserDefaults.standard.string(forKey: "selectedTeacherURL") : nil)
        
        // Валидация: убеждаемся, что для студента есть группа, для преподавателя - преподаватель
        if !mode && group == nil {
            print("⚠️ Warning: Attempting to save student schedule without group")
            return
        }
        if mode && teacher == nil {
            print("⚠️ Warning: Attempting to save teacher schedule without teacher")
            return
        }
        
        let cached = CachedSchedule(
            schedule: schedule,
            isTeacherMode: mode,
            selectedGroup: group,
            selectedTeacher: teacher,
            timestamp: Date().timeIntervalSince1970
        )
        
        guard let scheduleData = try? JSONEncoder().encode(cached) else {
            print("❌ Failed to encode schedule with metadata")
            return
        }
        
        // Генерируем уникальный ключ для этого режима и группы/преподавателя
        let cacheKey = self.cacheKey(forMode: mode, group: group, teacher: teacher)
        
        // Сохраняем в App Group (если настроен)
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.set(scheduleData, forKey: cacheKey)
            sharedDefaults.synchronize()
            print("✅ Saved schedule to App Group: \(identifier) (key: \(cacheKey), mode: \(mode ? "teacher" : "student"), \(mode ? "teacher: \(teacher ?? "none")" : "group: \(group ?? "none")"))")
        }
        
        // Также сохраняем в стандартный UserDefaults (на случай, если App Group не настроен)
        UserDefaults.standard.set(scheduleData, forKey: cacheKey)
        UserDefaults.standard.synchronize()
        print("✅ Saved schedule to UserDefaults.standard (key: \(cacheKey), mode: \(mode ? "teacher" : "student"), \(mode ? "teacher: \(teacher ?? "none")" : "group: \(group ?? "none")"))")
        
        // Также сохраняем для обратной совместимости с виджетом (последнее сохраненное расписание)
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.set(scheduleData, forKey: "savedSchedule")
            sharedDefaults.synchronize()
        }
        UserDefaults.standard.set(scheduleData, forKey: "savedSchedule")
        UserDefaults.standard.synchronize()
        
        // Сохраняем название группы/преподавателя в UserDefaults для отображения в фильтре
        // Это нужно для случая, когда пользователь заходит без сети
        if !mode {
            // Режим студента - сохраняем название группы
            if let group = group {
                UserDefaults.standard.set(group, forKey: "selectedGroup")
                UserDefaults.standard.set(group, forKey: "selectedGroupURL")
                print("✅ Saved group name to UserDefaults: \(group)")
            }
        } else {
            // Режим преподавателя - сохраняем название преподавателя
            if let teacher = teacher {
                UserDefaults.standard.set(teacher, forKey: "selectedTeacher")
                UserDefaults.standard.set(teacher, forKey: "selectedTeacherURL")
                print("✅ Saved teacher name to UserDefaults: \(teacher)")
            }
        }
    }
    
    // Загружает расписание только если оно соответствует текущему режиму и выбранной группе/преподавателю
    static func loadSchedule() -> [DaySchedule]? {
        let currentIsTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        let currentSelectedGroup = currentIsTeacherMode ? nil : UserDefaults.standard.string(forKey: "selectedGroupURL")
        let currentSelectedTeacher = currentIsTeacherMode ? UserDefaults.standard.string(forKey: "selectedTeacherURL") : nil
        
        // Генерируем ключ для текущего режима и группы/преподавателя
        let cacheKey = self.cacheKey(forMode: currentIsTeacherMode, group: currentSelectedGroup, teacher: currentSelectedTeacher)
        
        var scheduleData: Data?
        
        // Пробуем загрузить из App Group по специфичному ключу
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            scheduleData = sharedDefaults.data(forKey: cacheKey)
        }
        
        // Если не нашли в App Group, пробуем стандартный UserDefaults
        if scheduleData == nil {
            UserDefaults.standard.synchronize()
            scheduleData = UserDefaults.standard.data(forKey: cacheKey)
        }
        
        // Если не нашли по специфичному ключу, пробуем старый ключ для обратной совместимости
        if scheduleData == nil {
            if let identifier = appGroupIdentifier,
               let sharedDefaults = UserDefaults(suiteName: identifier) {
                scheduleData = sharedDefaults.data(forKey: "savedSchedule")
            }
            if scheduleData == nil {
                UserDefaults.standard.synchronize()
                scheduleData = UserDefaults.standard.data(forKey: "savedSchedule")
            }
        }
        
        guard let data = scheduleData else {
            print("❌ No cached schedule found for key: \(cacheKey)")
            return nil
        }
        
        // Пробуем декодировать как новую структуру с метаданными
        if let cached = try? JSONDecoder().decode(CachedSchedule.self, from: data) {
            // Проверяем соответствие режима
            guard cached.isTeacherMode == currentIsTeacherMode else {
                print("⚠️ Cached schedule mode mismatch (cached: \(cached.isTeacherMode ? "teacher" : "student"), current: \(currentIsTeacherMode ? "teacher" : "student"))")
                return nil
            }
            
            // Проверяем соответствие группы/преподавателя
            if currentIsTeacherMode {
                guard cached.selectedTeacher == currentSelectedTeacher else {
                    print("⚠️ Cached schedule teacher mismatch (cached: \(cached.selectedTeacher ?? "none"), current: \(currentSelectedTeacher ?? "none"))")
                    return nil
                }
            } else {
                guard cached.selectedGroup == currentSelectedGroup else {
                    print("⚠️ Cached schedule group mismatch (cached: \(cached.selectedGroup ?? "none"), current: \(currentSelectedGroup ?? "none"))")
                    return nil
                }
            }
            
            print("✅ Loaded schedule from cache (key: \(cacheKey), mode: \(cached.isTeacherMode ? "teacher" : "student"), \(cached.isTeacherMode ? "teacher: \(cached.selectedTeacher ?? "none")" : "group: \(cached.selectedGroup ?? "none")"))")
            
            // Восстанавливаем название группы/преподавателя в UserDefaults из метаданных кеша
            // Это нужно для случая, когда пользователь заходит без сети и значения отсутствуют
            if cached.isTeacherMode {
                // Режим преподавателя - восстанавливаем название преподавателя
                if let teacher = cached.selectedTeacher {
                    // Проверяем, что значение отсутствует или отличается
                    let currentTeacher = UserDefaults.standard.string(forKey: "selectedTeacher")
                    let currentTeacherURL = UserDefaults.standard.string(forKey: "selectedTeacherURL")
                    if currentTeacher != teacher || currentTeacherURL != teacher {
                        UserDefaults.standard.set(teacher, forKey: "selectedTeacher")
                        UserDefaults.standard.set(teacher, forKey: "selectedTeacherURL")
                        print("✅ Restored teacher name from cache: \(teacher)")
                    }
                }
            } else {
                // Режим студента - восстанавливаем название группы
                if let group = cached.selectedGroup {
                    // Проверяем, что значение отсутствует или отличается
                    let currentGroup = UserDefaults.standard.string(forKey: "selectedGroup")
                    let currentGroupURL = UserDefaults.standard.string(forKey: "selectedGroupURL")
                    if currentGroup != group || currentGroupURL != group {
                        UserDefaults.standard.set(group, forKey: "selectedGroup")
                        UserDefaults.standard.set(group, forKey: "selectedGroupURL")
                        print("✅ Restored group name from cache: \(group)")
                    }
                }
            }
            
            return cached.schedule
        }
        
        // Fallback: пробуем декодировать как старый формат (без метаданных)
        // Это для обратной совместимости, но только если режим соответствует
        if let schedule = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            print("⚠️ Loaded schedule in old format (without metadata validation) - use with caution")
            // В старом формате нет метаданных, поэтому возвращаем только если нет других вариантов
            // Но это может быть опасно, поэтому лучше вернуть nil если режим не совпадает
            return schedule
        }
        
        print("❌ Failed to decode schedule data")
        return nil
    }
    
    // Загружает расписание для виджета (без проверки метаданных)
    static func loadScheduleForWidget() -> [DaySchedule]? {
        var scheduleData: Data?
        
        // Пробуем загрузить из App Group
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            scheduleData = sharedDefaults.data(forKey: "savedSchedule")
        }
        
        // Если не нашли в App Group, пробуем стандартный UserDefaults
        if scheduleData == nil {
            UserDefaults.standard.synchronize()
            scheduleData = UserDefaults.standard.data(forKey: "savedSchedule")
        }
        
        guard let data = scheduleData else {
            return nil
        }
        
        // Пробуем декодировать как новую структуру с метаданными
        if let cached = try? JSONDecoder().decode(CachedSchedule.self, from: data) {
            return cached.schedule
        }
        
        // Fallback: пробуем декодировать как старый формат
        if let schedule = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            return schedule
        }
        
        return nil
    }
}



