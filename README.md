## Моя Академия — расписание для студентов и преподавателей

> Удобное iOS‑приложение, которое избавляет от PDF‑ок, скринов и бесконечного поиска актуального расписания.

**Моя Академия** позволяет быстро выбрать свою группу или перейти в режим преподавателя, смотреть расписание на день или неделю, получать уведомления о парах и выносить расписание на главный экран через виджеты.

---

### Основные возможности 📅

- **Выбор группы и фильтров**
  - выбор курса и уровня образования («СПО», «Бакалавриат», «Магистратура» и др.);
  - поиск и выбор учебной группы через `ViewController` (экран «Выбор группы»);
  - сохранение выбранной группы в `UserDefaults` и автоматическое восстановление при следующем запуске;
  - отдельный **режим преподавателя**, переключаемый в настройках.

- **Просмотр расписания**
  - экран `TwoViewController` отображает расписание:
    - только на **сегодня** или сразу на **всю неделю** (опция в настройках),
    - с разбивкой по дням недели и парам;
  - загрузка и формирование расписания с сервера через `ScheduleRepository` / `ScheduleAPIClient` и модели `DaySchedule` / `Lesson`;
  - поддержка «выходных» дней с дружелюбным сообщением «Сегодня выходной. Наслаждайтесь отдыхом!».

- **Уведомления о парах 🔔**
  - локальные уведомления через `UserNotifications` и `NotificationManager`;
  - настройка времени напоминания **за N минут до пары** (слайдер в настройках);
  - включение/отключение уведомлений в `SettingsViewController`;
  - уведомления планируются только в **режиме студента**, чтобы не мешать преподавателям.

- **Виджеты расписания 🧩**
  - расширение `ScheduleWidgetExtension` с виджетами для главного экрана iOS;
  - виджет показывает ближайшие пары / расписание группы;
  - синхронизация данных через общий `ScheduleStorage` и App Group;
  - отдельный экран `WidgetInfoViewController` с описанием новых виджетов и примером их внешнего вида.

- **Настройки приложения ⚙️**
  - экран `SettingsViewController` со скроллируемыми карточками‑настройками:
    - **Показать всю неделю** — переключение режима отображения расписания;
    - **Убрать выбор группы** — управление видимостью навигации;
    - **Сменить неделю** — ручной выбор первой/второй недели;
    - **Режим приложения** — «Студент» / «Препод.»;
    - **Уведомления о парах** и время напоминаний;
    - **Синхронизировать неделю** с сервером (автоопределение текущей недели);
    - выбор **темы**: светлая, тёмная или системная (`ThemeManager`);
    - раздел **«О приложении»**;
  - внизу — контакт разработчика в Telegram (`@tsep1lov`).

- **Онбординг 👋**
  - онбординг‑экраны с анимацией и страницами знакомства с приложением;
  - хранение флага `hasSeenOnboarding` в `UserDefaults`, чтобы онбординг показывался только один раз.

- **Реклама и аналитика 📊**
  - интеграция **YandexMobileAds** (адаптивный inline‑баннер в `ViewController`);
  - аналитика событий через **MyTrackerSDK** (отслеживаются выбор курса, группы, открытие расписания, изменение настроек и т.д.).

---

### Технический стек 🛠

- **Платформа**: iOS 13.0+ (основное приложение), iOS 17.6+ (виджет расписания)  
- **Язык**: Swift 5.0  
- **UI‑фреймворк**: UIKit, Auto Layout (кодом)  
- **Виджеты**: WidgetKit (`ScheduleWidgetExtension`)  
- **Архитектура**: модульное MVC / разбивка по экранам и фичам (`OneView`, `TwoView`, `Settings`, `TabBar` и др.)  
- **Сетевой слой**: собственный REST‑клиент `ScheduleAPIClient` + репозиторий `ScheduleRepository` (кэш в памяти и в `UserDefaults`)  
- **Парсинг HTML**: SwiftSoup  
- **Локальное хранилище**: `UserDefaults`, App Group (`ScheduleStorage`)  
- **Уведомления**: UserNotifications (`UNUserNotificationCenter`)  
- **Анимации**: Lottie (онбординг, состояния ошибок и пр.)  
- **Реклама**: YandexMobileAds (баннеры и инстрим‑реклама)  
- **Аналитика**: MyTrackerSDK  
- **Remote Config**: RSRemoteConfig (удалённое управление включением рекламы, токеном и URL сервера расписания)  

---

### Окружение и версии 🔧

**Инструменты сборки**

- **Xcode**: 16.0+ (проект создан и последний раз мигрирован в Xcode 16, `LastUpgradeCheck = 1600`)  
- **iOS SDK**: актуальный SDK из поставки Xcode 16 (проект собирался с iOS 18.0 SDK)  
- **Целевые версии iOS (Deployment Target)**:
  - **основное приложение**: iOS **13.0** (`IPHONEOS_DEPLOYMENT_TARGET = 13.0`);
  - **виджет расписания**: iOS **17.6** (`IPHONEOS_DEPLOYMENT_TARGET = 17.6`).
- **Swift compiler**: Swift **5.0** (`SWIFT_VERSION = 5.0`)  
- **C/C++ компилятор**:
  - C: стандарт **gnu17** (`GCC_C_LANGUAGE_STANDARD = gnu17`);
  - C++: стандарт **gnu++20** (`CLANG_CXX_LANGUAGE_STANDARD = "gnu++20"`).

**Swift Package Manager — зависимости и версии**  
(зафиксированы в `My Сollege.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`)

- **Lottie (`lottie-ios`)**: `4.5.0`  
- **SwiftSoup (`swiftsoup`)**: `2.7.6`  
- **Yandex Ads SDK (`yandex-ads-sdk-ios`, продукты `YandexMobileAds`, `YandexMobileAdsInstream`)**: `7.10.2`  
- **MyTrackerSDK (`mytracker-ios-spm`)**: `3.4.2`  
- **RSRemoteConfig (`rustore-remote-config-swift`)**: `1.0.0`  

Дополнительные транзитивные зависимости (например, `swift-markdown`, `swift-cmark`, `KSCrash`, `vgsl`, `appmetrica-sdk-ios`, `divkit-ios`) подтягиваются автоматически через Swift Package Manager и не требуют ручной настройки.

---

### Архитектура приложения 🧱

Проект имеет стандартную структуру iOS‑приложения на UIKit. Код разделён по директориям (feature‑sliced), отвечающим за пользовательский интерфейс, бизнес‑логику, работу с сетью и виджет.

```text
└── ./
    ├── My Сollege.xcodeproj           # Xcode‑проект и настройки сборки
    ├── README.md
    ├── ScheduleWidgetExtension        # таргет виджета расписания (WidgetKit)
    │   ├── Assets.xcassets
    │   ├── DaySchedule.swift          # модель дня расписания для виджета
    │   ├── Lesson.swift               # модель пары для виджета
    │   ├── ScheduleStorage.swift      # общее хранилище (App Group)
    │   ├── ScheduleWidgetExtension.swift
    │   └── ScheduleWidgetExtensionBundle.swift
    └── test111                        # код основного iOS‑приложения
        ├── AppDelegate.swift          # точка входа приложения
        ├── SceneDelegate.swift        # управление сценами (iOS 13+)
        ├── Assetss                    # ресурсы и ассеты (иконки, лонч‑экран, анимации)
        ├── OneView                    # выбор курса/группы/преподавателя
        │   ├── ViewController.swift   # экран выбора группы
        │   ├── TeacherViewController.swift  # экран выбора преподавателя
        │   ├── GroupFetcher.swift     # фасад для запросов по группам
        │   ├── GroupParser.swift      # парсер групп
        │   ├── TeacherParser.swift    # парсер преподавателей
        │   ├── TeacherParser*.swift   # вспомогательные тесты/утилиты парсинга
        │   └── ButtonFactory.swift    # фабрика UI‑кнопок и карточек
        ├── TwoView                    # экран расписания
        │   ├── TwoViewController.swift
        │   ├── LessonTableViewCell.swift
        │   ├── DaySchedule.swift      # доменная модель дня расписания
        │   └── Lesson.swift           # доменная модель пары
        ├── Settings                   # экран настроек и "О приложении"
        │   ├── SettingsViewController.swift
        │   └── AboutViewController.swift
        ├── Onbording                  # онбординг и анимации первого запуска
        │   ├── Onboording.swift
        │   ├── AnimationViewController.swift
        │   └── ModeSwitchAnimationViewController.swift
        ├── Splash                     # стартовый экран
        │   └── SplashViewController.swift
        ├── TabBar                     # корневой контейнер с вкладками
        │   └── MainViewController.swift
        ├── ScheduleWidget             # вспомогательный код для виджета внутри приложения
        ├── Base.lproj / Info.plist    # сториборды лонч‑экрана и настройки бандла
        ├── AdManager.swift            # работа с рекламой (YandexMobileAds)
        ├── NotificationManager.swift  # локальные уведомления о парах
        ├── ScheduleStorage.swift      # общее хранилище расписания (приложение + виджет)
        ├── ThemeManager.swift         # управление темой оформления
        ├── RemoteConfigService.swift  # RSRemoteConfig / RuStore Remote Config
        ├── AppUpdateChecker.swift     # проверка доступности обновлений
        └── WidgetInfoViewController.swift  # экран с информацией о виджетах
```

Логически код разделён на:
- **слой презентации (UI)** — контроллеры экранов (`OneView`, `TwoView`, `Settings`, `Onbording`, `Splash`, `TabBar`, `WidgetInfoViewController`) и ячейки/вью;
- **слой данных** — `ScheduleAPIClient`, `ScheduleRepository`, модели `DaySchedule` / `Lesson` и структуры ответов API;
- **сервисы и инфраструктуру** — уведомления (`NotificationManager`), реклама (`AdManager`), удалённая конфигурация (`RemoteConfigService`), хранилище (`ScheduleStorage`), тема (`ThemeManager`), проверка обновлений (`AppUpdateChecker`);
- **виджет** — отдельный таргет `ScheduleWidgetExtension` на WidgetKit, переиспользующий общие модели и хранилище.

---

### Инструкция по сборке и запуску 🧪

1. **Установите инструменты**
   - Xcode **16.0+** (из App Store или с сайта Apple).
   - Убедитесь, что установлен iOS SDK (идёт в комплекте с Xcode).

2. **Клонируйте репозиторий**
   - Склонируйте проект в удобную директорию:
     - `git clone <URL-репозитория>`

3. **Откройте проект**
   - Откройте файл `My Сollege.xcodeproj` в Xcode.  
   - Дождитесь, пока **Swift Package Manager** загрузит и проиндексирует зависимости (Lottie, SwiftSoup, YandexMobileAds, MyTrackerSDK, RSRemoteConfig и др.).

4. **Настройте подпись (Signing) при необходимости**
   - В разделе **Signing & Capabilities** для таргета `My Сollege` выберите свою команду разработчика (Team).
   - При необходимости измените `Bundle Identifier`, чтобы он не конфликтовал с уже установленным приложением.

5. **Выберите схему и устройство**
   - Схема: **`My Сollege`** (основное приложение).  
   - Устройство:
     - симулятор iPhone с iOS 13+ или
     - реальное устройство с установленным профилем разработчика.

6. **Соберите и запустите**
   - Нажмите **`Cmd + R`** или кнопку **Run** в Xcode.
   - После первого запуска выберите группу/режим и разрешите отправку уведомлений (если нужно).

7. **Сборка и тестирование виджета**
   - Выберите схему **`ScheduleWidgetExtensionExtension`**.
   - Устройство: iPhone с iOS **17.6+**.
   - Соберите таргет; виджет появится в галерее виджетов после установки приложения.

Приложение будет корректно работать даже без активного RSRemoteConfig: в этом случае используются дефолтные/закешированные значения (реклама включена, сервер расписания берётся из локальных настроек).

---

### Скриншоты

<img width="1290" height="2796" alt="Frame 2" src="https://github.com/user-attachments/assets/a47d0730-78a5-404b-92ae-d5099faf004d" />
<img width="1290" height="2796" alt="Frame 3" src="https://github.com/user-attachments/assets/f8243b2d-1056-46e3-aeb8-fa12a989df78" />
<img width="1290" height="2796" alt="Frame 4" src="https://github.com/user-attachments/assets/34ec33c2-f938-4565-863f-7f023a45f6fa" />

---

### Обратная связь

- **Разработчик**: @tsep1lov (Telegram)  
- Буду рад баг‑репортам, предложениям по улучшению и идеям для новых функций.

© Исходный код защищен авторским правом в Федеральной службе по интеллектуальной собственности Российской Федерации
