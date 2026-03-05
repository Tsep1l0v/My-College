import Foundation

struct Teacher {
    let name: String
    let department: String
    let url: String
}

class TeacherParser {
    static let shared = TeacherParser()
    
    private init() {}
    
    // Новый метод: поиск преподавателей по кафедре через REST
    func fetchTeachers(department: String? = nil, completion: @escaping (Result<[APITeacher], Error>) -> Void) {
        ScheduleRepository.shared.searchTeachers(department: department, completion: completion)
    }
    
    // Совместимая обертка поиска по подстроке имени
    func searchTeacher(name: String, completion: @escaping (Result<APITeacher?, Error>) -> Void) {
        ScheduleRepository.shared.searchTeachers(department: nil) { result in
            switch result {
            case .success(let list):
                let found = list.first { $0.label.lowercased().contains(name.lowercased()) }
                completion(.success(found))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Совместимость: сгруппировать преподавателей по кафедрам
    func fetchTeachersByDepartment(completion: @escaping (Result<[String: [String]], Error>) -> Void) {
        fetchTeachers(department: nil) { result in
            switch result {
            case .success(let teachers):
                var byDept: [String: [String]] = [:]
                for t in teachers {
                    let dept = t.department ?? "Без кафедры"
                    byDept[dept, default: []].append(t.label)
                }
                completion(.success(byDept))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
