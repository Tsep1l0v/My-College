//TwoViewController.swift


import UIKit
import SwiftSoup
import Lottie
import UserNotifications

class TwoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView!
    var schedule: [DaySchedule] = [] // Сюда будет сохраняться расписание для отображения
    var fullSchedule: [DaySchedule] = [] // Хранит полное расписание на неделю
    var selectedGroupURL: String?
    var errorLabel: UILabel!
    var animationView: LottieAnimationView!
    var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        overrideUserInterfaceStyle = .light

        // Настройка таблицы
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LessonTableViewCell.self, forCellReuseIdentifier: "LessonCell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none

        view.addSubview(tableView)

        // Измените значение константы на величину, на которую хотите поднять таблицу
        let topOffset: CGFloat = 0 // Поднимаем таблицу на 0 пикселей

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Текст при ошибке
        errorLabel = UILabel()
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        view.addSubview(errorLabel)
        
    
        let mainText = "Что-то пошло не так"
        let subText = "\n\nПожалуйста, проверьте следующие моменты:"
        let items = [
            "Убедитесь, что вы выбрали группу для отображения расписания.",
            "Попробуйте еще раз нажать кнопку \"Выбрать\".",
            "Проверьте стабильность вашего интернет-соединения.",
            "Возможно, есть временные проблемы с выводом расписания\n из сайта imsit.ru."
        ]

        let attributedText = NSMutableAttributedString(string: mainText, attributes: [
            .font: UIFont.boldSystemFont(ofSize: 30), // Увеличиваем размер шрифта для mainText
            .foregroundColor: UIColor.black
        ])

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mainText.count))

        attributedText.append(NSAttributedString(string: subText, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]))

        for item in items {
            attributedText.append(NSAttributedString(string: "\n• \(item)", attributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]))
        }

        errorLabel.attributedText = attributedText

        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20) // Поднимаем текст повыше
        ])

        // Настройка AnimationView для отображения Lottie анимации
        animationView = LottieAnimationView(name: "error_animation") // Замените "error_animation" на имя вашего Lottie файла
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.isHidden = true
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 20),
            animationView.widthAnchor.constraint(equalToConstant: 350), // Увеличиваем размер анимации
            animationView.heightAnchor.constraint(equalToConstant: 350) // Увеличиваем размер анимации
        ])

        // Добавляем кнопку настроек в заголовок таблицы
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = .systemBlue
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -5) // Поднимаем кнопку выше
        ])

        requestNotificationPermission()
        listScheduledNotifications()

        // Регистрируемся на нотификацию для обновления расписания
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSchedule), name: Notification.Name("reloadSchedule"), object: nil)
    }
    
    

    @objc func reloadSchedule() {
        loadTimetableData()
        updateTableViewBasedOnSettings() // Убедитесь, что таблица обновляется после загрузки данных
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }

    func scheduleNotifications(for schedule: [DaySchedule]) {
        let center = UNUserNotificationCenter.current()

        // Удаляем все старые уведомления
        center.removeAllPendingNotificationRequests()

        // Получаем расписание только для текущего дня
        if let todaysSchedule = getTodaysSchedule() {
            for lesson in todaysSchedule.lessons {
                guard let lessonDate = parseLessonDate(lesson.time) else { continue }
                let triggerDate = Calendar.current.date(byAdding: .minute, value: -5, to: lessonDate) // Уведомление за 5 минут
                guard let triggerDate = triggerDate else { continue }

                // Создание уникального идентификатора на основе времени урока и других данных
                let notificationID = "lesson_\(lesson.number)_\(lesson.time)_\(lesson.subject)"

                // Проверяем, существует ли уже уведомление с таким идентификатором
                center.getPendingNotificationRequests { requests in
                    // Проверяем, если уведомление с таким ID уже существует
                    let existingRequest = requests.first { $0.identifier == notificationID }

                    if existingRequest == nil {
                        // Уведомление еще не запланировано, создаем и добавляем новое
                        let content = UNMutableNotificationContent()
                        content.title = "Напоминание о паре 📚"
                        content.body = "Через 5 минут начнется пара: \(lesson.subject)"
                        content.sound = .default

                        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
                        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

                        center.add(request) { error in
                            if let error = error {
                                print("Ошибка при добавлении уведомления: \(error)")
                            } else {
                                print("Уведомление добавлено для \(content.body)")
                            }
                        }
                    } else {
                        print("Уведомление уже запланировано для урока \(lesson.subject) в \(lesson.time).")
                    }
                }
            }
        }
    }

    func listScheduledNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            if requests.isEmpty {
                print("Запланированные уведомления: Пусто")
            } else {
                print("Запланированные уведомления:")
                for request in requests {
                    print("ID: \(request.identifier), Контент: \(request.content.body)")
                }
            }
        }
    }

    @objc func openSettings() {
        let settingsViewController = SettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTableViewBasedOnSettings()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func loadTimetableData() {
        // Используем переданный URL группы
        guard let groupURL = selectedGroupURL, let url = URL(string: "https://imsit.ru/timetable/stud/\(groupURL)") else {
            print("Invalid URL")
            showError()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data")
                self.showError()
                return
            }

            if let htmlString = String(data: data, encoding: .windowsCP1251) {
                self.processHTML(htmlString)
            } else {
                print("Error converting data to string with windows-1251")
                self.showError()
            }
        }
        task.resume()
    }

    func showError() {
        DispatchQueue.main.async {
            self.errorLabel.isHidden = false
            self.animationView.isHidden = false
            self.animationView.play()
            self.tableView.isHidden = true
        }
    }

    func updateTableViewBasedOnSettings() {
        let isFullScheduleEnabled = UserDefaults.standard.bool(forKey: "showFullSchedule")
        if isFullScheduleEnabled {
            schedule = fullSchedule // Показываем расписание на всю неделю
        } else {
            updateTableForToday() // Показываем расписание на текущий день
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
            // Убедитесь, что текст отображается, если расписание пустое
            if self.schedule.isEmpty {
                self.showError()
            } else {
                self.errorLabel.isHidden = true
                self.animationView.isHidden = true
                self.animationView.stop()
                self.tableView.isHidden = false
            }
        }
    }

    func parseLessonDate(_ time: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        // Извлечение времени начала из диапазона (до символа "-")
        guard let startTime = time.split(separator: "-").first else {
            print("Неверный формат времени: \(time)")
            return nil
        }

        // Преобразование времени начала в Date
        guard let timeComponents = dateFormatter.date(from: String(startTime)) else {
            print("Не удалось преобразовать время: \(startTime)")
            return nil
        }

        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = calendar.component(.hour, from: timeComponents)
        dateComponents.minute = calendar.component(.minute, from: timeComponents)

        let resultDate = calendar.date(from: dateComponents)
        if resultDate == nil {
            print("Ошибка при создании даты для времени: \(startTime)")
        }
        return resultDate
    }

    func updateTableForToday() {
        if let todaysSchedule = getTodaysSchedule() {
            schedule = [todaysSchedule]

            // Теперь вызываем метод для планирования уведомлений
            scheduleNotifications(for: [todaysSchedule]) // Подаем расписание на сегодня
        } else {
            print("No schedule found for today.")
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func getTodaysSchedule() -> DaySchedule? {
        let calendar = Calendar.current
        let today = Date()

        // Получаем номер дня недели (1 - воскресенье, 2 - понедельник и т.д.)
        let weekday = calendar.component(.weekday, from: today)
        print("Current weekday: \(weekday)")

        // Вычисляем даты недели
        let weekDates = calculateWeekDates()
        print("Week dates: \(weekDates)")

        // Если воскресенье, возвращаем фиктивное расписание с датой
        if weekday == 1 {
            let sundayDate = weekDates.last ?? "Неизвестная дата" // Берем последнюю дату из массива
            return DaySchedule(
                day: "Воскресенье",
                date: sundayDate,
                lessons: [Lesson(
                    number: 0,
                    time: "",
                    subject: "Сегодня выходной. Наслаждайтесь отдыхом!",
                    teacher: "", room: "", type: "",
                    color: .systemGray
                )]
            )
        }

        // Возвращаем расписание для текущего дня
        if weekday > 1 && weekday <= fullSchedule.count + 1 {
            return fullSchedule[weekday - 2] // Индекс в расписании должен быть на 1 меньше
        }

        return nil
    }

    func calculateWeekDates() -> [String] {
        let calendar = Calendar.current
        let today = Date()

        // Определяем день недели (1 - воскресенье, 2 - понедельник и т.д.)
        let weekday = calendar.component(.weekday, from: today)

        // Смещение от сегодняшнего дня до понедельника
        let daysToMonday = weekday == 1 ? -6 : 2 - weekday

        // Понедельник текущей недели
        guard let startOfWeek = calendar.date(byAdding: .day, value: daysToMonday, to: today) else {
            fatalError("Unable to calculate start of week")
        }

        // Форматтер для вывода даты
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "d MMMM" // Пример: "18 ноября"

        // Генерируем даты недели с понедельника по воскресенье
        var weekDates: [String] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                weekDates.append(dateFormatter.string(from: date))
            }
        }

        return weekDates
    }

    func processHTML(_ htmlString: String) {
        do {
            let document = try SwiftSoup.parse(htmlString)

            // Проверяем, четная или нечетная неделя
            let isOddWeek = UserDefaults.standard.bool(forKey: "isOddWeek")

            // Селекторы для четной и нечетной недель
            let oddWeekSelectors = (
                lessonNumbers: "body > table:nth-child(3) > tbody > tr:nth-child(1)",
                lessonTimes: "body > table:nth-child(3) > tbody > tr:nth-child(2)",
                daySelectors: [
                    "body > table:nth-child(3) > tbody > tr:nth-child(3)", // Понедельник
                    "body > table:nth-child(3) > tbody > tr:nth-child(4)", // Вторник
                    "body > table:nth-child(3) > tbody > tr:nth-child(5)", // Среда
                    "body > table:nth-child(3) > tbody > tr:nth-child(6)", // Четверг
                    "body > table:nth-child(3) > tbody > tr:nth-child(7)", // Пятница
                    "body > table:nth-child(3) > tbody > tr:nth-child(8)"  // Суббота
                ]
            )

            let evenWeekSelectors = (
                lessonNumbers: "body > table:nth-child(6) > tbody > tr:nth-child(1)",
                lessonTimes: "body > table:nth-child(6) > tbody > tr:nth-child(2)",
                daySelectors: [
                    "body > table:nth-child(6) > tbody > tr:nth-child(3)", // Понедельник
                    "body > table:nth-child(6) > tbody > tr:nth-child(4)", // Вторник
                    "body > table:nth-child(6) > tbody > tr:nth-child(5)", // Среда
                    "body > table:nth-child(6) > tbody > tr:nth-child(6)", // Четверг
                    "body > table:nth-child(6) > tbody > tr:nth-child(7)", // Пятница
                    "body > table:nth-child(6) > tbody > tr:nth-child(8)"  // Суббота
                ]
            )

            let selectors = isOddWeek ? oddWeekSelectors : evenWeekSelectors

            // Парсим расписание с выбранными селекторами
            let weekSchedule = parseWeek(
                document: document,
                lessonNumbersSelector: selectors.lessonNumbers,
                lessonTimesSelector: selectors.lessonTimes,
                daySelectors: selectors.daySelectors
            )

            DispatchQueue.main.async {
                self.fullSchedule = weekSchedule
                self.updateTableViewBasedOnSettings()
                self.errorLabel.isHidden = true
                self.animationView.isHidden = true
                self.animationView.stop()
                self.tableView.isHidden = false

                // Добавляем задержку перед вызовом listScheduledNotifications
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.listScheduledNotifications()
                }
            }
        } catch {
            print("Error parsing HTML: \(error)")
            self.showError()
        }
    }

    func parseWeek(document: Document, lessonNumbersSelector: String, lessonTimesSelector: String, daySelectors: [String]) -> [DaySchedule] {
        var parsedSchedule: [DaySchedule] = []
        let daysOfWeek = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        let weekDates = calculateWeekDates()

        do {
            let lessonNumbers = try document.select(lessonNumbersSelector).select("td").map { try $0.text() }
            let lessonTimes = try document.select(lessonTimesSelector).select("td").map { try $0.text() }

            let timeSlots = [
                (start: "08:00", end: "09:30"),  // Пара 1
                (start: "09:40", end: "11:10"),  // Пара 2
                (start: "11:30", end: "13:00"),  // Пара 3
                (start: "13:10", end: "14:40"),  // Пара 4
                (start: "14:50", end: "16:20"),  // Пара 5
                (start: "16:30", end: "18:00"),  // Пара 6
                (start: "18:10", end: "19:40")   // Пара 7
            ]

            for (index, daySelector) in daySelectors.enumerated() {
                let lessonsForDay = try document.select(daySelector).select("td").map { try $0.text() }

                var dailyLessons: [Lesson] = []

                for (i, lessonData) in lessonsForDay.enumerated() {
                    let cleanedData = lessonData.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Фильтруем пустые строки и ненужные заголовки
                    if cleanedData.isEmpty { continue }
                    let invalidPatterns = ["№1", "Время", "Кабинет неизвестен", "Пнд", "Втр", "Срд", "Чтв", "Птн", "Сбт", ""]
                    if invalidPatterns.contains(where: { cleanedData.contains($0) }) {
                        continue
                    }

                    let parsedLesson = parseLesson(cleanedData)

                    // Если времени для текущей пары нет, пропускаем эту пару
                    guard i < lessonTimes.count else { continue }
                    let lessonTime = lessonTimes[i]
                    let lessonNumber = getLessonNumber(for: lessonTime, timeSlots: timeSlots)

                    let lesson = Lesson(
                        number: lessonNumber,
                        time: lessonTime,
                        subject: parsedLesson.subject,
                        teacher: parsedLesson.teacher,
                        room: parsedLesson.room,
                        type: parsedLesson.type,
                        color: getColor(for: lessonNumber)
                    )
                    dailyLessons.append(lesson)
                }

                if dailyLessons.isEmpty {
                    // Добавляем фиктивное расписание, аналогичное воскресенью
                    let daySchedule = DaySchedule(
                        day: daysOfWeek[index],
                        date: weekDates[index],
                        lessons: [Lesson(
                            number: 0,
                            time: "",
                            subject: "Сегодня выходной. Наслаждайтесь отдыхом!",
                            teacher: "", room: "", type: "",
                            color: .systemGray
                        )]
                    )
                    parsedSchedule.append(daySchedule)
                } else {
                    let daySchedule = DaySchedule(
                        day: daysOfWeek[index],
                        date: weekDates[index],
                        lessons: dailyLessons
                    )
                    parsedSchedule.append(daySchedule)
                }
            }
        } catch {
            print("Error parsing week: \(error)")
        }

        return parsedSchedule
    }

    // Функция для получения номера пары по времени
    func getLessonNumber(for time: String, timeSlots: [(start: String, end: String)]) -> Int {
        // Мы больше не используем сравнение с точным временем, а просто проверяем, какой интервал подходит
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        for (index, slot) in timeSlots.enumerated() {
            // Сравниваем с заданными интервалами
            if time.contains(slot.start) || time.contains(slot.end) {
                return index + 1 // Нумерация с 1
            }
        }

        return 0 // Если не попадает в интервал, возвращаем 0 (ошибка)
    }

    func parseLesson(_ lessonData: String) -> (subject: String, teacher: String, room: String, type: String) {
        // Регулярное выражение для кабинета (например, "1-109" или "с/зал")
        let regexForRoom = #"[0-9]+-[0-9]+[а-яА-Я]?|с/зал"#

        // Найти кабинет
        let roomMatch = lessonData.range(of: regexForRoom, options: .regularExpression)
        var room = roomMatch != nil ? String(lessonData[roomMatch!]) : "Кабинет неизвестен"

        // Убрать кабинет из строки
        var cleanedData = lessonData
        if let roomRange = roomMatch {
            cleanedData.removeSubrange(roomRange)
        }

        // Удаляем лишние пробелы и невидимые символы
        cleanedData = cleanedData.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedData = cleanedData.replacingOccurrences(of: "\u{00A0}", with: " ") // Удаляем неразрывные пробелы

        // Убираем "пр." из названия предмета
        cleanedData = cleanedData.replacingOccurrences(of: "пр.", with: "")

        // Проверяем, есть ли "лаб." в начале строки
        var type = "Практика"
        if cleanedData.hasPrefix("лаб.") {
            type = "Лаборатория" // Устанавливаем тип занятия как "Лаборатория"
            cleanedData = cleanedData.replacingOccurrences(of: "лаб.", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if cleanedData.contains("л.") {
            type = "Лекция"
            cleanedData = cleanedData.replacingOccurrences(of: "л.", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Попытка извлечь преподавателя в конце строки
        let teacherRegex = #"[А-ЯЁ][а-яё]+\s[А-ЯЁ]\.[А-ЯЁ]\."#
        var teacher = ""
        if let teacherRange = cleanedData.range(of: teacherRegex, options: .regularExpression) {
            teacher = String(cleanedData[teacherRange])
            cleanedData = cleanedData.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Удаляем лишнюю точку, если она осталась в конце строки
        if cleanedData.hasSuffix(".") {
            cleanedData = String(cleanedData.dropLast())
        }

        return (subject: cleanedData, teacher: teacher, room: room, type: type)
    }


    // Генерация цвета для урока
    func getColor(for number: Int) -> UIColor {
        let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemPurple, .systemGray]
        return colors[number % colors.count]
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return schedule.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let daySchedule = schedule[section]
        return "\(daySchedule.day), \(daySchedule.date)"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedule[section].lessons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as! LessonTableViewCell
        let lesson = schedule[indexPath.section].lessons[indexPath.row]
        let daySchedule = schedule[indexPath.section]

        // Проверяем, является ли урок фиктивным (аналогичным воскресенью)
        let isPlaceholder = lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!"
        cell.configure(with: lesson, isPlaceholder: isPlaceholder)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Создаем кастомный view для заголовка
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground  // Белый фон

        // Создаем и настраиваем лейбл для заголовка
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .black  // Черный цвет текста
        titleLabel.font = .boldSystemFont(ofSize: 15)  // Сделать текст жирным
        let daySchedule = schedule[section]
        titleLabel.text = "\(daySchedule.day), \(daySchedule.date)"  // День недели и дата

        // Добавляем лейбл на headerView
        headerView.addSubview(titleLabel)

        // Устанавливаем авто-расставление для лейбла
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])

        return headerView
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let lesson = schedule[indexPath.section].lessons[indexPath.row]
        if lesson.subject.count < 35 {
            return 125 // Уменьшаем высоту ячейки, если название предмета меньше 32 символов
        } else if lesson.subject.count > 80 {
            return 175
        } else if lesson.subject.count < 80 {
            return 165
        }
        return 150 // Стандартная высота для других случаев
    }
}



