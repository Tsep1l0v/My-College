//TwoViewController.swift


import UIKit
import SwiftSoup
import Lottie
import UserNotifications
import MyTrackerSDK
#if canImport(WidgetKit)
import WidgetKit
#endif

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

        // Настройка таблицы
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LessonTableViewCell.self, forCellReuseIdentifier: "LessonCell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false // Убираем индикатор скролла
        
        // Включаем автоматическую высоту ячеек
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150

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
        let attributedText = NSMutableAttributedString(string: mainText, attributes: [
            .font: UIFont.boldSystemFont(ofSize: 30),
            .foregroundColor: UIColor.label
        ])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mainText.count))
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
        
        // Регистрируемся на нотификацию для смены режима
        NotificationCenter.default.addObserver(self, selector: #selector(handleModeChange), name: Notification.Name("modeChanged"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func reloadSchedule() {
        // Очищаем расписание перед загрузкой, чтобы избежать обращения к старым индексам
        schedule = []
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        loadTimetableData()
        // updateTableViewBasedOnSettings() будет вызван внутри loadTimetableData() после загрузки данных
    }
    
    @objc func handleModeChange() {
        // При смене режима очищаем расписание, чтобы избежать показа данных из другого режима
        fullSchedule = []
        schedule = []
        print("🔄 TwoViewController: Очищено расписание при смене режима")
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
        // Делегируем в централизованный менеджер, не очищая все уведомления
        let isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        NotificationManager.shared.scheduleNotifications(for: fullSchedule, isTeacherMode: isTeacherMode)
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

        // Проверяем соответствие режима: если мы в режиме студента, но кеш содержит данные преподавателя (или наоборот),
        // нужно очистить fullSchedule и загрузить правильные данные
        let currentIsTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        if currentIsTeacherMode {
            // Если мы в режиме преподавателя, но открыт контроллер студентов - очищаем расписание
            fullSchedule = []
            schedule = []
            print("⚠️ TwoViewController: Очищено расписание - текущий режим преподавателя")
            updateTableViewBasedOnSettings()
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
            return
        }
        
        // Режим студента - всегда проверяем кеш, даже если fullSchedule не пустой
        // Это гарантирует, что мы используем правильные данные для текущего режима и группы
        if let cached = ScheduleStorage.loadSchedule(), !cached.isEmpty {
            // Если кеш найден и соответствует текущему режиму и группе, используем его
            print("📦 Используем закешированное расписание из ScheduleStorage")
            fullSchedule = cached
        } else if fullSchedule.isEmpty {
            // Если кеш не найден и fullSchedule пустой, пробуем загрузить с сервера
            // Но только если выбрана группа
            if let groupName = selectedGroupURL, !groupName.isEmpty {
                loadTimetableData()
                return
            }
        }
        // Если fullSchedule не пустой, но кеш не найден - это может быть старые данные в памяти
        // В этом случае оставляем как есть, но лучше было бы очистить
        
        updateTableViewBasedOnSettings()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func loadTimetableData() {
        // Имя группы хранится в selectedGroupURL раньше как URL. Теперь ожидаем имя группы.
        guard let groupName = selectedGroupURL, !groupName.isEmpty else {
            print("Не выбрана группа")
            // Пробуем загрузить из кеша перед показом ошибки
            if let cached = ScheduleStorage.loadSchedule(), !cached.isEmpty {
                print("📦 Загружаем расписание из кеша при отсутствии выбранной группы")
                fullSchedule = cached
                updateTableViewBasedOnSettings()
                return
            }
            showError()
            return
        }
        
        // Сначала пробуем загрузить из кеша (если есть)
        if let cached = ScheduleStorage.loadSchedule(), !cached.isEmpty {
            print("📦 Загружаем расписание из кеша перед запросом к серверу")
            fullSchedule = cached
            updateTableViewBasedOnSettings()
        }
        
        // Если включена синхронизация недели — сначала получаем weekCount с сервера
        let isSyncEnabled = UserDefaults.standard.bool(forKey: "syncWeekEnabled")
        if isSyncEnabled {
            ScheduleRepository.shared.getWeekCount { result in
                switch result {
                case .success(let week):
                    let isOdd = (week == 1)
                    UserDefaults.standard.set(isOdd, forKey: "isOddWeek")
                    ScheduleRepository.shared.getGroupSchedule(groupName: groupName, weekCount: week) { result in
                        switch result {
                        case .success(let items):
                            let weekSchedule = self.mapAPIScheduleToWeek(items)
                            DispatchQueue.main.async {
                                self.fullSchedule = weekSchedule
                                self.updateTableViewBasedOnSettings()
                            }
                        case .failure:
                            // При ошибке сети не показываем ошибку, если есть кеш
                            if self.fullSchedule.isEmpty {
                                self.showError()
                            }
                        }
                    }
                case .failure:
                    // Фоллбэк к локальной настройке недели
                    let isOdd = UserDefaults.standard.bool(forKey: "isOddWeek")
                    let weekLocal = isOdd ? 1 : 2
                    ScheduleRepository.shared.getGroupSchedule(groupName: groupName, weekCount: weekLocal) { result in
                        switch result {
                        case .success(let items):
                            let weekSchedule = self.mapAPIScheduleToWeek(items)
                            DispatchQueue.main.async {
                                self.fullSchedule = weekSchedule
                                self.updateTableViewBasedOnSettings()
                            }
                        case .failure:
                            // При ошибке сети не показываем ошибку, если есть кеш
                            if self.fullSchedule.isEmpty {
                                self.showError()
                            }
                        }
                    }
                }
            }
        } else {
            // Используем локальную настройку четности недели (isOddWeek: true -> 1, false -> 2)
            let isOdd = UserDefaults.standard.bool(forKey: "isOddWeek")
            let week = isOdd ? 1 : 2
            ScheduleRepository.shared.getGroupSchedule(groupName: groupName, weekCount: week) { result in
                switch result {
                case .success(let items):
                    let weekSchedule = self.mapAPIScheduleToWeek(items)
                    DispatchQueue.main.async {
                        self.fullSchedule = weekSchedule
                        self.updateTableViewBasedOnSettings()
                    }
                case .failure:
                    // При ошибке сети не показываем ошибку, если есть кеш
                    if self.fullSchedule.isEmpty {
                        self.showError()
                    }
                }
            }
        }
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
        print("Настройка отображения: \(isFullScheduleEnabled ? "полное расписание" : "только сегодня")")
        
        if isFullScheduleEnabled {
            schedule = fullSchedule // Показываем расписание на всю неделю
            MRMyTracker.trackEvent(name: "Открыть расписание группы на неделю")
        } else {
            updateTableForToday() // Показываем расписание на текущий день
            MRMyTracker.trackEvent(name: "Открыть расписание группы на сегодня")
        }

        print("Расписание для отображения: \(schedule.count) дней")

        DispatchQueue.main.async {
            self.tableView.reloadData()
            // Убедитесь, что текст отображается, если расписание пустое
            if self.schedule.isEmpty {
                print("Расписание пустое, показываем ошибку")
                self.showError()
            } else {
                print("Расписание загружено успешно, скрываем ошибку")
                self.errorLabel.isHidden = true
                self.animationView.isHidden = true
                self.animationView.stop()
                self.tableView.isHidden = false
                
                // Планируем уведомления для загруженного расписания
                self.scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        let notificationManager = NotificationManager.shared
        let isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        
        // Сохраняем расписание всегда (для виджета и уведомлений)
        // Используем ScheduleStorage для сохранения (поддерживает App Group)
        // Передаем метаданные для правильного кеширования
        ScheduleStorage.saveSchedule(fullSchedule, isTeacherMode: isTeacherMode, selectedGroup: selectedGroupURL, selectedTeacher: nil)
#if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
#endif
        
        // Планируем уведомления только для студентов
        if !isTeacherMode {
            notificationManager.scheduleNotifications(for: fullSchedule, isTeacherMode: false)
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

    // Строит дату занятия на конкретный день, устанавливая время начала пары из строки вида "HH:mm-HH:mm"
    func dateBySettingStartTime(for date: Date, from time: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        guard let startTimeString = time.split(separator: "-").first else {
            print("Неверный формат времени: \(time)")
            return nil
        }

        guard let startTime = dateFormatter.date(from: String(startTimeString)) else {
            print("Не удалось преобразовать время: \(startTimeString)")
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = calendar.component(.hour, from: startTime)
        dateComponents.minute = calendar.component(.minute, from: startTime)

        return calendar.date(from: dateComponents)
    }

    func updateTableForToday() {
        if let todaysSchedule = getTodaysSchedule() {
            schedule = [todaysSchedule]

            // Подаем централизованному планировщику все расписание недели
            self.scheduleNotifications() // планируем через NotificationManager на 7 дней
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
                    color: .systemGray,
                    eiosLink: nil
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

    func processHTML(_ htmlString: String) { }

    func parseWeek(document: Document, lessonNumbersSelector: String, lessonTimesSelector: String, daySelectors: [String]) -> [DaySchedule] {
        print("Начинаем парсинг недели...")
        var parsedSchedule: [DaySchedule] = []
        let daysOfWeek = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        let weekDates = calculateWeekDates()

        do {
            let lessonNumbers = try document.select(lessonNumbersSelector).select("td").map { try $0.text() }
            let lessonTimes = try document.select(lessonTimesSelector).select("td").map { try $0.text() }
            print("Найдено \(lessonNumbers.count) номеров пар и \(lessonTimes.count) временных слотов")

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
                    
                    // Проверяем, содержит ли урок только тире или похожие символы
                    let trimmedData = cleanedData.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedData == "-" || trimmedData == "—" || trimmedData == "–" || 
                       trimmedData.hasPrefix("-") || trimmedData.hasPrefix("—") || trimmedData.hasPrefix("–") ||
                       trimmedData.hasSuffix("-") || trimmedData.hasSuffix("—") || trimmedData.hasSuffix("–") {
                        continue
                    }
                    
                    let invalidPatterns = ["№1", "Время", "Кабинет неизвестен", "Пнд", "Втр", "Срд", "Чтв", "Птн", "Сбт", ""]
                    if invalidPatterns.contains(where: { cleanedData.contains($0) }) {
                        continue
                    }

                    let parsedLesson = parseLesson(cleanedData)

                    // Пропускаем уроки с пустыми предметами
                    if parsedLesson.subject.isEmpty { continue }

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
                        color: getColor(for: lessonNumber),
                        eiosLink: nil
                    )
                    dailyLessons.append(lesson)
                }

                if !dailyLessons.isEmpty {
                    let daySchedule = DaySchedule(
                        day: daysOfWeek[index],
                        date: weekDates[index],
                        lessons: dailyLessons
                    )
                    parsedSchedule.append(daySchedule)
                } else {
                    // Если в дне нет уроков, добавляем день выходного
                    let daySchedule = DaySchedule(
                        day: daysOfWeek[index],
                        date: weekDates[index],
                        lessons: [Lesson(
                            number: 0,
                            time: "",
                            subject: "Сегодня выходной. Наслаждайтесь отдыхом!",
                            teacher: "",
                            room: "",
                            type: "",
                            color: .systemGray,
                            eiosLink: nil
                        )]
                    )
                    parsedSchedule.append(daySchedule)
                }
            }
        } catch {
            print("Error parsing week: \(error)")
        }

        print("Парсинг завершен. Найдено \(parsedSchedule.count) дней с уроками")
        return parsedSchedule
    }

    // MARK: - Mapping REST → UI-модели
    private func mapAPIScheduleToWeek(_ items: [APIScheduleItem]) -> [DaySchedule] {
        let daysOrder: [String] = ["Понедельник","Вторник","Среда","Четверг","Пятница","Суббота","Воскресенье"]
        let weekDates = calculateWeekDates()
        var byDay: [String: [APIScheduleItem]] = [:]
        for item in items { byDay[item.dayWeek, default: []].append(item) }
        var result: [DaySchedule] = []
        for (idx, day) in daysOrder.enumerated() {
            let dayItems = byDay[day] ?? []
            if dayItems.isEmpty {
                let placeholder = DaySchedule(day: day, date: weekDates[idx], lessons: [Lesson(number: 0, time: "", subject: "Сегодня выходной. Наслаждайтесь отдыхом!", teacher: "", room: "", type: "", color: .systemGray, eiosLink: nil)])
                result.append(placeholder)
                continue
            }
            
            // Сортируем занятия по времени начала пары, чтобы пары шли по порядку
            let sortedItems: [APIScheduleItem] = dayItems.sorted { lhs, rhs in
                guard let leftDate = startTimeDate(from: lhs.timePeriod),
                      let rightDate = startTimeDate(from: rhs.timePeriod) else {
                    // Если не удаётся распарсить время, сравниваем как строки
                    return lhs.timePeriod < rhs.timePeriod
                }
                return leftDate < rightDate
            }
            
            let lessons: [Lesson] = sortedItems.enumerated().map { (index, it) in
                let number = index + 1
                let teacherLabel = it.teacher?.label ?? ""
                return Lesson(
                    number: number,
                    time: it.timePeriod,
                    subject: it.lessonName,
                    teacher: teacherLabel,
                    room: it.auditory ?? "",
                    type: it.lessonType,
                    color: getColor(for: number),
                    eiosLink: it.eiosLink
                )
            }
            result.append(DaySchedule(day: day, date: weekDates[idx], lessons: lessons))
        }
        return result
    }
    
    /// Возвращает дату, построенную только из времени начала интервала вида "HH:mm-HH:mm"
    private func startTimeDate(from timePeriod: String) -> Date? {
        let components = timePeriod.split(separator: "-")
        guard let startComponent = components.first else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        
        return formatter.date(from: String(startComponent))
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

        // Проверяем, что предмет не является тире или пустой строкой
        let finalData = cleanedData.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalData.isEmpty || 
           finalData == "-" || finalData == "—" || finalData == "–" ||
           finalData.hasPrefix("-") || finalData.hasPrefix("—") || finalData.hasPrefix("–") ||
           finalData.hasSuffix("-") || finalData.hasSuffix("—") || finalData.hasSuffix("–") ||
           finalData.count <= 2 { // Если предмет слишком короткий (например, только тире)
            return (subject: "", teacher: "", room: "", type: "")
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
        guard section < schedule.count else { return nil }
        let daySchedule = schedule[section]
        return daySchedule.day
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < schedule.count else { return 0 }
        return schedule[section].lessons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as! LessonTableViewCell
        
        guard indexPath.section < schedule.count,
              indexPath.row < schedule[indexPath.section].lessons.count else {
            // Возвращаем пустую ячейку, если индексы некорректные
            return cell
        }
        
        let lesson = schedule[indexPath.section].lessons[indexPath.row]
        let daySchedule = schedule[indexPath.section]

        // Проверяем, является ли урок фиктивным (аналогичным воскресенью)
        let isPlaceholder = lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!"
        cell.configure(with: lesson, isPlaceholder: isPlaceholder)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < schedule.count else { return nil }
        // Создаем кастомный view для заголовка
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground

        // Создаем и настраиваем лейбл для заголовка
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .label
        titleLabel.font = .boldSystemFont(ofSize: 15)  // Сделать текст жирным
        let daySchedule = schedule[section]
        titleLabel.text = daySchedule.day  // Только день недели

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
        guard indexPath.section < schedule.count,
              indexPath.row < schedule[indexPath.section].lessons.count else {
            return UITableView.automaticDimension
        }
        
        let lesson = schedule[indexPath.section].lessons[indexPath.row]
        
        // Для placeholder ячеек (выходной день) используем фиксированную высоту
        if lesson.subject == "Сегодня выходной. Наслаждайтесь отдыхом!" {
            return 150 // Увеличенная высота для анимации
        }
        
        // Для обычных ячеек используем автоматическую высоту
        return UITableView.automaticDimension
    }
}



