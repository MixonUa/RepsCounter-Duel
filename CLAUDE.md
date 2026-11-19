# Live Duel — Project Instructions for Claude Code

> Product specification and engineering guardrails for the native iOS 18+ application. Read before editing code. **Confirmed requirements** are binding; **proposals / open decisions** are not yet approved. Do not mistake a prototype default for product policy.

## 1. Product vision
Live Duel is a competitive fitness game for iPhone. Users perform squats and push-ups in front of an iPhone camera. On-device body-pose estimation and exercise-specific motion analysis count valid repetitions. Users can train individually and compete against an invited friend in synchronized live 1v1 duels.

## 2. Confirmed product decisions
- Build a native iPhone app with Swift and SwiftUI, with **minimum deployment target iOS 18.0**. Do not raise the deployment target without explicit approval.
- UI must reproduce the **approved Figma design**; prefer Figma MCP as the source of exact frames, assets, sizes, spacing, and components. The visual direction is classic **light iOS** with Liquid Glass when supported. Do not introduce a dark esports theme.
- First-run onboarding followed by **registration with a unique nickname** bound to the user's account (decided 2026-11-19; replaces the earlier Sign in with Apple requirement). **No Sign in with Apple**, email/password or Google sign-in unless explicitly approved later. What the nickname is bound to (e.g. device-held anonymous Supabase session in Keychain, optional recovery later) is an **open decision** — see section 11; do not implement account binding/recovery before it is decided.
- User profile supports a user-uploaded photo or a default avatar.
- Main navigation: **Home**, **Rating**, **Profile**, plus a visually separate **Duel** action at the right edge / outside the main body of the bottom bar. Exact layout and accessibility interaction must be validated.
- Home and Profile: personal statistics, workout history, weekly activity and related progress displays.
- Exercises: **squats** and **push-ups**.
- **Training** mode: individual camera-based workouts count accepted repetitions and store personal training data; training repetitions do not contribute to global rankings.
- **Live Duel**: exactly two users exercise simultaneously and compete on number of accepted repetitions within the chosen time.
- Host chooses **30, 60 or 90 seconds** before inviting a friend.
- Opponent is found **only through an in-app friends list and invitation**; no random matchmaking, share link, or matchmaking codes in MVP. Friend search is by exact username (not address book access).
- **Every duel is ranked**; do not build a Ranked/Friendly switch without a new product decision.
- Duels use **strict repetition counting**, including pose quality, required range of motion, correct phase sequence and a return to the start position.
- Winner is the player with more accepted repetitions. Equal scores are a tie (pending additional tie-policy detail).
- Ranking is based on **accepted repetitions from finalized, valid ranked duels only**.
- Rating screen has **Overall**, **Squats**, and **Push-ups** leaderboards. Overall is the sum of each player's counted Squats + Push-ups duel repetitions; separate categories use their respective exercise totals.
- Both players' accepted reps can count toward their leaderboard totals after a valid completed duel, regardless of who wins. Wins/losses and win rate are separate statistics, not leaderboard scoring factors.
- An interrupted, disputed, invalid or unfinalized match does not award leaderboard repetitions. Default MVP resolution rules are in section 6; any subsequent policy change requires explicit approval.

## 3. Technology and security boundaries
- UI: SwiftUI, SF Symbols, native accessibility APIs where suitable; support iOS 18 and later. Use iOS 26+ Liquid Glass APIs only within availability-guarded branches, with design-faithful standard SwiftUI/material fallbacks for iOS 18–25. Test both ranges.
- Camera: AVFoundation; handle permission refusal, camera interruption and device orientation.
- Body landmarks: Apple Vision, starting with a tested 2D pipeline; evaluate 3D only if it measurably helps.
- Pose processing happens **on-device**. Do not upload raw video or frames by default; an eventual evidence/anti-cheat flow requires a separate privacy and product decision.
- Backend: **Supabase is the selected architecture direction** for Auth, PostgreSQL, Realtime, Storage and server-side functions. Before implementation verify current SDK/API compatibility, configuration and operating costs; do not claim it has already been provisioned.
- Authentication: nickname registration on top of a Supabase Auth session (no Sign in with Apple). Store session tokens only in the Keychain, handle session restoration, expiry/refresh and a lost or reset device. Nickname uniqueness is enforced server-side (case-insensitive unique constraint), never by the client alone. Nicknames are public identifiers, not credentials.
- Without an external identity, creating many accounts is cheap. Treat multi-accounting as a leaderboard-abuse risk (section 6): rate-limit registration and keep server-side signals for review.
- Store photos in access-controlled storage with appropriate file-size/type restrictions. Profiles must never expose private authentication data.
- Never embed Supabase service-role keys, database secrets or privileged credentials in the client. Use least-privilege Row Level Security and private/authenticated channels.
- Treat clients as untrusted: they cannot directly award themselves leaderboard points, edit another player's match or finalize a match.
- Account deletion, data retention and privacy rules need explicit product decisions and platform-compliant implementation before release.

### 3.1 Confirmed project setup (decided 2026-11-19)
- Xcode project: `RepsCounterDuel/RepsCounterDuel.xcodeproj`, target and shared scheme `RepsCounterDuel`, sources in `RepsCounterDuel/RepsCounterDuel/` (file-system synchronized groups: new files there are picked up automatically). On-screen app name is "RepsCounter:Duel" via `INFOPLIST_KEY_CFBundleDisplayName`.
- **Never put `:` in any folder, project, target, scheme or file name** — it breaks xcodebuild dependency files.
- Minimum iOS **18.0**, **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`), **Swift 6 language mode**, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` with approachable concurrency. Camera/Vision processing must explicitly run off the main actor.
- Bundle ID (`com.RepsCounter-Duel`) and signing team: **do not change** without explicit approval.
- Verify builds on both the iOS 18.0 and iOS 26.x simulators.
- Module packaging: **hybrid** — one local Swift package with targets `DesignSystem`, `PoseDetection`/`ExerciseAnalyzer` and `Backend` (pure logic testable via `swift test`), and feature modules (Home, Training, Duel, Ranking, …) as folders in the app target.
- Backend client: official **`supabase-swift`** with a pinned version; verify current version and iOS 18 compatibility before adding.
- Training data: **SwiftData** locally with background sync to Supabase, so training works offline.
- Supabase: only a **`dev`** project (free tier) for now; `prod` is created before beta. Create projects, apply migrations or change data **only on an explicit user command**.

## 4. Suggested module boundaries
Keep these independently testable; adapt to the actual repository, and avoid a giant view model:
- `Auth` — nickname registration, auth session (Keychain) and profile bootstrap.
- `Onboarding` — first launch explanation and camera guidance.
- `Profile` — nickname/avatar and settings.
- `Home` / `Statistics` — personal progress and history.
- `CameraService` — frame acquisition, orientation, interruptions.
- `PoseDetectionService` — Vision landmarks and confidence estimates.
- `ExerciseAnalyzer` — squat/push-up form analysis and rep finite-state machine.
- `Training` — solo workout session lifecycle and persistence.
- `Friends` — username lookup, friend requests, accept/decline, block/remove and in-app duel invitations.
- `Duel` — invitations, lobby, readiness, countdown, match and results.
- `Ranking` — Overall / Squats / Push-ups views and leaderboard data.
- `Backend` — Supabase SDK, repositories, auth-safe API calls and realtime synchronization.
- `DesignSystem` — semantic colors, typography, components, motions and accessibility.

## 5. Pose estimation and strict rep counting
- Represent exercises using deterministic, testable state machines (e.g. `ready -> descending -> bottomReached -> ascending -> completed -> ready`). Do not count raw up/down pixel movements.
- Verify visibility/confidence of relevant joints and full required movement phases. Apply signal smoothing, hysteresis and minimum stable observation windows to reduce double-counting and noise.
- Squats: evaluate hip/knee/ankle geometry, depth and return to standing using a sufficiently observable camera angle.
- Push-ups: evaluate shoulder/elbow/wrist geometry, body alignment and return to upper position.
- Count **exactly once** only when a complete valid cycle finishes within the active scoring window; reject partial movements, duplicate transitions and uncertain pose segments.
- Low confidence, occlusion or a person leaving frame must produce actionable feedback, never invented repetitions.
- Provide a pre-duel calibration step and distance-readable feedback such as “Move back”, “Turn sideways”, “Full body not visible”.
- Treat all numeric angle, timing, confidence and camera-position thresholds as **provisional tunable configuration**; calibrate with diverse real device recordings and real testers before claiming accuracy.
- Unit-test accepted reps, rejected/partial reps, noisy landmarks, left/right side handling, camera dropout, recovery, repeated events and end-of-timer boundary cases using recorded or synthetic pose sequences.
- Do not imply medical-grade assessment or certify perfect exercise form based on a single camera.

## 6. Friends, invitations, and authoritative Live Duel lifecycle
Friend-based in-app invitations are **confirmed**. MVP behavior below is a **proposed implementation policy** until accepted in product review; keep constants configurable and do not claim these numbers have been user-approved.

### Friends and invitations
- Provide an in-app Friends screen reachable from the approved UI flow (do not add an unapproved fifth tab). Search by unique, case-insensitive nickname and disambiguating identifier where needed. Never expose email, Apple ID, phone number or private auth data.
- Friend requests: `pending -> accepted | declined | cancelled`; only accepted friends can invite each other. Support unfriend and block, with server-side authorization and privacy controls.
- Invites are in-app records tied to host and intended friend, exercise and 30/60/90 s duration. A friend can accept or decline only their own invite. Prevent a player joining two active matches. Expire pending invites after a configurable default of 2 minutes; cancel if host withdraws or disconnects before acceptance. Prevent duplicate and stale acceptance with transactional checks.
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
- `overallReps = completedRankedSquatReps + completedRankedPushupReps` for each player.
- Distinguish `trainingReps`, `duelReps`, `duelsWon`, `duelsLost`, `duelsTied`, and weekly activity; do not combine training with leaderboard totals.
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
- Screen scope: Onboarding, Nickname Registration, Create Profile, Home, Overall/Squats/Push-ups Ranking, Profile, Training Setup, Camera Calibration, Training Live/Results, Duel Setup, Invite/Join, Ready Lobby, Countdown, Live Duel, Results. Screen existence does not mean Figma has all variants; inspect first.
- Opponent live video streaming is **not** an approved feature. Prefer avatar, nickname and live score unless approved design/product requirements say otherwise.
- App language/localization, sound and haptic preferences remain open decisions.

## 9. Tests and definition of done
- Build with the actual installed Xcode version and project deployment target; do not presume latest APIs work on the supported minimum iOS version.
- Test exercise engine as pure logic where possible; add end-to-end tests for login/profile, training persistence, invite acceptance, duel lifecycle, tie, reconnect, timeout, cancellation, leaderboard eligibility and idempotent finalization.
- Test camera and pose estimation on **physical iPhones** across framing, lighting, body sizes and both exercises. Simulator-only validation is insufficient. Explicitly check UI functionality on iOS 18–25 and iOS 26+ (including Liquid Glass/fallback behavior).
- Verify permissions and failure states, Dynamic Type, VoiceOver labels, safe-area layout and degraded connectivity.
- Do not claim functionality is tested or ready for release unless it was built and verified in the relevant environment.

## 10. Claude Code operating instructions
1. Read this `CLAUDE.md`, inspect repository layout and relevant existing code before making changes. This may be a pre-existing prototype with different data models; do not silently break it.
2. Discover the actually installed iOS/SwiftUI, Swift Concurrency, architecture and testing skills; use the relevant ones only. The Apple Skills / `ios-dev` skill may help if available, but never assume it is installed. Use official Figma MCP for Figma-based UI work when connected.
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
- Exact Figma file/frame references, approved asset export rules and variant coverage; app UI languages and branded naming.
- Supported iPhone models and portrait-vs-landscape camera arrangement. Minimum iOS is **confirmed at 18.0**, not open.
- Specific validated exercise thresholds, acceptable form, permitted camera angles, allowed floor/knee variants, and occlusion/lighting limits.
- **Friends-list invitation is confirmed.** Nickname search, friend-request moderation, invite expiry (proposed 2 min), duplicate protection and notifications must be validated against approved Figma flow.
- **Connection and match policies are proposed MVP defaults** (10-second reconnect grace, disputed/abandoned matches yield zero leaderboard credit, no timer pause); get explicit approval before treating them as business rules for production.
- No additional duel tie-break: a duel with equal accepted reps is a draw; equal leaderboard totals share the same displayed rank.
- Repeat-match anti-abuse thresholds, evidence retention, moderation/appeals and when a result may be reinstated.
- **Nickname account binding and recovery**: what the nickname account is bound to (device-held anonymous session only vs. later linking of email or a recovery code), behavior on a new/reset device, nickname change rules and reserved/offensive nickname filtering. Blocks the Auth stage.
- Exact profile fields, privacy controls, photo moderation and account deletion UX.
- Whether match sound, haptics and countdown voice prompts are optional.

## 12. Product invariants and safeguards
- In-app invitation **from the friends list** is the only approved opponent discovery mechanism. Every accepted duel is **ranked**, with host choice of 30, 60 or 90 seconds; there is no friendly switch.
- The ranking shows **Overall**, **Squats** and **Push-ups**, where Overall = qualified squat reps + qualified push-up reps. Training repetitions never affect any global leaderboard.
- Winners are determined by valid repetitions during the agreed window; a tie is allowed. A losing player still receives earned leaderboard repetitions if both results are verified and the duel is finalized.
- **Important:** detailed thresholds for reconnect, friend invite expiry, anti-abuse review and disputed matches are documented as proposed MVP policies, not user-approved business rules. Keep them configurable, test their UX, and request sign-off before production release. The safe invariant remains: never award repetitions for invalid, disputed or interrupted matches.

Use reversible, explicitly labeled prototypes for undecided UX details; never silently turn proposed defaults into confirmed requirements.

## 13. Suggested backend entities and state invariants
Implement via versioned SQL migrations once authorized; names can follow existing repository conventions:
- `profiles` (public nickname, avatar metadata, privacy-safe profile fields; linked to auth identity)
- `friend_requests` and `friendships` (pending/accepted/rejected/blocked, pair uniqueness and authorization)
- `duel_invitations` (inviter, intended invitee, exercise, duration, status, expiry)
- `duels` (server start/end, state, result, adjudication)
- `duel_participants` (two players, accepted/verified reps, readiness, finish outcome)
- `duel_rep_events` (event IDs, sequence, matching session, deduplication/reconciliation metadata)
- `training_sessions` (private personal training data, excluded from global rating)
- `leaderboard_totals` (derived or server-maintained transactional totals for eligible completed matches only)

For friend acceptance and duel finalization, use transactions / safe RPC / server functions; use RLS on user-facing tables and private realtime authorization. Include database integration tests for cross-user reads/writes, duplicate requests and concurrent changes. Audit access to photo storage and sensitive fields.

## 14. Implementation sequence
1. Inspect the actual iOS project, Xcode scheme, deployment target and approved Figma frames; document any differences without overwriting work.
2. Auth + profiles + Friends with end-to-end authorization and RLS tests.
3. Camera + Vision pose landmarks + deterministic, testable rep analyzers + offline training.
4. Invitations + lobby + synced time + duel client state + private Realtime + database reconciliation.
5. Verified results + leaderboard aggregation + edge-case/integrity tests.
6. Visual QA against Figma, iOS 18 fallback/iOS 26+ Liquid Glass, accessibility, physical-device calibration and release hardening.

Do not interpret this sequence as permission to provision services, access private repositories, rotate credentials, delete data, ship to production or modify Figma without explicit user authorization.
