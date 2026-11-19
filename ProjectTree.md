# ProjectTree — структура проекта Reps Counter

> Живая карта проекта: что реализовано, как и где лежит. Обновляется вместе с кодом (правила — в `CLAUDE.md`, раздел 10).
> Статусы: ✅ реализовано · 🚧 в работе · 📋 запланировано (ещё нет в коде)

**Последнее обновление:** 2026-11-20 — «Этап UI», шаг 5: экран тренировки поверх фронтальной камеры (Start → отсчёт 3·2·1 → REPS и Finish, без таймера) и её результат (Great Job! / Don't Give Up !, Total Reps в памяти телефона, рекорды по упражнениям → Home). Шаги 5–6: экран результата дуэли (победа / поражение / ничья, корона, Total Reps и Win Rate с изменением, Play Again / Exit), отсчёт 3-2-1 и сама дуэль поверх фронтальной камеры (верхняя панель со счётом и временем, нижняя «YOUR REPS» / Give up), лобби «Ready to duel?» (тёмный фон из макета, HEAD TO HEAD, I'm Ready, статус соперника), входящий вызов на дуэль (модальный экран + плашка на всех табах, `-debugIncomingDuel YES`), Waiting... (ожидание ответа друга, обратный отсчёт 3:00, Cancel Challenge), Set a duel time (−/+ по 10 с, пресеты 1/2/3/5/10 мин; DuelDuration теперь в секундах), Choose a Friend для дуэли (нет друзей / только отправленные заявки / список друзей), экраны Choose Activity (по кнопке VS) и Choose Exercise (из Choose Activity или с кнопок Home) с режимом «тренировка / дуэль»; дальнейшие экраны — заглушка. Шаг 4: экран Rating по макету (пустое и заполненное состояния, подиум топ-3, Global / Friends, своя строка закреплена над таббаром, пока не доскроллили до неё); тестовая кнопка Invite убрана с Home. Шаг 3: Profile, список Friends, Settings, Add a Friend, карточка игрока и входящая заявка в друзья (по макету), Edit Profile (свой дизайн: смена аватара и ника); рейтинг недельный. Шаг 2: Home по макету (пустое и заполненное состояния, недельный график, новый таббар с кнопкой VS). Шаг 1: онбординг — вводные слайды 1–2, экран ника (с ошибкой «ник занят»), выбор аватара, «Your Profile Is Ready!», весь онбординг по макету Figma: слайды, ник, аватар, профиль, цель, слайды-объяснения, пейвол и запрос камеры (с экраном «доступ запрещён» и Open Settings); онбординг продолжается с места остановки после перезапуска; прогресс-бар и кнопка «назад»; токены цвета и кнопки сняты с макета; приложение закреплено в светлой теме.

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
│       │   │   ├── Buttons.swift      # ✅ кнопки: .rcPrimaryLarge (64) / .rcPrimary (50) / .rcPrimaryCompact (48) — градиент, неактивная серая; .rcDestructive(Large) — розовая «Reject»; .rcSecondary
│       │   │   ├── RCSegmentedToggle.swift    # ✅ переключатель из двух вариантов (On/Off, Mon/Sun) как в Settings
│       │   │   ├── RCPageIndicator.swift      # ✅ точки страниц (активная — синяя капсула)
│       │   │   ├── RCViewfinderCorners.swift  # ✅ уголки «видоискателя» вокруг картинки / превью камеры
│       │   │   ├── RCProgressBar.swift    # ✅ тонкий прогресс-бар онбординга (128 × 6 pt)
│       │   │   ├── RCBackButton.swift     # ✅ круглая стеклянная кнопка «назад»
│       │   │   ├── RCTextField.swift      # ✅ .rcCapsuleField() — белое поле-капсула 57 pt
│       │   │   └── RCTabBar.swift     # ✅ нижняя панель по макету: капсула с табами (серая «пилюля» под выбранным) + круглая синяя кнопка «VS»
│       │   ├── ExerciseAnalyzer/
│       │   │   └── Exercise.swift     # ✅ упражнения: squats, push-ups (машины состояний — этап 3)
│       │   └── Backend/
│       │       ├── Models/            # ✅ Friends (FriendListItem, TopFriend, ProfileOverview), PlayerProfile, PlayerStats (рекорды тренировок по упражнению + их сумма; `applying(_:reps:)` — статистика после дуэли, `winRatePercent`), DailyDuelReps, TrainingProgress (все повторы тренировок на телефоне + рекорд по упражнению), DuelInvitation (входящий вызов: хозяин, упражнение, время, срок; отсчёт «3:00»), DuelDuration (длительность дуэли в секундах: шаг 10 с, 10 с … 10 мин, пресеты 1/2/3/5/10 мин), DuelSummary, LeaderboardEntry, HomeOverview (неделя Пн–Вс `WeekSummary`, недельное место `WeeklyRank` с «топ N»), RatingOverview (недельный рейтинг Global + Friends)
│       │       ├── FriendsService.swift       # ✅ `PlayerCard` и протокол поиска игрока / отправки и ответа на заявку в друзья + тестовый сервис (находятся Theo_9, Max_Power, Mila_K, NewPlayer; `offline` — нет сети)
│       │       ├── ProfileRegistration.swift  # ✅ протокол регистрации профиля + тестовый сервис (admin → «занят», offline → нет сети)
│       │       ├── NicknameAvailability.swift # ✅ протокол проверки ника + NicknameRules + тестовый сервис (занят только admin; `offline` — имитация нет сети)
│       │       ├── LeaderboardRanking.swift   # ✅ сортировка рейтинга: равные суммы — одно место, стабильная вторичная сортировка
│       │       ├── BackendConfiguration.swift # ✅ URL проекта + anon key → SupabaseClient (проект ещё не создан)
│       │       └── MockData.swift     # ✅ тестовые данные для превью и каркаса (не реальные пользователи), `homeEmpty` / `homeFilled` для Home, `profileEmpty` / `profileFilled` для Profile
│       └── Tests/
│           ├── ExerciseAnalyzerTests/ # ✅ тесты Exercise
│           └── BackendTests/          # ✅ тесты рейтинга (ничьи, детерминизм), исхода дуэли, проверки ника, недели Пн–Вс и «топ N», длительности дуэли (шаг 10 с, границы, подписи), отсчёта и истечения вызова, статистики после дуэли (сумма повторов, % побед), рекордов тренировки
└── RepsCounterDuel/                   # папка Xcode-проекта
    ├── RepsCounterDuel.xcodeproj      # ✅ проект Xcode; подключает локальный пакет (../Packages/RepsCounterKit)
    │   ├── project.xcworkspace/xcshareddata/swiftpm/Package.resolved  # ✅ версии пакетов для Xcode
    │   └── xcshareddata/xcschemes/
    │       └── RepsCounterDuel.xcscheme   # ✅ общая схема (для сборки из CLI/CI)
    └── RepsCounterDuel/               # ✅ исходники приложения (синхронизируемая папка: новые файлы подхватываются автоматически)
        ├── App/
        │   ├── RepsCounter_DuelApp.swift  # ✅ точка входа (@main), показывает RootView
        │   ├── LocalStorageKeys.swift # ✅ ключи UserDefaults (ник/эмодзи, шаг онбординга, настройки) и ссылки `AppLinks` (почта поддержки и App Store — пока nil)
        │   ├── AppTab.swift           # ✅ табы Home / Rating / Profile (Duel — не таб, а отдельная кнопка)
        │   └── RootView.swift         # ✅ RootView: онбординг до завершения, затем MainTabsView (текущий таб + плавающий RCTabBar в 22 pt от края экрана, кнопка VS → Choose Activity, кнопки Home → Choose Exercise в нужном режиме — общий лист `ActivityFlowView`); ник/эмодзи — из сохранённой регистрации (DEBUG: `-debugDataState filled` — заполненные Home, Rating и Profile)
        ├── Services/
        │   ├── CameraPermission.swift # ✅ статус и запрос доступа к камере (AVFoundation); часть будущего CameraService
        │   └── FrontCameraSession.swift # ✅ сессия только фронтальной камеры: настройка и запуск на своей очереди (не на главном потоке), состояния running / unavailable (симулятор) / denied / interrupted; видео никуда не пишется
        ├── Shared/Components/
        │   ├── CameraOverlay.swift    # ✅ общие элементы экранов с камерой: бейдж YOU / инициалы, круг отсчёта GET READY, тёмная нижняя панель
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
        │   │   └── WeeklyRepsChart.swift  # ✅ недельный график Пн–Вс: значения в ряд над столбцами, прошедшие дни голубые, сегодня синий, пустые/будущие — серые «пилюли»
        │   ├── Rating/
        │   │   ├── RatingView.swift   # ✅ Rating по макету: заголовок + чип «моё место + аватар», подиум, подпись (своя для пустого Global / Friends), переключатель Global / Friends, полный список с 1-го места (на макете с 4-го — ошибка дизайна; в пустом — серые заглушки), своя строка подсвечена и закреплена снизу, пока её не видно (onScrollVisibilityChange)
        │   │   └── RatingPodium.swift # ✅ подиум 2 · 1 · 3 (карточки, аватар «?» для пустого места, номер места с градиентом) и фон RatingRaysBackground (картинка `RatingRays` из Assets)
        │   ├── Profile/
        │   │   ├── ProfileView.swift  # ✅ Profile по макету: синяя шапка, Edit/Settings, ник + копирование, «Top N», статистика, Top Friends недели → see all; пустое состояние — «No friends yet» (временно)
        │   │   └── EditProfileView.swift  # 🚧 свой дизайн (макета нет): тап по аватару → сетка эмодзи, карандаш у ника → свой алерт смены ника с проверкой как в онбординге; сохраняется локально
        │   ├── Training/
        │   │   ├── TrainingSessionView.swift # ✅ «<Упражнение> · Practice» поверх фронтальной камеры: панель GET IN FRAME со Start → отсчёт 3·2·1 → верх с ✕ и заголовком, низ REPS + Finish; без таймера; повторы пока не считаются (DEBUG: тап по числу), ✕ до старта — временно
        │   │   ├── TrainingResultView.swift  # ✅ результат: «Great Job!» / «Don't Give Up !» (0 повторов), аватар, «N Reps», Total Reps (+N) и место в недельном рейтинге дуэлей («Your Rank» — тренировка рейтинг не меняет), Continue Practice (новая тренировка) / Exit, поделиться; TrainingFlow: тренировка → результат → снова
        │   │   └── TrainingProgressStore.swift # ✅ хранит TrainingProgress (все повторы тренировок + рекорд по упражнению) в UserDefaults до SwiftData (этап 3); рекорды показываются в Home
        │   ├── Settings/
        │   │   └── SettingsView.swift # ✅ Settings по макету: карточка PRO → пейвол Go PRO, Rep sound, First day of the week (Пн/Вс для графика Home), Rate the app, Share, Contact us (заглушка без почты), Privacy, Terms
        │   ├── Friends/
        │   │   ├── FriendsCard.swift  # ✅ общая белая карточка друзей (строки + «Add New Friend»), используется в Friends и Choose a Friend; PlayerCard.mock(for:) — тестовая карточка друга
        │   │   ├── FriendsListView.swift  # ✅ «Friends»: друзья с недельным местом (→ карточка игрока), «Request Sent», «Add New Friend»; без таббара; режим «только чтение» для друзей другого игрока
        │   │   ├── AddFriendSheet.swift   # ✅ «Add a Friend» (лист): поле + Paste, Find User, ошибка «User not found…» → карточка игрока
        │   │   ├── FriendRequestCenter.swift # ✅ входящие заявки на уровне табов: новая → модальный лист, закрыли → плашка сверху до ответа; DEBUG: `simulateIncomingRequest()`
        │   │   ├── FriendRequestViews.swift  # ✅ лист «New Friend !» (👋, Add to Friends / Reject) и закреплённая плашка с теми же кнопками
        │   │   └── PlayerCardView.swift   # ✅ карточка игрока: шапка как в Profile + назад, статистика, 3 последних друга + see all, «+ Add Friend» → «Request Sent»
        │   ├── Duel/
        │   │   ├── ChooseFriendView.swift    # ✅ «Choose a Friend»: 🤝 + Add Friend, если никого нет; список с подсказкой, если есть только отправленные заявки (их нельзя вызвать); список друзей → Set a duel time
        │   │   ├── DuelTimeView.swift        # ✅ «Set a duel time»: большое число секунд, −/+ по 10 с, карточка Time с пресетами 1/2/3/5/10 мин (нестандартное значение снимает выбор), Send Challenge → Waiting... (DEBUG `-debugAutoAccept YES`: друг принимает через 3 с → лист закрывается и открывается лобби)
        │   │   ├── DuelLobby.swift           # ✅ модель лобби: я, соперник, упражнение, время, статистика обоих (соперника — тестовая)
        │   │   ├── DuelLobbyView.swift       # ✅ «Ready to duel?» на весь экран: аватары и VS, HEAD TO HEAD (рекорд упражнения, победы, % побед; большее значение в строке ярко, меньшее — на 50%), I'm Ready, статус соперника; ‹ — выход до отсчёта; DuelLobbyFlow: оба готовы → LiveDuelView → DuelResultView (Play Again → снова лобби, Exit → закрыть); на этапе UI соперник «готов» через 3 с
        │   │   ├── LiveDuelView.swift        # ✅ дуэль поверх фронтальной камеры: отсчёт 3·2·1 (круг GET READY, панель GET IN FRAME), затем верхняя чёрная панель (YOU и инициалы соперника, счёт, время LEFT, полоса долей; зелёный — у лидера: в начале и при равенстве я, соперник — когда впереди) и нижняя (YOUR REPS, «<соперник> is on N», Give up с подтверждением); повторы пока не считаются (этап 3), счёт соперника тестовый, в DEBUG тап по числу добавляет повтор; скелета позы ещё нет
        │   │   ├── DuelResultView.swift      # ✅ результат: «You Won!» / «You Lost» / «Draw» на чёрной основе с фоном из макета (зелёный / красный / синий), счёт между аватарами, корона над победителем, проигравший приглушён, PR, плашка «Won by N reps» / «N Reps were not enough» / «Equal result», Total Reps и Win Rate с изменением; результат пока считается на устройстве
        │   │   ├── DuelInvitationCenter.swift # ✅ входящие вызовы на дуэль для всех табов: новый вызов → модальный экран, закрыли → плашка сверху до ответа или истечения; принятый → лобби «Ready to duel?»; на этапе UI вызов создаётся только DEBUG-аргументом `-debugIncomingDuel YES`
        │   │   ├── DuelInvitationViews.swift  # ✅ модальный экран «New Duel !» (отсчёт «3:00 LEFT», большой VS, Start Duel ! / Refuse) и плашка «New Duel» с отсчётом и двумя кнопками
        │   │   └── DuelWaitingView.swift     # ✅ «Waiting...»: песочные часы, «<друг> must accept the challenge in 3:00 minutes» с живым отсчётом, Cancel Challenge и ✕ отменяют вызов; по истечении — временное состояние «Time's up» (макета нет); на этапе UI друг не отвечает
        │   └── Activity/              # общий старт тренировки и дуэли
        │       ├── ActivityFlowView.swift    # ✅ лист с NavigationStack: ActivityMode (training / duel), ActivityFlowStart (с Choose Activity или сразу с Choose Exercise), общий макет экранов выбора, синие карточки ActivityChoiceCard, кнопка ✕; дуэль: Choose Exercise → Choose a Friend (Add Friend → лист поиска → карточка игрока) → Set a duel time → Waiting...; тренировка: Choose Exercise → лист закрывается → TrainingSessionView на весь экран
        │       ├── ChooseActivityView.swift  # ✅ «Choose Activity»: Duel / Train (только ✕)
        │       └── ChooseExerciseView.swift  # ✅ «Choose Exercise»: Push-Ups / Squats; режим передаётся дальше, ‹ — только если пришли с Choose Activity
        └── Assets.xcassets/           # ✅ AccentColor = #2A8DFD; Onboarding/OnboardingPushup — фигура с отжиманием (фон вырезан), Onboarding/OnboardingSetupPath — иконка-планшет, Onboarding/Goal* — иконки трёх целей; Paywall/PaywallTrialHero — телефон на пейволе (экспорт из Figma); Onboarding/CameraAccess* — телефон, карточка системного запроса и экран настроек для шага камеры (@3x); RatingRays — фон с лучами на экране Rating (@3x); Activity/Activity*, Exercise*, DuelWaiting — круглые иконки, DuelInviteVS — большой VS для входящего вызова (вырезан из макета), DuelLobbyBackground — тёмно-синий фон лобби, DuelResultCrown — корона победителя, DuelResult{Win,Loss,Draw}Background — фоны результата карточек Choose Activity / Choose Exercise (экспорт из Figma); иконка приложения пока пустая
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
| `PoseDetection` | 📋 | локальный пакет | Vision: точки тела и их уверенность |
| `ExerciseAnalyzer` | 🚧 | пакет `RepsCounterKit` | пока только тип `Exercise`; машины состояний — этап 3 |
| `Backend` | 🚧 | пакет `RepsCounterKit` | модели, правила рейтинга, тестовые данные, фабрика SupabaseClient; репозитории и Realtime — дальше |
| `CameraService` | 📋 | приложение | захват кадров, разрешения, прерывания, ориентация |
| `Auth` | 📋 | приложение | анонимная сессия Supabase, привязка ника к ID; после переустановки — новый профиль, восстановления нет |
| `Onboarding` | ✅ UI | `Features/Onboarding` | все экраны по макету, реальный запрос камеры; ник, регистрация и покупки — тестовые сервисы (сервер — этап 1) |
| `Profile` | ✅ UI | `Features/Profile`, `Features/Friends` | Profile и список Friends по макету на тестовых данных; поиск друга, карточка игрока и заявки — следующие экраны |
| `Home` / `Statistics` | ✅ UI | `Features/Home` | экран по макету в двух состояниях на тестовых данных; реальные данные — этап 5 |
| `Training` | 🚧 UI | `Features/Training` | тренировка на камере и результат готовы; сумма повторов и рекорды хранятся в UserDefaults; подсчёт повторов (Vision) и SwiftData — этап 3 |
| `Friends` | 📋 | приложение | поиск по точному нику, карточка игрока, заявки (всплывающий экран + плашка на всех табах), приглашения в дуэль |
| `Duel` | 🚧 | `Features/Duel` | только временный экран настройки; лобби, отсчёт, матч, результаты — этап 4 |
| `Ranking` | 🚧 | `Features/Rating` + `Backend/LeaderboardRanking` | один рейтинг по общей сумме, Global / Friends, на тестовых данных |

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

Проект не создан. В клиенте есть только `BackendConfiguration` (URL + публичный anon key → `SupabaseClient`). Здесь будут: таблицы и их назначение, RLS-политики, серверные функции, путь к миграциям.
