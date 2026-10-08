# D34 — TaskFlow logo across native icons and GitHub (2026-10-08)

The owner confirmed that the selected TaskFlow motion contains the new logo and requested replacing the logo, including GitHub. This approves the static identity update independently of the unresolved motion runtime target.

Candidate feedback: the public README and app icon still showed the earlier purple checkmark after TaskFlow had been selected.
Preliminary cause: static branding was left coupled to the Native/Flutter runtime question even though the supplied vector master can be used independently.

## Acceptance recorded before implementation

- Use `taskflow_v9_3_vector_master.svg` from the final v9.3.1 production bundle. Copy its bytes, paths and gradients without redesigning or reconstructing the mark.
- Keep the final `.riv` unchanged at `assets/animations/taskflow_v9_3_1.riv`; SHA256 must be `17713eba411aba7887449bd70f34d236e122f9a25e1644066c7fd6f2d02591a2`.
- Replace the existing 1024×1024 iOS and Android icon resources using a static SVG export on `#030914`, centered with uniform scaling and safe space for launcher masks. All pixels opaque; no new icon/resource flow.
- Use the supplied SVG master in the GitHub README header. Replace the old showcase icon too, keeping existing media URLs current. Preserve the product name, native platform descriptions, portfolio links and all eight screenshots.
- Inspect the new icon beside the supplied final-hold Rive reference; verify path/gradient equality, raster dimensions/opacity/centering, native resource references, local links and the final asset hash. Commit/push normally and verify GitHub delivery/rendered markup.
- No website, geometry/color edits, animation conversion, new dependency, routing/onboarding/auth/data change or claimed runtime splash integration.

## Intended files

`assets/brand/taskflow-logo.svg`: unchanged static master. `assets/animations/taskflow_v9_3_1.riv`: unchanged production motion master. Existing iOS AppIcon.png, Android app_icon.png and docs/showcase/app-icon.png: matching static icon exports. README and showcase provenance: selected logo and source links. TASKFLOW_INTEGRATION_HANDOFF, DECISIONS, CURRENT_STATE and this document: distinguish completed branding from pending runtime motion.

## Static export

Render the supplied SVG directly with the installed SVG renderer, preserving its aspect ratio. Output canvas 1024×1024, logo height 704, exact proportional width 684.521739, centered at approximately x=169.739130/y=160, background `#030914`. These are export placement values; the source geometry/gradients remain byte-identical. No first-frame fade/placeholder trick is added to the application.

## Source/export verification

| Element | Evidence |
| --- | --- |
| Logo geometry | SVG byte-identical to the supplied master, SHA256 `14ee503948647142f7008589a9d832759e565f7cb57ab017b15388a382fb3308`; 3 paths / 119 cubic segments. No path edits. |
| Logo color | The master's 3 gradients are unchanged; direct SVG raster export. |
| Motion master | 7236 bytes, byte-identical to the selected production .riv; expected SHA256 passed. No GIF/Lottie or rebuilt animation. |
| Native icon placement | Declared static export placement, 1024×1024 opaque RGB, corner/background `(3,9,20)`. Foreground bounds `(166,159)–(854,863)`; center offset only 1.5/0.5 px from the canvas center, all mark pixels within a circular launcher mask. Geometry remains untouched. |
| Reference comparison | Supplied final-hold Rive screenshot inspected beside the exported icon: same three joined ribbons, cyan/blue/purple gradient arrangement and checkmark silhouette; square icon margins are the declared export adaptation. This is asset visual review, not an application screenshot. |
| Resource wiring | iOS Contents.json and AppIcon build setting still select AppIcon.png; Android manifest still uses @drawable/app_icon. All 3 PNG copies have identical hashes. |
| README/captures | 32 local targets resolve; header points to the new SVG with width only; both Native stacks/product name retained. All eight original JPEGs byte-identical. |
| Public configuration | Current files plus reachable history rescanned without credential-pattern or sensitive-file findings; local configs remain ignored. |

No native build, installation or startup animation run for this static-asset checkpoint. Static branding checks do not verify Rive playback, first-frame hiding or startup navigation; those retain their existing separate acceptance items.

## GitHub delivery verified

Normal push [`37cf16c`](https://github.com/Husseinabozina/task_management_native/commit/37cf16c3db283e64199388198a1dc8a451b0ac15) succeeded; local HEAD, remote main and GitHub commit API matched. README, SVG, .riv and all 3 icon PNGs returned HTTP 200 with bytes matching local files. GitHub-rendered markup references the new SVG and retains all eight screenshot links. The actual public README was opened in the browser and visually inspected: the blue/cyan/purple TaskFlow mark appears centered above Mahami, with the Native iOS/Android labels present. A screenshot was captured outside the repository for delivery. Later documentation-only commits record this evidence.

## Files changed and why

| File | Purpose |
| --- | --- |
| `assets/brand/taskflow-logo.svg` | Exact supplied vector logo for GitHub and static exports. |
| `assets/animations/taskflow_v9_3_1.riv` | Exact final production master, ready for the later selected runtime integration. |
| `ios/TaskManagement/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | New logo in the existing iOS icon slot. |
| `android/app/src/main/res/drawable-nodpi/app_icon.png` | Same logo in the existing Android icon slot. |
| `docs/showcase/app-icon.png` | Same icon under the existing showcase media URL. |
| `README.md` | Replace the old header checkmark with the TaskFlow SVG. |
| `docs/showcase/README.md` | Explain provenance, static export and unchanged captures. |
| `docs/design/TASKFLOW_INTEGRATION_HANDOFF.md` | Locate the checked-in master and distinguish static approval from runtime target. |
| `docs/project/BACKLOG.md` | Track completed static identity and remaining motion work accurately. |
| `docs/project/CURRENT_STATE.md` | Current scope, assets and verification limits. |
| `docs/architecture/DECISIONS.md` | Record independent D34 branding approval. |
| `docs/design/TASKFLOW_BRANDING.md` | This acceptance record, reference comparison and file inventory. |
