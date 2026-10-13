//
//  CorrespondenceDatePickerViewController.swift
//  test111
//
//  Месячный календарь: только даты с занятиями можно выбрать; точка — есть пары.
//

import UIKit

private final class CorrespondenceCalendarDayCell: UICollectionViewCell {
    static let reuseId = "day"

    private let numberLabel = UILabel()
    private let dotView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.textAlignment = .center
        numberLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.layer.cornerRadius = 3
        dotView.clipsToBounds = true
        dotView.isHidden = true
        contentView.addSubview(numberLabel)
        contentView.addSubview(dotView)
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            dotView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dotView.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 4),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(day: Int, isCurrentMonth: Bool, isSunday: Bool, hasLessons: Bool, isSelected: Bool, isSelectable: Bool, isToday: Bool) {
        numberLabel.text = day > 0 ? "\(day)" : ""
        if day <= 0 {
            numberLabel.textColor = .clear
            dotView.isHidden = true
            contentView.backgroundColor = .clear
            return
        }
        if isCurrentMonth {
            if isSunday {
                numberLabel.textColor = .systemRed
            } else {
                numberLabel.textColor = .label
            }
        } else {
            numberLabel.textColor = UIColor.tertiaryLabel
        }
        // Точка только на реальной текущей дате телефона
        dotView.isHidden = !isToday
        dotView.backgroundColor = UIColor.systemGreen
        if isSelected {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
            contentView.layer.cornerRadius = 10
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.cornerRadius = 0
        }
        contentView.alpha = isSelectable || isCurrentMonth ? 1 : 0.45
    }
}

final class CorrespondenceDatePickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var isoDates: [String] = []
    var selectedISO: String?
    var onPick: ((String) -> Void)?

    private var displayedMonth: Date = Date()
    private var availableMonthAnchors: [Date] = []
    private var displayedMonthIndex: Int = 0

    private static let isoFmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Календарь сетки: воскресенье — первый столбец (как на макете).
    private var gridCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US_POSIX")
        c.firstWeekday = 1
        return c
    }()

    private var dayItems: [(date: Date?, day: Int, inMonth: Bool)] = []

    private let monthTitleLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private var weekdayRow = UIStackView()
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Календарь"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))

        buildAvailableMonths()
        if let s = selectedISO, let d = Self.isoFmt.date(from: s) {
            setDisplayedMonth(containing: d)
        } else if let f = isoDates.sorted().first, let d = Self.isoFmt.date(from: f) {
            setDisplayedMonth(containing: d)
        } else {
            displayedMonth = Date()
        }

        monthTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        monthTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        monthTitleLabel.textAlignment = .center

        prevButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        let prevCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        prevButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: prevCfg), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: prevCfg), for: .normal)
        prevButton.tintColor = .systemBlue
        nextButton.tintColor = .systemBlue
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [prevButton, monthTitleLabel, nextButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        prevButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)

        weekdayRow = UIStackView()
        weekdayRow.axis = .horizontal
        weekdayRow.distribution = .fillEqually
        weekdayRow.translatesAutoresizingMaskIntoConstraints = false
        let headers = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
        for t in headers {
            let lab = UILabel()
            lab.text = t
            lab.font = .systemFont(ofSize: 12, weight: .bold)
            lab.textColor = .secondaryLabel
            lab.textAlignment = .center
            weekdayRow.addArrangedSubview(lab)
        }

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CorrespondenceCalendarDayCell.self, forCellWithReuseIdentifier: CorrespondenceCalendarDayCell.reuseId)

        view.addSubview(header)
        view.addSubview(weekdayRow)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.widthAnchor.constraint(equalToConstant: 44),

            weekdayRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            weekdayRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            weekdayRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            collectionView.topAnchor.constraint(equalTo: weekdayRow.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        rebuildMonthGrid()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func prevMonth() {
        guard displayedMonthIndex > 0 else { return }
        displayedMonthIndex -= 1
        displayedMonth = availableMonthAnchors[displayedMonthIndex]
        rebuildMonthGrid()
    }

    @objc private func nextMonth() {
        guard displayedMonthIndex + 1 < availableMonthAnchors.count else { return }
        displayedMonthIndex += 1
        displayedMonth = availableMonthAnchors[displayedMonthIndex]
        rebuildMonthGrid()
    }

    private func rebuildMonthGrid() {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "LLLL yyyy"
        monthTitleLabel.text = fmt.string(from: displayedMonth).capitalized

        let cal = gridCalendar
        var comps = cal.dateComponents([.year, .month], from: displayedMonth)
        comps.day = 1
        guard let startOfMonth = cal.date(from: comps),
              let daysInMonth = cal.range(of: .day, in: .month, for: startOfMonth)?.count else {
            dayItems = []
            collectionView.reloadData()
            return
        }

        let weekdayOfFirst = cal.component(.weekday, from: startOfMonth)
        let leading = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        dayItems = []

        // Не показываем дни других месяцев
        for _ in 0..<leading {
            dayItems.append((nil, 0, false))
        }

        for day in 1...daysInMonth {
            if let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dayItems.append((d, day, true))
            }
        }

        while dayItems.count % 7 != 0 {
            dayItems.append((nil, 0, false))
        }

        while dayItems.count < 42 {
            dayItems.append((nil, 0, false))
        }

        collectionView.reloadData()
        updateMonthNavButtons()
    }

    private func buildAvailableMonths() {
        let cal = gridCalendar
        let sorted = isoDates.sorted()
        var set = Set<String>()
        var anchors: [Date] = []
        for iso in sorted {
            guard let d = Self.isoFmt.date(from: iso) else { continue }
            let comps = cal.dateComponents([.year, .month], from: d)
            let key = "\(comps.year ?? 0)-\(comps.month ?? 0)"
            if set.contains(key) { continue }
            set.insert(key)
            if let anchor = cal.date(from: comps) { anchors.append(anchor) }
        }
        availableMonthAnchors = anchors.sorted()
        displayedMonthIndex = 0
        updateMonthNavButtons()
    }

    private func setDisplayedMonth(containing date: Date) {
        let cal = gridCalendar
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let anchor = cal.date(from: comps) else { return }
        if let idx = availableMonthAnchors.firstIndex(where: { cal.isDate($0, equalTo: anchor, toGranularity: .month) }) {
            displayedMonthIndex = idx
            displayedMonth = availableMonthAnchors[idx]
        } else {
            displayedMonth = anchor
        }
        updateMonthNavButtons()
    }

    private func updateMonthNavButtons() {
        prevButton.isEnabled = displayedMonthIndex > 0
        nextButton.isEnabled = displayedMonthIndex + 1 < availableMonthAnchors.count
        prevButton.alpha = prevButton.isEnabled ? 1.0 : 0.35
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.35
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dayItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CorrespondenceCalendarDayCell.reuseId, for: indexPath) as! CorrespondenceCalendarDayCell
        guard indexPath.item < dayItems.count else {
            cell.apply(day: 0, isCurrentMonth: false, isSunday: false, hasLessons: false, isSelected: false, isSelectable: false, isToday: false)
            return cell
        }
        let item = dayItems[indexPath.item]
        guard let d = item.date else {
            cell.apply(day: 0, isCurrentMonth: false, isSunday: false, hasLessons: false, isSelected: false, isSelectable: false, isToday: false)
            return cell
        }
        let iso = Self.isoFmt.string(from: d)
        let has = isoDates.contains(iso)
        let sel = (iso == selectedISO)
        let sun = gridCalendar.component(.weekday, from: d) == 1
        // Выбираем любые дни внутри месяца: если на этот день нет пар — покажем выходной (плейсхолдером в таблице).
        let isToday = gridCalendar.isDateInToday(d)
        cell.apply(day: item.day, isCurrentMonth: item.inMonth, isSunday: sun, hasLessons: has, isSelected: sel, isSelectable: item.inMonth, isToday: isToday)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < dayItems.count,
              let d = dayItems[indexPath.item].date,
              dayItems[indexPath.item].inMonth else { return }

        let iso = Self.isoFmt.string(from: d)
        onPick?(iso)
        dismiss(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = floor((collectionView.bounds.width) / 7)
        return CGSize(width: w, height: 58)
    }
}
