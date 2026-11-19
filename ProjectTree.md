# ProjectTree — структура проекта Reps Counter

> Живая карта проекта: что реализовано, как и где лежит. Обновляется вместе с кодом (правила — в `CLAUDE.md`, раздел 10).
> Статусы: ✅ реализовано · 🚧 в работе · 📋 запланировано (ещё нет в коде)

**Последнее обновление:** 2026-11-19 — этап 0: локальный пакет `RepsCounterKit` (DesignSystem, ExerciseAnalyzer, Backend + supabase-swift 2.55.7), каркас приложения со своим таббаром и кнопкой Duel, экраны Home / Rating / Profile на тестовых данных.

**Дизайн:** [Figma — Vibecode-test](https://www.figma.com/design/sdECikkyovjvnloQ6SqFqo/Vibecode-test) (источник истины для экранов). Доступа через Figma MCP пока нет, поэтому все экраны и токены — **временные** (системный стиль iOS), помечены `PROVISIONAL` в коде.

**План:** [`Roadmap.md`](Roadmap.md).

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
│       │   │   ├── Tokens.swift       # ✅ отступы, радиусы, цвета, шрифты (временные значения до Figma)
│       │   │   ├── Glass.swift        # ✅ rcGlass / rcProminentGlass: Liquid Glass на iOS 26+, материал на iOS 18–25
│       │   │   ├── Card.swift         # ✅ карточка, заголовок секции, плитка статистики, эмодзи-аватар
│       │   │   ├── Buttons.swift      # ✅ стили кнопок .rcPrimary / .rcSecondary
│       │   │   └── RCTabBar.swift     # ✅ нижняя панель: капсула с табами + отдельная круглая кнопка справа
│       │   ├── ExerciseAnalyzer/
│       │   │   └── Exercise.swift     # ✅ упражнения: squats, push-ups (машины состояний — этап 3)
│       │   └── Backend/
│       │       ├── Models/            # ✅ PlayerProfile, PlayerStats, DailyDuelReps, DuelDuration, DuelSummary, LeaderboardEntry
│       │       ├── LeaderboardRanking.swift   # ✅ сортировка рейтинга: равные суммы — одно место, стабильная вторичная сортировка
│       │       ├── BackendConfiguration.swift # ✅ URL проекта + anon key → SupabaseClient (проект ещё не создан)
│       │       └── MockData.swift     # ✅ тестовые данные для превью и каркаса (не реальные пользователи)
│       └── Tests/
│           ├── ExerciseAnalyzerTests/ # ✅ тесты Exercise
│           └── BackendTests/          # ✅ тесты рейтинга (ничьи, детерминизм) и исхода дуэли
└── RepsCounterDuel/                   # папка Xcode-проекта
    ├── RepsCounterDuel.xcodeproj      # ✅ проект Xcode; подключает локальный пакет (../Packages/RepsCounterKit)
    │   ├── project.xcworkspace/xcshareddata/swiftpm/Package.resolved  # ✅ версии пакетов для Xcode
    │   └── xcshareddata/xcschemes/
    │       └── RepsCounterDuel.xcscheme   # ✅ общая схема (для сборки из CLI/CI)
    └── RepsCounterDuel/               # ✅ исходники приложения (синхронизируемая папка: новые файлы подхватываются автоматически)
        ├── App/
        │   ├── RepsCounter_DuelApp.swift  # ✅ точка входа (@main), показывает RootView
        │   ├── AppTab.swift           # ✅ табы Home / Rating / Profile (Duel — не таб, а отдельная кнопка)
        │   └── RootView.swift         # ✅ текущий таб + RCTabBar; кнопка Duel открывает настройку дуэли
        ├── Features/
        │   ├── Home/
        │   │   ├── HomeView.swift     # ✅ статистика, график, рекорд + Start training, Recent Duels / Challenge, место в рейтинге (тестовые данные)
        │   │   └── DailyDuelRepsChart.swift  # ✅ столбчатый график «день → повторения в дуэлях» (Swift Charts)
        │   ├── Rating/
        │   │   └── RatingView.swift   # ✅ переключатель Global / Friends, одна общая сумма (тестовые данные)
        │   ├── Profile/
        │   │   └── ProfileView.swift  # ✅ эмодзи, ник, компактная статистика, топ-3 друзей, See all / Add friend (кнопки пока пустые)
        │   └── Duel/
        │       └── DuelSetupPlaceholderView.swift  # 🚧 выбор упражнения и 30/60/90 с; приглашение — этап 4
        └── Assets.xcassets/           # ✅ иконка приложения и AccentColor (пока пустые шаблоны)
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
| Info.plist | генерируется Xcode (`GENERATE_INFOPLIST_FILE`), ключи — через `INFOPLIST_KEY_*` | build settings таргета |
| Зависимости | `supabase-swift` 2.55.7 (exact) через локальный пакет | `Packages/RepsCounterKit/Package.swift` |
| Проверенная сборка | симуляторы iOS 18.0 и iOS 26.3 (iPhone 16) | — |

## 3. Модули и функциональность

| Модуль | Статус | Где лежит | Что делает |
|---|---|---|---|
| `DesignSystem` | 🚧 | пакет `RepsCounterKit` | токены (временные), карточки, кнопки, Liquid Glass + фолбэк, таббар; ждёт значений из Figma |
| `PoseDetection` | 📋 | локальный пакет | Vision: точки тела и их уверенность |
| `ExerciseAnalyzer` | 🚧 | пакет `RepsCounterKit` | пока только тип `Exercise`; машины состояний — этап 3 |
| `Backend` | 🚧 | пакет `RepsCounterKit` | модели, правила рейтинга, тестовые данные, фабрика SupabaseClient; репозитории и Realtime — дальше |
| `CameraService` | 📋 | приложение | захват кадров, разрешения, прерывания, ориентация |
| `Auth` | 📋 | приложение | анонимная сессия Supabase, привязка ника к ID; после переустановки — новый профиль, восстановления нет |
| `Onboarding` | 📋 | приложение | первый запуск, обязательная регистрация ника + выбор эмодзи, подсказки по камере |
| `Profile` | 🚧 | `Features/Profile` | экран на тестовых данных; друзья и переходы — этап 2 |
| `Home` / `Statistics` | 🚧 | `Features/Home` | экран на тестовых данных; реальные данные — этап 5 |
| `Training` | 📋 | приложение | одиночная тренировка, обновляет рекорд, хранение в SwiftData |
| `Friends` | 📋 | приложение | поиск по точному нику, карточка игрока, заявки (всплывающий экран + плашка на всех табах), приглашения в дуэль |
| `Duel` | 🚧 | `Features/Duel` | только временный экран настройки; лобби, отсчёт, матч, результаты — этап 4 |
| `Ranking` | 🚧 | `Features/Rating` + `Backend/LeaderboardRanking` | один рейтинг по общей сумме, Global / Friends, на тестовых данных |

## 4. Ключевые сценарии: где искать код

- **Запуск приложения:** `App/RepsCounter_DuelApp.swift` → `App/RootView.swift` → выбранный таб (`Features/*`). Онбординга пока нет.
- **Нижняя навигация:** `RootView` → `DesignSystem/RCTabBar` (табы из `AppTab`) → кнопка Duel → `Features/Duel/DuelSetupPlaceholderView`.
- **Данные на экранах:** все экраны берут `Backend/MockData` (параметры по умолчанию во вью) — сервер подключается на этапах 1–5.
- **Рейтинг:** `RatingView` → `MockData.leaderboard(scope)` → `LeaderboardRanking.rank` (те же правила будут на сервере).

## 5. Тесты

- Пакет `RepsCounterKit`: Swift Testing, запуск `cd Packages/RepsCounterKit && swift test` (9 тестов: `ExerciseTests`, `LeaderboardRankingTests`, `DuelSummaryTests`).
- Таргета UI-/юнит-тестов в Xcode-проекте пока нет.

## 6. Бэкенд (Supabase)

Проект не создан. В клиенте есть только `BackendConfiguration` (URL + публичный anon key → `SupabaseClient`). Здесь будут: таблицы и их назначение, RLS-политики, серверные функции, путь к миграциям.
