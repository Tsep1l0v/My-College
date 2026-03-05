//
//  Lesson.swift
//  ScheduleWidgetExtension
//
//  Shared model for Widget Extension
//

import UIKit

// MARK: - Модель данных
struct Lesson: Codable {
    let number: Int
    let time: String
    let subject: String
    let teacher: String
    let room: String
    let type: String
    let color: UIColor
    let eiosLink: String?
    
    // Кастомное кодирование для UIColor
    enum CodingKeys: String, CodingKey {
        case number, time, subject, teacher, room, type, color, eiosLink
    }
    
    init(number: Int,
         time: String,
         subject: String,
         teacher: String,
         room: String,
         type: String,
         color: UIColor,
         eiosLink: String? = nil) {
        self.number = number
        self.time = time
        self.subject = subject
        self.teacher = teacher
        self.room = room
        self.type = type
        self.color = color
        self.eiosLink = eiosLink
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        time = try container.decode(String.self, forKey: .time)
        subject = try container.decode(String.self, forKey: .subject)
        teacher = try container.decode(String.self, forKey: .teacher)
        room = try container.decode(String.self, forKey: .room)
        type = try container.decode(String.self, forKey: .type)
        
        // Декодируем цвет как строку и конвертируем в UIColor
        let colorString = try container.decode(String.self, forKey: .color)
        self.color = UIColor(hex: colorString)
        
        // Декодируем eiosLink опционально
        eiosLink = try container.decodeIfPresent(String.self, forKey: .eiosLink)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(time, forKey: .time)
        try container.encode(subject, forKey: .subject)
        try container.encode(teacher, forKey: .teacher)
        try container.encode(room, forKey: .room)
        try container.encode(type, forKey: .type)
        
        // Кодируем цвет как hex строку
        let colorString = color.toHexString()
        try container.encode(colorString, forKey: .color)
        
        // Кодируем eiosLink опционально
        if let eiosLink = eiosLink {
            try container.encode(eiosLink, forKey: .eiosLink)
        }
    }
}

// Расширение для UIColor: методы сериализации
extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06X", rgb)
    }
}

