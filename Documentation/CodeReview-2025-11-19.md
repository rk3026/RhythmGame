# RhythmGame Code Review — 19 Nov 2025

## Scope & Method
- Reviewed project structure, primary scenes, and core gameplay scripts (`gameplay.gd`, `note_spawner.gd`, `input_handler.gd`, `ScoreManager.gd`, `TimelineController.gd`).
- Sampled supporting systems with large footprints (`ProfileManager.gd`, `song_select.gd`, `profile_select.gd`, `board_renderer.gd`).
- Cross-checked `.tscn` layouts (notably `gameplay.tscn`, `profile_select.tscn`) to verify separation between presentation and logic.
- Captured line counts to quantify refactor priorities and inspected hot-path code for SOLID/GRASP adherence and Godot best practices.

## Architecture Snapshot
- **Scenes & Layers**: 3D gameplay scene orchestrated by `gameplay.gd`, UI overlays under `UI` canvas layer, data-driven board built at runtime by `board_renderer.gd`.
- **Singletons/Autoloads**: `SettingsManager`, `SceneSwitcher`, `ResourceCache`, `ProfileManager`, `SoundEffectManager`, `ScoreHistoryManager`, etc. provide global state for settings, persistence, and scoring.
- **Core Flow**: Song select → chart loading (`ChartLoadingService`) → note scheduling (`note_spawner.gd`) → timeline playback/commands (`TimelineController.gd`) → scoring/VFX/limit break → results scene.

## Findings Overview
| # | Severity | Area | Summary |
|---|----------|------|---------|
| 1 | High | Gameplay orchestration (`gameplay.gd`) | Single script (525 lines) mixes chart loading, audio, UI, limit break, countdown, timeline, and VFX, leading to tight coupling and brittle changes. |
| 2 | High | UI layout vs runtime creation | Multiple scripts instantiate and wire UI at runtime (`song_select.gd` 276-354 & 348, `profile_select.gd` 60-441, `board_renderer.gd` 27-63), contradicting the desired tscn-driven layout and causing costly `get_node` churn. |
| 3 | Medium | Hot-path node lookups | `input_handler.gd` (lines 98/153/239/256) and `note_spawner.gd` (163-295) repeatedly call `gameplay.get_node(...)` inside `_input`/`_process`, creating per-frame tree traversals and hidden dependencies. |
| 4 | Medium | Global data duplication | Lane colors, note speed, and hit windows are hard-coded in several places (`gameplay.gd` lines 22-33, `board_renderer.gd` 33-48) instead of flowing from `SettingsManager`, inviting drift between UI and logic. |
| 5 | High | Profile subsystem complexity | `ProfileManager.gd` (1,536 lines) plus `profile_select.gd` (470 lines) blend persistence, validation, UI orchestration, and dialog creation, violating SRP/GRASP and complicating testing. |
| 6 | Medium | Timeline & spawn coupling | `note_spawner.gd` owns spawn-data prep, pooling, VFX hookup, and timeline command bookkeeping, while `TimelineController.gd` reaches back into the spawner to reposition nodes. Responsibilities overlap, making scrubbing & replay logic fragile. |

## Detailed Findings & Recommendations

### 1. Monolithic gameplay controller (High)
- **Where**: `Scripts/gameplay.gd` (entire file).
- **Symptoms**: Handles chart IO, board setup, audio playback (single stream + MIDI), countdown UX, HUD updates, VFX, limit-break state, pause stack, results routing, and timeline wiring. Duplicate color data (`LANE_COLORS`) and UI manipulation (`JudgementLabel` reused for countdown + grading) live alongside audio/timeline logic.
- **Why it matters**: Any change (e.g., countdown UX) risks breaking unrelated systems (timeline, audio). Testing is near-impossible, and SOLID’s SRP plus GRASP’s Controller/Low Coupling guidelines are violated.
- **Recommendations**:
  1. Split responsibilities: `GameplaySessionController` (chart/audio lifecycle), `GameplayHUD` (countdown, labels, pause), `LimitBreakCoordinator`, `AudioSyncService`, and `TimelineBootstrapper` can be separate nodes/scripts exported via `NodePath`.
  2. Replace hard-coded `LANE_COLORS` with `SettingsManager.lane_colors` or a shared `GamePalette` resource to keep visuals consistent.
  3. Move countdown/pause UI into its own Control scene; expose start/resume signals instead of mutating the judgement label directly.
  4. Inject dependencies (note spawner, score manager, VFX manager) through exported vars or a lightweight context struct instead of repeated `$Node` fetches, simplifying tests and reuse.

### 2. UI assembled from scripts rather than scenes (High)
- **Where**: `Scripts/song_select.gd` lines 276-354 & 348 (`TextureRect.new`, `Button.new`), `Scripts/profile_select.gd` lines 60-441 (`FileDialog.new`, `AcceptDialog.new`, runtime checkbox builds), `Scripts/board_renderer.gd` lines 27-63 (hit zones and lane lines).
- **Symptoms**: Layout nodes are created, configured, and connected at runtime, often using string-based `get_node` calls. Designers cannot edit these elements in the editor, and nodes are rebuilt every selection/resume.
- **Why it matters**: Violates the project’s goal (“UI layout defined in tscn, scripts handle logic”), increases CPU cost (node creation, material duplication, signal wiring), and makes it difficult to reason about the scene tree.
- **Recommendations**:
  1. Promote runtime UI to reusable scenes: e.g., a `DifficultyButton.tscn` (button + metadata) instanced via `PackedScene`, a `ProfileExportDialog.tscn`, predefined `FileDialog` nodes toggled via `.popup()`, and a `LaneBoard.tscn` containing `MultiMeshInstance3D` for lanes.
  2. Provide placeholder containers (`HBoxContainer/DifficultyButtons`, `Profiles/Dialogs`) in `.tscn` files and populate them by enabling/disabling child scenes instead of creating nodes via `Button.new` or `AcceptDialog.new`.
  3. Cache references to per-lane hit zones through exported arrays rather than deriving node names (`"HitZone" + str(i)`), allowing artists to rename nodes without breaking code.

### 3. Hot-path `get_node` lookups (Medium)
- **Where**: `input_handler.gd` lines 98/153/239/256 repeatedly fetch `NoteSpawner` and `HitZone*` inside `_input` and `_process`; `note_spawner.gd` lines 163-295 repeatedly traverse to `HitEffectPool`; `gameplay_vfx_manager.gd` line 71 fetches `Runway/LimitBreakGlow` on init.
- **Symptoms**: Per-input operations walk the scene tree, allocate temporary strings (`"HitZone" + str(lane_index)`), and duplicate logic for every lane. Spawner code repeatedly searches for `HitEffectPool` even though the reference never changes during a song.
- **Why it matters**: `get_node` is cheap but not free; doing it every frame or input event across six lanes accumulates CPU cost and GC churn, and string-based paths are brittle.
- **Recommendations**:
  1. Inject dependencies via `@export var note_spawner: NodePath` or setter methods so `_process` can access pre-cached references (`var note_spawner := gameplay.note_spawner`).
  2. Store lane zone references in an array returned by `board_renderer.setup_lanes()`; pass that array into `input_handler.configure(...)` so no node lookup is needed during play.
  3. Cache `HitEffectPool` and other sibling nodes once (e.g., in `_ready()`), or pass them via dependency injection when the spawner is initialized.

### 4. Global data duplication & hidden coupling (Medium)
- **Where**: `gameplay.gd` defines `LANE_COLORS`; `board_renderer.gd` pulls colors and geometry constants from `SettingsManager` directly; `note_spawner.gd` queries `SettingsManager.note_speed` in multiple functions; `input_handler.gd` directly reads `SettingsManager` for timing windows.
- **Symptoms**: Visual palettes and tuning constants live in multiple scripts, and logic scripts reach into the global singleton rather than being configured explicitly. Any settings change must be updated in several files, causing potential mismatches (e.g., Settings says 6 lanes, but `LANE_COLORS` only supplies 5 entries).
- **Recommendations**:
  1. Introduce a `GameSessionConfig` resource (lane colors, note speed, timing windows, audio offset) built from `SettingsManager` once per song and passed to interested systems.
  2. Remove duplicate constants from gameplay scripts; rely on the shared config or `SettingsManager` when constructing the board, then treat the provided arrays as authoritative.
  3. For testing/practice tools, allow injecting mock configs instead of touching global singletons.

### 5. Profile subsystem complexity (High)
- **Where**: `Scripts/ProfileManager.gd` (1,536 lines), `Scripts/profile_select.gd` (470 lines), `Scripts/Components/ProfileCard.gd` (not reviewed but interacts tightly).
- **Symptoms**: Profile creation, persistence, migrations, achievements, score history, XP math, import/export, and privacy settings all live in one autoload. The UI layer duplicates business rules (validation, conflict handling) and spawns dialogs programmatically.
- **Why it matters**: Hard to maintain, risky to change (e.g., altering file format touches dozens of branches), and violates SOLID (Single Responsibility, Interface Segregation) plus GRASP (Low Coupling). Automated testing is nearly impossible because everything depends on filesystem calls and dialogs.
- **Recommendations**:
  1. Split `ProfileManager` into smaller services: `ProfileRepository` (IO), `ProfileService` (validation + mutations), `ProfileStatsService` (XP/achievements), and `ProfileSyncService` (import/export). Autoload can compose these but expose a slim API.
  2. Move dialog scenes for import/export/rename into `.tscn` files bound to dedicated scripts so the UI logic becomes declarative (toggle visibility, bind signals) rather than procedural.
  3. Define data models using `Resource` or lightweight classes, enabling serialization without manual dictionary juggling.

### 6. Timeline + spawner responsibility overlap (Medium)
- **Where**: `note_spawner.gd` (spawn data prep, command generation, movement pause, VFX hookup) and `TimelineController.gd` (advance/undo) with cross-references such as `timeline_controller.command_log` access in `_ensure_spawned_notes`.
- **Symptoms**: The spawner must understand timeline internals (executed_count, command_log) to ensure notes exist during scrubbing, while timeline commands hold references back to note instances. `note_spawned` also triggers animation/vfx inside the spawner, blurring boundaries.
- **Why it matters**: Changes to timeline behavior (e.g., variable speed, practice loops) require edits in multiple scripts, increasing regression risk. Coupling makes it difficult to unit test spawn scheduling or timeline independently.
- **Recommendations**:
  1. Introduce a dedicated `SpawnScheduler` class that produces immutable spawn events; `TimelineController` consumes those, while `NoteSpawner` only handles instancing/pooling based on events passed in.
  2. Provide timeline hooks (signals or interface methods) instead of allowing the spawner to dig into `command_log`.
  3. Move VFX/animation emission (`note_spawned`, `_spawn_hit_effect`) out of the spawner into higher-level observers to keep the class focused on note lifecycle.

## Suggested Refactor Roadmap
1. **Stabilize Gameplay Scene**
   - Create `GameplayHUD.tscn` with dedicated script for countdown, score, combo, pause menu, and limit-break UI.
   - Extract `GameplaySessionController` (chart/audio/timeline) and `LimitBreakCoordinator` nodes; wire them through exported NodePaths.
2. **UI Scene Ownership**
   - Build prefab scenes for runtime-created dialogs/buttons (difficulty button, export options, import conflict, countdown overlay). Replace `*.new()` calls with instanced scenes referenced via exported `PackedScene` vars or pre-placed nodes.
   - Replace `board_renderer.gd` runtime geometry with a parameterized `LaneBoard` scene (or `MultiMeshInstance3D`) where lane count drives material arrays.
3. **Dependency Injection & Node References**
   - Pass references (`NoteSpawner`, `HitEffectPool`, lane nodes) into `input_handler.gd` and `note_spawner.gd` once during setup; remove string-based `get_node` calls inside `_input`/`_process`.
4. **Profile Module Split**
   - Extract persistence helpers from `ProfileManager.gd` into separate files, add interfaces for import/export, and move dialog scenes to `.tscn` resources controlled by smaller scripts.
5. **Timeline Decoupling**
   - Define a `SpawnEvent` data structure and mediator between `TimelineController` and `NoteSpawner`, ensuring the timeline never needs to know about pooled node instances.
6. **Testing Hooks**
   - After splitting modules, add GdUnit4 tests for spawn scheduling, scoring, profile validation, and limit-break state transitions to prevent regressions during refactors.

## Appendix: File Size Context
Largest project scripts (excluding third-party addons), gathered via PowerShell line counts:
- `Scripts/ProfileManager.gd` — **1536** lines.
- `Scripts/Editor/chart_editor.gd` — 987 lines.
- `Scripts/gameplay.gd` — 525 lines.
- `Scripts/song_select.gd` — 491 lines.
- `Scripts/profile_select.gd` — 470 lines.
- `Scripts/Parsers/midi_file_parser.gd` — 489 lines.

These files should be primary candidates for staged refactors to improve readability, testability, and adherence to SOLID/GRASP.
