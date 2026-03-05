import Foundation
import SwiftSoup

// Консольный тест для проверки работы TeacherParser
class TeacherParserConsoleTest {
    
    static func runTest() {
        print("🚀 Запуск консольного теста TeacherParser...")
        print("=" * 50)
        
        // Тест 1: Загрузка всех преподавателей
        print("\n📋 Тест 1: Загрузка всех преподавателей")
        TeacherParser.shared.fetchTeachers { result in
            switch result {
            case .success(let teachers):
                print("✅ Успешно загружено \(teachers.count) преподавателей")
                print("\nПервые 5 преподавателей:")
                for (index, teacher) in teachers.prefix(5).enumerated() {
                    print("  \(index + 1). \(teacher.name)")
                    print("     Кафедра: \(teacher.department)")
                    print("     URL: \(teacher.url)")
                }
                
                if teachers.count > 5 {
                    print("  ... и еще \(teachers.count - 5) преподавателей")
                }
                
            case .failure(let error):
                print("❌ Ошибка при загрузке преподавателей: \(error.localizedDescription)")
            }
        }
        
        // Тест 2: Группировка по кафедрам
        print("\n🏢 Тест 2: Группировка преподавателей по кафедрам")
        TeacherParser.shared.fetchTeachersByDepartment { result in
            switch result {
            case .success(let teachersByDept):
                print("✅ Успешно сгруппировано по \(teachersByDept.count) кафедрам")
                print("\nКафедры и количество преподавателей:")
                for (dept, teachers) in teachersByDept.sorted(by: { $0.key < $1.key }) {
                    print("  📚 \(dept): \(teachers.count) преподавателей")
                    
                    // Показываем первых 3 преподавателей с каждой кафедры
                    let previewTeachers = teachers.prefix(3)
                    for teacher in previewTeachers {
                        print("     • \(teacher)")
                    }
                    
                    if teachers.count > 3 {
                        print("     ... и еще \(teachers.count - 3) преподавателей")
                    }
                }
                
            case .failure(let error):
                print("❌ Ошибка при группировке: \(error.localizedDescription)")
            }
        }
        
        // Тест 3: Поиск конкретного преподавателя
        print("\n🔍 Тест 3: Поиск преподавателя")
        TeacherParser.shared.searchTeacher(name: "Авгайтис") { result in
            switch result {
            case .success(let teacher):
                if let teacher = teacher {
                    print("✅ Найден преподаватель: \(teacher.name)")
                    print("   Кафедра: \(teacher.department)")
                    print("   URL: \(teacher.url)")
                } else {
                    print("❌ Преподаватель 'Авгайтис' не найден")
                }
                
            case .failure(let error):
                print("❌ Ошибка при поиске: \(error.localizedDescription)")
            }
        }
        
        print("\n" + "=" * 50)
        print("🏁 Тестирование завершено")
    }
}

// Вспомогательная функция для повторения строки
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

