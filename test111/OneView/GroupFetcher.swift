//
//  GroupFetcher.swift
//  schedule
//
//  Created by Дмитрий Цепилов on 30.11.2024.
//

import Foundation
import SwiftSoup

func fetchGroups(forCourse course: String, specialty: String, completion: @escaping (Result<[(name: String, url: String)], Error>) -> Void) {
    let url = URL(string: "https://imsit.ru/timetable/stud/raspisan.html")!

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет данных"])))
            return
        }

        // Используем кодировку UTF-8
        guard let html = String(data: data, encoding: .windowsCP1251) else {
            completion(.failure(NSError(domain: "ParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось преобразовать данные в строку"])))
            return
        }


        do {
            let document = try SwiftSoup.parse(html)
            let elements = try document.select("a[href$='.html']")
            let allGroups = try elements.map { element -> (name: String, url: String) in
                let name = try element.text()
                let url = try element.attr("href")
                return (name: name, url: url)
            }
            completion(.success(allGroups))
        } catch {
            completion(.failure(NSError(domain: "ParsingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга HTML: \(error.localizedDescription)"])))
        }
    }
    task.resume()
}





