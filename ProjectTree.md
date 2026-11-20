# ProjectTree — структура проекта Reps Counter

> Живая карта проекта: что реализовано, как и где лежит. Обновляется вместе с кодом (правила — в `CLAUDE.md`, раздел 10).
> Статусы: ✅ реализовано · 🚧 в работе · 📋 запланировано (ещё нет в коде)

**Последнее обновление:** 2026-11-20 — иконка приложения, звук на каждый повтор (Rep sound); экран Duels History по макету (Home → See all, данные с сервера). Этап 4: обрыв связи в дуэли (пульс, «Reconnecting…», «прервана» после 10 с без рейтинга). Этап 5: недельный рейтинг, история и статистика с сервера; Home, Profile и Rating показывают настоящие данные. Этап 4: в лобби и результате настоящая статистика (сервер считает по завершённым дуэлям, рекорды тренировок синхронизируются). Ранее в этапе 4: дуэли на сервере (таблица `duels`, RPC жизненного цикла, синхронный старт, повторы по порядку, финализация), экраны дуэли опрашивают сервер. Этап 2: друзья на сервере (заявки, дружбы, поиск по нику, карточка игрока, входящие заявки опросом раз в 20 с), профиль и выбор друга для дуэли показывают настоящих друзей. Этап 1: Supabase dev-проект, таблица `profiles` с RLS, анонимная сессия, настоящая проверка ника и регистрация в онбординге, смена ника и эмодзи на сервере, сброс сессии при переустановке. Этап 0.5 / 3: настоящее распознавание позы (Vision) и подсчёт повторов (машины состояний приседаний и отжиманий с тестами на синтетике), скелет и подсказки поверх камеры в тренировке и дуэли; пороги временные, нужна проверка на iPhone. «Этап UI», шаг 5: экран тренировки поверх фронтальной камеры (Start → отсчёт 3·2·1 → REPS и Finish, без таймера) и её результат (Great Job! / Don't Give Up !, Total Reps в памяти телефона, рекорды по упражнениям → Home). Шаги 5–6: экран результата дуэли (победа / поражение / ничья, корона, Total Reps и Win Rate с изменением, Play Again / Exit), отсчёт 3-2-1 и сама дуэль поверх фронтальной камеры (верхняя панель со счётом и временем, нижняя «YOUR REPS» / Give up), лобби «Ready to duel?» (тёмный фон из макета, HEAD TO HEAD, I'm Ready, статус соперника), входящий вызов на дуэль (модальный экран + плашка на всех табах, `-debugIncomingDuel YES`), Waiting... (ожидание ответа друга, обратный отсчёт 3:00, Cancel Challenge), Set a duel time (−/+ по 10 с, пресеты 1/2/3/5/10 мин; DuelDuration теперь в секундах), Choose a Friend для дуэли (нет друзей / только отправленные заявки / список друзей), экраны Choose Activity (по кнопке VS) и Choose Exercise (из Choose Activity или с кнопок Home) с режимом «тренировка / дуэль»; дальнейшие экраны — заглушка. Шаг 4: экран Rating по макету (пустое и заполненное состояния, подиум топ-3, Global / Friends, своя строка закреплена над таббаром, пока не доскроллили до неё); тестовая кнопка Invite убрана с Home. Шаг 3: Profile, список Friends, Settings, Add a Friend, карточка игрока и входящая заявка в друзья (по макету), Edit Profile (свой дизайн: смена аватара и ника); рейтинг недельный. Шаг 2: Home по макету (пустое и заполненное состояния, недельный график, новый таббар с кнопкой VS). Шаг 1: онбординг — вводные слайды 1–2, экран ника (с ошибкой «ник занят»), выбор аватара, «Your Profile Is Ready!», весь онбординг по макету Figma: слайды, ник, аватар, профиль, цель, слайды-объяснения, пейвол и запрос камеры (с экраном «доступ запрещён» и Open Settings); онбординг продолжается с места остановки после перезапуска; прогресс-бар и кнопка «назад»; токены цвета и кнопки сняты с макета; приложение закреплено в светлой теме.

**Дизайн:** [Figma — Vibecode-test](https://www.figma.com/design/sdECikkyovjvnloQ6SqFqo/Vibecode-test) (источник истины для экранов). Доступа через Figma MCP пока нет. Экраны верстаются по PNG-экспортам фреймов: значения, снятые с макета, помечены в коде `FIGMA`, придуманные — `PROVISIONAL`.

**План:** [`Roadmap.md`](Roadmap.md). Сейчас идёт «Этап UI» — вёрстка всех экранов на тестовых данных.

---

## 1. Дерево репозитория

```text
RepsCounter-Duel/                      # корень git-репозитория
├── CLAUDE.md                          # ✅ спецификация продукта и правила разработки (главный источник требований)
├── ProjectTree.md                     # ✅ этот файл — карта структуры проекта
├── Roadmap.md                         # ✅ поэтапный план разработки и решения по макету
├── supabase/migrations/               # ✅ SQL-миграции (применены к dev): profiles + RLS + is_nickname_available (+ исправление регистра), друзья (friend_requests, friendships, RPC), фиксированный search_path, дуэли (duels + RPC), рекорды тренировок и статистика игроков, недельный рейтинг и история, пульс и прерванные дуэли, друзья с нулём в Friends
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
│       │   │   ├── Buttons.swift      # ✅ кнопки: .rcPrimaryLarge (64) / .rcPrimary (50) / .rcPrimaryCompact (48) — градиент, неактивная серая; .rcDestructive(Large) — розовая «Reject»; .rcSecondary
│       │   │   ├── RCSegmentedToggle.swift    # ✅ переключатель из двух вариантов (On/Off, Mon/Sun) как в Settings
│       │   │   ├── RCPageIndicator.swift      # ✅ точки страниц (активная — синяя капсула)
│       │   │   ├── RCViewfinderCorners.swift  # ✅ уголки «видоискателя» вокруг картинки / превью камеры
│       │   │   ├── RCProgressBar.swift    # ✅ тонкий прогресс-бар онбординга (128 × 6 pt)
│       │   │   ├── RCBackButton.swift     # ✅ круглая стеклянная кнопка «назад»
│       │   │   ├── RCTextField.swift      # ✅ .rcCapsuleField() — белое поле-капсула 57 pt
│       │   │   └── RCTabBar.swift     # ✅ нижняя панель по макету: капсула с табами (серая «пилюля» под выбранным) + круглая синяя кнопка «VS»
│       │   ├── ExerciseAnalyzer/      # чистая логика подсчёта, без Vision (тесты идут через `swift test`)
│       │   │   ├── Exercise.swift     # ✅ упражнения: squats, push-ups
│       │   │   ├── Pose.swift         # ✅ BodyJoint, PosePoint (0…1, y вниз), PoseFrame; какие точки и кости рисовать для упражнения
│       │   │   ├── ExerciseSignal.swift # ✅ кадр → один сигнал «насколько выпрямлен» (приседания: (колено−таз)/(лодыжка−колено); отжимания: (запястье−плечо)/ширина плеч) + подсказки PoseFeedback (не видно тело, отойди назад, займи стартовую позу, глубже)
│       │   │   ├── RepCounterConfiguration.swift # ✅ все пороги (ВРЕМЕННЫЕ, доли от собственной стартовой позы игрока): сглаживание, калибровка, глубина, гистерезис, длительность повтора, потеря трекинга
│       │   │   └── RepCounter.swift   # ✅ машина состояний calibrating → ready → descending → bottomReached → ascending → повтор; полный цикл считается ровно один раз, неглубокие и слишком быстрые — нет, потеря тела отменяет повтор
│       │   ├── PoseDetection/
│       │   │   └── VisionPoseDetector.swift # ✅ Apple Vision 2D-поза → PoseFrame (самый уверенный человек, координаты в ориентации экрана); только на устройстве
│       │   └── Backend/
│       │       ├── Models/            # ✅ Friends (FriendListItem, TopFriend, ProfileOverview), PlayerProfile, PlayerStats (рекорды тренировок по упражнению + их сумма; `applying(_:reps:)` — статистика после дуэли, `winRatePercent`), DailyDuelReps, TrainingProgress (все повторы тренировок на телефоне + рекорд по упражнению), DuelInvitation (входящий вызов: хозяин, упражнение, время, срок; отсчёт «3:00»), DuelDuration (длительность дуэли в секундах: шаг 10 с, 10 с … 10 мин, пресеты 1/2/3/5/10 мин), DuelSummary, LeaderboardEntry, HomeOverview (неделя Пн–Вс `WeekSummary`, недельное место `WeeklyRank` с «топ N»), RatingOverview (недельный рейтинг Global + Friends)
│       │       ├── FriendsService.swift       # ✅ `PlayerCard` и протокол поиска игрока / отправки и ответа на заявку в друзья + тестовый сервис (находятся Theo_9, Max_Power, Mila_K, NewPlayer; `offline` — нет сети)
│       │       ├── ProfileRegistration.swift  # ✅ протоколы регистрации и смены профиля (ProfileRegistering, ProfileUpdating), ошибки «ник занят» / «неверный формат», тестовые сервисы
│       │       ├── NicknameAvailability.swift # ✅ протокол проверки ника + NicknameRules (3–20: буквы, цифры, _ и .) + тестовый сервис
│       │       ├── LeaderboardRanking.swift   # ✅ сортировка рейтинга: равные суммы — одно место, стабильная вторичная сортировка
│       │       ├── BackendConfiguration.swift # ✅ URL проекта + anon key → SupabaseClient (проект ещё не создан)
│       │       ├── SupabaseBackend.swift      # ✅ один SupabaseClient + анонимная сессия (сброс при новой установке); SupabaseNicknameAvailabilityService (RPC is_nickname_available), SupabaseProfileService (регистрация upsert, смена ника и эмодзи)
│       │       ├── SupabaseFriendsService.swift # ✅ друзья через RPC: поиск, заявки, ответ, мои друзья, входящие, друзья игрока; ошибки «не найден» / «сам себе» / «лимит»
│       │       ├── StatsService.swift         # ✅ рейтинг недели, история дуэлей, моя статистика, Top Friends (Supabase + пустой мок); `LeaderboardEntry.weeklyRank` — место и «сколько повторов до топ-N»
│       │       ├── DuelService.swift          # ✅ DuelSnapshot (дуэль глазами участника, время переведено на часы устройства), DuelHeadToHead (статистика обоих), протоколы DuelServicing и TrainingRecordSyncing, разбор ответов сервера
│       │       ├── SupabaseDuelService.swift  # ✅ дуэли через RPC (create, incoming, view, respond, ready, rep, finish, leave) + ошибки busy / not friends / no longer available / rate limited
│       │       ├── MockDuelService.swift      # ✅ офлайн-друг для одного устройства (`-useMockBackend YES`): принимает, готовится, набирает повторы
│       │       └── MockData.swift     # ✅ тестовые данные для превью и каркаса (не реальные пользователи), `homeEmpty` / `homeFilled` для Home, `profileEmpty` / `profileFilled` для Profile
│       └── Tests/
│           ├── ExerciseAnalyzerTests/ # ✅ тесты Exercise и RepCounter на синтетических позах: полные повторы, неглубокие, шум, калибровка, потеря трекинга, одна сторона тела, слишком быстрые, задержка внизу, «отойди назад»
│           └── BackendTests/          # ✅ тесты рейтинга (ничьи, детерминизм), исхода дуэли, проверки ника, недели Пн–Вс и «топ N», длительности дуэли (шаг 10 с, границы, подписи), отсчёта и истечения вызова, статистики после дуэли (сумма повторов, % побед), рекордов тренировки
└── RepsCounterDuel/                   # папка Xcode-проекта
    ├── RepsCounterDuel.xcodeproj      # ✅ проект Xcode; подключает локальный пакет (../Packages/RepsCounterKit)
    │   ├── project.xcworkspace/xcshareddata/swiftpm/Package.resolved  # ✅ версии пакетов для Xcode
    │   └── xcshareddata/xcschemes/
    │       └── RepsCounterDuel.xcscheme   # ✅ общая схема (для сборки из CLI/CI)
    └── RepsCounterDuel/               # ✅ исходники приложения (синхронизируемая папка: новые файлы подхватываются автоматически)
        ├── App/
        │   ├── RepsCounter_DuelApp.swift  # ✅ точка входа (@main), показывает RootView
        │   ├── AppServices.swift      # ✅ сервисы бэкенда для приложения: dev-проект Supabase (URL + публичный anon key), проверка ника, регистрация, смена профиля; метка новой установки; DEBUG `-useMockBackend YES` — офлайн-моки
        │   ├── LocalStorageKeys.swift # ✅ ключи UserDefaults (ник/эмодзи, шаг онбординга, настройки) и ссылки `AppLinks` (почта поддержки и App Store — пока nil)
        │   ├── AppTab.swift           # ✅ табы Home / Rating / Profile (Duel — не таб, а отдельная кнопка)
        │   └── RootView.swift         # ✅ RootView: онбординг до завершения, затем MainTabsView (текущий таб + плавающий RCTabBar в 22 pt от края экрана, кнопка VS → Choose Activity, кнопки Home → Choose Exercise в нужном режиме — общий лист `ActivityFlowView`); ник/эмодзи — из сохранённой регистрации (DEBUG: `-debugDataState filled` — заполненные Home, Rating и Profile)
        ├── Services/
        │   ├── AppLog.swift           # ✅ OSLog-логгер `backend` (ошибки сервера видны в консоли Xcode) + `isNetworkError`: отличает «нет сети» от ответа сервера с ошибкой
        │   ├── RepSound.swift         # ✅ короткий системный звук (1057, «Tink») на каждый засчитанный повтор в тренировке и дуэли; выключается Settings → Rep sound; вибрация — sensoryFeedback на экранах
        │   ├── CameraPermission.swift # ✅ статус и запрос доступа к камере (AVFoundation); часть будущего CameraService
        │   └── FrontCameraSession.swift # ✅ сессия только фронтальной камеры: настройка и запуск на своей очереди (не на главном потоке), кадры для Vision (портрет, зеркально, поздние кадры отбрасываются), состояния running / unavailable (симулятор) / denied / interrupted; видео никуда не пишется
        ├── Shared/Components/
        │   ├── CameraOverlay.swift    # ✅ общие элементы экранов с камерой: бейдж YOU / инициалы, круг отсчёта GET READY, тёмная нижняя панель, скелет PoseSkeletonOverlay (по точкам упражнения, с учётом обрезки превью) и подсказка PoseFeedbackBadge (временная)
        │   ├── CameraPreview.swift    # ✅ живая фронтальная камера на весь экран (зеркально), тёмная заглушка с текстом, если камеры нет / доступ выключен / пауза
        │   ├── TabBarVisibility.swift # ✅ `.hidesTabBar()` — экраны без таббара по макету (Friends)
        │   ├── PlayerHeader.swift     # ✅ синяя шапка игрока (аватар, ник + копирование, «Top N», кнопки по бокам) — Profile и карточка игрока
        │   ├── AvatarGrid.swift       # ✅ сетка эмодзи 3 в ряд (онбординг и Edit Profile)
        │   ├── PlaceholderSheet.swift # 🚧 временный лист для ещё не нарисованных экранов (Settings, тренировка, история дуэлей)
        │   ├── RecordsCard.swift      # ✅ карточка-статистика: колонки (иконка, значение, подпись, «+N this week») — «Your records» и статистика Profile
        │   └── RecentDuelCard.swift   # ✅ карточка «Recent duels»: я (кольцо + ⚡) — счёт, исход, упражнение — соперник, для онбординга и Home
        ├── Features/
        │   ├── Onboarding/
        │   │   ├── OnboardingStep.swift   # ✅ шаги онбординга по порядку макета (три слайда-объяснения — отдельные шаги), значение прогресс-бара для каждого шага
        │   │   ├── OnboardingTitle.swift  # ✅ двухстрочный заголовок (чёрная + синяя строка)
        │   │   ├── OnboardingProgressHeader.swift  # ✅ «назад» слева + прогресс-бар по центру
        │   │   ├── AvatarEmoji.swift      # ✅ список из 21 эмодзи-мордочки (первая выбрана по умолчанию)
        │   │   ├── OnboardingAvatarCircle.swift # ✅ большой эмодзи-аватар в голубом круге с белым свечением
        │   │   ├── ProfileReadyStepView.swift   # ✅ «Your Profile Is Ready!»: аватар + ник, «Great !» регистрирует профиль (тестовый сервис)
        │   │   ├── TrainOrChallengeStepView.swift # ✅ слайд-объяснение 1 «Train Solo Or Challenge Friends»: пример рекордов и дуэли с ником и аватаром игрока (цифры — для примера)
        │   │   ├── CameraAccessStepView.swift # ✅ «Allow Access To Your Camera» → системный запрос; отказ → «Access to the Camera is Restricted» + Open Settings; при возврате проверяет доступ снова
        │   │   ├── BuildingPathStepView.swift # ✅ слайд-объяснение 2 «Building Your Personal Path»: пункты списка выполняются по очереди (ожидание → загрузка → галочка), затем автопереход дальше
        │   │   ├── MotivationGoal.swift   # ✅ три цели (Get Stronger / Maintain Discipline / Challenge Friends); выбор нигде не сохраняется
        │   │   ├── MotivationStepView.swift # ✅ «What Is Your Main Goal ?»: три синие карточки с иконками из Figma, тап по любой — дальше
        │   │   ├── AvatarStepView.swift   # ✅ выбор аватара: большой превью-кружок + прокручиваемая сетка 3 в ряд, выбор нельзя снять
        │   │   ├── NicknameStepView.swift # ✅ ввод ника: клавиатура сразу, Continue активна с первого символа, проверка ника, ошибка «занят» / «нет сети»
        │   │   ├── OnboardingFlowView.swift   # ✅ переключение шагов вперёд/назад, общий фон и шапка с прогрессом; после регистрации запоминает шаг и ник/эмодзи (UserDefaults), чтобы продолжить после перезапуска (DEBUG: `-debugOnboardingStep N`)
        │   │   ├── IntroSlide.swift   # ✅ содержимое слайдов: картинка в уголках (слайд 1) или отдельная картинка (слайд 2)
        │   │   ├── IntroSlideView.swift   # ✅ слайд: заголовок, подзаголовок, картинка в уголках, карточка подсказок
        │   │   ├── IntroPagerView.swift   # ✅ листание слайдов + точки + Continue (DEBUG: `-debugIntroPage N`)
        │   │   └── OnboardingPlaceholderStepView.swift  # 🚧 временный экран-заглушка (сейчас не используется в потоке)
        │   ├── Paywall/
        │   │   ├── PaywallContent.swift   # ✅ содержимое пейвола (тексты, картинка, планы `PaywallPlan`, порядок заголовка); `.onboardingTrial` — онбординг, `.goPro` — Go PRO из Settings (цены пока текстом, PROVISIONAL)
        │   │   ├── PaywallView.swift      # ✅ общий макет пейвола: ✕, заголовок над или под картинкой, карточки планов с выбором и бейджем, «✅ …», описание, кнопка, ссылки Terms · Privacy · Restore
        │   │   ├── PaywallPurchasing.swift # ✅ протокол покупки / восстановления + тестовый сервис (покупка удаётся, восстанавливать нечего); StoreKit — позже
        │   │   ├── LegalDocumentView.swift # 🚧 временный экран Terms of Use / Privacy Policy (документов ещё нет)
        │   │   └── PaywallFlowView.swift  # ✅ пейвол с поведением: ✕ или покупка → `onDone`, ссылки и Restore работают (онбординг и Go PRO из Settings)
        │   ├── Home/
        │   │   ├── HomeView.swift     # ✅ Home по макету: приветствие + Settings, This week, Your records, Set a new record / Start Train, Recent duels / Challenge a Friend, недельное место → Rating (тестовые данные)
        │   │   ├── WeeklyRepsChart.swift  # ✅ недельный график Пн–Вс: значения в ряд над столбцами, прошедшие дни голубые, сегодня синий, пустые/будущие — серые «пилюли»
        │   │   └── DuelHistoryView.swift # ✅ «Duels History» (Home → See all): All / Wins / Losses, завершённые дуэли по локальным дням (Today, Yesterday, 31 Aug), карточка «я – счёт – соперник», у победителя синий круг с кольцом и молнией, при ничьей выделены оба без молнии; данные — `my_duel_history`
        │   ├── Rating/
        │   │   ├── StatsStore.swift   # ✅ серверные данные для Home / Profile / Rating: доски Global и Friends, мои дуэли за 8 дней, моя статистика, Top Friends; обновляется при активации, при открытии экранов и после дуэли
        │   │   ├── RatingView.swift   # ✅ Rating по макету: заголовок + чип «моё место + аватар», подиум, подпись (своя для пустого Global / Friends), переключатель Global / Friends, полный список с 1-го места (на макете с 4-го — ошибка дизайна; в пустом — серые заглушки), своя строка подсвечена и закреплена снизу, пока её не видно (onScrollVisibilityChange)
        │   │   └── RatingPodium.swift # ✅ подиум 2 · 1 · 3 (карточки, аватар «?» для пустого места, номер места с градиентом) и фон RatingRaysBackground (картинка `RatingRays` из Assets)
        │   ├── Profile/
        │   │   ├── ProfileView.swift  # ✅ Profile по макету: синяя шапка, Edit/Settings, ник + копирование, «Top N», статистика, Top Friends недели → see all; пустое состояние — «No friends yet» (временно)
        │   │   └── EditProfileView.swift  # 🚧 свой дизайн (макета нет): тап по аватару → сетка эмодзи, карандаш у ника → свой алерт смены ника с проверкой как в онбординге; сохраняется локально
        │   ├── Workout/
        │   │   └── WorkoutTracker.swift # ✅ камера → Vision → RepCounter на видеоочереди (не на главном потоке); на экран — последняя поза (скелет), подсказка и засчитанные повторы; повтор засчитывается, только если весь цикл внутри окна счёта (после отсчёта / до конца дуэли)
        │   ├── Training/
        │   │   ├── TrainingSessionView.swift # ✅ «<Упражнение> · Practice» поверх фронтальной камеры: панель GET IN FRAME со Start → отсчёт 3·2·1 → верх с ✕ и заголовком, низ REPS + Finish; без таймера; повторы считает WorkoutTracker после отсчёта, скелет и подсказки поверх камеры (DEBUG: тап по числу добавляет повтор), ✕ до старта — временно
        │   │   ├── TrainingResultView.swift  # ✅ результат: «Great Job!» / «Don't Give Up !» (0 повторов), аватар, «N Reps», Total Reps (+N) и место в недельном рейтинге дуэлей («Your Rank» — тренировка рейтинг не меняет), Continue Practice (новая тренировка) / Exit, поделиться; TrainingFlow: тренировка → результат → снова
        │   │   └── TrainingProgressStore.swift # ✅ хранит TrainingProgress (все повторы тренировок + рекорд по упражнению) в UserDefaults; рекорды отправляются на сервер после нового рекорда и при каждой активации приложения; показываются в Home
        │   ├── Settings/
        │   │   └── SettingsView.swift # ✅ Settings по макету: карточка PRO → пейвол Go PRO, Rep sound, First day of the week (Пн/Вс для графика Home), Rate the app, Share, Contact us (заглушка без почты), Privacy, Terms
        │   ├── Friends/
        │   │   ├── FriendsCard.swift  # ✅ общая белая карточка друзей (строки + «Add New Friend»), используется в Friends и Choose a Friend; PlayerCard.mock(for:) — тестовая карточка друга
        │   │   ├── FriendsListView.swift  # ✅ «Friends»: друзья с недельным местом (→ карточка игрока), «Request Sent», «Add New Friend»; без таббара; режим «только чтение» для друзей другого игрока
        │   │   ├── AddFriendSheet.swift   # ✅ «Add a Friend» (лист): поле + Paste, Find User, ошибка «User not found…» → карточка игрока
        │   │   ├── FriendRequestCenter.swift # ✅ входящие заявки с сервера (`incoming_friend_requests`) при активном приложении и раз в 20 с (временно вместо realtime): новая → модальный экран, закрыли → плашка на всех табах; ответ уходит на сервер, после принятия обновляется список друзей
        │   │   ├── FriendsStore.swift # ✅ мои друзья и отправленные заявки с сервера (`my_friends`) для Profile, Friends и Choose a Friend; обновляется после каждого изменения; PlayerFriendsListView — полный список друзей другого игрока (`player_friends`)
        │   │   ├── FriendRequestViews.swift  # ✅ лист «New Friend !» (👋, Add to Friends / Reject) и закреплённая плашка с теми же кнопками
        │   │   └── PlayerCardView.swift   # ✅ карточка игрока: шапка как в Profile + назад, статистика, 3 последних друга + see all, «+ Add Friend» → «Request Sent»
        │   ├── Duel/
        │   │   ├── ChooseFriendView.swift    # ✅ «Choose a Friend»: 🤝 + Add Friend, если никого нет; список с подсказкой, если есть только отправленные заявки (их нельзя вызвать); список друзей → Set a duel time
        │   │   ├── DuelTimeView.swift        # ✅ «Set a duel time»: большое число секунд, −/+ по 10 с, карточка Time с пресетами 1/2/3/5/10 мин (нестандартное значение снимает выбор), Send Challenge → дуэль создаётся на сервере → Waiting... (принял → лист закрывается и открывается лобби; на одном устройстве — `-useMockBackend YES`, офлайн-друг принимает сам)
        │   │   ├── DuelLobby.swift           # ✅ модель лобби: ID серверной дуэли, я, соперник, упражнение, время; сначала мои локальные рекорды, потом настоящая статистика обоих с сервера (`withServerStats`; до загрузки у соперника «—»)
        │   │   ├── DuelLobbyView.swift       # ✅ «Ready to duel?»: I'm Ready → сервер, опрос раз в 1 с (готовность соперника, старт), ‹ → выход на сервере; DuelLobbyFlow: лобби → дуэль → результат → Play Again (новый вызов → Waiting... → новое лобби)
        │   │   ├── LiveDuelView.swift        # ✅ дуэль поверх фронтальной камеры: отсчёт до серверного starts_at, окно счёта до ends_at, мои повторы считает WorkoutTracker и по одному отправляет на сервер, счёт соперника — опрос раз в 1 с; после конца — finish_duel и итог по серверному счёту; Give up / уход соперника = поражение без рейтинга; DEBUG тап по числу добавляет повтор; пульс раз в 1 с, «Reconnecting…» после 3 с без ответа (счёт продолжается, повторы досылаются), «Duel interrupted» после 10 с
        │   │   ├── DuelResultView.swift      # ✅ результат: «You Won!» / «You Lost» / «Draw» на чёрной основе с фоном из макета (зелёный / красный / синий), счёт между аватарами, корона над победителем, проигравший приглушён, PR, плашка «Won by N reps» / «N Reps were not enough» / «Equal result», Total Reps и Win Rate с изменением; результат пока считается на устройстве
        │   │   ├── DuelInvitationCenter.swift # ✅ входящие вызовы с сервера (`incoming_duel_invitations`, опрос раз в 5 с при активном приложении): новый → модальный экран, закрыли → плашка; Start Duel ! / Refuse уходят на сервер, принятый вызов открывает лобби
        │   │   ├── DuelInvitationViews.swift  # ✅ модальный экран «New Duel !» (отсчёт «3:00 LEFT», большой VS, Start Duel ! / Refuse) и плашка «New Duel» с отсчётом и двумя кнопками
        │   │   └── DuelWaitingView.swift     # ✅ «Waiting...»: отсчёт до серверного истечения, опрос дуэли раз в 2 с (принял → лобби, отклонил → «Declined», истёк → «Time's up»), Cancel / ✕ отменяют вызов на сервере
        │   └── Activity/              # общий старт тренировки и дуэли
        │       ├── ActivityFlowView.swift    # ✅ лист с NavigationStack: ActivityMode (training / duel), ActivityFlowStart (с Choose Activity или сразу с Choose Exercise), общий макет экранов выбора, синие карточки ActivityChoiceCard, кнопка ✕; дуэль: Choose Exercise → Choose a Friend (Add Friend → лист поиска → карточка игрока) → Set a duel time → Waiting...; тренировка: Choose Exercise → лист закрывается → TrainingSessionView на весь экран
        │       ├── ChooseActivityView.swift  # ✅ «Choose Activity»: Duel / Train (только ✕)
        │       └── ChooseExerciseView.swift  # ✅ «Choose Exercise»: Push-Ups / Squats; режим передаётся дальше, ‹ — только если пришли с Choose Activity
        └── Assets.xcassets/           # ✅ AccentColor = #2A8DFD; Onboarding/OnboardingPushup — фигура с отжиманием (фон вырезан), Onboarding/OnboardingSetupPath — иконка-планшет, Onboarding/Goal* — иконки трёх целей; Paywall/PaywallTrialHero — телефон на пейволе (экспорт из Figma); Onboarding/CameraAccess* — телефон, карточка системного запроса и экран настроек для шага камеры (@3x); RatingRays — фон с лучами на экране Rating (@3x); Activity/Activity*, Exercise*, DuelWaiting — круглые иконки, DuelInviteVS — большой VS для входящего вызова (вырезан из макета), DuelLobbyBackground — тёмно-синий фон лобби, DuelResultCrown — корона победителя, DuelResult{Win,Loss,Draw}Background — фоны результата карточек Choose Activity / Choose Exercise (экспорт из Figma); AppIcon — иконка приложения «VS» (1024, края обрезаны под маску iOS; тёмный и tinted варианты iOS строит сам)
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
| Камера | `INFOPLIST_KEY_NSCameraUsageDescription` — текст системного запроса доступа | build settings таргета |
| Тема | только светлая (`INFOPLIST_KEY_UIUserInterfaceStyle = Light`), макет только светлый | build settings таргета |
| Info.plist | генерируется Xcode (`GENERATE_INFOPLIST_FILE`), ключи — через `INFOPLIST_KEY_*` | build settings таргета |
| Зависимости | `supabase-swift` 2.55.7 (exact) через локальный пакет | `Packages/RepsCounterKit/Package.swift` |
| Проверенная сборка | собирается для симуляторов iOS 18.0 и iOS 26.1 (iPhone 16); экраны онбординга с аватаром визуально проверены на iOS 18.0. На симуляторе iOS 26.3 не отображаются эмодзи (ошибка Apple, исправлена в 26.4) | — |

## 3. Модули и функциональность

| Модуль | Статус | Где лежит | Что делает |
|---|---|---|---|
| `DesignSystem` | 🚧 | пакет `RepsCounterKit` | токены (временные), карточки, кнопки, Liquid Glass + фолбэк, таббар; ждёт значений из Figma |
| `PoseDetection` | ✅ | пакет `RepsCounterKit` | Vision: точки тела и их уверенность → PoseFrame |
| `ExerciseAnalyzer` | 🚧 | пакет `RepsCounterKit` | машины состояний приседаний и отжиманий с тестами; пороги временные — проверить на реальных iPhone |
| `Backend` | 🚧 | пакет `RepsCounterKit` | модели, правила рейтинга, тестовые данные; Supabase: сессия, проверка ника, регистрация и смена профиля (`SupabaseBackend.swift`); остальное (друзья, дуэли, рейтинг) — этапы 2–5 |
| `CameraService` | ✅ | `Services/FrontCameraSession`, `Shared/Components/CameraPreview` | фронтальная камера, кадры для Vision, состояния нет камеры / нет доступа / пауза |
| `Auth` | ✅ | `Backend/SupabaseBackend.swift`, `App/AppServices.swift` | анонимная сессия Supabase (Keychain, автообновление), ник привязан к ID пользователя; после переустановки старая сессия удаляется → новый профиль |
| `Onboarding` | ✅ UI | `Features/Onboarding` | все экраны по макету, реальный запрос камеры; ник, регистрация и покупки — тестовые сервисы (сервер — этап 1) |
| `Profile` | ✅ | `Features/Profile`, `Features/Friends` | Duels Won / Win Rate / Total Reps (за всё время), недельное место и Top Friends недели — с сервера; друзья — с сервера |
| `Home` / `Statistics` | ✅ | `Features/Home`, `StatsStore` | график недели из моих завершённых дуэлей (локальные дни), последняя дуэль, недельное место и «N reps to top M» — с сервера; рекорды — с телефона |
| `Training` | 🚧 UI | `Features/Training` | тренировка на камере и результат готовы; сумма повторов и рекорды хранятся в UserDefaults; подсчёт повторов (Vision) и SwiftData — этап 3 |
| `Friends` | ✅ | `Features/Friends`, `Backend/SupabaseFriendsService.swift` | поиск по точному нику, карточка игрока, заявки (отправить / принять / отклонить; встречная заявка = дружба), мои друзья, друзья игрока — всё через серверные функции без ID аккаунтов; удаление из друзей и отмена заявки есть на сервере, но без UI; блокировка — позже |
| `Duel` | 🚧 | `Features/Duel` | только временный экран настройки; лобби, отсчёт, матч, результаты — этап 4 |
| `Ranking` | ✅ | `Features/Rating` (`StatsStore`), `Backend/StatsService.swift`, `Backend/LeaderboardRanking` | недельный рейтинг Global / Friends с сервера (топ-100 + моё место), равные суммы — одно место |

## 4. Ключевые сценарии: где искать код

- **Запуск приложения:** `App/RepsCounter_DuelApp.swift` → `App/RootView.swift` → если онбординг не пройден (`@AppStorage("onboardingCompleted")`) — `OnboardingFlowView`, иначе `MainTabsView`. Сбросить в симуляторе: запуск с аргументом `-onboardingCompleted NO`.
- **Онбординг:** `OnboardingFlowView` → `IntroPagerView` (слайды `IntroSlide`) → `NicknameStepView` → `NicknameAvailabilityChecking` (сейчас `MockNicknameAvailabilityService`, на этапе 1 — сервер) → `AvatarStepView` (`AvatarEmoji`) → `ProfileReadyStepView` → `ProfileRegistering` (сейчас `MockProfileRegistrationService`; ник заняли за это время → назад на шаг ника) → `MotivationStepView` (`MotivationGoal`) → `TrainOrChallengeStepView` (`RecordsCard`, `RecentDuelCard`) → `BuildingPathStepView` (≈ 5 с анимации, автопереход) → `PaywallFlowView` → `PaywallView` (`PaywallContent.onboardingTrial`, `MockPaywallPurchaseService`) → `CameraAccessStepView` → `SystemCameraPermission` → доступ есть → `onFinish` ставит флаг и открывает табы.
- **Нижняя навигация:** `RootView` → `DesignSystem/RCTabBar` (табы из `AppTab`) → кнопка VS → `ActivityFlowView(start: .chooseActivity)` → Choose Activity → Choose Exercise(режим).
- **Данные на экранах:** все экраны берут `Backend/MockData` (параметры по умолчанию во вью) — сервер подключается на этапах 1–5.
- **Входящая заявка:** `MainTabsView` держит `FriendRequestCenter` → `.sheet(item: modalRequest)` → `FriendRequestSheet`; закрыли → `bannerRequest` → `FriendRequestBanner` поверх всех табов; ответ → `FriendsServicing.respondToFriendRequest`. Для теста — кнопка Invite на Home (только DEBUG).
- **Друзья:** Profile → see all → `FriendsListView` → строка друга → `PlayerCardView`; Add Friend / Add New Friend → `AddFriendSheet` → `FriendsServicing.findPlayer` (сейчас `MockFriendsService`) → найден → `PlayerCardView` (стек навигации Profile).
- **Settings / Edit Profile:** шестерёнка на Home и Profile → `SettingsView` (fullScreenCover); карандаш на Profile → `EditProfileView`; ник и эмодзи хранятся в UserDefaults (`LocalStorageKeys`), Home и Profile обновляются сразу.
- **Home:** `MainTabsView` → `HomeView(me:overview:)` → `HomeOverview` (`MockData.homeEmpty()` по умолчанию, `homeFilled()` с `-debugDataState filled`) → `WeeklyRepsChart`, `RecordsCard`, `RecentDuelCard`; карточка места → таб Rating; Start Train → `ActivityFlowView(start: .chooseExercise(.training))`, Challenge a Friend → `.chooseExercise(.duel)`.
- **Рейтинг:** `MainTabsView` → `RatingView(me:overview:)` → `RatingOverview` (`.empty` по умолчанию, `MockData.ratingFilled(me:)` с `-debugDataState filled`: я на 24-м месте глобально и на 4-м среди друзей) → `LeaderboardRanking.rank` (те же правила будут на сервере: равные суммы — одно место).

## 5. Тесты

- Пакет `RepsCounterKit`: Swift Testing, запуск `cd Packages/RepsCounterKit && swift test` (27 тестов: `ExerciseTests`, `LeaderboardRankingTests`, `DuelSummaryTests`, `NicknameAvailabilityTests`, `ProfileRegistrationTests`, `WeekSummaryTests`, `WeeklyRankTests`, `FriendsServiceTests`).
- Таргета UI-/юнит-тестов в Xcode-проекте пока нет.

## 6. Бэкенд (Supabase)

Проект `reps-counter-dev` (ref `kreicqgbbrxeerzquiue`, Франкфурт, бесплатный тариф) создан 2026-11-20. Миграции лежат в `supabase/migrations/` и применены к dev (profiles, друзья, дуэли). В клиенте только URL и публичный anon key (`App/AppServices.swift`), права даёт RLS.

**Нужно включить в панели Supabase:** Authentication → Sign In / Providers → Allow anonymous sign-ins (без этого регистрация не работает). Лимит анонимных входов — 30 в час с одного IP (это и есть лимит регистраций для MVP).

- `profiles` — ✅ ник (`citext`, уникален без учёта регистра, 3–20 символов: буквы, цифры, `_`, `.`) + эмодзи, `id` = ID анонимного пользователя Auth.
  - RLS: игрок читает, создаёт и меняет **только свою** строку; удаления нет; роль `anon` доступа не имеет. ID других игроков наружу не отдаются.
  - `updated_at` обновляет триггер `set_updated_at`.
- `is_nickname_available(candidate)` — ✅ RPC «свободен ли ник» (только да/нет, без данных; свой текущий ник считается свободным). SECURITY DEFINER — предупреждение советника ожидаемое.
- Проверено SQL-тестом в откатываемой транзакции: чужую строку нельзя создать, изменить и прочитать; дубль ника в другом регистре → 23505; неверный формат → 23514; удаление не работает; `anon` не читает таблицу и не вызывает RPC; проверка ника не зависит от регистра.

- `friend_requests` — ✅ заявки (pending → accepted | declined | cancelled), одна ожидающая на пару в любом направлении (уникальный индекс), лимит 50 заявок в сутки с одного игрока (временный).
- `friendships` — ✅ дружба одной строкой на пару (`user_a < user_b`).
  - Прямого доступа у клиента нет (RLS без политик + revoke): только через RPC ниже. RPC узнают игрока по нику и возвращают ник / эмодзи / отношение — ID аккаунтов наружу не уходят. Вспомогательные функции лежат в схеме `private` (недоступна через API).
- RPC друзей (все только для вошедших игроков с профилем): `find_player(ник)` → карточка (отношение self / friends / request_sent / request_received / none + 3 последних друга), `player_friends(ник)`, `my_friends()` (друзья, потом мои отправленные заявки), `incoming_friend_requests()`, `send_friend_request(ник)` (sent / already_sent / already_friends / accepted — если он уже звал меня), `respond_to_friend_request(ник, accept)`, `cancel_friend_request(ник)`, `remove_friend(ник)`.
- Проверено SQL-тестом на трёх игроках в откатываемой транзакции (27 случаев): поиск без учёта регистра, дубли, встречная заявка, отклонение, отмена и повтор, удаление из друзей, ошибки «не найден» / «сам себе», нет доступа к таблицам, без профиля и `anon` — отказ.

- `duels` — ✅ дуэль одной строкой: игроки, упражнение, длительность, состояние, готовность, серверные `starts_at` / `ends_at`, принятые повторы и номер последнего повтора у каждого. Прямого доступа нет, только RPC: `create_duel`, `incoming_duel_invitations`, `duel_view`, `respond_to_duel`, `set_duel_ready`, `submit_duel_rep`, `finish_duel`, `leave_duel`. Временные константы: приглашение 3 мин, отсчёт 4 с, приём повторов до конца + 2 с, повторы не чаще 0,4 с, лобби без старта 5 мин, 20 вызовов в час. Проверено SQL-тестом (24 случая): только друзья, нельзя две дуэли сразу, чужой не видит дуэль, повторы только в окне и по порядку, дубли игнорируются, финализация повторяемая, уход во время дуэли = поражение.

- `training_records` — ✅ лучший результат тренировки по упражнению (с телефона; сервер хранит наибольшее). Только через `save_training_record(упражнение, повторы)`. На рейтинг не влияет, показывается как «PR».
- `duel_head_to_head(дуэль)` — ✅ настоящая статистика обоих игроков дуэли: победы / поражения / ничьи / сумма повторов по завершённым дуэлям (поражения выходом и незавершённые не считаются) + PR по упражнению дуэли. Проверено SQL-тестом.

- Обрыв связи — ✅ `duel_heartbeat(дуэль)` раз в секунду в лобби и во время дуэли (повторы тоже считаются пульсом); если игрок молчит дольше 10 с во время дуэли, фаза становится `interrupted`, `finish_duel` сохраняет её так, в рейтинг она не идёт. Проверено SQL-тестом.
- Рейтинг и статистика (этап 5) — ✅ считаются из завершённых дуэлей, отдельных итоговых таблиц нет: `weekly_leaderboard(scope, max)` (неделя с понедельника 00:00 UTC; Global — только у кого есть повторы, Friends — я и все друзья, без повторов — 0; равные суммы — одно место), `my_duel_history(since, max)`, `my_stats()`, `top_friends_this_week()` (3 друга с наибольшей суммой недели + их % побед). Проверено SQL-тестом: прошлая неделя и поражения выходом не считаются, ничья в рейтинге, Friends — только я и друзья.

Поток регистрации: `NicknameStepView` → `SupabaseNicknameAvailabilityService` (анонимная сессия + RPC) → `ProfileReadyStepView` → `SupabaseProfileService.register` (upsert своей строки; 23505 → ник занят). Edit Profile → `SupabaseProfileService.updateNickname / updateEmoji`. Новая установка: `AppServices` видит отсутствие метки в UserDefaults и удаляет старую сессию из Keychain до первого запроса.
