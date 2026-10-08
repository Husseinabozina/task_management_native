# TaskFlow motion — runtime target clarification required

The user supplied production Flutter instructions on 2026-10-08. Before editing, the existing startup, routing, theme and splash were inspected and reported. This repository has no `main.dart` or `pubspec.yaml`.

## Verified current architecture

- Android: `MainActivity` creates the existing `TaskAppViewModel`, Room observation and `TaskApp`; a saved onboarding preference selects welcome or four native Compose tabs. Account/sync is optional. Notification task IDs now pass through the same TaskApp after onboarding.
- iOS: `TaskManagementApp` calls `AppDependencies.bootstrap()` to open SwiftData and start reminder observation, then supplies dependencies to `RootView`; saved onboarding selects `EntryScreen` or `RootTabs`. Cloud/auth is optional. Bootstrap failures remain visible. Notification routing uses the same `AppSession`/RootTabs.
- Native launch screen is static; no Rive/animated splash architecture currently exists. No second flow was created.
- A separate Flutter prototype named `task_management_ui_test` was inspected read-only and was not selected or modified. Its private checkout path is not published here.

## Production asset published

The unchanged final master is now in this repository at [`assets/animations/taskflow_v9_3_1.riv`](../../assets/animations/taskflow_v9_3_1.riv). Its private source bundle path is not published here.

7236 bytes; SHA256 `17713eba411aba7887449bd70f34d236e122f9a25e1644066c7fd6f2d02591a2`.
Local copies in the production project and format benchmark match. The asset was not altered, converted, reconstructed or replaced.

## Static branding — D34 approved independently

The owner confirmed that TaskFlow is the new logo and requested updating it, including GitHub. The supplied [SVG master](../../assets/brand/taskflow-logo.svg) now appears in the README; static exports replace the existing iOS/Android launcher icons and showcase icon. This identity update does not require choosing an animation SDK and does not claim startup motion is integrated. Export checks and scope are in [TASKFLOW_BRANDING](TASKFLOW_BRANDING.md).

## Required answer, already asked

Integrate the unchanged motion in **this Native SwiftUI/Compose project with native Rive SDKs**, or in **a different Flutter project supplied by the user**? The literal `rive: 0.14.11`, `RiveNative.init()`, `FileLoader`, `RiveWidgetBuilder` and `Factory.rive` instructions apply to Flutter and cannot be installed into SwiftUI/Compose directly.

No dependency, launch background or routing was changed for the logo while this choice remains unresolved.

## Requirements to retain after target selection

Artboard `TaskFlow`; state machine `TaskFlowIntro`, or `TaskFlowReducedMotion` when the existing accessibility preference applies. Rive renderer, contain fit, centered approximately 280–320 logical px. Static native background and animated Flutter/native view background `#030914`. Intro approximately 1.8 s plus small final hold, then the real existing destination at approximately 1.9 s, preserving startup checks and onboarding/auth. No first-frame opacity/fade/placeholder trick, Lottie, GIF, geometry edits or fake HomePage. Own/dispose the loader/player and any bounded startup task correctly; consume the startup transition once.

Flutter asset path requested: `assets/animations/taskflow_v9_3_1.riv`. If Native is confirmed, inspect the official native renderer/runtime equivalents before choosing and adding SDK versions; do not invent a Flutter version equivalence.

Verification remains pending: renderer initialization, hidden first frame, native-to-runtime transition without white flash, contain alignment, single transition, rebuild/resume behavior and unchanged startup decisions. Build success from D31/D32 does not verify the animation.
