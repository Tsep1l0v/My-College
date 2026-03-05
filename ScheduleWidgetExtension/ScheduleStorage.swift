//
//  ScheduleStorage.swift
//  ScheduleWidgetExtension
//
//  Helper for shared data storage between app and widget
//

import Foundation

/// Структура для хранения расписания с метаданными (как в основном приложении)
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
    
    // Генерируем разные ключи для студента и преподавателя, чтобы не перезаписывать друг друга
    private static func cacheKey(forMode isTeacherMode: Bool, group: String?, teacher: String?) -> String {
        func sanitizeKey(_ key: String) -> String {
            key.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "\\", with: "_")
                .replacingOccurrences(of: ".", with: "_")
        }
        
        if isTeacherMode {
            let teacherKey = teacher.map(sanitizeKey) ?? "none"
            return "savedSchedule_teacher_\(teacherKey)"
        } else {
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
    
    /// Сохранение расписания (поддержка виджета, если нужно что-то сохранять из расширения)
    static func saveSchedule(_ schedule: [DaySchedule], isTeacherMode: Bool? = nil, selectedGroup: String? = nil, selectedTeacher: String? = nil) {
        let mode = isTeacherMode ?? shared.bool(forKey: "isTeacherMode")
        let group = selectedGroup ?? (mode ? nil : shared.string(forKey: "selectedGroupURL"))
        let teacher = selectedTeacher ?? (mode ? shared.string(forKey: "selectedTeacherURL") : nil)
        
        guard let data = try? JSONEncoder().encode(CachedSchedule(schedule: schedule,
                                                                 isTeacherMode: mode,
                                                                 selectedGroup: group,
                                                                 selectedTeacher: teacher,
                                                                 timestamp: Date().timeIntervalSince1970)) else {
            print("❌ Widget: failed to encode schedule")
            return
        }
        
        let key = cacheKey(forMode: mode, group: group, teacher: teacher)
        
        // Сохраняем в App Group
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.set(data, forKey: key)
            sharedDefaults.synchronize()
            print("✅ Widget: saved schedule to App Group \(identifier) key=\(key)")
        }
        // Fallback
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.synchronize()
        
        // Совместимость со старым ключом
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.set(data, forKey: "savedSchedule")
            sharedDefaults.synchronize()
        }
        UserDefaults.standard.set(data, forKey: "savedSchedule")
        UserDefaults.standard.synchronize()
    }
    
    /// Загрузка расписания для виджета с учетом текущего режима и выбора
    static func loadSchedule() -> [DaySchedule]? {
        print("🔍 Widget: Starting to load schedule...")
        
        // Читаем режим и выбор из App Group (если доступен) или стандартного UserDefaults
        var isTeacherMode = false
        var selectedGroup: String? = nil
        var selectedTeacher: String? = nil
        
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.synchronize()
            isTeacherMode = sharedDefaults.bool(forKey: "isTeacherMode")
            selectedGroup = isTeacherMode ? nil : sharedDefaults.string(forKey: "selectedGroupURL")
            selectedTeacher = isTeacherMode ? sharedDefaults.string(forKey: "selectedTeacherURL") : nil
            print("🔍 Widget: Read from App Group - mode: \(isTeacherMode), group: \(selectedGroup ?? "none"), teacher: \(selectedTeacher ?? "none")")
        } else {
            UserDefaults.standard.synchronize()
            isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
            selectedGroup = isTeacherMode ? nil : UserDefaults.standard.string(forKey: "selectedGroupURL")
            selectedTeacher = isTeacherMode ? UserDefaults.standard.string(forKey: "selectedTeacherURL") : nil
            print("🔍 Widget: Read from UserDefaults.standard - mode: \(isTeacherMode), group: \(selectedGroup ?? "none"), teacher: \(selectedTeacher ?? "none")")
        }
        
        let key = cacheKey(forMode: isTeacherMode, group: selectedGroup, teacher: selectedTeacher)
        print("🔍 Widget: Looking for key: \(key)")
        
        var dataSource = "none"
        var scheduleData: Data?
        
        // Сначала пробуем старый ключ "savedSchedule" (для обратной совместимости и простоты)
        if let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            sharedDefaults.synchronize()
            scheduleData = sharedDefaults.data(forKey: "savedSchedule")
            if let d = scheduleData {
                dataSource = "App Group (legacy savedSchedule), \(d.count) bytes"
                print("✅ Widget: Found data in App Group (legacy key)")
            }
        }
        
        if scheduleData == nil {
            UserDefaults.standard.synchronize()
            scheduleData = UserDefaults.standard.data(forKey: "savedSchedule")
            if let d = scheduleData {
                dataSource = "UserDefaults.standard (legacy savedSchedule), \(d.count) bytes"
                print("✅ Widget: Found data in UserDefaults.standard (legacy key)")
            }
        }
        
        // Потом пробуем специфичный ключ в App Group
        if scheduleData == nil {
            if let identifier = appGroupIdentifier,
               let sharedDefaults = UserDefaults(suiteName: identifier) {
                sharedDefaults.synchronize()
                scheduleData = sharedDefaults.data(forKey: key)
                if let d = scheduleData {
                    dataSource = "App Group (\(key)), \(d.count) bytes"
                    print("✅ Widget: Found data in App Group (specific key)")
                }
            }
        }
        
        // Fallback к стандартному UserDefaults
        if scheduleData == nil {
            UserDefaults.standard.synchronize()
            scheduleData = UserDefaults.standard.data(forKey: key)
            if let d = scheduleData {
                dataSource = "UserDefaults.standard (\(key)), \(d.count) bytes"
                print("✅ Widget: Found data in UserDefaults.standard (specific key)")
            }
        }
        
        guard let data = scheduleData else {
            print("❌ Widget: No cached schedule found. Tried keys: 'savedSchedule', '\(key)'")
            return nil
        }
        
        print("🔍 Widget: Decoding cached data from \(dataSource)")
        
        // Пробуем декодировать с метаданными
        if let cached = try? JSONDecoder().decode(CachedSchedule.self, from: data) {
            // Если загрузили из специфичного ключа - проверяем соответствие
            // Если загрузили из старого ключа "savedSchedule" - показываем без проверки (для обратной совместимости)
            let isLegacyKey = dataSource.contains("legacy savedSchedule")
            
            if !isLegacyKey {
                // Для нового формата проверяем соответствие режима/выбора
                // Но если не совпадает - все равно показываем (виджет должен быть гибким)
                if cached.isTeacherMode != isTeacherMode {
                    print("⚠️ Widget: mode mismatch in cache (cached \(cached.isTeacherMode), current \(isTeacherMode)), but showing anyway")
                } else if isTeacherMode {
                    if cached.selectedTeacher != selectedTeacher {
                        print("⚠️ Widget: teacher mismatch in cache (cached \(cached.selectedTeacher ?? "none"), current \(selectedTeacher ?? "none")), but showing anyway")
                    }
                } else {
                    if cached.selectedGroup != selectedGroup {
                        print("⚠️ Widget: group mismatch in cache (cached \(cached.selectedGroup ?? "none"), current \(selectedGroup ?? "none")), but showing anyway")
                    }
                }
            } else {
                // Для старого ключа просто предупреждаем, но показываем расписание
                print("⚠️ Widget: Using legacy cache key, showing schedule without strict validation")
            }
            
            print("✅ Widget: Loaded cached schedule (\(cached.schedule.count) days) from \(dataSource)")
            return cached.schedule
        }
        
        // Фоллбек: старый формат без метаданных
        if let schedule = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            print("⚠️ Widget: Loaded schedule in old format from \(dataSource)")
            return schedule
        }
        
        print("❌ Widget: Failed to decode cached data")
        return nil
    }
}

