# Chart Editor Completion Plan - Version 2
**Last Updated:** December 7, 2025  
**Goal:** Create a fully functional, Moonscraper-grade chart editor for rhythm game chart creation

---

## Executive Summary

This document provides a comprehensive plan to complete the chart editor for your Godot rhythm game. The editor will enable players to create custom charts with an experience comparable to Moonscraper Chart Editor. The plan addresses critical gaps in the current implementation and provides a clear roadmap for development.

### Current State Assessment

**What Works:**
- ✅ Basic UI structure (toolbar, settings, toolbox, progress bar)
- ✅ 3D runway visualization with board renderer
- ✅ Audio loading and playback (OGG, MP3, WAV)
- ✅ Waveform generation with PCM extraction
- ✅ Timeline scrubbing with slider
- ✅ Note placement via mouse click and keyboard (keys 1-5)
- ✅ Note deletion with erase tool
- ✅ Undo/redo system via command stack
- ✅ File I/O for .chart format
- ✅ Multiple difficulty/instrument selection
- ✅ Song properties dialog
- ✅ Basic snap grid (1/4, 1/8, 1/12, 1/16, 1/24, 1/32, 1/64)
- ✅ Note type support (Regular, HOPO, Tap, Open)

**Critical Issues Identified:**
1. ❌ **Snap grid NOT aligned to song BPM** - This is your biggest problem. Notes snap to arbitrary divisions, not to the song's actual beats
2. ❌ No sustain note editing (click-and-drag to set length)
3. ❌ Limited keyboard shortcuts
4. ❌ No note selection system (box select, multi-select)
5. ❌ No 2D view option (currently only 3D runway)
6. ❌ BPM/tempo marker editing non-functional
7. ❌ Event/section marker placement incomplete
8. ❌ No star power phrase placement
9. ❌ No chord placement support (multi-lane notes at same time)
10. ❌ No "Test Chart" quick-play feature

---

## Part 1: Critical Fix - BPM-Based Snap System

### Problem Analysis

Currently, your snap system (`runway_interaction_controller.gd`) uses this formula:

```gdscript
func snap_time_to_grid(time_value: float) -> float:
    var bpm: float = 120.0
    if tempo_events.size() > 0:
        bpm = tempo_events[0].bpm
    var beat_duration: float = 60.0 / bpm
    var snap_duration: float = beat_duration / (snap_division / 4.0)
    return round(time_value / snap_duration) * snap_duration
```

**Issues:**
1. Only uses the first BPM, doesn't account for BPM changes
2. Doesn't account for song offset
3. Doesn't respect time signatures
4. Not aligned to resolution ticks (standard chart format uses ticks, not time)

### Moonscraper's Approach

Based on the source code analysis, Moonscraper uses a **tick-based system** where:
- Charts use a **resolution** (ticks per beat, typically 192)
- Notes are placed at specific **tick positions**
- Snapping converts ticks to grid-aligned ticks based on time signatures
- BPM changes are handled via a tempo map

**Key Code from Moonscraper (`Snapable.cs`):**
```csharp
public static uint TickToSnappedTick(uint tick, int step, Song song)
{
    float resolution = song.resolution;
    var timeSignatures = song.timeSignatures;
    int tsIndex = SongObjectHelper.FindClosestPositionRoundedDown(tick, timeSignatures);
    TimeSignature ts = timeSignatures[tsIndex];
    
    TimeSignature.MeasureInfo measureInfo = ts.GetMeasureInfo();
    TimeSignature.BeatInfo beatLineInfo = measureInfo.beatLine;
    
    float realBeatStep = step / 4.0f;
    float tickGap = beatLineInfo.tickGap / realBeatStep * ts.denominator / 4.0f;
    
    uint tickOffsetFromTs = tick - ts.tick;
    int measuresFromTsToSnap = (int)((float)tickOffsetFromTs / measureLineInfo.tickGap);
    uint lastMeasureTick = ts.tick + (uint)(measuresFromTsToSnap * measureLineInfo.tickGap);
    
    uint tickOffsetFromLastMeasure = tick - lastMeasureTick;
    int beatsFromLastMeasureToSnap = Mathf.RoundToInt((float)tickOffsetFromLastMeasure / tickGap);
    
    uint snappedTick = lastMeasureTick + (uint)(beatsFromLastMeasureToSnap * tickGap + 0.5f);
    return snappedTick;
}
```

### Implementation Plan

#### Step 1: Add Time ↔ Tick Conversion System

Create `Scripts/Editor/Services/tempo_calculator.gd`:

```gdscript
class_name TempoCalculator
extends RefCounted

# Converts time (seconds) to tick position using tempo map
static func time_to_tick(time: float, tempo_events: Array, resolution: int, offset: float = 0.0) -> int:
    var adjusted_time = time - offset
    if adjusted_time < 0.0:
        return 0
    
    var current_tick: int = 0
    var current_time: float = 0.0
    
    for i in range(tempo_events.size()):
        var event = tempo_events[i]
        var next_event_time: float = INF
        
        if i + 1 < tempo_events.size():
            next_event_time = tempo_events[i + 1].time
        
        var bpm = event.bpm
        var seconds_per_beat = 60.0 / bpm
        var seconds_per_tick = seconds_per_beat / float(resolution)
        
        if adjusted_time <= next_event_time:
            var time_in_section = adjusted_time - current_time
            var ticks_in_section = int(time_in_section / seconds_per_tick)
            return current_tick + ticks_in_section
        else:
            var time_in_section = next_event_time - current_time
            var ticks_in_section = int(time_in_section / seconds_per_tick)
            current_tick += ticks_in_section
            current_time = next_event_time
    
    return current_tick

# Converts tick position to time (seconds) using tempo map
static func tick_to_time(tick: int, tempo_events: Array, resolution: int, offset: float = 0.0) -> float:
    var current_tick: int = 0
    var current_time: float = 0.0
    
    for i in range(tempo_events.size()):
        var event = tempo_events[i]
        var next_event_tick: int = INF
        
        if i + 1 < tempo_events.size():
            next_event_tick = tempo_events[i + 1].tick
        
        var bpm = event.bpm
        var seconds_per_beat = 60.0 / bpm
        var seconds_per_tick = seconds_per_beat / float(resolution)
        
        if tick <= next_event_tick:
            var ticks_in_section = tick - current_tick
            return current_time + (ticks_in_section * seconds_per_tick) + offset
        else:
            var ticks_in_section = next_event_tick - current_tick
            current_time += ticks_in_section * seconds_per_tick
            current_tick = next_event_tick
    
    return current_time + offset

# Snaps a tick to the nearest grid division
static func snap_tick_to_grid(tick: int, snap_division: int, resolution: int, time_signatures: Array = []) -> int:
    # If no time signatures, default to 4/4
    if time_signatures.is_empty():
        time_signatures = [{"tick": 0, "numerator": 4, "denominator": 4}]
    
    # Find the relevant time signature
    var ts = time_signatures[0]
    for sig in time_signatures:
        if sig.tick <= tick:
            ts = sig
        else:
            break
    
    # Calculate ticks per measure and beat
    var ticks_per_beat = resolution
    var ticks_per_measure = ticks_per_beat * ts.numerator
    
    # Calculate snap grid size
    # snap_division is like 16 for 1/16 notes
    var real_beat_step = snap_division / 4.0  # 16/4 = 4 snaps per beat
    var tick_gap = ticks_per_beat / real_beat_step
    
    # Find offset from time signature start
    var tick_offset_from_ts = tick - ts.tick
    
    # Snap to nearest grid line
    var snapped_offset = round(float(tick_offset_from_ts) / tick_gap) * tick_gap
    
    return ts.tick + int(snapped_offset)
```

#### Step 2: Update ChartDocument to Store Ticks

Modify `Scripts/Editor/chart_document.gd`:

```gdscript
# Add to _sanitize_note():
var sanitized := {
    "lane": int(source.get("lane", 0)),
    "time": float(source.get("time", 0.0)),
    "tick": int(source.get("tick", 0)),  # ADD THIS
    "note_type": source.get("note_type", NoteType.Type.REGULAR),
    # ... rest of fields
}
```

#### Step 3: Update RunwayInteractionController

Modify `Scripts/Editor/Services/runway_interaction_controller.gd`:

```gdscript
const TempoCalculator = preload("res://Scripts/Editor/Services/tempo_calculator.gd")

var resolution: int = 192  # Add this
var time_signatures: Array = []  # Add this

func set_resolution(res: int) -> void:
    resolution = res

func set_time_signatures(signatures: Array) -> void:
    time_signatures = signatures

func snap_time_to_grid(time_value: float) -> float:
    # Convert time to tick
    var tick = TempoCalculator.time_to_tick(time_value, tempo_events, resolution, 0.0)
    
    # Snap tick to grid
    var snapped_tick = TempoCalculator.snap_tick_to_grid(tick, snap_division, resolution, time_signatures)
    
    # Convert back to time
    var snapped_time = TempoCalculator.tick_to_time(snapped_tick, tempo_events, resolution, 0.0)
    
    return snapped_time
```

#### Step 4: Update chart_editor.gd

```gdscript
# In _ready() or _configure_runway_interaction():
if runway_interaction:
    runway_interaction.set_tempo_events(tempo_events)
    runway_interaction.set_resolution(resolution)
    runway_interaction.set_time_signatures([])  # Load from chart or default to 4/4
```

**Priority:** 🔴 CRITICAL - Must be completed first

---

## Part 2: Sustain Note Editing

### Current Gap
Notes can have `is_sustain` and `sustain_length` properties, but there's no UI for creating or editing them.

### Moonscraper Behavior
- Right-click and drag on a note's body to adjust sustain length
- Sustain length snaps to grid
- Visual feedback shows sustain tail during drag
- Sustains auto-cap if they would overlap the next note in the same lane

### Implementation Plan

#### Step 1: Add Sustain Drag Mode to RunwayInteractionController

```gdscript
var is_dragging_sustain: bool = false
var sustain_drag_start_note: Dictionary = {}
var sustain_drag_commands: Array = []

func _on_runway_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed:
                _start_sustain_drag(event.position)
            else:
                _end_sustain_drag()
    elif event is InputEventMouseMotion and is_dragging_sustain:
        _update_sustain_drag(event.position)

func _start_sustain_drag(mouse_pos: Vector2) -> void:
    var world_pos = _mouse_to_runway_position(mouse_pos)
    if world_pos == Vector3.ZERO:
        return
    
    var lane = _position_to_lane(world_pos.x)
    var time_value = _position_to_time(world_pos.z)
    
    var note = chart_document.find_note_by_lane_and_time(lane, time_value, 0.2)
    if not note.is_empty():
        is_dragging_sustain = true
        sustain_drag_start_note = note.duplicate(true)

func _update_sustain_drag(mouse_pos: Vector2) -> void:
    if not is_dragging_sustain:
        return
    
    var world_pos = _mouse_to_runway_position(mouse_pos)
    var end_time = snap_time_to_grid(_position_to_time(world_pos.z))
    var start_time = sustain_drag_start_note.time
    
    if end_time > start_time:
        var new_length = end_time - start_time
        # Update note via command
        var update_data = {"sustain_length": new_length, "is_sustain": true}
        # This would need to be connected to command stack
        chart_document.update_note(sustain_drag_start_note.id, update_data)

func _end_sustain_drag() -> void:
    is_dragging_sustain = false
    sustain_drag_start_note = {}
```

#### Step 2: Add Sustain Visual Feedback

Modify `Scripts/Editor/Services/editor_note_visual_manager.gd` to render sustain tails during editing.

#### Step 3: Add Keyboard Shortcut for Sustain Placement

In `chart_editor.gd`:

```gdscript
# Hold SHIFT while placing notes to create a sustain that extends to the next grid line
# Or hold 1-5 keys to continuously extend sustain length
```

**Priority:** 🟡 HIGH

---

## Part 3: Enhanced Keyboard Shortcuts

### Moonscraper Shortcuts to Implement

| Shortcut | Action | Status |
|----------|--------|--------|
| **Space** | Play/Pause | ✅ Implemented |
| **1-5** | Place note in lane | ✅ Implemented |
| **Ctrl+S** | Save | ✅ Implemented |
| **Ctrl+Z** | Undo | ✅ Implemented |
| **Ctrl+Y / Ctrl+Shift+Z** | Redo | ✅ Implemented |
| **Delete** | Delete selected notes | ✅ Implemented |
| **[ ]** | Decrease/Increase snap | ✅ Implemented |
| **Q/W/E/R/T/Y** | Tool selection | ❌ Not implemented |
| **Ctrl+A** | Select all notes | ❌ Not implemented |
| **Ctrl+C** | Copy notes | ❌ Not implemented |
| **Ctrl+V** | Paste notes | ❌ Not implemented |
| **Ctrl+X** | Cut notes | ❌ Not implemented |
| **Ctrl+D** | Duplicate notes | ❌ Not implemented |
| **Arrow Keys** | Move timeline | ❌ Not implemented |
| **Shift+Arrow** | Jump to next/prev note | ❌ Not implemented |
| **Home/End** | Jump to start/end | ❌ Not implemented |
| **Shift+1-5** | Toggle note type | ❌ Not implemented |
| **Tab** | Toggle between 2D/3D view | ❌ Not implemented |

### Implementation

Add to `chart_editor.gd`:

```gdscript
func _handle_keyboard_shortcut(event: InputEventKey):
    var key = event.keycode
    
    # Tool shortcuts Q/W/E/R/T/Y
    if not event.ctrl_pressed and not event.shift_pressed:
        match key:
            KEY_Q: _on_tool_selected("Cursor")
            KEY_W: _on_tool_selected("Note")
            KEY_E: _on_tool_selected("Erase")
            KEY_R: _on_tool_selected("BPM")
            KEY_T: _on_tool_selected("Section")
            KEY_Y: _on_tool_selected("Event")
    
    # Select All
    if event.ctrl_pressed and key == KEY_A:
        _select_all_notes()
        get_viewport().set_input_as_handled()
        return
    
    # Copy
    if event.ctrl_pressed and key == KEY_C:
        _copy_selected_notes()
        get_viewport().set_input_as_handled()
        return
    
    # Paste
    if event.ctrl_pressed and key == KEY_V:
        _paste_notes()
        get_viewport().set_input_as_handled()
        return
    
    # Cut
    if event.ctrl_pressed and key == KEY_X:
        _cut_selected_notes()
        get_viewport().set_input_as_handled()
        return
    
    # Duplicate
    if event.ctrl_pressed and key == KEY_D:
        _duplicate_selected_notes()
        get_viewport().set_input_as_handled()
        return
    
    # Timeline navigation
    match key:
        KEY_LEFT: _move_timeline(-0.5)
        KEY_RIGHT: _move_timeline(0.5)
        KEY_UP: if event.ctrl_pressed: _zoom_in()
        KEY_DOWN: if event.ctrl_pressed: _zoom_out()
        KEY_HOME: _jump_to_start()
        KEY_END: _jump_to_end()
```

**Priority:** 🟡 HIGH

---

## Part 4: Note Selection System

### Requirements
1. Click to select single note
2. Ctrl+Click to add/remove from selection
3. Click-and-drag box select (marquee)
4. Visual highlighting of selected notes
5. Multi-edit capabilities (change type, delete all, etc.)

### Implementation Plan

#### Step 1: Create SelectionManager

Create `Scripts/Editor/Services/editor_selection_manager.gd`:

```gdscript
class_name EditorSelectionManager
extends RefCounted

signal selection_changed(selected_notes: Array)

var selected_note_ids: Array = []
var chart_document: ChartDocument

func _init(document: ChartDocument):
    chart_document = document

func select_note(note_id: int, additive: bool = false):
    if not additive:
        clear_selection()
    
    if not selected_note_ids.has(note_id):
        selected_note_ids.append(note_id)
        emit_signal("selection_changed", get_selected_notes())

func deselect_note(note_id: int):
    selected_note_ids.erase(note_id)
    emit_signal("selection_changed", get_selected_notes())

func clear_selection():
    selected_note_ids.clear()
    emit_signal("selection_changed", [])

func is_selected(note_id: int) -> bool:
    return selected_note_ids.has(note_id)

func get_selected_notes() -> Array:
    var notes = []
    for id in selected_note_ids:
        var note = chart_document.get_note(id)
        if not note.is_empty():
            notes.append(note)
    return notes

func select_in_region(start_time: float, end_time: float, lanes: Array):
    clear_selection()
    for note in chart_document.get_notes():
        if note.time >= start_time and note.time <= end_time:
            if note.lane in lanes:
                selected_note_ids.append(note.id)
    emit_signal("selection_changed", get_selected_notes())

func select_all():
    clear_selection()
    for note in chart_document.get_notes():
        selected_note_ids.append(note.id)
    emit_signal("selection_changed", get_selected_notes())
```

#### Step 2: Add Box Select to RunwayInteractionController

```gdscript
var is_box_selecting: bool = false
var box_select_start: Vector2
var box_select_end: Vector2
var box_select_visual: Control  # Draw selection rectangle

func _on_runway_input(event: InputEvent) -> void:
    if current_tool == "Cursor":
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _start_box_select(event.position)
            else:
                _end_box_select()
        elif event is InputEventMouseMotion and is_box_selecting:
            _update_box_select(event.position)
```

#### Step 3: Visual Feedback for Selected Notes

Modify `editor_note_visual_manager.gd`:

```gdscript
func update_note_selection(selected_ids: Array):
    for note_visual in active_notes:
        if note_visual.note_data.id in selected_ids:
            note_visual.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow highlight
        else:
            note_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
```

**Priority:** 🟠 MEDIUM

---

## Part 5: 2D Chart View

### Problem
Currently only 3D highway view exists. Moonscraper has a 2D view that's often easier for precise editing.

### Implementation Approach

#### Option A: Separate 2D View (Recommended)

Create a new 2D rendering system that exists alongside the 3D view:

```gdscript
# Scripts/Editor/Services/editor_2d_view.gd
class_name Editor2DView
extends Control

var chart_document: ChartDocument
var tempo_events: Array
var resolution: int
var num_lanes: int = 5
var pixels_per_beat: float = 40.0
var scroll_position: float = 0.0

func _draw():
    # Draw measure lines
    _draw_measure_lines()
    
    # Draw beat lines
    _draw_beat_lines()
    
    # Draw lane separators
    _draw_lane_separators()
    
    # Draw notes as rectangles
    _draw_notes()
    
    # Draw playhead
    _draw_playhead()

func _draw_notes():
    for note in chart_document.get_notes():
        var y_pos = _tick_to_y_position(note.tick)
        var x_pos = _lane_to_x_position(note.lane)
        var rect = Rect2(x_pos, y_pos, lane_width, note_height)
        draw_rect(rect, _get_note_color(note.note_type))
        
        # Draw sustain tail
        if note.is_sustain:
            var tail_length = _time_to_pixels(note.sustain_length)
            var tail_rect = Rect2(x_pos + 5, y_pos, lane_width - 10, tail_length)
            draw_rect(tail_rect, _get_note_color(note.note_type).darkened(0.3))
```

Add to `chart_editor.tscn`:
- Toggle button to switch between 2D and 3D views
- Or split screen showing both simultaneously

**Priority:** 🟢 MEDIUM-LOW (Nice to have, but not critical)

---

## Part 6: BPM/Tempo Editing

### Current State
BPM tool button exists but does nothing.

### Requirements
1. Click to place BPM marker at cursor position
2. Edit BPM value via inspector panel
3. Drag BPM marker to reposition
4. BPM changes affect note timing calculations
5. Visual representation on timeline

### Implementation

#### Step 1: BPM Marker Data Structure

```gdscript
# Add to chart_document.gd
var tempo_markers: Array = []  # Array of {tick: int, bpm: float, time: float}

func add_tempo_marker(tick: int, bpm: float):
    var marker = {"tick": tick, "bpm": bpm}
    tempo_markers.append(marker)
    tempo_markers.sort_custom(func(a, b): return a.tick < b.tick)
    _recalculate_tempo_times()

func _recalculate_tempo_times():
    # Recalculate time values for all tempo markers based on ticks
    var current_time = 0.0
    for i in range(tempo_markers.size()):
        if i == 0:
            tempo_markers[i].time = 0.0
        else:
            var prev_marker = tempo_markers[i - 1]
            var tick_delta = tempo_markers[i].tick - prev_marker.tick
            var time_delta = TempoCalculator.ticks_to_time(tick_delta, prev_marker.bpm, resolution)
            tempo_markers[i].time = prev_marker.time + time_delta
```

#### Step 2: BPM Placement Tool

```gdscript
# In runway_interaction_controller.gd
func _place_bpm_marker(mouse_pos: Vector2):
    var world_pos = _mouse_to_runway_position(mouse_pos)
    var time_value = snap_time_to_grid(_position_to_time(world_pos.z))
    var tick = TempoCalculator.time_to_tick(time_value, tempo_events, resolution)
    
    # Open dialog to enter BPM value
    var dialog = BPMInputDialog.new()
    dialog.bpm_entered.connect(func(bpm_value):
        chart_document.add_tempo_marker(tick, bpm_value)
    )
    dialog.popup_centered()
```

#### Step 3: BPM Inspector Panel

Create `Scenes/Editor/bpm_inspector_panel.tscn` with:
- BPM value input field
- Position (tick) display
- Delete button
- Time display

**Priority:** 🟠 MEDIUM

---

## Part 7: Section Markers & Events

### Requirements
- Section markers (e.g., "Intro", "Verse 1", "Chorus")
- Events (e.g., "solo", "crowd_clap", "lighting_change")
- Visual timeline representation
- Click on marker to jump to that position

### Implementation

#### Step 1: Data Structure

```gdscript
# Add to chart_document.gd
var sections: Array = []  # {tick: int, name: String, time: float}
var events: Array = []  # {tick: int, event_type: String, time: float}

signal section_added(section_data: Dictionary)
signal event_added(event_data: Dictionary)
```

#### Step 2: Section Placement Tool

```gdscript
func _place_section_marker(mouse_pos: Vector2):
    var time_value = snap_time_to_grid(_position_to_time_from_mouse(mouse_pos))
    var dialog = SectionNameDialog.new()
    dialog.section_named.connect(func(section_name):
        chart_document.add_section(time_value, section_name)
    )
    dialog.popup_centered()
```

#### Step 3: Update Progress Bar

The existing `editor_progress_bar.tscn` should display and navigate sections.

**Priority:** 🟢 MEDIUM-LOW

---

## Part 8: Test Chart Feature

### Requirement
Button to immediately test-play the current chart without saving.

### Implementation

```gdscript
# In chart_editor.gd
func _on_test_chart_requested():
    # Save current chart to temporary memory
    var temp_chart_data = {
        "notes": chart_document.get_notes(),
        "tempo_events": tempo_events,
        "resolution": resolution,
        "offset": offset,
        "audio_file": audio_file_path
    }
    
    # Store in global/autoload
    ChartLoadingService.preload_chart_for_testing(temp_chart_data)
    
    # Launch gameplay scene
    SceneSwitcher.push_scene("res://Scenes/gameplay.tscn")

# Add to toolbar
toolbar.test_chart_requested.connect(_on_test_chart_requested)
```

**Priority:** 🟡 HIGH (Essential for workflow)

---

## Part 9: Additional Quality-of-Life Features

### 9.1 Metronome/Click Track
- Audio click on each beat during playback
- Helps with timing while charting
- Toggle in settings panel

### 9.2 Note Density Visualization
- Graph showing notes per second
- Helps identify difficulty spikes
- Visual feedback for chart balance

### 9.3 Validation Warnings
- Warn about impossible chord combinations
- Flag notes too close together
- Detect overlapping sustains

### 9.4 Chord Helper
- Hold multiple 1-5 keys to place chord
- Visual preview of chord before placement

### 9.5 Auto-HOPO Detection
- Automatically assign HOPO flags based on note spacing
- Moonscraper has this feature

### 9.6 Waveform Improvements
- Currently waveform works but could be more accurate
- Add zoom controls
- Sync beats to waveform peaks

---

## Implementation Priority & Timeline

### Phase 1: Critical Fixes (Week 1-2)
1. ✅ **BPM-Based Snap System** - Days 1-3
2. ✅ **Sustain Note Editing** - Days 4-6
3. ✅ **Enhanced Keyboard Shortcuts** - Days 7-8
4. ✅ **Test Chart Feature** - Days 9-10

### Phase 2: Core Functionality (Week 3-4)
5. ✅ **Note Selection System** - Days 11-14
6. ✅ **BPM/Tempo Editing** - Days 15-18
7. ✅ **Section Markers** - Days 19-21

### Phase 3: Usability (Week 5-6)
8. ✅ **2D View** - Days 22-25
9. ✅ **Metronome** - Days 26-27
10. ✅ **Validation System** - Days 28-30

### Phase 4: Polish (Week 7-8)
11. ✅ **Chord Helper** - Days 31-33
12. ✅ **Auto-HOPO** - Days 34-36
13. ✅ **UI/UX Polish** - Days 37-40
14. ✅ **Testing & Bug Fixes** - Days 41-45

---

## Technical Architecture Recommendations

### Service Layer Pattern
Keep the modular service-based architecture:
- `tempo_calculator.gd` - Time/tick conversions
- `editor_selection_manager.gd` - Note selection
- `runway_interaction_controller.gd` - Input handling
- `editor_note_visual_manager.gd` - Visual representation
- `chart_editor_file_service.gd` - File I/O

### Command Pattern for Undo/Redo
Expand the existing command system:
- `ModifySustainCommand`
- `ChangeBPMCommand`
- `AddSectionCommand`
- `BatchEditCommand` (for multi-note operations)

### Event-Driven Updates
Use signals to decouple systems:
```gdscript
chart_document.note_added.connect(note_visual_manager.on_note_added)
selection_manager.selection_changed.connect(note_visual_manager.update_selection)
```

---

## Testing Strategy

### Unit Tests (GdUnit4)
- ✅ Tempo calculations (time ↔ tick conversion)
- ✅ Snap grid accuracy
- ✅ Note serialization/deserialization
- ✅ Command undo/redo

### Integration Tests
- ✅ Full chart save/load cycle
- ✅ BPM changes affect note timing
- ✅ Test chart launches gameplay correctly

### Manual QA Checklist
- [ ] Create a chart from scratch
- [ ] Place notes at different snap divisions
- [ ] Verify notes align with audio beats
- [ ] Create sustain notes of various lengths
- [ ] Test with multiple BPM changes
- [ ] Export chart and load in gameplay
- [ ] Verify all keyboard shortcuts work
- [ ] Test selection and multi-edit
- [ ] Switch between 2D/3D views
- [ ] Test undo/redo for all operations

---

## Success Criteria

The chart editor will be considered **complete** when:

1. ✅ Notes snap correctly to song's actual beats (BPM-aligned)
2. ✅ Sustain notes can be created and edited intuitively
3. ✅ All essential Moonscraper keyboard shortcuts work
4. ✅ Multi-note selection and editing is functional
5. ✅ BPM markers can be placed and edited
6. ✅ Test chart feature allows instant playtesting
7. ✅ Charts created in editor play correctly in gameplay mode
8. ✅ File save/load is reliable and preserves all data
9. ✅ A user can create a complete, playable chart in under 30 minutes (for a 3-minute song)
10. ✅ No major bugs prevent chart creation workflow

---

## References & Resources

### Moonscraper Source Code
- Repository: https://github.com/FireFox2000000/Moonscraper-Chart-Editor
- Key Files Analyzed:
  - `Snapable.cs` - Grid snapping logic
  - `BPMController.cs` - BPM editing
  - `SustainController.cs` - Sustain dragging
  - `PlaceNoteController.cs` - Note placement
  - `DrawBeatLines.cs` - Beat line rendering

### .chart Format Specification
- Understanding resolution, tick positions, SyncTrack, Events
- Example charts in `Other Songs/` directory

### Your Existing Systems
- `ChartLoadingService.gd` - Already handles .chart parsing
- `NoteType.gd` - Defines note types
- `board_renderer.gd` - Runway visualization
- Command stack already implemented

---

## Conclusion

This plan provides a clear, prioritized roadmap to complete your chart editor. The most critical issue—BPM-aligned snap grid—must be addressed first, as it affects the accuracy of all placed notes. Following the phased approach will result in a professional-grade chart editor that rivals Moonscraper in functionality.

The implementation leverages your existing architecture and adds the missing pieces systematically. By Week 8, you'll have a fully functional chart editor that enables players to create high-quality charts for your rhythm game.

**Next Steps:**
1. Review this plan and adjust priorities based on your preferences
2. Begin with Part 1 (BPM-Based Snap System) immediately
3. Implement test cases for tempo calculations
4. Move through phases systematically
5. Test with real songs at each milestone

Good luck with the implementation! 🎵🎸
