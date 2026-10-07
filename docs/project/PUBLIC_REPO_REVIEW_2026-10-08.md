# D33 — Public repository review, October 8, 2026

The owner confirmed the repository is public, requested excluding private material and pushing all relevant corrections, and explicitly excluded website work. The earlier local-only README note describes D30; README, all eight screenshots, reminders and personal sync were already published in 51e4e34, followed by documentation in 5605ee5.

## Scope and acceptance

Starting point: clean `main` at `5605ee597368afe6efc2b8aa1a3dc6b8b1987b13`; GitHub API reports `PUBLIC`. Remote heads/tags exposed only `main`, matching local baseline. Acceptance was recorded before edits: inspect all reachable historical blobs/messages and current files, confirm exclusion of real configuration and signing/data, remove unnecessary machine details, add ignore coverage, verify cloud/GitHub security state and deliver through a normal push.

Preserve native code, local data, existing routing, optional account flow, original screenshots, public portfolio links and user's local environment. No website, key rotation, database change, app redesign, new dependency or destructive history rewrite.

## Findings and actions

| Checked area | Evidence and action |
| --- | --- |
| Reachable Git history | All 19 baseline commits, 322 unique blobs, 8,148,017 bytes, plus commit messages scanned. Patterns cover private-key headers; GitHub, Supabase, AWS, Google, Slack, Stripe, OpenAI, npm, GitLab and SendGrid tokens; JWTs; credential URLs; literal credential assignments and plist values. No matches or literal candidates. |
| Sensitive file names | Historical and current paths checked for environment/configuration, service accounts, signing material, app databases and build exports. No tracked sensitive files found. |
| Real local configuration | iOS SupabaseConfig.plist, Android supabase.properties and local.properties exist locally, are ignored, and never appeared in reachable history. Contents were not printed or uploaded. |
| Screenshot/asset metadata | Eight showcase JPEGs have no EXIF. PNG metadata inspected: icon color-space/dimensions, image-format/tool information and software metadata; no location or credential markers identified. Original screenshots remain unchanged. |
| Operational metadata | Personal filesystem paths, owner device model and live deployment identifier removed from current public documentation. These are not administrative credentials; old commits still contain non-secret operational metadata. |
| GitHub protections | Secret scanning and push protection were disabled. Both enabled via repository settings API and read back as enabled. Alerts endpoint returned an empty list at the check; this is not a claim that asynchronous scanning can detect every secret. No release assets were present. |
| Supabase | Live security advisor returned `lints: []`. No schema, key or account changes. Earlier D32 rollback-fixture ownership/isolation checks remain documented separately. |
| Device launcher | Replaced private hardcoded defaults with environment/local.properties lookup and standard macOS fallbacks. Existing external SDK/cache selection preserved locally. Syntax, local selection and environment precedence checked without invoking a build, installation or phone. |

## Files changed and why

| File | Purpose |
| --- | --- |
| `.gitignore` | Exclude environment files, local overrides, private signing/service-account material, app data/backups, logs and package outputs; keep environment examples visible. |
| `SECURITY.md` | Document safe configuration, client versus privileged keys, actual review scope and history limitations. |
| `README.md` | Link security/configuration notes and explain portable launcher configuration. Features, eight screenshots and Native iOS/Android descriptions retained. |
| `android/run-on-device.command` | Read SDK/cache paths from local configuration/environment rather than a developer-specific path. |
| `docs/HANDOFF_FULL.md` | Sanitize paths/deployment details, label the public repository and current GitHub delivery. |
| `docs/architecture/DECISIONS.md` | Remove environment identifier and record D33 scope/decision. |
| `docs/design/ANDROID_CLOUD_SYNC.md` | Refer to locally configured backend without publishing the owner's environment identifier. |
| `docs/design/ANDROID_DEMO_DATA.md` | Remove owner device model while preserving Android version and actual verification. |
| `docs/design/ANDROID_PRESENTATION_PLAN.md` | Use portable SDK/cache examples and remove owner device model. |
| `docs/design/README_SHOWCASE.md` | Replace personal reference path with public project link and distinguish historical local-only state from verified delivery. |
| `docs/design/TASKFLOW_INTEGRATION_HANDOFF.md` | Keep exact asset name/hash and unresolved Native/Flutter target; remove private asset/prototype paths. |
| `docs/supabase/SETUP.md` | Use a general dashboard link and local environment selection. |
| `docs/project/CURRENT_STATE.md` | Record D33 checks/limits and remove workstation/device details. |
| `docs/project/PUBLIC_REPO_REVIEW_2026-10-08.md` | This scope, findings and file inventory. |

Local-only preservation: the existing external Gradle cache preference is recorded under `taskmanagement.gradleUserHome` in ignored `android/local.properties`. No real client key or task data was changed. The local audit helper/results live outside the repository and contain locations/rule names rather than secret values.

## Verification and limits

Final working-tree review included history plus all publishable current files: 336 unique blobs, with no credential findings or sensitive filename candidates. Ignore checks passed for 26 sensitive-path examples, while eight portable example/lockfile/source cases stayed visible; zero previously tracked files were newly ignored. All 32 local README targets resolve and the eight screenshot files match their published baseline byte-for-byte. Current Markdown/launcher files contain none of the removed personal absolute paths, owner device model or deployment identifier. Launcher syntax/configuration checks and `git diff --check` passed.

Delivery gate: commit/push normally and compare remote `main` with local HEAD. No application build/runtime checks are repeated for these documentation/launcher changes; previous D31/D32 evidence remains separately scoped. No secret was found that required rotation or a destructive history rewrite. This is a credential/privacy review, not a complete application penetration test.

TaskFlow animation still requires the previously requested target answer: native SDK integration in this SwiftUI/Compose repository, or a separately supplied Flutter project. The final `.riv` asset and existing startup flow remain unchanged.
