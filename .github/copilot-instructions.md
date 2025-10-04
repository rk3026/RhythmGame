---
applyTo: "**"
---

# AI Coding Guidelines – Rhythm Game (Godot 4)

Keep responses focused on THIS codebase’s patterns. Always append the full user prompt and your response to `.github/copilot-logs.md` (create if missing, append chronologically).

## 1. Big Picture
3D Guitar-Hero–style game. Runtime pipeline:
Track folder chosen → `.chart` parsed (`ChartParser.gd`) → tempo + tick positions converted to hit times → spawn schedule built (`note_spawner.gd`) → notes instantiated to travel from z=-25 toward hit line (≈ z=0) at `config.note_speed` → per-frame chord-aware input (`input_handler.gd`) grades hits using timing windows → scoring/combo (`ScoreManager.gd`) → end-of-song → results screen.

## 2. Core Scenes & Roles
- `song_select.tscn` – browse tracks (folder structure under `Assets/Tracks/`).
- `gameplay.tscn` – assembles rendering, spawner, input, scoring, audio, UI.
- `note.tscn` – individual moving note (fields: `expected_hit_time`, `note_type`, sustains).
- `results_screen.tscn` – summary after completion.
- `main_menu.tscn` / `settings.tscn` – navigation + user configuration.

## 3. Key Scripts & Responsibilities
- `ChartParser.gd`: Minimal line-based parser; derives resolution (default 192), offset (ms → seconds), tempo map (`B` events), note list with HOPO/TAP/open detection (special frets 5–7). Filters instrument sections that have at least one `N` line.
- `note_spawner.gd`: Precomputes `spawn_data` entries: `{spawn_time, lane, hit_time, note_type, is_sustain, sustain_length}`. Spawn time = `hit_time - travel_time` where `travel_time = (abs(runway_begin_z) / note_speed)`. Maintains `active_notes` and removes them when passed end z or hit.
- `input_handler.gd`: Collects key state in `_input`; resolves best candidate per lane each frame in `_process` (supports chords). Uses timing windows from `game_config.gd` (`perfect_window`, etc.). Emits `note_hit(note, grade)`.
- `gameplay.gd`: Orchestrates lifecycle (countdown, audio start w/ offset, detection of finished song). Dynamically determines lane count from max fret. Injects settings (lane keys, note speed). Updates UI labels on signals.
- `ScoreManager.gd`: Combo, max_combo, score (base points scaled by combo and note type multiplier), per-grade counts. Emits `combo_changed`, `score_changed`.
- `settings_manager.gd`: Autoload-recommended singleton. Persists lane keys, note speed, volume, timing offset in `user://settings.cfg`.
- `board_renderer.gd`: Procedural lane mesh, hit zones, lane line materials & texture.

## 4. Timing & Grading Rules
Windows (seconds) from `game_config.gd`: Perfect 0.025, Great 0.05, Good 0.1, Bad fallback. Grade chosen by smallest matching window; miss handling occurs elsewhere (note expiry / not hit before passing zone). HOPO/TAP detection: natural HOPO if within `resolution / 4` ticks and different fret; specials at same tick can flip HOPO or mark TAP.

## 5. Note Types
Internal numeric mapping (see `note_spawner.gd` & scoring): 0 REGULAR, 1 HOPO, 2 TAP, 3 OPEN. Score multipliers in `ScoreManager.get_type_multiplier` (HOPO/TAP = 2x).

## 6. End-of-Song Detection
In `gameplay._process`: song ends when (all spawn_data consumed) AND (`active_notes` empty) AND (audio finished or absent). Then results scene instantiated with collected stats.

## 7. Settings Integration
If `SettingsManager` singleton present: lane keys and `note_speed` override defaults. Rebinding updates `settings_manager.lane_keys` immediately (saved) and gameplay copies them into the input handler on score updates (`_on_score_changed`). Timing offset currently applied only at scheduling (offset < 0 handles pre-roll start using negative seek).

## 8. Adding Content (Songs)
Each track directory: `notes.chart`, `song.ogg` (or alternative .ogg; parser first tries `MusicStream` or `song.ini` `MusicStream=` then any .ogg), plus `album.png`/`background.jpg` if desired. Folder name pattern: `Artist - Title [Charter]` (used cosmetically; not parsed for metadata yet).

## 9. Common Extension Points (Follow Existing Patterns)
- New hit window logic: add fields to `game_config.gd` and adjust `input_handler.gd` comparison order only (keep single pass per frame to preserve chord integrity).
- Additional note type: extend mapping in `note_spawner.get_note_type` + multiplier in `ScoreManager.get_type_multiplier` + update visuals in `note.gd` (not shown here) and results formatting if necessary.
- Latency calibration: would adjust either global `timing_offset` in settings or shift comparison in `input_handler.check_hit`—keep spawn scheduling untouched to avoid desync.

## 10. Style & Conventions
- Use `res://Scripts/...` explicit loads (already pervasive) rather than relying on class_name singletons (except potential autoloads).
- Arrays of dictionaries for parsed chart data (no custom classes). Keep dictionary keys consistent (`pos`, `fret`, `length`, flags).
- Sorting: `sort_custom(func(a,b): return a.key < b.key)` pattern—mirror this for new comparable collections.
- Signals: prefer emitting after state mutation (`ScoreManager` order is canonical).

## 11. Performance/Avoidances
- Do not iterate & free children every frame; spawn schedule uses while-loop with current_time guard (retain this pattern for any parallel spawns).
- Avoid per-note polling from input: current design filters candidates by lane each frame once (copy this approach for features like sustain tracking rather than adding nested loops elsewhere).

## 12. Safety / Edge Cases
- Missing audio: gameplay still proceeds (spawner + scoring). Preserve this silent mode when adding audio features.
- Empty instrument section: `get_available_instruments` filters; do not list instruments without at least one `N` event.
- Variable lane count: Derived from max fret; always rebuild any lane-dependent arrays using this value before spawning or input binding.

## 13. Example Snippets
Parse + schedule excerpt:
```
var parser = ChartParser.new()
var sections = parser.load_chart(chart_path)
var res = parser.get_resolution(sections)
var tempos = parser.get_tempo_events(sections)
var notes = parser.get_notes(sections, "EasySingle", res)
```
Chord-friendly grading (condensed logic):
```
if diff <= config.good_window and diff < best_diff: best_note = note
```

## 14. When Modifying
- Touch spawning? Recalculate `travel_time = abs(runway_begin_z)/note_speed` consistently.
- Add stat fields? Update results scene population in `gameplay._show_results` and persist naming.
- Change keybind flow? Maintain frame-based hit resolution (do not revert to immediate key events or chords will break).

## 15. Logging Requirement
Every interaction with the AI assistant must append: `### Prompt\n<user prompt>\n### Response\n<assistant response>\n---` to `.github/copilot-logs.md`.

Reference deeper `.chart` specification: `Documentation/Core Infrastructure.md`.