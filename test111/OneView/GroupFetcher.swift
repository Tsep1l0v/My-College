//
//  GroupFetcher.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import Foundation
import MyTrackerSDK

// MARK: - Фасад для работы с группами через REST

func fetchGroups(forCourse course: Int, level: String?, completion: @escaping (Result<[APIGroup], Error>) -> Void) {
    ScheduleAPIClient.shared.searchGroups(course: course, level: level, completion: completion)
}

// Репозиторий расписания с простым кэшем в памяти
final class ScheduleRepository {
    static let shared = ScheduleRepository()
    private init() {}

    private var memoryCache: [String: Data] = [:]
    private let cacheTTL: TimeInterval = 60 * 10
    private var cacheDates: [String: Date] = [:]
    private let disk = UserDefaults.standard

    private func cacheKey(_ path: String, _ params: [String: String]) -> String {
        let sorted = params.sorted { $0.key < $1.key }
        let q = sorted.map { "\($0)=\($1)" }.joined(separator: "&")
        return path + "?" + q
    }

    private func isValid(key: String) -> Bool {
        guard let date = cacheDates[key] else { return false }
        return Date().timeIntervalSince(date) < cacheTTL
    }

    private func loadFromDisk(key: String) -> Data? {
        guard let entry = disk.object(forKey: "cache_\(key)") as? [String: Any],
              let ts = entry["ts"] as? TimeInterval,
              let data = entry["data"] as? Data else { return nil }
        if Date().timeIntervalSince(Date(timeIntervalSince1970: ts)) < cacheTTL {
            return data
        }
        return nil
    }

    private func saveToDisk(key: String, data: Data) {
        let entry: [String: Any] = ["ts": Date().timeIntervalSince1970, "data": data]
        disk.set(entry, forKey: "cache_\(key)")
    }

    func getWeekCount(completion: @escaping (Result<Int, Error>) -> Void) {
        // Мемоизация за сессию + кэш на диск
        let key = "weekCount"
        if let cached = memoryCache[key],
           let val = try? JSONDecoder().decode([String:Int].self, from: cached)["weekCount"],
           let ts = cacheDates[key], Date().timeIntervalSince(ts) < cacheTTL {
            MRMyTracker.trackEvent(name: "Фоновый процесс синхронизации четности недели из сервера")
            completion(.success(val))
            return
        }
        if let diskData = loadFromDisk(key: key), let val = try? JSONDecoder().decode([String:Int].self, from: diskData)["weekCount"] {
            MRMyTracker.trackEvent(name: "Фоновый процесс синхронизации четности недели из сервера")
            completion(.success(val))
            return
        }
        ScheduleAPIClient.shared.getWeekCount { result in
        switch result {
            case .success(let week):
                let data = try? JSONEncoder().encode(["weekCount": week])
                if let data = data {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(week))
        case .failure(let error):
            completion(.failure(error))
        }
        }
    }

    func getGroupSchedule(groupName: String, weekCount: Int, completion: @escaping (Result<[APIScheduleItem], Error>) -> Void) {
        let key = cacheKey("groups/schedule", ["group": groupName, "weekCount": String(weekCount)])
        if isValid(key: key), let data = memoryCache[key], let items = try? JSONDecoder().decode(APIScheduleResponse.self, from: data) {
            MRMyTracker.trackEvent(name: "Фоновый процесс загрузки расписания группы из сервера")
            completion(.success(items.schedule))
            return
        }
        if let diskData = loadFromDisk(key: key), let items = try? JSONDecoder().decode(APIScheduleResponse.self, from: diskData) {
            MRMyTracker.trackEvent(name: "Фоновый процесс загрузки расписания группы из сервера")
            completion(.success(items.schedule))
            return
        }
        MRMyTracker.trackEvent(name: "Получить расписание группы из сервера")
        ScheduleAPIClient.shared.groupSchedule(groupName: groupName, dayWeek: nil, weekCount: weekCount) { result in
            switch result {
            case .success(let schedule):
                if let data = try? JSONEncoder().encode(APIScheduleResponse(schedule: schedule)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(schedule))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getTeacherSchedule(teacher: String, weekCount: Int, completion: @escaping (Result<[APIScheduleItem], Error>) -> Void) {
        let key = cacheKey("teachers/schedule", ["teacher": teacher, "weekCount": String(weekCount)])
        if isValid(key: key), let data = memoryCache[key], let items = try? JSONDecoder().decode(APIScheduleResponse.self, from: data) {
            MRMyTracker.trackEvent(name: "Фоновый процесс загрузки расписания преподавателя из сервера")
            completion(.success(items.schedule))
            return
        }
        if let diskData = loadFromDisk(key: key), let items = try? JSONDecoder().decode(APIScheduleResponse.self, from: diskData) {
            MRMyTracker.trackEvent(name: "Фоновый процесс загрузки расписания преподавателя из сервера")
            completion(.success(items.schedule))
            return
        }
        MRMyTracker.trackEvent(name: "Получить расписание преподавателя из сервера")
        ScheduleAPIClient.shared.teacherSchedule(teacher: teacher, dayWeek: nil, weekCount: weekCount) { result in
            switch result {
            case .success(let schedule):
                if let data = try? JSONEncoder().encode(APIScheduleResponse(schedule: schedule)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(schedule))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Teacher Methods
    func searchTeachers(department: String?, completion: @escaping (Result<[APITeacher], Error>) -> Void) {
        let params = ["department": department ?? ""].filter { !$0.value.isEmpty }
        let key = cacheKey("teachers/search", params)
        
        print("🔍 ScheduleRepository.searchTeachers - department: '\(department ?? "nil")', key: '\(key)'")
        
        if isValid(key: key), let data = memoryCache[key], let teachers = try? JSONDecoder().decode(APITeacherSearchResponse.self, from: data) {
            print("📦 Найдено в кэше: \(teachers.teachers.count) преподавателей")
            MRMyTracker.trackEvent(name: "Получить кешированный список преподавателей")
            completion(.success(teachers.teachers))
            return
        }
        if let diskData = loadFromDisk(key: key), let teachers = try? JSONDecoder().decode(APITeacherSearchResponse.self, from: diskData) {
            print("💾 Найдено на диске: \(teachers.teachers.count) преподавателей")
            MRMyTracker.trackEvent(name: "Получить кешированный список преподавателей")
            completion(.success(teachers.teachers))
            return
        }
        print("🌐 Запрашиваем с API...")
        MRMyTracker.trackEvent(name: "Получить список преподавателей из сервера")
        ScheduleAPIClient.shared.searchTeachers(department: department) { result in
            switch result {
            case .success(let teachers):
                print("✅ API вернул: \(teachers.count) преподавателей")
                if let data = try? JSONEncoder().encode(APITeacherSearchResponse(teachers: teachers)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(teachers))
            case .failure(let error):
                print("❌ API ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func getTeacherByName(_ name: String, completion: @escaping (Result<APITeacher, Error>) -> Void) {
        let key = "teacher/\(name)"
        if isValid(key: key), let data = memoryCache[key], let teacher = try? JSONDecoder().decode(APITeacher.self, from: data) {
            completion(.success(teacher))
            return
        }
        if let diskData = loadFromDisk(key: key), let teacher = try? JSONDecoder().decode(APITeacher.self, from: diskData) {
            completion(.success(teacher))
            return
        }
        ScheduleAPIClient.shared.getTeacherByName(name) { result in
            switch result {
            case .success(let teacher):
                if let data = try? JSONEncoder().encode(teacher) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(teacher))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Group Methods
    func courses(completion: @escaping (Result<[Int], Error>) -> Void) {
        let key = "courses"
        if isValid(key: key), let data = memoryCache[key], let courses = try? JSONDecoder().decode(APICoursesResponse.self, from: data) {
            MRMyTracker.trackEvent(name: "Получить кешированный список курсов")
            completion(.success(courses.courses))
            return
        }
        if let diskData = loadFromDisk(key: key), let courses = try? JSONDecoder().decode(APICoursesResponse.self, from: diskData) {
            MRMyTracker.trackEvent(name: "Получить кешированный список курсов")
            completion(.success(courses.courses))
            return
        }
        MRMyTracker.trackEvent(name: "Получить список курсов из сервера")
        ScheduleAPIClient.shared.courses { result in
            switch result {
            case .success(let courses):
                if let data = try? JSONEncoder().encode(APICoursesResponse(courses: courses)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(courses))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func levels(completion: @escaping (Result<[String], Error>) -> Void) {
        let key = "levels"
        if isValid(key: key), let data = memoryCache[key], let levels = try? JSONDecoder().decode(APILevelsResponse.self, from: data) {
            MRMyTracker.trackEvent(name: "Получить кешированный список уровней")
            completion(.success(levels.levels))
            return
        }
        if let diskData = loadFromDisk(key: key), let levels = try? JSONDecoder().decode(APILevelsResponse.self, from: diskData) {
            MRMyTracker.trackEvent(name: "Получить кешированный список уровней")
            completion(.success(levels.levels))
            return
        }
        MRMyTracker.trackEvent(name: "Получить список уровней из сервера")
        ScheduleAPIClient.shared.levels { result in
            switch result {
            case .success(let levels):
                if let data = try? JSONEncoder().encode(APILevelsResponse(levels: levels)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(levels))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func searchGroups(course: Int, level: String?, completion: @escaping (Result<[APIGroup], Error>) -> Void) {
        let params = [
            "course": String(course),
            "level": level ?? ""
        ].filter { !$0.value.isEmpty }
        let key = cacheKey("groups/search", params)
        
        if isValid(key: key), let data = memoryCache[key], let groups = try? JSONDecoder().decode(APIGroupSearchResponse.self, from: data) {
            MRMyTracker.trackEvent(name: "Получить кешированный список групп")
            completion(.success(groups.groups))
            return
        }
        if let diskData = loadFromDisk(key: key), let groups = try? JSONDecoder().decode(APIGroupSearchResponse.self, from: diskData) {
            MRMyTracker.trackEvent(name: "Получить кешированный список групп")
            completion(.success(groups.groups))
            return
        }
        MRMyTracker.trackEvent(name: "Получить список групп из сервера")
        ScheduleAPIClient.shared.searchGroups(course: course, level: level) { result in
            switch result {
            case .success(let groups):
                if let data = try? JSONEncoder().encode(APIGroupSearchResponse(groups: groups)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(groups))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func groupSchedule(groupName: String, dayWeek: String?, weekCount: Int, completion: @escaping (Result<[APIScheduleItem], Error>) -> Void) {
        let params = [
            "group": groupName,
            "dayWeek": dayWeek ?? "",
            "weekCount": String(weekCount)
        ].filter { !$0.value.isEmpty }
        let key = cacheKey("groups/schedule", params)
        
        if isValid(key: key), let data = memoryCache[key], let schedule = try? JSONDecoder().decode(APIScheduleResponse.self, from: data) {
            completion(.success(schedule.schedule))
            return
        }
        if let diskData = loadFromDisk(key: key), let schedule = try? JSONDecoder().decode(APIScheduleResponse.self, from: diskData) {
            completion(.success(schedule.schedule))
            return
        }
        ScheduleAPIClient.shared.groupSchedule(groupName: groupName, dayWeek: dayWeek, weekCount: weekCount) { result in
            switch result {
            case .success(let schedule):
                if let data = try? JSONEncoder().encode(APIScheduleResponse(schedule: schedule)) {
                    self.memoryCache[key] = data
                    self.cacheDates[key] = Date()
                    self.saveToDisk(key: key, data: data)
                }
                completion(.success(schedule))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

func fetchAvailableCourses(completion: @escaping (Result<[Int], Error>) -> Void) {
    ScheduleAPIClient.shared.courses(completion: completion)
}

func fetchLevels(completion: @escaping (Result<[String], Error>) -> Void) {
    ScheduleAPIClient.shared.levels(completion: completion)
}

func fetchGroupByName(_ name: String, completion: @escaping (Result<APIGroup, Error>) -> Void) {
    ScheduleAPIClient.shared.getGroupByName(name, completion: completion)
}
