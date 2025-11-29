# Chart Editor Completion Plan

## Objective
Deliver a Moonscraper-grade chart editor that lets players author full Clone Hero–compatible charts entirely inside the game. The finished tool must reuse existing gameplay assets (runway, notes, ChartLoadingService) while adding the workflows, UX affordances, and data management features chart authors expect.

## Research Summary
- **Moonscraper baseline:** Mature Clone Hero editor with per-lane keyboard input, snap grid ranging from 1/4 to 1/64, multi-note chords, sustain handles, HOPO/tap/star-power toggles, BPM & time-signature tracks, timeline scrubbing, section markers, metadata editing, and instant test-play.
- **Project intent (`Documentation/ChartEditor-Plan.md`):** Match Moonscraper UX, keep playback + runway shared with gameplay, componentize UI, support scrubbing, snap placement, selection rectangles, hold-note resizing, and note pooling optimizations.
- **Current implementation snapshot:**
  - Scene layout (`Scenes/chart_editor.tscn`) instantiates toolbar, settings panel, toolbox, progress bar, playback controls, and SubViewport runway.
  - Controller (`Scripts/Editor/chart_editor.gd`) loads/saves `.chart`, plays audio, toggles waveform texture, updates snap grid, places notes (mouse + keys 1–5), erases notes, and spawns preview ghosts. Playback uses `AudioStreamPlayer`; notes render via gameplay `Scenes/note.tscn` with movement paused. Waveform generation is placeholder for OGG/MP3.
  - Toolbox/settings/dialog scripts expose UI signals but no deeper logic (e.g., BPM tool does nothing yet).
  - Game already owns `ChartLoadingService.gd`, gameplay runway renderer, note scenes, and metadata dialogs that can be reused.

## Current Capability vs. Target
| Area | Moonscraper / Design Expectation | Current State | Gap |
| --- | --- | --- | --- |
| **Note authoring** | Multiple note types, chords, sustains with drag handles, HOPO/tap/open/star power, forced gems, hammer-on logic | Only single-lane regular notes, sustain data unused, star power button unused | Implement sustain editing, chord placement, note metadata fields, per-note modifiers, ghost preview for multi-lane input |
| **Selection & editing tools** | Box select, shift-click multi-select, contextual inspector, delete/duplicate, note properties editing | No notion of selection; delete key placeholder | Build selection model, gizmos, inspector panel, copy/paste, quantized move/resize |
| **Timeline & playback** | Bidirectional scrubbing, shuttle speed, timeline ruler w/ measures, BPM & TS lanes, markers, loop playback | Slider scrubs but notes do not re-evaluate; BPM tool stub; no sections or loops | Sync note visuals to arbitrary time, add BPM editor, markers, loop handles, rate control |
| **Audio & waveform** | Reliable waveform, metronome/clap, click track, multi-track preview | Waveform uses random data for OGG/MP3, no clap/metronome, single audio stream only | Implement true waveform extraction, metronome tied to BPM, per-track muting |
| **Chart data management** | Multiple difficulties/instruments, section/event editing, validation warnings | Saves only active difficulty, no events/sections, limited metadata | Extend ChartLoadingService integration for multi-difficulty editing, event authoring, validation layer |
| **Workflow utilities** | Undo/redo stack, hotkeys, quick test-play, project autosave/backups | No undo/redo, no autosave, testing requires manual scene swap | Add command stack, autosave, "Test Chart" button to boot gameplay scene with temp data |
| **Performance** | Efficient pooling for timeline scrubbing and zoom | Each note = new node, no pooling, scrubbing will stutter | Introduce pooled NoteVisualManager tied to note controller, viewport LOD |

## System Enhancements & Decisions
1. **Chart Data Model**
   - Centralize editor state in `ChartDocument` resource (notes, events, sections, metadata, tempo map). Provide diff-friendly serialization and hooks for undo/redo.
   - Distinguish logical notes vs. visuals; store modifiers (type, HOPO, tap, star power, forced, open) and sustain lengths in beats.
   - Integrate with `ChartLoadingService` for import/export; extend service to round-trip editor-specific metadata (e.g., selection sets, viewport state) via auxiliary JSON.

2. **Note Visual & Pooling Layer**
   - Create `NoteVisualManager` responsible for pooling `Scenes/note.tscn` instances, updating positions on timeline scrubs, and handling selection highlighting. This manager subscribes to document change events.
   - Implement ghost preview for chords: while holding multiple number keys or lanes, show stacked preview. Add sustain preview when dragging vertically.

3. **Selection, Editing, and Tools**
   - Add `EditorSelection` service tracking selected notes/events. Implement marquee selection in SubViewport, shift-click toggling, and keyboard modifiers (Ctrl+C/V, Ctrl+D, Delete).
   - Create inspectors (sidebar panel or popup) for editing properties of single/multiple notes (type, sustain, HOPO flag, star power sections, forced). Provide handles for sustain resizing similar to Moonscraper.
   - Flesh out toolbox buttons: BPM tool opens tempo marker editor; Section/Event tools place markers with dialog inputs; Cursor tool enables selection/move; Erase tool respects selection.

4. **Timeline & Playback Systems**
   - Replace ad-hoc `current_time` updates with unified `PlaybackController` supporting play, pause, stop, seek, loop, and rate. Ensure `_update_note_positions` derives from playback controller state (supports scrubbing while paused).
   - Build timeline ruler component showing measures/beats; hooking into tempo map to render dynamic spacing. Add draggable playhead and loop region handles.
   - Add clap/metronome toggle, playback speed slider hooking into `AudioStreamPlayer.pitch_scale`, and "jump to marker" shortcuts.

5. **Tempo, Sections, Events**
   - Implement BPM/time-signature editors: list of markers, inline editing, drag to reposition. Support anchored scrubbing (notes move when tempo changes).
   - Enable section/event authoring: `EditorProgressBar` should display real sections, support add/delete/rename, highlight active section.
   - Provide star power phrase editing (drag region to mark, visual overlay) and validation (minimum length, overlaps).

6. **File Workflow & Testing Loop**
   - Expand save format to include `[SyncTrack]`, `[Events]`, `[Sections]`, multiple instrument+difficulty brackets. Provide import UI for selecting difficulty/instrument and duplicating charts between difficulties.
   - Add "Test Chart" button launching gameplay scene with unsaved document via in-memory data transfer (e.g., temporary resource or `ChartLoadingService.chart_data_from_preloaded`).
   - Implement undo/redo via command pattern; log actions (place note, move, change BPM, modify metadata). Provide history view and keyboard shortcuts (Ctrl+Z/Y).
   - Autosave to user cache every X minutes; recovery dialog on next launch.

7. **UX & Quality-of-Life**
   - Improve waveform: decode audio to PCM (use Godot `AudioStreamSample` or external libs) for accurate texture; support zoom/scroll of waveform independent of runway.
   - Add status bar for coordinates (measure:beat:tick), snap resolution, selection count. Provide tooltips + inline keyboard hints mirroring Moonscraper.
   - Provide configurable keybinds stored via `SettingsManager` for note tools, grid, playback, etc.

## Implementation Roadmap
1. **Phase 0 – Foundations & Cleanup**
   - Extract `ChartDocument`, `NoteData`, `TempoEvent`, `SectionMarker` structs in `Scripts/Editor`. Migrate `placed_notes` into document.
   - Introduce `EditorEventBus` (signals) plus `CommandStack` for undo/redo.
   - Refactor `chart_editor.gd` into coordinator referencing new services (PlaybackController, SelectionManager, NoteVisualManager).

2. **Phase 1 – Authoring Core**
   - Implement selection system, marquee input in SubViewport, highlight states.
   - Support multi-lane placement (mouse drag + keyboard combos) and sustain handles. Wire toolbox note-type buttons to actual metadata fields.
   - Build inspector sidebar for editing selected notes.

3. **Phase 2 – Timeline & Tempo**
   - Replace slider with custom timeline ruler showing measures, markers, loop region, zoom controls.
   - Implement BPM/time-signature editors and ensure scrubbing updates note visuals instantly.
   - Add metronome/clap and waveform improvements.

4. **Phase 3 – Chart Data & Playback Loop**
   - Expand import/export to cover multiple instruments/difficulties, `[Events]`, `[Sections]`, star power phrases.
   - Add "Test Chart" workflow launching gameplay for the active document using `ChartLoadingService.chart_data_from_preloaded`.
   - Implement autosave, validation warnings, and chart metrics (note density graph stub).

5. **Phase 4 – Polish & QA**
   - Undo/redo polish, keyboard shortcut coverage, tooltips, theming.
   - Performance tuning: note pooling, partial rendering, async waveform.
   - Create GdUnit regression tests for document serialization, tempo math, snap accuracy, and command stack. Record manual test checklist updates (`Documentation/TESTING-CHECKLIST.md`).

## Dependencies & Considerations
- **Existing gameplay assets** (`Scenes/note.tscn`, `Scripts/board_renderer.gd`, `SettingsManager`) should remain authoritative to avoid divergence. Consider moving shared constants (lane widths, note speed) into a common module.
- **Audio decoding** may require lightweight PCM extraction utility; evaluate using Godot `AudioStreamSample` or integrating a small external decoder for MP3/OGG if licensing permits.
- **MIDI support**: for full parity with Moonscraper, plan follow-up work to expose per-track mixing using existing `MidiAudioLoader` outputs.

## Testing Strategy
- **Unit/Service tests:** Use GdUnit4 for snap math, BPM conversions, undo/redo commands, serialization/deserialization.
- **Integration tests:** Scripted scenarios verifying note placement + save/load round trip, BPM marker editing, and section marker navigation.
- **Manual QA:** Follow `Documentation/TESTING-CHECKLIST.md`, add new sections for editor workflows (placement, scrubbing, playback, export/import, test-play).

## Risks & Mitigations
- **Performance under heavy scrubbing:** mitigate via pooled visuals, run timeline updates on reduced frequency while dragging, and allow adjustable runway length.
- **Complex undo/redo interactions:** adopt command pattern early; instrument commands with telemetry logs for debugging.
- **Audio inaccuracies:** validate waveform + metronome against `AudioStreamPlayer.get_playback_position`; provide calibration UI for latency offsets.
- **Large scope creep:** lock MVP to Moonscraper core (note tools, tempo map, section markers, test-play). Track advanced analytics/features in backlog once MVP functions end-to-end.
