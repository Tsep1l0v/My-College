//
//  GroupParser.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import Foundation

// MARK: - Новый API для групп через REST (вместо HTML парсинга)

struct APIGroup: Codable {
    let id: Int
    let name: String
    let course: Int
    let level: String
}

struct APIGroupSearchResponse: Codable {
    let groups: [APIGroup]
}

struct APILevelsResponse: Codable {
    let levels: [String]
}

struct APICoursesResponse: Codable {
    let courses: [Int]
}

struct APIScheduleTeacher: Codable {
    let id: Int
    let label: String
    let department: String?
}

struct APIScheduleGroup: Codable {
    let id: Int
    let name: String
    let course: Int
    let level: String
    /// Например «Заочная» — приходит в ответе расписания с `date=full`.
    let studyForm: String?

    var isCorrespondenceStudyForm: Bool {
        (studyForm ?? "").lowercased().contains("заоч")
    }
}

struct APIScheduleItem: Codable {
    let id: Int
    let dayWeek: String
    let timePeriod: String
    let weekCount: Int
    let group: APIScheduleGroup
    /// API может отдавать null для занятий без номера пары
    let lessonCount: Int?
    let lessonType: String
    let lessonName: String
    let teacher: APIScheduleTeacher?
    let auditory: String?
    let eiosLink: String?
    /// Календарная дата занятия (например заочное обучение, сессия). Формат yyyy-MM-dd или ISO-8601 с датой.
    let lessonDate: String?

    enum CodingKeys: String, CodingKey {
        case id, dayWeek, timePeriod, weekCount, group, lessonCount, lessonType, lessonName, teacher, auditory, eiosLink
        case lessonDate
        case lesson_date
        case pinnedDate
        case pinned_date
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        dayWeek = try c.decode(String.self, forKey: .dayWeek)
        timePeriod = try c.decode(String.self, forKey: .timePeriod)
        weekCount = try c.decode(Int.self, forKey: .weekCount)
        group = try c.decode(APIScheduleGroup.self, forKey: .group)
        lessonCount = try c.decodeIfPresent(Int.self, forKey: .lessonCount)
        lessonType = try c.decode(String.self, forKey: .lessonType)
        lessonName = try c.decode(String.self, forKey: .lessonName)
        teacher = try c.decodeIfPresent(APIScheduleTeacher.self, forKey: .teacher)
        auditory = try c.decodeIfPresent(String.self, forKey: .auditory)
        eiosLink = try c.decodeIfPresent(String.self, forKey: .eiosLink)
        var resolvedDate: String?
        if let ld = try c.decodeIfPresent(String.self, forKey: .lessonDate) {
            resolvedDate = Self.normalizeLessonDateString(ld)
        } else if let ld = try c.decodeIfPresent(String.self, forKey: .lesson_date) {
            resolvedDate = Self.normalizeLessonDateString(ld)
        }
        if resolvedDate == nil {
            if let p = try c.decodeIfPresent(String.self, forKey: .pinnedDate) {
                resolvedDate = Self.lessonDateFromPinnedDayMonth(p)
            } else if let p = try c.decodeIfPresent(String.self, forKey: .pinned_date) {
                resolvedDate = Self.lessonDateFromPinnedDayMonth(p)
            }
        }
        lessonDate = resolvedDate
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(dayWeek, forKey: .dayWeek)
        try c.encode(timePeriod, forKey: .timePeriod)
        try c.encode(weekCount, forKey: .weekCount)
        try c.encode(group, forKey: .group)
        try c.encodeIfPresent(lessonCount, forKey: .lessonCount)
        try c.encode(lessonType, forKey: .lessonType)
        try c.encode(lessonName, forKey: .lessonName)
        try c.encodeIfPresent(teacher, forKey: .teacher)
        try c.encodeIfPresent(auditory, forKey: .auditory)
        try c.encodeIfPresent(eiosLink, forKey: .eiosLink)
        try c.encodeIfPresent(lessonDate, forKey: .lessonDate)
    }

    /// Обрезка до yyyy-MM-dd из ISO-строки.
    private static func normalizeLessonDateString(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count >= 10 {
            let idx = t.index(t.startIndex, offsetBy: 10)
            return String(t[..<idx])
        }
        return t
    }

    /// API отдаёт интервал как «13.10-14.40»; в UI и парсерах нужны двоеточия.
    static func normalizeDottedTimePeriod(_ period: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "(\\d{1,2})\\.(\\d{2})", options: []) else { return period }
        let range = NSRange(location: 0, length: (period as NSString).length)
        return regex.stringByReplacingMatches(in: period, options: [], range: range, withTemplate: "$1:$2")
    }

    var timePeriodNormalized: String {
        Self.normalizeDottedTimePeriod(timePeriod)
    }

    /// pinnedDate с API: «дд.ММ» → yyyy-MM-dd (год подбирается ближе всего к текущей дате).
    private static func lessonDateFromPinnedDayMonth(_ pinned: String) -> String? {
        let t = pinned.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = t.split(separator: ".").map { String($0) }
        guard parts.count == 2,
              let d = Int(parts[0]), let m = Int(parts[1]),
              (1...31).contains(d), (1...12).contains(m) else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let now = Date()
        let refY = cal.component(.year, from: now)

        func anchorDate(year: Int) -> Date? {
            var dc = DateComponents()
            dc.year = year
            dc.month = m
            dc.day = d
            dc.hour = 12
            guard let dt = cal.date(from: dc),
                  cal.component(.month, from: dt) == m,
                  cal.component(.day, from: dt) == d else { return nil }
            return dt
        }

        let pairs: [(Int, Date)] = [refY - 1, refY, refY + 1].compactMap { y in
            guard let dt = anchorDate(year: y) else { return nil }
            return (y, dt)
        }
        guard let best = pairs.min(by: { abs($0.1.timeIntervalSince(now)) < abs($1.1.timeIntervalSince(now)) }) else { return nil }
        return String(format: "%04d-%02d-%02d", best.0, m, d)
    }
}

struct APIScheduleResponse: Codable {
    let schedule: [APIScheduleItem]
}

final class ScheduleAPIClient {
    static let shared = ScheduleAPIClient()
    private init() {}
    
    private var baseURL: URL {
        if let urlString = UserDefaults.standard.string(forKey: "schedule_server_url"), let url = URL(string: urlString), !urlString.isEmpty {
            print("[RC] Используем baseURL из Remote Config: \(urlString)")
            return url
        } else {
            print("[RC] Используем стандартный baseURL: https://api.myimsit.ru/schedule")
            return URL(string: "https://api.myimsit.ru/schedule")!
        }
    }
    
    private func authToken() -> String? {
        UserDefaults.standard.string(forKey: "schedule_api_token")
    }
    
    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(url: baseURL.appendingPathComponent(cleanPath), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw NSError(domain: "ScheduleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"]) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = authToken() { request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    func getWeekCount(completion: @escaping (Result<Int, Error>) -> Void) {
        guard authToken() != nil else {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        do {
            let request = try makeRequest(path: "/api/v1/configuration/week")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let obj = try self.decoder.decode([String:Int].self, from: data)
                    completion(.success(obj["weekCount"] ?? 1))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }
    
    func searchGroups(course: Int, level: String?, completion: @escaping (Result<[APIGroup], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        var items = [URLQueryItem(name: "course", value: String(course))]
        if let level = level { items.append(URLQueryItem(name: "level", value: level)) }
        do {
            let request = try makeRequest(path: "/api/v1/groups/search", queryItems: items)
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let resp = try self.decoder.decode(APIGroupSearchResponse.self, from: data)
                    completion(.success(resp.groups))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }
    
    func levels(completion: @escaping (Result<[String], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        do {
            let request = try makeRequest(path: "/api/v1/groups/levels")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let resp = try self.decoder.decode(APILevelsResponse.self, from: data)
                    completion(.success(resp.levels))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }

    func courses(completion: @escaping (Result<[Int], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        do {
            let request = try makeRequest(path: "/api/v1/groups/courses")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let resp = try self.decoder.decode(APICoursesResponse.self, from: data)
                    completion(.success(resp.courses))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }

    func getGroupByName(_ groupName: String, completion: @escaping (Result<APIGroup, Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        do {
            let encoded = groupName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? groupName
            let request = try makeRequest(path: "/api/v1/groups/\(encoded)")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let group = try self.decoder.decode(APIGroup.self, from: data)
                    completion(.success(group))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }
    
    func groupSchedule(groupName: String, dayWeek: String?, weekCount: Int, date: String = "full", completion: @escaping (Result<[APIScheduleItem], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        var items = [
            URLQueryItem(name: "group", value: groupName),
            URLQueryItem(name: "weekCount", value: String(weekCount)),
            URLQueryItem(name: "date", value: date)
        ]
        if let dayWeek = dayWeek { items.append(URLQueryItem(name: "dayWeek", value: dayWeek)) }
        do {
            let request = try makeRequest(path: "/api/v1/groups/schedule", queryItems: items)
            print("➡️ GET \(request.url?.absoluteString ?? "")")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                if let body = String(data: data, encoding: .utf8) { print("⬅️ Body: \(body.prefix(512))...") }
                do {
                    let resp = try self.decoder.decode(APIScheduleResponse.self, from: data)
                    completion(.success(resp.schedule))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }

    // MARK: - Преподаватели

    func searchTeachers(department: String?, completion: @escaping (Result<[APITeacher], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        var items: [URLQueryItem] = []
        if let department = department { 
            let encodedDepartment = department.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? department
            items.append(URLQueryItem(name: "department", value: encodedDepartment))
            print("🔤 Кодируем кафедру: '\(department)' -> '\(encodedDepartment)'")
        }
        do {
            let request = try makeRequest(path: "/api/v1/teachers/search", queryItems: items)
            print("🔍 Teacher search API request: \(request.url?.absoluteString ?? "N/A")")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                
                // Логируем сырой ответ для отладки
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Сырой ответ API преподавателей: \(responseString.prefix(500))...")
                }
                
                do {
                    let resp = try self.decoder.decode(APITeacherSearchResponse.self, from: data)
                    print("✅ Teacher search API response: \(resp.teachers.count) teachers")
                    completion(.success(resp.teachers))
                } catch { 
                    print("❌ Ошибка декодирования: \(error)")
                completion(.failure(error))
            }
            }.resume()
        } catch { completion(.failure(error)) }
    }

    func getTeacherByName(_ name: String, completion: @escaping (Result<APITeacher, Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        do {
            let request = try makeRequest(path: "/api/v1/teachers/\(name)")
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }
                do {
                    let teacher = try self.decoder.decode(APITeacher.self, from: data)
                    completion(.success(teacher))
                } catch { completion(.failure(error)) }
            }.resume()
        } catch { completion(.failure(error)) }
    }
    
    func teacherSchedule(teacher: String, dayWeek: String?, weekCount: Int, completion: @escaping (Result<[APIScheduleItem], Error>) -> Void) {
        if authToken() == nil {
            completion(.failure(NSError(domain: "ScheduleAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Отсутствует токен API"]))); return
        }
        var items = [URLQueryItem(name: "teacher", value: teacher), URLQueryItem(name: "weekCount", value: String(weekCount))]
        if let dayWeek = dayWeek { items.append(URLQueryItem(name: "dayWeek", value: dayWeek)) }
        do {
            let request = try makeRequest(path: "/api/v1/teachers/schedule", queryItems: items)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.failure(NSError(domain: "ScheduleAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"]))); return }

                // Log the URL and response body for debugging
                if let httpResponse = response as? HTTPURLResponse {
                    print("API Request URL: \(request.url?.absoluteString ?? "N/A")")
                    print("API Response Status Code: \(httpResponse.statusCode)")
                }
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("API Response Body (first 512 chars): \(responseBody.prefix(512))")
                }

                do {
                    let resp = try self.decoder.decode(APIScheduleResponse.self, from: data)
                    completion(.success(resp.schedule))
                } catch {
                    print("Decoding error for teacher schedule: \(error)")
                completion(.failure(error))
            }
            }.resume()
        } catch { completion(.failure(error)) }
    }
}

// MARK: - Teacher DTO Models
struct APITeacher: Codable {
    let id: Int
    let label: String
    let department: String?
    var name: String { label } // For backward compatibility
    var url: String { label }  // For backward compatibility, now stores name
}

struct APITeacherSearchResponse: Codable { 
    let teachers: [APITeacher] 
}

