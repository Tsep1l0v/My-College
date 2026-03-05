import Foundation
import SwiftSoup

// Тестовый файл для проверки работы TeacherParser
class TeacherParserTest {
    
    static func testParser() {
        print("Начинаем тестирование TeacherParser...")
        
        TeacherParser.shared.fetchTeachers { result in
            switch result {
            case .success(let teachers):
                print("✅ Успешно получено \(teachers.count) преподавателей")
                for (index, teacher) in teachers.prefix(5).enumerated() {
                    print("\(index + 1). \(teacher.name) - \(teacher.department)")
                    print("   URL: \(teacher.url)")
                }
                if teachers.count > 5 {
                    print("... и еще \(teachers.count - 5) преподавателей")
                }
                
            case .failure(let error):
                print("❌ Ошибка при парсинге: \(error.localizedDescription)")
            }
        }
        
        TeacherParser.shared.fetchTeachersByDepartment { result in
            switch result {
            case .success(let teachersByDept):
                print("\n📊 Преподаватели по кафедрам:")
                for (dept, teachers) in teachersByDept {
                    print("\(dept): \(teachers.count) преподавателей")
                }
                
            case .failure(let error):
                print("❌ Ошибка при получении преподавателей по кафедрам: \(error.localizedDescription)")
            }
        }
    }
}

