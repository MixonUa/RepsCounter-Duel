# Reps Counter — Project Instructions for Claude Code

> Product specification and engineering guardrails for the native iOS 18+ application. Read before editing code. **Confirmed requirements** are binding; **proposals / open decisions** are not yet approved. Do not mistake a prototype default for product policy.

## 1. Product vision
**Reps Counter** (the app's name; "Live Duel" is the name of its 1v1 duel mode) is a competitive fitness game for iPhone. Users perform squats and push-ups in front of an iPhone camera. On-device body-pose estimation and exercise-specific motion analysis count valid repetitions. Users can train individually and compete against an invited friend in synchronized live 1v1 duels.

## 2. Confirmed product decisions
- Build a native iPhone app with Swift and SwiftUI, with **minimum deployment target iOS 18.0**. Do not raise the deployment target without explicit approval.
- UI must reproduce the **approved Figma design** — file: https://www.figma.com/design/sdECikkyovjvnloQ6SqFqo/Vibecode-test (file key `sdECikkyovjvnloQ6SqFqo`); prefer Figma MCP as the source of exact frames, assets, sizes, spacing, and components. The visual direction is classic **light iOS** with Liquid Glass when supported. Do not introduce a dark esports theme.
- **Registration is part of onboarding and is mandatory**: the user enters a nickname (= username; the two words mean the same thing in this spec), the server registers it if it is not taken, and only then the user enters the app. No registration — no access to the app. First launch therefore needs a network connection.
- **No sign-in of any kind**: no Sign in with Apple, email/password, Google or any other login. The nickname is bound once, on first launch, to the user's account ID (Supabase Auth user ID of an anonymous session). There is no in-app profile reset and **no account recovery**: deleting the app and installing it again creates a new, empty profile with a new nickname. Multi-accounting is an accepted MVP risk.
- Profile = unique nickname + an **emoji icon** chosen by the user. **No photo upload** of any kind.
- Main navigation: **Home**, **Rating**, **Profile**, plus a visually separate **Duel** action at the right edge / outside the main body of the bottom bar (Figma: a round accent **VS** button next to a floating capsule tab bar). Exact layout and accessibility interaction must be validated against Figma.
- **Home** (Figma, 2026-11-19): greeting "Hello, <nickname>! 👋" + "Reps Counter" title + Settings button; **This week** card — total duel reps of the current Monday–Sunday week, date range and a chart of **duel repetitions per day** (past days light-blue bars, today accent, days without reps and future days gray pills; on first launch only today's pill is accent with "0"); **Your records** (training record per exercise, "+N this week" when improved); when there are no records yet a **Set a new record!** card with **Start Train**; **Recent duels** (last duel with **See all**, or **Win your first duel** + **Challenge a Friend**); a **weekly rank** card ("You're #24 this week · 6 more reps to break into the top 20") that opens Rating. **Profile** (Figma, 2026-11-19): blue header with the emoji avatar, Edit and Settings buttons, nickname with a copy button and the weekly place ("Top 11"); stats card (Duels Won, Win Rate, Total Reps); **Top Friends** — 3 best friends of the week (place, avatar, nickname, win rate, "joint reps"), recalculated weekly; **see all** opens **Friends** (friends with weekly place → player card, sent requests marked "Request Sent", **Add New Friend**; no tab bar). With no friends a provisional "No friends yet" card with **Add Friend** is shown. In a Top Friends row the win rate is **the friend's own** win rate, and "joint reps" is the friend's **combined** reps of the week (push-ups + squats from ranked duels; decided 2026-11-19).
- **Training record**: the best result achieved in training, **stored per exercise** (squats and push-ups separately; decided 2026-11-19). Screens show either the per-exercise records or their **sum**, as the design requires (e.g. the onboarding "Your records" card shows both exercises). Training never feeds the daily duel chart or rankings.
- Exercises: **squats** and **push-ups**.
- **Training** mode: individual camera-based workouts count accepted repetitions and update the personal training record; training repetitions do not contribute to rankings or to the daily duel chart. Training works offline once the user is registered.
- Camera setup: **portrait** orientation, and **every exercise is filmed from the front** (preferred; feasibility for push-ups must be validated on real devices before it is treated as final).
- App language: **English only**.
- **Live Duel**: exactly two users exercise simultaneously and compete on number of accepted repetitions within the chosen time.
- The host sets the **duel time** after choosing the friend (Figma "Set a duel time", decided 2026-11-19; replaces the earlier 30/60/90 s rule): presets **1 / 2 / 3 / 5 / 10 min** (single choice, 1 min preselected) or any value with **− / + in 10-second steps**; a non-preset value deselects the presets and **Send Challenge** stays enabled. Bounds **10 s … 10 min** are confirmed (2026-11-19); the server must validate the same range.
- Opponent is found **only through an in-app friends list and invitation**; no random matchmaking, share link, or matchmaking codes in MVP. Friend search is **only by exact username** (case-insensitive; no partial search, no address book access).
- Duel invitations are delivered by **push notifications** (APNs), backed by an in-app invitation inbox and realtime updates.
- **Every duel is ranked**; do not build a Ranked/Friendly switch without a new product decision.
- Duels use **strict repetition counting**, including pose quality, required range of motion, correct phase sequence and a return to the start position.
- Winner is the player with more accepted repetitions. Equal scores are a **draw**; there is no tie-break.
- Ranking is based on **accepted repetitions from finalized, valid ranked duels only**.
- **The rating is weekly** (decided 2026-11-19): leaderboard places and totals count accepted duel reps of the current week (Monday–Sunday, the week starts at Monday 00:00 UTC for everyone) and start over each week. Home shows "You're #N this week"; Profile shows the weekly place ("Top 11") and **Top Friends** — the 3 best friends of the week, recalculated once a week.
- Rating screen has **one leaderboard** with a **Global / Friends** selector. Layout (Figma, 2026-11-19): "Rating" title with my place + emoji chip at the top right; a podium for places 1–3 ("?" placeholders when empty); caption "Data is updated weekly" (empty Global adds "Become FIRST in the top!", empty Friends adds "Add friends to start your own top"); the full list from place 1 (Figma starts it at 4 — a design bug, decided 2026-11-19; gray skeleton rows when empty); my row is highlighted and pinned above the tab bar until it scrolls into view. The score is the **single total** of accepted duel repetitions (squats + push-ups combined). There are **no per-exercise leaderboards or per-exercise statistics** anywhere in the UI (decided 2026-11-19, follows Figma). Training repetitions are never included.
- Both players' accepted reps can count toward their leaderboard totals after a valid completed duel, regardless of who wins. Wins/losses and win rate are separate statistics, not leaderboard scoring factors.
- An interrupted, disputed, invalid or unfinalized match does not award leaderboard repetitions. Default MVP resolution rules are in section 6; any subsequent policy change requires explicit approval.

## 3. Technology and security boundaries
- UI: SwiftUI, SF Symbols, native accessibility APIs where suitable; support iOS 18 and later. Use iOS 26+ Liquid Glass APIs only within availability-guarded branches, with design-faithful standard SwiftUI/material fallbacks for iOS 18–25. Test both ranges.
- Camera: AVFoundation; handle permission refusal, camera interruption and device orientation.
- **Camera permission gates app entry** (Figma requirement, decided 2026-11-19): the last onboarding step ("Allow Access To Your Camera") shows the system alert on Continue; if denied, the same screen switches to "Access to the Camera is Restricted" with **Open Settings**, and the user reaches Home only after access is granted (also re-check when access is revoked later). iOS terminates the app when the permission changes in Settings, so onboarding **resumes at the saved step** after registration instead of starting over. Camera usage description: "Reps Counter uses the camera to count your squats and push-ups. Video is processed on your iPhone and is never uploaded." Risk to recheck before App Store submission: Guideline 5.1.1 (forcing permissions).
- Body landmarks: Apple Vision, starting with a tested 2D pipeline; evaluate 3D only if it measurably helps.
- Pose processing happens **on-device**. Do not upload raw video or frames by default; an eventual evidence/anti-cheat flow requires a separate privacy and product decision.
- Backend: **Supabase is the selected architecture direction** for Auth, PostgreSQL, Realtime, Storage and server-side functions. Before implementation verify current SDK/API compatibility, configuration and operating costs; do not claim it has already been provisioned.
- Authentication: an anonymous Supabase Auth session created on first launch; the profile row (nickname + emoji) is linked to its user ID. Nickname uniqueness is enforced server-side (case-insensitive unique constraint), never by the client alone. Nicknames are public identifiers, not credentials. Handle session refresh/expiry while the app stays installed.
- **Reinstall = new profile.** iOS Keychain items survive app deletion, so a session stored only in the Keychain would silently restore the old account after reinstall. Detect a fresh install (e.g. a marker in app storage, which is wiped on deletion) and clear any leftover Keychain session before onboarding. Profiles abandoned this way stay on the server; their cleanup/retention policy is an open decision.
- Multi-accounting is an accepted MVP risk (no login exists); still rate-limit registration server-side.
- No user-uploaded images: no photo storage. Profiles must never expose private authentication data.
- Never embed Supabase service-role keys, database secrets or privileged credentials in the client. Use least-privilege Row Level Security and private/authenticated channels.
- Treat clients as untrusted: they cannot directly award themselves leaderboard points, edit another player's match or finalize a match.
- **No in-app account deletion** (product decision 2026-11-19). Risk to recheck before App Store submission: App Store Review Guideline 5.1.1(v) requires in-app account deletion for apps that create accounts; the server-side profile is not removed when the app is deleted.
- **Required before release**: a privacy policy (camera use, on-device pose processing, nickname/statistics stored on the server, push token) and a `PrivacyInfo.xcprivacy` privacy manifest, plus a camera usage description. Data retention rules still need a decision.
- **Push notifications require the paid Apple Developer Program** (APNs is not available to a free Personal Team). Until the team changes, push cannot be tested; build the in-app inbox + realtime path so invites work without push.

### 3.1 Confirmed project setup (decided 2026-11-19)
- Xcode project: `RepsCounterDuel/RepsCounterDuel.xcodeproj`, target and shared scheme `RepsCounterDuel`, sources in `RepsCounterDuel/RepsCounterDuel/` (file-system synchronized groups: new files there are picked up automatically). On-screen app name is "Reps Counter" via `INFOPLIST_KEY_CFBundleDisplayName`.
- **Never put `:` in any folder, project, target, scheme or file name** — it breaks xcodebuild dependency files.
- Minimum iOS **18.0**, **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`), **Swift 6 language mode**, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` with approachable concurrency. UI orientation: **portrait only** for the iPhone. Camera/Vision processing must explicitly run off the main actor.
- Bundle ID (`com.RepsCounter-Duel`) and signing team: **do not change** without explicit approval.
- Verify builds on both the iOS 18.0 and iOS 26.x simulators.
- Module packaging: **hybrid** — one local Swift package with targets `DesignSystem`, `PoseDetection`/`ExerciseAnalyzer` and `Backend` (pure logic testable via `swift test`), and feature modules (Home, Training, Duel, Ranking, …) as folders in the app target.
- Backend client: official **`supabase-swift`** with a pinned version; verify current version and iOS 18 compatibility before adding.
- Training data: **SwiftData** locally with background sync to Supabase (training record), so training works offline after registration.
- Supabase: only a **`dev`** project (free tier) for now; `prod` is created before beta. Create projects, apply migrations or change data **only on an explicit user command**.

## 4. Suggested module boundaries
Keep these independently testable; adapt to the actual repository, and avoid a giant view model:
- `Auth` — nickname registration, auth session (Keychain) and profile bootstrap.
- `Onboarding` — first launch explanation and camera guidance.
- `Profile` — nickname, emoji icon, compact statistics, friends' results and settings.
- `Home` / `Statistics` — extended statistics, daily duel-reps chart, training record.
- `CameraService` — frame acquisition, orientation, interruptions.
- `PoseDetectionService` — Vision landmarks and confidence estimates.
- `ExerciseAnalyzer` — squat/push-up form analysis and rep finite-state machine.
- `Training` — solo workout session lifecycle and persistence.
- `Friends` — username lookup, friend requests, accept/decline, block/remove and in-app duel invitations.
- `Duel` — invitations, lobby, readiness, countdown, match and results.
- `Ranking` — single total-reps leaderboard (Global / Friends) and leaderboard data.
- `Backend` — Supabase SDK, repositories, auth-safe API calls and realtime synchronization.
- `DesignSystem` — semantic colors, typography, components, motions and accessibility.

## 5. Pose estimation and strict rep counting
- Represent exercises using deterministic, testable state machines (e.g. `ready -> descending -> bottomReached -> ascending -> completed -> ready`). Do not count raw up/down pixel movements.
- Verify visibility/confidence of relevant joints and full required movement phases. Apply signal smoothing, hysteresis and minimum stable observation windows to reduce double-counting and noise.
- Squats: evaluate hip/knee/ankle geometry, depth and return to standing using a sufficiently observable camera angle.
- Push-ups: evaluate shoulder/elbow/wrist geometry, body alignment and return to upper position. The camera is in front of the user, so depth and body alignment are partly foreshortened in 2D; validate early which checks are reliable from the front.
- Count **exactly once** only when a complete valid cycle finishes within the active scoring window; reject partial movements, duplicate transitions and uncertain pose segments.
- Low confidence, occlusion or a person leaving frame must produce actionable feedback, never invented repetitions.
- Provide a pre-duel calibration step and distance-readable feedback such as “Move back”, “Face the camera”, “Full body not visible”. The camera stands in portrait orientation in front of the user.
- Treat all numeric angle, timing, confidence and camera-position thresholds as **provisional tunable configuration**; calibrate with diverse real device recordings and real testers before claiming accuracy.
- Unit-test accepted reps, rejected/partial reps, noisy landmarks, left/right side handling, camera dropout, recovery, repeated events and end-of-timer boundary cases using recorded or synthetic pose sequences.
- Do not imply medical-grade assessment or certify perfect exercise form based on a single camera.

### 5.1 Current implementation (2026-11-20; thresholds provisional, not validated on devices)
- `ExerciseAnalyzer` (pure, `swift test`): each exercise is reduced to one scale-free extension signal measured from the front — squats: (kneeY − hipY) / (ankleY − kneeY), push-ups: (wristY − shoulderY) / shoulder width; both sides averaged, one visible side is enough. `RepCounter` calibrates on a held start position, then runs `ready → descending → bottomReached → ascending → rep` with smoothing, hysteresis, min/max rep duration and tracking-loss cancellation; thresholds are fractions of the player's own baseline (`RepCounterConfiguration`, all PROVISIONAL). Elbow-angle and body-alignment checks for push-ups are not used yet (unreliable from the front until validated).
- `PoseDetection`: Apple Vision 2D body pose on upright mirrored frames from the front camera.
- App: `WorkoutTracker` runs detection + counting on the camera's video queue; a rep scores only if its whole cycle lies in the scoring window (after the countdown; before the duel ends). The skeleton and provisional hints ("Full body not visible", "Move back", "Hold the start position", "Go lower to count the rep") are drawn over the camera.

## 6. Friends, invitations, and authoritative Live Duel lifecycle
Friend-based in-app invitations are **confirmed**. MVP behavior below is a **proposed implementation policy** until accepted in product review; keep constants configurable and do not claim these numbers have been user-approved.

### Friends and invitations
- Provide an in-app Friends screen reachable from the approved UI flow (do not add an unapproved fifth tab). Search only by the exact, case-insensitive username (it is unique, so no extra identifier is needed). Never expose account IDs, push tokens or private auth data.
- Friend requests: `pending -> accepted | declined | cancelled`; only accepted friends can invite each other. Support unfriend and block, with server-side authorization and privacy controls.
- **Add friend** flow (Figma, 2026-11-19): **Add a Friend** opens as a page sheet (✕, "Enter or paste your friend's full username", field with **Paste**, **Find User**); exact case-insensitive search; not found → red "User not found. Check username and try again"; found → the **player card** (Profile-style header with back button, stats, **Friends** — their **3 most recently added** friends with **see all**, public by product decision, and **+ Add Friend**). Provisional: own nickname → "That's your username…"; after sending the button shows "Request Sent", for friends "Friends".
- **Incoming friend request UI** (Figma, 2026-11-19): a page sheet with 👋, "New Friend !", "<nickname> sent you a request", **Add to Friends**, **Reject** and a close (✕) button. If closed without answering (✕ or swipe), a white banner with the same text and side-by-side **Add to Friends** / **Reject** stays pinned at the top of every tab (also over pushed screens) until the request is answered. Debug builds have a temporary **Invite** button on Home that simulates an incoming request.
- Invites are in-app records tied to host and intended friend, exercise and the chosen duration (10-second steps, range 10 s … 10 min). A friend can accept or decline only their own invite. Prevent a player joining two active matches. Expire pending invites after a configurable default of 3 minutes (Figma shows 3:00); cancel if host withdraws or disconnects before acceptance. Prevent duplicate and stale acceptance with transactional checks.
- Push notifications may be added later; an in-app invitation inbox and realtime updates are sufficient for MVP. An invitation must remain fetchable from database after a missed realtime event.

### Match lifecycle
States: `invited -> joined -> calibrating -> ready -> countdown -> live -> finalizing -> completed`, with explicit `expired`, `cancelled`, `forfeited`, `interrupted`, `disputed`, `invalid` where applicable. Server state is authoritative; state transitions are validated for user membership and legal sequence.
- Validate that the invite is accepted by the intended player, only two participants can join and the exercise and duration are immutable once locked.
- Both players pass camera readiness and explicitly confirm Ready before the countdown.
- Server owns match ID, roster, exercise, duration, start/end timestamps and authoritative state transitions; clients use clock-offset estimates for display.
- Realtime is used to share scores, ready status and connection status; it is **not the source of truth**. Use authenticated private Broadcast/Presence channels when supported by the chosen Supabase implementation.
- Number rep events monotonically per player and match, deduplicate events and reconcile with authoritative snapshots after reconnect. Never assume all realtime broadcasts arrive.
- Only accept eligible events within the scoring window. Avoid trusting arbitrary client-side timestamps alone. Account for bounded transmission delay in a policy that is tested and documented.
- Use atomic/idempotent server-side finalization: validate participants and state, record both scores and outcome, and award leaderboard repetitions **at most once**. Repeated finish requests must not duplicate stats.

### Connection loss / lifecycle policy (proposed MVP defaults)
- The server controls `starts_at` and `ends_at` in UTC, not client clocks. Both users must be Ready and have calibrated camera pose; countdown begins only when both are ready.
- Temporary disconnect: show a prominent reconnection banner; on-device counting may continue, but such reps are **provisional only**, pending server verification and inclusion within the original match window. No server-side timer pause.
- Reconnect grace: configurable initial default **10 seconds**. If the disconnect exceeds the grace interval while the match is live, mark the match `interrupted` and withhold rating repetitions from both players; do **not** silently grant the connected player a ranked win or award unverifiable repeats. Clear the provisional result in the UI.
- If a player deliberately taps Leave during `live`, record `forfeited` for outcome/win-loss display, but neither player receives leaderboard repetitions unless a separate verified-forfeit scoring policy is explicitly approved. Before countdown, leaving is a `cancelled` match with no rating impact.
- Camera permission revoked, app backgrounded, session interruption, or sustained loss of critical pose data: stop crediting unverifiable reps; display state and treat persistent inability to score as interruption, not an automatic fair-play win. Differentiate camera failure from intentional cheating only when evidence supports it.
- Server/network outage affecting match state: mark `disputed`/`interrupted`, preserve evidence and retry safely; never optimistically credit rating.
- Countdown and score windows are based on server timestamps. A cycle counts only when fully completed before `ends_at`. Account for bounded network delay through signed/session-bound event ordering and latency checks; **device timestamps alone are not proof**.
- On normal expiration, enter `finalizing`; validate and finalize atomically. Show `completed` only after the server confirms the result. If results disagree or cannot be validated, show `under review`/`disputed` and award no rating until resolved.
- Outcome: greater accepted repetitions wins; equal accepted repetitions are a **draw**, both users' eligible repetitions count. Neither repeated finalization nor repeat reconnect can award points more than once.

### Anti-cheat and leaderboard integrity
- Never treat Realtime broadcasts, client counters, device time, or an Apple device attestation as proof of actual physical repetitions.
- Require an authenticated match session, unique ordered rep events, bounded rates, plausibility checks, authoritative phase/timing constraints, and atomic server reconciliation. Reject duplicate/out-of-window events, missing participants, impossible rates and ineligible match states.
- Apply per-pair repeat-duel and high-volume anomaly monitoring, rate-limit friend requests/invites, and maintain auditable moderation flags. **Do not silently invent a lifetime rep cap or daily quota.** Flag suspicious repeated matches for review or withhold rewards according to an explicit policy.
- Key limitation: without independently trusted evidence, a modified client can fabricate plausible rep sequences. These mechanisms reduce casual abuse but do not guarantee cheat-proof rankings. Before a high-stakes public competitive launch, run a threat-model review and decide whether additional privacy-consented evidence or anti-fraud infrastructure is acceptable.
- Store only the minimum necessary posture events and logs with a retention policy; do not record or upload video for anti-cheat by default.

## 7. Leaderboard and statistics invariants
- Maintain immutable/finalized duel result records as the audit source; derive leaderboard totals from eligible completed duel results or maintain a server-updated aggregate with idempotent transactions.
- `totalDuelReps = completedRankedSquatReps + completedRankedPushupReps` for each player — the only leaderboard and statistics total shown in the UI. Per-exercise reps may be kept in duel records (each duel has one exercise) but are not displayed or ranked separately.
- Distinguish `trainingRecords` (per exercise; the total is their sum), `duelReps`, `duelsWon`, `duelsLost`, `duelsTied`, and **daily duel reps** (per calendar day, the sum of accepted reps from finalized duels — the source of the Home chart); do not combine training with leaderboard totals or the daily chart.
- Friends leaderboards use the same totals and ranking rules as global ones, limited to the player and their accepted friends.
- If two players have equal leaderboard totals, show the **same displayed rank**; use a stable secondary sort such as public username and account ID for deterministic pagination, never represent that sort as a sporting tiebreaker.
- Return deterministic ordering and paginate leaderboard results.
- Enforce user-level access policies; never rely on obscured client UI for authorization.

## 8. UI/UX and approved Figma — CONFIRMED
- The existing approved **Figma designs are the source of truth** for screen appearance. Use the official Figma MCP to inspect relevant frames before implementing screens, if available and authorized. If unavailable, request design references or flag the limitation; do not claim to have inspected Figma.
- Visual direction: **classic light iOS appearance**, using **native Liquid Glass on iOS 26+ where the approved design calls for it**. For **iOS 18–25**, provide visually consistent, accessible native SwiftUI controls/material fallbacks. Never use iOS 26-only APIs on iOS 18 without `#available(iOS 26, *)` or equivalent availability isolation.
- Prefer semantic design tokens and shared SwiftUI components extracted from Figma. Match approved layout, typography, colors, spacing, assets and interaction states. Do not invent or impose a new theme; never use a dark gaming palette merely because the product is competitive.
- Keep Home, Rating, Profile and the separately prominent right-hand Duel action consistent with approved Figma. Check accessible touch targets, Dynamic Type, contrast, safe areas and VoiceOver. Do not assume standard `TabView` automatically matches the custom layout.
- Preserve distance-readable live workout/duel counters and safety/tracking feedback in accordance with approved camera-screen designs. If a functional requirement conflicts with Figma, explain the conflict and request a design decision rather than silently changing either.
- Include permission, calibration, loading, tracking loss, reconnecting, empty-state and error-state UI; use Figma variants where available; otherwise label new states as provisional.
- Implement visual comparison/inspection for target devices and iOS 18 and 26+ when test devices/simulators are available; never claim pixel-perfect match without verification.
- Do not modify Figma files without approval. Do not expose Figma authentication tokens or embed design API secrets in the app.
- Screen scope: Onboarding (see 8.1), Home, Rating (Global / Friends, single total), Profile, Friends list (See all), Add Friend search + player card, incoming friend request pop-up + pinned banner, Training Setup, Camera Calibration, Training Live/Results, Duel Setup, Invite/Join, Ready Lobby, Countdown, Live Duel, Results. Screen existence does not mean Figma has all variants; inspect first.
- Opponent live video streaming is **not** an approved feature. Show the opponent's emoji icon, nickname and live score unless approved design/product requirements say otherwise.
- UI text is **English only**. Sound and haptic preferences remain open decisions.

### 8.1 Screen inventory from Figma (described by the user 2026-11-19; Figma MCP access still pending)
- **Onboarding, in order:** 2 intro slides → nickname registration → emoji choice → confirm nickname + emoji (server registration) → motivation choice (3 buttons; engagement only, not stored on the server and does not affect app logic) → 2 explanation slides ("Train Solo Or Challenge Friends", animated "Building Your Personal Path") → **paywall** → camera permission → Home, or the "camera tips" screen with **Open Settings** until permission is granted.
- **Settings** (Figma, 2026-11-19; opened from the gear on Home and Profile): **Reps Counter PRO** card with **Go PRO** (opens the shared paywall); General — **Rep sound** On/Off (stored; no sounds exist yet) and **First day of the week** Mon/Sun (affects only how the Home "This week" chart is drawn; the weekly rating always resets Monday 00:00 UTC); Support — **Rate the app** (system review prompt), **Share with friends** (share sheet); More — **Contact us**, **Privacy Policy**, **Terms of Service**. Support e-mail and App Store link are still unknown.
- **Edit Profile** (no Figma frame — provisional design, 2026-11-19): Profile-style header; tapping the avatar opens the emoji grid; a pencil next to the nickname opens a custom alert to change it with the same validation and availability check as onboarding. **The nickname can be changed** (decided 2026-11-19); the server must re-check uniqueness on rename.
- **Paywall** (in Figma, added 2026-11-19): "Train Smarter / Free for 3 Days", 3-day free trial then $6.99/week, **Start for $0.00**, ✕ to skip, footer **Terms of Use · Privacy Policy · Restore**. Built as a reusable layout (`PaywallView` + `PaywallContent`) so other paywalls reuse it. A second paywall, **Go PRO** (Settings → Go PRO): "Go PRO, Keep Going", **Yearly Plan** $29.99/year ($0.58 per week, badge "1 Week Free", preselected) or **Weekly Plan** $7.99/week, "✅ Full Refund, No Questions Asked", **Start for $0.00**. Current behaviour is UI-only with a mock purchase service; ✕ and a started trial both continue onboarding.
- **Tab bar:** Home, Rating, Profile + a separate Duel button on the right.
- **Choose Activity / Choose Exercise** (Figma, 2026-11-19): the VS button opens a sheet "Choose Activity" (Duel / Train, ✕); either card leads to "Choose Exercise" (Push-Ups / Squats, ‹ and ✕). Home "Start Train" and "Challenge a Friend" open Choose Exercise directly. Choose Exercise is shared and receives the mode (training or duel), which decides the screens that follow. In duel mode it leads to **Choose a Friend**: with nobody added — 🤝, "You can challenge only your friends. Add friend to create a duel." and **+ Add Friend**; with only sent requests — the same hint above the list, requests grayed with "Request Sent" and not selectable (Figma's "Level 7" under a request is a design bug); with accepted friends — the list ("Top N") and **Add New Friend**; tapping a friend opens **Set a duel time**, whose **Send Challenge** creates the invitation and opens **Waiting...** (hourglass, "<friend> must accept the challenge in 3:00 minutes" with a live countdown, **Cancel Challenge**, ✕ only). Provisional: ✕ also withdraws the invitation; at 0:00 the invitation expires and a "Time's up" state with **Close** is shown (no Figma frame).
- **Incoming duel invitation** (Figma, 2026-11-19): same pattern as the incoming friend request — a page sheet ("3:00 LEFT" countdown, ✕, big VS, "New Duel !", "<host> invited you to a <exercise> competition", **Start Duel !** / **Refuse**); closing it leaves a white banner pinned over every tab ("New Duel" + countdown, the same line, side-by-side Start Duel ! / Refuse) until answered. Provisional: an expired invitation silently disappears. Debug builds: launch argument `-debugIncomingDuel YES` simulates one.
- **Ready to duel? lobby** (Figma, 2026-11-19): full screen on the dark blue Figma backdrop (an approved exception to the light theme for duel screens); ‹ leaves (before the countdown = cancelled, no rating impact); "<exercise> competition"; both emoji avatars with VS; **HEAD TO HEAD** card (my value left, the opponent's right: training PR for the duel's exercise, Duels Won, Win Rate; in each row the bigger value is fully opaque and the smaller one at 50% on either side, equal values both opaque — decided 2026-11-20); **I'm Ready**; the opponent's status (green dot "<name> is ready"). The countdown starts only when both are ready. Opens for the host when the friend accepts (Waiting... closes) and for the invitee after Start Duel !. Provisional: "Waiting for <name>…" status and a disabled "You're ready" button after tapping. Debug: `-debugAutoAccept YES` makes the invited friend accept after 3 s; in the UI stage the opponent becomes ready after 3 s.
- **Live duel** (Figma, 2026-11-19): every element is an overlay on the full-screen **front camera** (only the front camera is opened; nothing is recorded). Countdown 3 · 2 · 1: black top bar (YOU green badge, opponent initials red badge, "<Exercise> · 60 seconds", "Both of you start together", green/red bar), a round "GET READY" counter in the middle, bottom panel "GET IN FRAME / <Exercise> / Step back so your whole body fits". Then live: the top bar shows both scores and "0:31 LEFT"; the bar shows the share of reps (50/50 at 0:0); **green marks the leader** — at the start (and on a tie) I am green and the opponent red, and the badges and bar colors swap while the opponent is ahead (decided 2026-11-20); the bottom panel shows "YOUR REPS", the big number, "<opponent> is on N" and **Give up** (provisional confirmation; leaving during live = forfeit). The pose skeleton from the mockup appears once pose detection exists (stage 3). UI stage: my reps are not counted (DEBUG: tap the number), the opponent's are mock.
- **Training session** (Figma, 2026-11-20): Choose Exercise in training mode closes the sheet and opens a full-screen screen over the front camera. Before start: black top bar with a blue YOU badge, "<Exercise> · Practice", "No timer — stop when you want"; bottom panel "GET IN FRAME / <Exercise> / Step back so your whole body fits" + **Start**. Start hides the button and shows the 3 · 2 · 1 counter in the middle; at the same moment the top bar switches to ✕ + centered title and the bottom panel to "REPS", the count and **Finish**. No timer. Provisional: ✕ in the bar before Start (Figma has no exit there), Finish disabled during the countdown; ✕ leaves without a result. UI stage: reps not counted (DEBUG: tap the number).
- **Training result** (Figma, 2026-11-20): dark blue backdrop, ‹ and share, "Great Job!" (0 reps: "Don't Give Up !" / "Do an exercise to continue your streak"), my avatar, "<N> Reps", a card with **Total Reps** (every training rep ever done, kept on the phone, "+N" for this session; never reset) and the weekly rank, **Continue Practice** (a new session of the same exercise) and **Exit**. Each finished session updates the per-exercise training record, shown on Home. Figma's "New Rank #18" / "Do 6 more reps to break into the top 20" conflict with §2 (training never affects the rating), so it is decided (2026-11-20): the card always shows **"Your Rank"** (the unchanged weekly duel rank) and the subtitle says "Do N more duel reps to break into the top M" (or "New <exercise> record!" after a record). "streak" in the 0-reps copy has no feature behind it yet.
- **Duel results** (Figma, 2026-11-19): three variants on a black base with the Figma backdrop — green "You Won!", red "You Lost", blue "Draw"; "<Exercise> competition"; both avatars with the score between them (winner wears the crown, the loser is dimmed; no crown on a draw), "PR N" under each name; a chip "⚡ Won by N reps" / "N Reps were not enough" / "Equal result"; a card with **Total Reps** (+ this duel's reps) and **Win Rate** (± percentage points, hidden when unchanged); **Play Again** and **Exit**. Provisional: Play Again returns to a fresh lobby with the same friend/exercise/time (stage 4: a new challenge that must be accepted). The final screen must show only server-finalized results (§6).
- Not yet designed (decide later; build as labelled provisional states): nickname-taken / offline errors, duel reconnect / interrupted / under-review states, unfriend/block, training-record definition.

## 9. Tests and definition of done
- Build with the actual installed Xcode version and project deployment target; do not presume latest APIs work on the supported minimum iOS version.
- Test exercise engine as pure logic where possible; add end-to-end tests for login/profile, training persistence, invite acceptance, duel lifecycle, tie, reconnect, timeout, cancellation, leaderboard eligibility and idempotent finalization.
- Test camera and pose estimation on **physical iPhones** across framing, lighting, body sizes and both exercises. Simulator-only validation is insufficient. Explicitly check UI functionality on iOS 18–25 and iOS 26+ (including Liquid Glass/fallback behavior).
- Verify permissions and failure states, Dynamic Type, VoiceOver labels, safe-area layout and degraded connectivity.
- Do not claim functionality is tested or ready for release unless it was built and verified in the relevant environment.

## 10. Claude Code operating instructions
1. Read this `CLAUDE.md`, inspect repository layout and relevant existing code before making changes. This may be a pre-existing prototype with different data models; do not silently break it.
2. Discover the actually installed iOS/SwiftUI, Swift Concurrency, architecture and testing skills; use the relevant ones only. Installed skills in `~/.claude/skills/` include `swiftui-expert-skill`, `swiftui`, `design`, `ios`, `swift-concurrency`, `core-ml`, `testing`, `performance`, `release-review`; re-check the list instead of assuming. Use official Figma MCP for Figma-based UI work when connected.
3. State a short plan for non-trivial modifications, identify affected modules and important assumptions.
4. Follow feature boundaries and existing conventions; use modern, compatible native APIs and avoid speculative third-party dependencies.
5. Implement incremental focused changes; preserve unrelated user edits and working features.
6. Verify current documentation for Swift, Vision, Supabase SDK and Xcode integration when the implementation depends on recent API details.
7. Run builds and relevant tests if Xcode/tools are accessible; fix introduced issues and explain any verification that was impossible.
8. Before changing schema, authentication, data migration, camera recording, permissions, signing or production credentials, explain risks and request explicit authorization for destructive or privacy-sensitive changes.
9. Never reset or delete production/dev user data, leak secrets, or change project signing silently.
10. When done, report changed files, behavioral changes, build/test commands actually run, outcomes, and unresolved risks.
11. **Maintain `ProjectTree.md`** (repository root, next to this file) — the shared map of the project for the developer and Claude. Read it at the start of work to orient yourself. In the **same change** that adds, moves, renames or deletes files/modules, or changes how a feature is implemented, update it: the repository tree with a one-line purpose per file/folder, module status (✅ implemented / 🚧 in progress / 📋 planned), key flows as "screen → service → data" with file paths, tests, backend tables/policies/migrations, and the "Last updated" line. Write it **in Russian**, plainly, describing what exists and how it works — never list planned items as implemented. A task that changes structure is not done until `ProjectTree.md` matches the code.

## 11. Remaining open decisions and configurable MVP defaults
- Figma frame-by-frame mapping to screens, asset export rules and variant coverage (the file itself is confirmed, see section 2). Language (English only) and name (Reps Counter) are decided.
- Supported iPhone models: to be determined by real-device testing of Vision performance. Portrait + front-facing camera is the preferred arrangement; minimum iOS is **confirmed at 18.0**.
- Specific validated exercise thresholds, acceptable form, permitted camera angles, allowed floor/knee variants, and occlusion/lighting limits.
- **Friends-list invitation and push delivery are confirmed.** Friend-request moderation, invite expiry (3 min per Figma "Waiting...", configurable), duplicate protection and push content must be validated against approved Figma flow.
- **Connection and match policies are proposed MVP defaults** (10-second reconnect grace, disputed/abandoned matches yield zero leaderboard credit, no timer pause); get explicit approval before treating them as business rules for production.
- No additional duel tie-break: a duel with equal accepted reps is a draw; equal leaderboard totals share the same displayed rank.
- Repeat-match anti-abuse thresholds, evidence retention, moderation/appeals and when a result may be reinstated.
- Nickname rules: allowed characters and length, how often a nickname may be changed, reserved/offensive nickname filtering. Emoji icon: free choice from the system emoji keyboard or a fixed set (check Figma).
- **Training record definition**: best reps in one training session, per exercise (decided). Still open: does it depend on the chosen duration?
- Daily duel chart: time zone of a "day" (proposed: the user's local calendar day) and the range shown (check Figma).
- Rating period details: the weekly rating resets at **Monday 00:00 UTC** for everyone (decided 2026-11-19; the Home daily chart still uses the user's local day). Still open: whether past weeks/all-time totals are shown anywhere, and the "top N" milestones (1/2/3/5/10/20/…).
- Retention/cleanup of profiles abandoned after reinstall (they still appear in friends lists and rankings).
- Whether match sound, haptics and countdown voice prompts are optional.
- **Monetization (open):** trial length differs between paywalls (3 days onboarding vs 1 week yearly) — confirm; the Go PRO copy "Full Refund, No Questions Asked" is risky because App Store refunds are decided by Apple, not the developer (App Review may treat it as misleading) — confirm wording before release; button text for the weekly plan is not in Figma; which features the subscription unlocks (and what a user who closes the paywall can do), final price/trial/products, where else paywalls appear, Terms of Use and Privacy Policy URLs. Before release: StoreKit 2 products in App Store Connect (paid Apple Developer Program), localized price taken from StoreKit (never hard-coded copy), working Restore, and App Review guideline 3.1.2 subscription disclosures.

## 12. Product invariants and safeguards
- In-app invitation **from the friends list** is the only approved opponent discovery mechanism. Every accepted duel is **ranked**, with the host choosing the duel time (presets 1–10 min or 10-second steps); there is no friendly switch.
- The ranking shows a **single total** = qualified squat reps + qualified push-up reps from duels, Global and among Friends. Training repetitions never affect any leaderboard or statistic other than the training record.
- Winners are determined by valid repetitions during the agreed window; a tie is allowed. A losing player still receives earned leaderboard repetitions if both results are verified and the duel is finalized.
- **Important:** detailed thresholds for reconnect, friend invite expiry, anti-abuse review and disputed matches are documented as proposed MVP policies, not user-approved business rules. Keep them configurable, test their UX, and request sign-off before production release. The safe invariant remains: never award repetitions for invalid, disputed or interrupted matches.

Use reversible, explicitly labeled prototypes for undecided UX details; never silently turn proposed defaults into confirmed requirements.

## 13. Suggested backend entities and state invariants
Implement via versioned SQL migrations once authorized; names can follow existing repository conventions:
- `profiles` (public unique nickname, emoji icon, privacy-safe profile fields; linked to the anonymous auth user ID)
- `push_tokens` (APNs device tokens per user, private)
- `daily_duel_stats` or a derived view (user, date, accepted duel reps) — source of the Home chart
- `friend_requests` and `friendships` (pending/accepted/rejected/blocked, pair uniqueness and authorization)
- `duel_invitations` (inviter, intended invitee, exercise, duration, status, expiry)
- `duels` (server start/end, state, result, adjudication)
- `duel_participants` (two players, accepted/verified reps, readiness, finish outcome)
- `duel_rep_events` (event IDs, sequence, matching session, deduplication/reconciliation metadata)
- `training_sessions` / training record (private personal training data, excluded from ratings and the daily duel chart)
- `leaderboard_totals` (derived or server-maintained transactional totals for eligible completed matches only)

For friend acceptance and duel finalization, use transactions / safe RPC / server functions; use RLS on user-facing tables and private realtime authorization. Include database integration tests for cross-user reads/writes, duplicate requests and concurrent changes. Audit access to sensitive fields (push tokens, auth IDs).

## 14. Implementation sequence
1. Inspect the actual iOS project, Xcode scheme, deployment target and approved Figma frames; document any differences without overwriting work.
2. Onboarding with mandatory nickname registration (anonymous auth, emoji icon, fresh-install detection) + profiles + Friends, with end-to-end authorization and RLS tests. This is the first development stage because registration happens in onboarding.
3. Camera + Vision pose landmarks + deterministic, testable rep analyzers + offline training.
4. Invitations + lobby + synced time + duel client state + private Realtime + database reconciliation.
5. Verified results + leaderboard aggregation + edge-case/integrity tests.
6. Visual QA against Figma, iOS 18 fallback/iOS 26+ Liquid Glass, accessibility, physical-device calibration and release hardening.

Do not interpret this sequence as permission to provision services, access private repositories, rotate credentials, delete data, ship to production or modify Figma without explicit user authorization.
