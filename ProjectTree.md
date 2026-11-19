# ProjectTree — структура проекта Reps Counter

> Живая карта проекта: что реализовано, как и где лежит. Обновляется вместе с кодом (правила — в `CLAUDE.md`, раздел 10).
> Статусы: ✅ реализовано · 🚧 в работе · 📋 запланировано (ещё нет в коде)

**Последнее обновление:** 2026-11-19 — «Этап UI», шаг 1: онбординг — вводные слайды 1–2, экран ника (с ошибкой «ник занят»), выбор аватара и «Your Profile Is Ready!» по макету Figma, остальные шаги заглушками; прогресс-бар и кнопка «назад»; токены цвета и кнопки сняты с макета; приложение закреплено в светлой теме.

**Дизайн:** [Figma — Vibecode-test](https://www.figma.com/design/sdECikkyovjvnloQ6SqFqo/Vibecode-test) (источник истины для экранов). Доступа через Figma MCP пока нет. Экраны верстаются по PNG-экспортам фреймов: значения, снятые с макета, помечены в коде `FIGMA`, придуманные — `PROVISIONAL`.

**План:** [`Roadmap.md`](Roadmap.md). Сейчас идёт «Этап UI» — вёрстка всех экранов на тестовых данных.

---

## 1. Дерево репозитория

```text
RepsCounter-Duel/                      # корень git-репозитория
├── CLAUDE.md                          # ✅ спецификация продукта и правила разработки (главный источник требований)
├── ProjectTree.md                     # ✅ этот файл — карта структуры проекта
├── Roadmap.md                         # ✅ поэтапный план разработки и решения по макету
├── .gitignore                         # ✅ исключает .DS_Store, xcuserdata, DerivedData, .build, .env
├── Packages/
│   └── RepsCounterKit/                # ✅ локальный Swift-пакет (iOS 18+, macOS 15 только для `swift test`)
│       ├── Package.swift              # ✅ продукты DesignSystem / ExerciseAnalyzer / Backend; supabase-swift закреплён на 2.55.7
│       ├── Package.resolved           # ✅ зафиксированные версии зависимостей
│       ├── Sources/
│       │   ├── DesignSystem/          # ✅ общий UI
│       │   │   ├── Tokens.swift       # ✅ отступы, радиусы, цвета, шрифты; градиентный фон экранов (часть значений с макета)
│       │   │   ├── Glass.swift        # ✅ rcGlass / rcProminentGlass: Liquid Glass на iOS 26+, материал на iOS 18–25
│       │   │   ├── Card.swift         # ✅ карточка, заголовок секции, плитка статистики, эмодзи-аватар
│       │   │   ├── Buttons.swift      # ✅ кнопки: .rcPrimaryLarge (64 pt, градиент; неактивная — серая) / .rcPrimary / .rcSecondary
│       │   │   ├── RCPageIndicator.swift      # ✅ точки страниц (активная — синяя капсула)
│       │   │   ├── RCViewfinderCorners.swift  # ✅ уголки «видоискателя» вокруг картинки / превью камеры
│       │   │   ├── RCProgressBar.swift    # ✅ тонкий прогресс-бар онбординга (128 × 6 pt)
│       │   │   ├── RCBackButton.swift     # ✅ круглая стеклянная кнопка «назад»
│       │   │   ├── RCTextField.swift      # ✅ .rcCapsuleField() — белое поле-капсула 57 pt
│       │   │   └── RCTabBar.swift     # ✅ нижняя панель: капсула с табами + отдельная круглая кнопка справа
│       │   ├── ExerciseAnalyzer/
│       │   │   └── Exercise.swift     # ✅ упражнения: squats, push-ups (машины состояний — этап 3)
│       │   └── Backend/
│       │       ├── Models/            # ✅ PlayerProfile, PlayerStats, DailyDuelReps, DuelDuration, DuelSummary, LeaderboardEntry
│       │       ├── ProfileRegistration.swift  # ✅ протокол регистрации профиля + тестовый сервис (admin → «занят», offline → нет сети)
│       │       ├── NicknameAvailability.swift # ✅ протокол проверки ника + NicknameRules + тестовый сервис (занят только admin; `offline` — имитация нет сети)
│       │       ├── LeaderboardRanking.swift   # ✅ сортировка рейтинга: равные суммы — одно место, стабильная вторичная сортировка
│       │       ├── BackendConfiguration.swift # ✅ URL проекта + anon key → SupabaseClient (проект ещё не создан)
│       │       └── MockData.swift     # ✅ тестовые данные для превью и каркаса (не реальные пользователи)
│       └── Tests/
│           ├── ExerciseAnalyzerTests/ # ✅ тесты Exercise
│           └── BackendTests/          # ✅ тесты рейтинга (ничьи, детерминизм), исхода дуэли и проверки ника
└── RepsCounterDuel/                   # папка Xcode-проекта
    ├── RepsCounterDuel.xcodeproj      # ✅ проект Xcode; подключает локальный пакет (../Packages/RepsCounterKit)
    │   ├── project.xcworkspace/xcshareddata/swiftpm/Package.resolved  # ✅ версии пакетов для Xcode
    │   └── xcshareddata/xcschemes/
    │       └── RepsCounterDuel.xcscheme   # ✅ общая схема (для сборки из CLI/CI)
    └── RepsCounterDuel/               # ✅ исходники приложения (синхронизируемая папка: новые файлы подхватываются автоматически)
        ├── App/
        │   ├── RepsCounter_DuelApp.swift  # ✅ точка входа (@main), показывает RootView
        │   ├── AppTab.swift           # ✅ табы Home / Rating / Profile (Duel — не таб, а отдельная кнопка)
        │   └── RootView.swift         # ✅ RootView: онбординг до завершения, затем MainTabsView (текущий таб + RCTabBar, кнопка Duel → настройка дуэли)
        ├── Features/
        │   ├── Onboarding/
        │   │   ├── OnboardingStep.swift   # ✅ шаги онбординга по порядку макета, значение прогресс-бара для каждого шага
        │   │   ├── OnboardingTitle.swift  # ✅ двухстрочный заголовок (чёрная + синяя строка)
        │   │   ├── OnboardingProgressHeader.swift  # ✅ «назад» слева + прогресс-бар по центру
        │   │   ├── AvatarEmoji.swift      # ✅ список из 21 эмодзи-мордочки (первая выбрана по умолчанию)
        │   │   ├── OnboardingAvatarCircle.swift # ✅ большой эмодзи-аватар в голубом круге с белым свечением
        │   │   ├── ProfileReadyStepView.swift   # ✅ «Your Profile Is Ready!»: аватар + ник, «Great !» регистрирует профиль (тестовый сервис)
        │   │   ├── AvatarStepView.swift   # ✅ выбор аватара: большой превью-кружок + прокручиваемая сетка 3 в ряд, выбор нельзя снять
        │   │   ├── NicknameStepView.swift # ✅ ввод ника: клавиатура сразу, Continue активна с первого символа, проверка ника, ошибка «занят» / «нет сети»
        │   │   ├── OnboardingFlowView.swift   # ✅ переключение шагов вперёд/назад, общий фон и шапка с прогрессом; шаги без макета — заглушки (DEBUG: `-debugOnboardingStep N`)
        │   │   ├── IntroSlide.swift   # ✅ содержимое слайдов: картинка в уголках (слайд 1) или отдельная картинка (слайд 2)
        │   │   ├── IntroSlideView.swift   # ✅ слайд: заголовок, подзаголовок, картинка в уголках, карточка подсказок
        │   │   ├── IntroPagerView.swift   # ✅ листание слайдов + точки + Continue (DEBUG: `-debugIntroPage N`)
        │   │   └── OnboardingPlaceholderStepView.swift  # 🚧 временный экран для шагов без макета
        │   ├── Home/
        │   │   ├── HomeView.swift     # ✅ статистика, график, рекорд + Start training, Recent Duels / Challenge, место в рейтинге (тестовые данные)
        │   │   └── DailyDuelRepsChart.swift  # ✅ столбчатый график «день → повторения в дуэлях» (Swift Charts)
        │   ├── Rating/
        │   │   └── RatingView.swift   # ✅ переключатель Global / Friends, одна общая сумма (тестовые данные)
        │   ├── Profile/
        │   │   └── ProfileView.swift  # ✅ эмодзи, ник, компактная статистика, топ-3 друзей, See all / Add friend (кнопки пока пустые)
        │   └── Duel/
        │       └── DuelSetupPlaceholderView.swift  # 🚧 выбор упражнения и 30/60/90 с; приглашение — этап 4
        └── Assets.xcassets/           # ✅ AccentColor = #2A8DFD; Onboarding/OnboardingPushup — фигура с отжиманием (фон вырезан), Onboarding/OnboardingSetupPath — иконка-планшет; иконка приложения пока пустая
```

## 2. Настройки проекта

| Параметр | Значение | Где задаётся |
|---|---|---|
| Таргет / схема | `RepsCounterDuel` | `RepsCounterDuel.xcodeproj` |
| Имя на экране | «Reps Counter» | `INFOPLIST_KEY_CFBundleDisplayName` в build settings таргета |
| Ориентация | только портрет | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` |
| Язык | только английский | — |
| Bundle ID | `com.RepsCounter-Duel` (не менять без согласования) | build settings таргета |
| Минимальная iOS | 18.0 | `IPHONEOS_DEPLOYMENT_TARGET` (проект и таргет) |
| Устройства | только iPhone | `TARGETED_DEVICE_FAMILY = 1` |
| Swift | 6, `MainActor` по умолчанию, approachable concurrency | build settings таргета |
| Тема | только светлая (`INFOPLIST_KEY_UIUserInterfaceStyle = Light`), макет только светлый | build settings таргета |
| Info.plist | генерируется Xcode (`GENERATE_INFOPLIST_FILE`), ключи — через `INFOPLIST_KEY_*` | build settings таргета |
| Зависимости | `supabase-swift` 2.55.7 (exact) через локальный пакет | `Packages/RepsCounterKit/Package.swift` |
| Проверенная сборка | собирается для симуляторов iOS 18.0 и iOS 26.1 (iPhone 16); экраны онбординга с аватаром визуально проверены на iOS 18.0. На симуляторе iOS 26.3 не отображаются эмодзи (ошибка Apple, исправлена в 26.4) | — |

## 3. Модули и функциональность

| Модуль | Статус | Где лежит | Что делает |
|---|---|---|---|
| `DesignSystem` | 🚧 | пакет `RepsCounterKit` | токены (временные), карточки, кнопки, Liquid Glass + фолбэк, таббар; ждёт значений из Figma |
| `PoseDetection` | 📋 | локальный пакет | Vision: точки тела и их уверенность |
| `ExerciseAnalyzer` | 🚧 | пакет `RepsCounterKit` | пока только тип `Exercise`; машины состояний — этап 3 |
| `Backend` | 🚧 | пакет `RepsCounterKit` | модели, правила рейтинга, тестовые данные, фабрика SupabaseClient; репозитории и Realtime — дальше |
| `CameraService` | 📋 | приложение | захват кадров, разрешения, прерывания, ориентация |
| `Auth` | 📋 | приложение | анонимная сессия Supabase, привязка ника к ID; после переустановки — новый профиль, восстановления нет |
| `Onboarding` | 🚧 | `Features/Onboarding` | вводные слайды 1–2, экран ника и выбор аватара и «Profile Is Ready» по макету; остальные шаги — заглушки; регистрация и разрешение камеры — этап 1 |
| `Profile` | 🚧 | `Features/Profile` | экран на тестовых данных; друзья и переходы — этап 2 |
| `Home` / `Statistics` | 🚧 | `Features/Home` | экран на тестовых данных; реальные данные — этап 5 |
| `Training` | 📋 | приложение | одиночная тренировка, обновляет рекорд, хранение в SwiftData |
| `Friends` | 📋 | приложение | поиск по точному нику, карточка игрока, заявки (всплывающий экран + плашка на всех табах), приглашения в дуэль |
| `Duel` | 🚧 | `Features/Duel` | только временный экран настройки; лобби, отсчёт, матч, результаты — этап 4 |
| `Ranking` | 🚧 | `Features/Rating` + `Backend/LeaderboardRanking` | один рейтинг по общей сумме, Global / Friends, на тестовых данных |

## 4. Ключевые сценарии: где искать код

- **Запуск приложения:** `App/RepsCounter_DuelApp.swift` → `App/RootView.swift` → если онбординг не пройден (`@AppStorage("onboardingCompleted")`) — `OnboardingFlowView`, иначе `MainTabsView`. Сбросить в симуляторе: запуск с аргументом `-onboardingCompleted NO`.
- **Онбординг:** `OnboardingFlowView` → `IntroPagerView` (слайды `IntroSlide`) → `NicknameStepView` → `NicknameAvailabilityChecking` (сейчас `MockNicknameAvailabilityService`, на этапе 1 — сервер) → `AvatarStepView` (`AvatarEmoji`) → `ProfileReadyStepView` → `ProfileRegistering` (сейчас `MockProfileRegistrationService`; ник заняли за это время → назад на шаг ника) → шаги-заглушки → `onFinish` ставит флаг.
- **Нижняя навигация:** `RootView` → `DesignSystem/RCTabBar` (табы из `AppTab`) → кнопка Duel → `Features/Duel/DuelSetupPlaceholderView`.
- **Данные на экранах:** все экраны берут `Backend/MockData` (параметры по умолчанию во вью) — сервер подключается на этапах 1–5.
- **Рейтинг:** `RatingView` → `MockData.leaderboard(scope)` → `LeaderboardRanking.rank` (те же правила будут на сервере).

## 5. Тесты

- Пакет `RepsCounterKit`: Swift Testing, запуск `cd Packages/RepsCounterKit && swift test` (15 тестов: `ExerciseTests`, `LeaderboardRankingTests`, `DuelSummaryTests`, `NicknameAvailabilityTests`, `ProfileRegistrationTests`).
- Таргета UI-/юнит-тестов в Xcode-проекте пока нет.

## 6. Бэкенд (Supabase)

Проект не создан. В клиенте есть только `BackendConfiguration` (URL + публичный anon key → `SupabaseClient`). Здесь будут: таблицы и их назначение, RLS-политики, серверные функции, путь к миграциям.
