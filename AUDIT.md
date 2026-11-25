# spoiler_widget — Audit Report

Four-axis audit: **performance**, **code readability**, **pub-package DX**, **security**.
Scope: `lib/`, `example/`, `shaders/`, `test/`, CI, packaging. Date: 2026-11-25.
Baseline: Flutter 3.50 (local fvm default; CI pins 3.27.0), Dart analyze clean on `lib/`, 41/41 tests green. Post-fix: 46/46 tests green, pana 150/160.

## Severity legend

- **HIGH** — correctness bug, CI failure, or major DX breakage
- **MED** — real defect or meaningful perf/readability cost
- **LOW** — polish, hygiene, minor risk
- **INFO** — observation / decision point

---

## A. Correctness

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| A1 | HIGH | `shaders/glitch_stripes.frag` declares 18 float uniforms (no `uSize`) but `ShaderConfig.glitchStripes()` emits the 19-float `_baseUniforms` layout → all uniforms from index 12 shifted by one, index 18 out of bounds. Verified by uniform-slot count script. | Fixed |
| A2 | HIGH | `example/lib/pages/spoiler_benchmark_page.dart` (uncommitted WIP) doesn't compile: `py:` param, `GridPaper.subDivisions`, protected/`@visibleForTesting` member usage → `flutter analyze` + `dart format` CI gates red. | Fixed |
| A3 | MED | `SpoilerSpotsController.toggle` returns `isEnabled` after toggling instead of toggle-success like `SpoilerController.toggle` — returns `false` on a *successful* toggle that hid the spoiler. | Fixed |
| A4 | MED | `ParticlePathPreset`, `ShaderConfig`, `SpoilerMask` lack `==`/`hashCode`/`@immutable`; `ParticleConfig.==` compares `shapePreset` by identity → custom presets break config equality → `didUpdateWidget` misfires. | Fixed |
| A5 | MED | `_onParticleFrameTick` uses hardcoded `0.016` dt — particle speed/life run at ~half rate on 120 Hz displays. | Fixed |
| A6 | LOW | `dart format --set-exit-if-changed` failed on `spoiler_drawing_strategy.dart` + benchmark page (WIP drift). | Fixed |
| A7 | INFO | `SpoilerConfig.==`/`hashCode` include `onSpoilerVisibilityChanged` closure (identity compare) — configs with callbacks are never equal. Kept as-is (documented behavior); revisit if it causes issues. | Accepted |

## B. Performance

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| B1 | HIGH | `RenderSpoiler.paint` runs `_findRenderEditables` + `_findRenderParagraphs` — two full render-subtree walks — **every paint**, even when rects are cached. | Fixed |
| B2 | MED | `new Random()` allocated per particle per frame (`Particle.moveToRandomAngle`), per particle at init (`PathX.getRandomPoint`), per wave (`RectX.randomOffset`). | Fixed |
| B3 | MED | Wave animation: each `_ActiveWave` listener scans **all** particles per tick → O(waves × particles) per frame. | Fixed |
| B4 | LOW-MED | `ShaderSpoilerDrawer.draw` allocates `params.toList()` per rect per frame; `SpoilerShaderRenderer.render` allocates a `Paint` per call. | Fixed |
| B5 | LOW-MED | `SpoilerTextPainter.build` creates + lays out a new `TextPainter` every build. | Fixed |
| B6 | LOW | `initializeParticles` computes `_spoilerPath.subPaths` twice and rebuilds `_encapsulatedPaths` twice. | Fixed |
| B7 | LOW | `_estimatePathAreaFactor` costs 2304 `path.contains` samples per unique `Path`; `Expando` cache helps only if the same `Path` instance is reused. | Documented |
| B8 | MED | Golden tests were **nondeterministic**: particle placement/waves used unseeded `Random()` → ~12% pixel variance run-to-run; goldens only passed by luck. | Fixed (`ParticleSpoilerDrawer.debugRandomSeed`, goldens regenerated) |

## C. Readability / architecture

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| C1 | MED | `lib/widgets/spoiler_render_object.dart` = 777 lines: render object + rect collection + ~160-line `Canvas` forwarding wrapper (`SpoilerCanvas`) with `dynamic` superellipse dispatch. | Fixed (split) |
| C2 | MED | Legacy-param bridging duplicated across 3 `copyWith` implementations (~60 ln each); dedupe scan: 15 clusters / 9.3% duplication. | Fixed |
| C3 | LOW | Dead code: `RectX.divideRect`, `widgets/path_clipper.dart`, `SpoilerGeometry.signature`/`path_signature.dart` (test-only consumer), `_encapsulatedPaths` TODO. | Fixed |
| C4 | LOW | Mixed `package:`/`../` import styles in `spoiler_controller.dart`. | Fixed |
| C5 | MED (DX) | Dual wave systems undocumented: Dart-side `SpoilerSpotsController`+`maxActiveWaves` vs shader-side `ParticleConfig.enableWaves/maxWaveRadius/maxWaveCount`. | Documented |
| C6 | LOW (DX) | `SpoilerOverlay` silently uses `SpoilerSpotsController` (waves on) when `shaderConfig == null` — undocumented. | Documented |
| C7 | LOW | Example leaked `FocusNode()` created in `build` (`spoiler_text_field_page.dart`) — hoisted to state + disposed. Hardcoded demo image URL kept intentionally (it is the point of the `CachedNetworkImage` demo). | Fixed |

## D. Pub-package DX

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| D1 | HIGH | `SpoilerController`/`SpoilerSpotsController` not exported — programmatic control requires deep `package:spoiler_widget/models/...` imports. | Fixed |
| D2 | HIGH | README §1.2 `SpoilerTextFieldWrapper` example uses a non-existent API (`controller:`, `focusNode:`, `cursorColor:`, `maxLines:`) — real API is `builder:` + `contextMenuBuilder`. Copy-paste fails. | Fixed |
| D3 | LOW | README: duplicate `### 3.` headings/numbering; `imageFilter` documented `ImageFilter?` but is required non-nullable. | Fixed |
| D4 | LOW | `pubspec.yaml`: no `repository:` field; `flutter_lints ^2.0.0` outdated (6.0.0 available — constrained by Flutter 3.27 floor); trailing whitespace in `platforms:`/`topics:`. | Fixed |
| D5 | LOW | `example/pubspec.yaml`: `cached_network_image: any` → pinned; `cupertino_icons` outdated; sdk floor `>=3.1.4` below package `>=3.4.0`. | Fixed |
| D6 | MED | Shader uniform contract untested — goldens only cover `ShaderConfig.particles()`. | Fixed (new test) |
| D7 | INFO | CI/`.fvmrc` pin Flutter 3.27.0; local fvm default is 3.50.0 which already deprecates `package:flutter/material.dart` imports (per Codacy dartanalyzer). Floor decision deferred. | Open |
| D8 | INFO | `flutter pub get` notices: 10 packages have newer incompatible versions — normal constraint drift, no action. | Noted |

## E. Security

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| E1 | LOW | `.github/workflows/auto-assign.yml` uses `pull_request_target` + write perms — safe today (no checkout, only `addAssignees`) but fragile; added guard comment, kept trigger (fork PRs need it for auto-assign). | Fixed |
| E2 | LOW | Semgrep: `dorny/paths-filter@v3` + `subosito/flutter-action@v2` in `ci.yml` not pinned to commit SHA. | Fixed |
| E3 | INFO | Trivy: **clean** — no known vulnerabilities. | Clean |
| E4 | INFO | Zero runtime dependencies (only `flutter` SDK + `flutter_lints`); no secrets/keys tracked; shaders are bundled assets (`FragmentProgram.fromAsset` cannot load remote code); `.pubignore` correctly excludes example scaffolding. | Clean |

## Verification

All gates green on Flutter 3.50 (local); CI pins 3.27.0 where the `material_ui` deprecation infos do not exist:

- `dart format .` — clean
- `flutter analyze` (root) — 0 errors/warnings; only `deprecated_member_use` infos from Flutter ≥3.47 (`material_ui` migration), absent on the CI-pinned 3.27
- `flutter analyze` (example) — same, infos only; benchmark page compiles
- `flutter test` — **46/46 pass**, goldens stable across repeated runs (seeded via `debugRandomSeed`)
- `test/shader_uniforms_test.dart` (new) — asserts emitted uniform count == declared float uniforms for all 6 shaders (24 for `particles.frag`, 19 for the rest)
- `dart pub publish --dry-run` — passes; `.pubignore` now excludes `AUDIT.md` + `test/failures/`
- `pana` — **150/160** (CI gate: ≥120)
- `flutter_lints` bumped `^2.0.0` → `^5.0.0` (6.x requires newer Dart than the Flutter 3.27 floor allows); `dart fix` was tried and reverted — it auto-applied the 3.50-only `material_ui` import migration

Notes:

- `SpoilerShaderRenderer` logs "missing sampler" for `particles.frag` under `flutter test` — a headless test-runner limitation (sampler uniforms can't bind without GPU); the drawer falls back to atlas/vector. Sampler binding (`setImageSampler`) is correctly wired for device runs.
- `use_super_parameters` info remains on `SpoilerSpotsController(vsync:)` — intentional: the controller stores `_vsync` for wave `AnimationController`s, so the parameter can't become a pure super parameter.
- Goldens were regenerated once after seeding; subsequent runs are deterministic.
