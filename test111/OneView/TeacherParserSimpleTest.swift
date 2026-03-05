import Foundation
import SwiftSoup

// Простой тест для проверки парсинга с новой структурой HTML
class TeacherParserSimpleTest {
    
    static func testWithMockHTML() {
        print("🧪 Тестируем парсер с mock HTML...")
        
        // Создаем mock HTML, похожий на структуру с сайта
        let mockHTML = """
        <html>
        <body>
        <tbody>
        <tr class="bg_td">
            <td width="17%" valign="TOP">
                <font face="Times New Roman" size="5" color="#ff00ff"></font>
                <p align="CENTER"><font face="Times New Roman" size="5" color="#ff00ff">ФИО, кафедра</font></p>
            </td>
        </tr>
        <tr>
            <td width="17%" valign="TOP">
                <p align="CENTER">
                    <a href="m1.html"><font face="Times New Roman">Авгайтис Л.С., Предметно цикловая комиссия преподавателей педагогики и гуманитарных специальностей</font></a>
                </p>
            </td>
        </tr>
        <tr>
            <td width="17%" valign="TOP">
                <p align="CENTER">
                    <a href="m2.html"><font face="Times New Roman">Агеева А.А., Предметно цикловая комиссия преподавателей естественно-научных и инженерно-информационных дисциплин</font></a>
                </p>
            </td>
        </tr>
        <tr>
            <td width="17%" valign="TOP">
                <p align="CENTER">
                    <a href="m8.html"><font face="Times New Roman">Андреев Н.В., </font></a>
                </p>
            </td>
        </tr>
        </tbody>
        </body>
        </html>
        """
        
        do {
            let document = try SwiftSoup.parse(mockHTML)
            print("✅ Mock HTML успешно распарсен")
            
            // Ищем tbody
            let tbody = try document.select("tbody").first()
            if let tbody = tbody {
                print("✅ Tbody найден")
                
                // Создаем искусственную таблицу
                let artificialTable = try document.createElement("table")
                try artificialTable.appendChild(tbody)
                
                // Тестируем парсинг
                let rows = try artificialTable.select("tr")
                print("📊 Найдено строк: \(rows.count)")
                
                var teachers: [Teacher] = []
                
                // Пропускаем первую строку (заголовок)
                for i in 1..<rows.count {
                    let row = rows[i]
                    let cells = try row.select("td")
                    
                    if cells.count == 1 {
                        let cell = cells[0]
                        let links = try cell.select("a")
                        
                        if let link = links.first {
                            let linkText = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)
                            let href = try link.attr("href")
                            
                            print("🔗 Обрабатываем: '\(linkText)' -> '\(href)'")
                            
                            let components = linkText.components(separatedBy: ", ")
                            
                            if components.count >= 2 {
                                let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                let department = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                if !name.isEmpty {
                                    let teacherURL = "https://imsit.ru/timetable/teach/\(href)"
                                    let teacher = Teacher(name: name, department: department, url: teacherURL)
                                    teachers.append(teacher)
                                    print("✅ Добавлен: \(name) - \(department)")
                                }
                            } else if components.count == 1 {
                                let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                if !name.isEmpty {
                                    let teacherURL = "https://imsit.ru/timetable/teach/\(href)"
                                    let teacher = Teacher(name: name, department: "Без кафедры", url: teacherURL)
                                    teachers.append(teacher)
                                    print("✅ Добавлен (без кафедры): \(name)")
                                }
                            }
                        }
                    }
                }
                
                print("\n📋 Результат парсинга mock HTML:")
                print("Всего преподавателей: \(teachers.count)")
                for teacher in teachers {
                    print("  • \(teacher.name) - \(teacher.department)")
                }
                
            } else {
                print("❌ Tbody не найден")
            }
            
        } catch {
            print("❌ Ошибка при парсинге mock HTML: \(error)")
        }
    }
}

