//
//  CorrespondenceScheduleHeaderView.swift
//  test111
//
//  Верхняя панель расписания сессии (заочное): дата, горизонтальная прокрутка дней, кнопка календаря.
//

import UIKit

protocol CorrespondenceScheduleHeaderViewDelegate: AnyObject {
    func correspondenceScheduleHeader(_ view: CorrespondenceScheduleHeaderView, didSelectCalendarDay date: Date)
    func correspondenceScheduleHeaderDidTapCalendarButton(_ view: CorrespondenceScheduleHeaderView)
}

// MARK: - Ячейка дня (не UIButton — иначе дата и индикаторы обрезаются и «теряются»)

private final class CorrespondenceDayChip: UIControl {

    private let abbrLabel = UILabel()
    private let numberLabel = UILabel()
    private let dotView = UIView()

    private var isSundayChip = false
    private var hasScheduleData = false
    private var chipSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true

        abbrLabel.translatesAutoresizingMaskIntoConstraints = false
        abbrLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        abbrLabel.textAlignment = .center

        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 17, weight: .bold)
        numberLabel.textAlignment = .center

        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.layer.cornerRadius = 2.5
        dotView.backgroundColor = UIColor.systemGreen

        addSubview(abbrLabel)
        addSubview(numberLabel)
        addSubview(dotView)

        isAccessibilityElement = true

        NSLayoutConstraint.activate([
            abbrLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            abbrLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            abbrLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            numberLabel.topAnchor.constraint(equalTo: abbrLabel.bottomAnchor, constant: 2),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            numberLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            dotView.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 6),
            dotView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 5),
            dotView.heightAnchor.constraint(equalToConstant: 5),
            dotView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ])

    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(abbr: String, dayNumber: String, isSunday: Bool, isSelected: Bool, hasData: Bool, isToday: Bool) {
        isSundayChip = isSunday
        hasScheduleData = hasData
        chipSelected = isSelected

        abbrLabel.text = abbr
        numberLabel.text = dayNumber
        // Зелёную точку показываем только на "сегодня" (реальная дата телефона)
        dotView.isHidden = !isToday

        accessibilityLabel = "\(abbr), \(dayNumber)"
        refreshColors()
        applyBackground()
    }

    private func refreshColors() {
        if isSundayChip {
            abbrLabel.textColor = .systemRed
            numberLabel.textColor = .systemRed
        } else {
            abbrLabel.textColor = .secondaryLabel
            numberLabel.textColor = .label
        }
    }

    private func applyBackground() {
        if chipSelected {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.22)
            layer.borderWidth = 1.5
            layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.55).cgColor
        } else if hasScheduleData {
            // Дни с парами — чуть более заметный серый
            backgroundColor = UIColor.secondarySystemFill
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        } else {
            // Будние дни без пар и выходные должны выглядеть так же “серо”, как остальные
            backgroundColor = UIColor.tertiarySystemFill
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                if self.isHighlighted && !self.chipSelected {
                    self.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
                    self.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
                } else {
                    self.transform = .identity
                    self.applyBackground()
                }
            }
        }
    }
}

// MARK: - Панель

final class CorrespondenceScheduleHeaderView: UIView {

    weak var delegate: CorrespondenceScheduleHeaderViewDelegate?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let calendarButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let daysStack = UIStackView()

    private var scrollDayDates: [Date] = []
    private var dayChips: [CorrespondenceDayChip] = []
    private var datesWithData = Set<String>()
    private var selectedDate: Date = Date()
    private var todayDate: Date = Date()
    private var shouldCenterOnNextConfigure: Bool = true
    private var lastRangeKey: String?

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let ruCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ru_RU")
        c.firstWeekday = 2
        return c
    }()

    private let chipWidth: CGFloat = 56
    private let chipHeight: CGFloat = 78

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        calendarButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.14)
        calendarButton.layer.cornerRadius = 12
        calendarButton.clipsToBounds = true
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let calImg = UIImage(systemName: "calendar", withConfiguration: cfg)
        calendarButton.setImage(calImg, for: .normal)
        calendarButton.tintColor = .systemBlue
        calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        calendarButton.accessibilityLabel = "Календарь"

        let textColumn = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textColumn.axis = .vertical
        textColumn.spacing = 2
        textColumn.alignment = .leading

        let headerRow = UIStackView(arrangedSubviews: [textColumn, calendarButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 12
        headerRow.distribution = .fill
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true

        daysStack.axis = .horizontal
        daysStack.spacing = 10
        daysStack.alignment = .center
        daysStack.distribution = .fill
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(daysStack)

        NSLayoutConstraint.activate([
            daysStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            daysStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            daysStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            daysStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            daysStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        let root = UIStackView(arrangedSubviews: [headerRow, scrollView])
        root.axis = .vertical
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor),
            calendarButton.widthAnchor.constraint(equalToConstant: 48),
            calendarButton.heightAnchor.constraint(equalToConstant: 48),
            scrollView.heightAnchor.constraint(equalToConstant: chipHeight)
        ])
    }

    @objc private func calendarTapped() {
        delegate?.correspondenceScheduleHeaderDidTapCalendarButton(self)
    }

    @objc private func chipTapped(_ sender: CorrespondenceDayChip) {
        let idx = sender.tag
        guard idx >= 0, idx < scrollDayDates.count else { return }
        let day = scrollDayDates[idx]
        selectedDate = day
        shouldCenterOnNextConfigure = false

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            for (i, chip) in self.dayChips.enumerated() {
                let d = self.scrollDayDates[i]
                let iso = Self.isoFormatter.string(from: d)
                let isSel = Self.ruCalendar.isDate(d, inSameDayAs: day)
                let has = self.datesWithData.contains(iso)
                let sun = Self.ruCalendar.component(.weekday, from: d) == 1
                let isToday = Self.ruCalendar.isDate(d, inSameDayAs: self.todayDate)
                let abbrFmt = DateFormatter()
                abbrFmt.locale = Locale(identifier: "ru_RU")
                abbrFmt.dateFormat = "EE"
                let abbr = abbrFmt.string(from: d).lowercased()
                let dayNum = String(Self.ruCalendar.component(.day, from: d))
                chip.configure(abbr: abbr, dayNumber: dayNum, isSunday: sun, isSelected: isSel, hasData: has, isToday: isToday)
            }
        }

        delegate?.correspondenceScheduleHeader(self, didSelectCalendarDay: day)
    }

    func configure(selectedDate: Date, datesWithData: Set<String>) {
        self.selectedDate = selectedDate
        self.datesWithData = datesWithData
        self.todayDate = Date()

        let cal = Self.ruCalendar

        let titleFmt = DateFormatter()
        titleFmt.locale = Locale(identifier: "ru_RU")
        titleFmt.dateFormat = "EEEE"
        var dayTitle = titleFmt.string(from: selectedDate)
        if let first = dayTitle.first {
            dayTitle = String(first).uppercased() + dayTitle.dropFirst()
        }
        titleLabel.text = dayTitle

        let subFmt = DateFormatter()
        subFmt.locale = Locale(identifier: "ru_RU")
        subFmt.dateFormat = "d MMMM"
        subtitleLabel.text = subFmt.string(from: selectedDate)

        let sortedISO = datesWithData.sorted()
        let daysToShow: [Date]
        if sortedISO.isEmpty {
            guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: selectedDate) else { return }
            var d = weekInterval.start
            var arr: [Date] = []
            for _ in 0..<7 {
                arr.append(d)
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
            daysToShow = arr
        } else {
            guard let firstD = Self.isoFormatter.date(from: sortedISO.first!),
                  let lastD = Self.isoFormatter.date(from: sortedISO.last!) else { return }
            var d = cal.startOfDay(for: firstD)
            let end = cal.startOfDay(for: lastD)
            var arr: [Date] = []
            while d <= end {
                arr.append(d)
                guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
                d = next
            }
            daysToShow = arr
        }

        let rangeKey: String = {
            if let f = daysToShow.first, let l = daysToShow.last {
                return "\(Self.isoFormatter.string(from: f))|\(Self.isoFormatter.string(from: l))"
            }
            return ""
        }()

        // Если диапазон дат не изменился — не пересоздаём чипы (чтобы анимация была плавной)
        if rangeKey == lastRangeKey, dayChips.count == daysToShow.count {
            scrollDayDates = daysToShow
            let abbrFmt = DateFormatter()
            abbrFmt.locale = Locale(identifier: "ru_RU")
            abbrFmt.dateFormat = "EE"
            UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                for (idx, day) in daysToShow.enumerated() {
                    let iso = Self.isoFormatter.string(from: day)
                    let wd = cal.component(.weekday, from: day)
                    let isSunday = (wd == 1)
                    let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
                    let hasData = datesWithData.contains(iso)
                    let isToday = cal.isDate(day, inSameDayAs: self.todayDate)
                    let abbr = abbrFmt.string(from: day).lowercased()
                    let dayNum = String(cal.component(.day, from: day))
                    self.dayChips[idx].configure(abbr: abbr, dayNumber: dayNum, isSunday: isSunday, isSelected: isSelected, hasData: hasData, isToday: isToday)
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.scrollSelectedIntoView(animated: true)
            }
            return
        }

        lastRangeKey = rangeKey
        scrollDayDates = daysToShow
        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        dayChips.removeAll()

        let abbrFmt = DateFormatter()
        abbrFmt.locale = Locale(identifier: "ru_RU")
        abbrFmt.dateFormat = "EE"

        for (idx, day) in daysToShow.enumerated() {
            let iso = Self.isoFormatter.string(from: day)
            let wd = cal.component(.weekday, from: day)
            let isSunday = (wd == 1)
            let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
            let hasData = datesWithData.contains(iso)
            let isToday = cal.isDate(day, inSameDayAs: todayDate)

            let abbr = abbrFmt.string(from: day).lowercased()
            let dayNum = String(cal.component(.day, from: day))

            let chip = CorrespondenceDayChip()
            chip.tag = idx
            chip.configure(abbr: abbr, dayNumber: dayNum, isSunday: isSunday, isSelected: isSelected, hasData: hasData, isToday: isToday)
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chip.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chip.widthAnchor.constraint(equalToConstant: chipWidth),
                chip.heightAnchor.constraint(equalToConstant: chipHeight)
            ])
            daysStack.addArrangedSubview(chip)
            dayChips.append(chip)
        }

        DispatchQueue.main.async { [weak self] in
            self?.scrollSelectedIntoView(animated: self?.shouldCenterOnNextConfigure ?? true)
            self?.shouldCenterOnNextConfigure = true
        }
    }

    private func scrollSelectedIntoView(animated: Bool) {
        guard let idx = scrollDayDates.firstIndex(where: { Self.ruCalendar.isDate($0, inSameDayAs: selectedDate) }),
              idx < dayChips.count else { return }
        let chip = dayChips[idx]
        scrollView.layoutIfNeeded()
        let boundsW = scrollView.bounds.width
        guard boundsW > 10 else { return }

        // Центрируем выбранный чип внутри скролла
        let maxOffsetX = max(0, scrollView.contentSize.width - boundsW)
        let chipCenterX = chip.convert(CGPoint(x: chip.bounds.midX, y: chip.bounds.midY), to: scrollView).x
        var offsetX = chipCenterX - boundsW / 2
        offsetX = min(max(offsetX, 0), maxOffsetX)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
    }
}
