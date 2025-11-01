# Chart Editor Design Document

**Version:** 1.0  
**Date:** November 1, 2025  
**Project:** Godot 4 3D Rhythm Game - Chart Creation System

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Design Goals & Philosophy](#design-goals--philosophy)
3. [Research & Inspiration](#research--inspiration)
4. [File Format Design](#file-format-design)
5. [Editor Architecture](#editor-architecture)
6. [Core Systems](#core-systems)
7. [User Interface Design](#user-interface-design)
8. [Workflow & User Experience](#workflow--user-experience)
9. [Technical Implementation](#technical-implementation)
10. [Testing & Quality Assurance](#testing--quality-assurance)
11. [Future Enhancements](#future-enhancements)
12. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

This document outlines the design for a comprehensive chart creation system for the rhythm game. The system will enable players to create, edit, test, and share custom charts for their own music files. The design emphasizes:

- **Ease of Use**: Intuitive interface accessible to both beginners and advanced charters
- **Precision**: Frame-perfect note placement with audio synchronization
- **Testing Integration**: Seamless transition between editing and testing
- **Community Focus**: Export/import capabilities for sharing charts
- **Professional Quality**: Features comparable to established tools like Moonscraper and Clone Hero Chart Editor

### Key Features

- Custom chart file format (`.rgchart` - Rhythm Game Chart) with backward compatibility to `.chart` format
- Visual waveform display for accurate note placement
- Real-time audio playback with note preview
- Multiple difficulty editing in one session
- Keyboard shortcuts for rapid charting
- Auto-save and undo/redo functionality
- Direct integration with gameplay for instant testing
- Chart validation and quality checks
- Metadata editor for song information

---

## Design Goals & Philosophy

### Primary Goals

1. **Accessibility**: The editor should be learnable within 30 minutes by users familiar with rhythm games
2. **Precision**: Support frame-accurate note placement synchronized with audio
3. **Efficiency**: Enable rapid charting with keyboard-driven workflow
4. **Integration**: Seamless integration with existing gameplay systems
5. **Extensibility**: Architecture that supports future feature additions

### Design Philosophy

- **Music First**: Audio waveform and playback are central to the editing experience
- **Visual Feedback**: Immediate visual representation of chart changes
- **Forgiving UX**: Undo/redo, auto-save, and non-destructive editing
- **Progressive Disclosure**: Simple interface with advanced features available when needed
- **Community Standards**: Compatibility with existing charting conventions from Clone Hero/Guitar Hero

---

## Research & Inspiration

### Industry Analysis

#### Moonscraper Chart Editor
**Strengths:**
- Keyboard-driven workflow (QWERTY mapping to lanes)
- Real-time waveform visualization
- Snap grid system for consistent timing
- BPM detection and sync track editing
- Copy/paste/mirror note operations

**Key Takeaways:**
- Waveform display is essential for accurate charting
- Keyboard shortcuts dramatically speed up workflow
- Snap-to-grid prevents timing errors
- Visual distinction between note types (regular, HOPO, tap, sustain)

#### Clone Hero Chart Editor
**Strengths:**
- Clean, minimalist interface
- Split view for multiple difficulties
- In-editor playback with note preview
- Comprehensive metadata editing
- Chart validation warnings

**Key Takeaways:**
- Metadata management is critical for organization
- Visual consistency with gameplay aids learning
- Validation prevents common charting mistakes
- Quick access to playback controls

#### Osu! Beatmap Editor
**Strengths:**
- Timeline scrubbing with visual feedback
- Distance snap for rhythm consistency
- Bookmark system for navigation
- Test play from current position
- Extensive keyboard shortcuts

**Key Takeaways:**
- Timeline scrubbing enables precise positioning
- Bookmarks help manage long songs
- "Test from here" feature is invaluable
- Audio playback rate adjustment aids charting

#### Phase Shift / FoFiX
**Strengths:**
- Open-source reference implementations
- Community-driven feature additions
- Focus on user-generated content
- Cross-compatibility emphasis

**Key Takeaways:**
- Open formats promote community growth
- Compatibility with existing formats lowers barrier to entry
- User feedback drives feature priority

---

## File Format Design

### Custom Format: `.rgchart`

We'll create a custom JSON-based format that's human-readable, version-controlled friendly, and extensible. This format will be the primary format for the editor, with conversion utilities for `.chart` format import/export.

#### Format Specification

```json
{
  "version": "1.0",
  "metadata": {
    "title": "Song Title",
    "artist": "Artist Name",
    "album": "Album Name",
    "year": "2025",
    "charter": "Charter Name",
    "genre": "Rock",
    "duration": 245.5,
    "previewStart": 30.0,
    "previewDuration": 15.0
  },
  "audio": {
    "musicFile": "song.ogg",
    "guitarFile": "",
    "bassFile": "",
    "rhythmFile": "",
    "drumFile": "",
    "crowdFile": ""
  },
  "sync": {
    "resolution": 192,
    "offset": 0.0,
    "tempoMap": [
      {
        "tick": 0,
        "bpm": 120.0,
        "timeSignature": [4, 4]
      }
    ]
  },
  "instruments": {
    "guitar": {
      "difficulties": {
        "expert": {
          "notes": [
            {
              "tick": 768,
              "lane": 2,
              "type": "regular",
              "length": 0
            },
            {
              "tick": 960,
              "lane": 1,
              "type": "hopo",
              "length": 96
            }
          ],
          "starPower": [
            {
              "start": 768,
              "end": 1152
            }
          ],
          "events": []
        },
        "hard": { "notes": [], "starPower": [], "events": [] },
        "medium": { "notes": [], "starPower": [], "events": [] },
        "easy": { "notes": [], "starPower": [], "events": [] }
      }
    },
    "bass": {
      "difficulties": {}
    },
    "drums": {
      "difficulties": {}
    }
  },
  "events": [
    {
      "tick": 0,
      "type": "section",
      "name": "Intro"
    }
  ],
  "chartMetadata": {
    "createdDate": "2025-11-01T12:00:00Z",
    "modifiedDate": "2025-11-01T15:30:00Z",
    "editorVersion": "1.0.0",
    "customData": {}
  }
}
```

#### Format Advantages

1. **Human-Readable**: JSON allows easy manual editing and debugging
2. **Version Control Friendly**: Text-based format works well with git
3. **Extensible**: Easy to add new fields without breaking compatibility
4. **Structured**: Clear hierarchy and organization
5. **Validation**: JSON schema can validate chart correctness
6. **Metadata Rich**: Comprehensive tracking of chart history

#### Backward Compatibility

The system will include converters:
- **Import**: `.chart` → `.rgchart` (one-time conversion)
- **Export**: `.rgchart` → `.chart` (for compatibility with other tools)

Conversion will be lossless for standard features, with custom features stored in comments or separate files when exporting to `.chart`.

---

## Editor Architecture

### High-Level Component Structure

```
ChartEditorScene (Main Container)
├── AudioManager (Playback & Waveform)
├── TimelineController (Timeline State & Navigation)
├── ChartDataModel (Data Layer)
├── EditorViewport (Visual Representation)
│   ├── WaveformDisplay
│   ├── NoteHighway (Lane Visualization)
│   ├── BPMMarkers
│   ├── EventMarkers
│   └── PlaybackCursor
├── EditorUI (User Interface)
│   ├── TopToolbar (File, Edit, View, Help)
│   ├── PlaybackControls (Play, Pause, Stop, Seek)
│   ├── EditToolbar (Note Types, Snap, Tools)
│   ├── SidePanel (Metadata, Difficulty Select, Properties)
│   └── StatusBar (Timestamp, BPM, Snap, Stats)
├── InputManager (Keyboard/Mouse Input)
├── HistoryManager (Undo/Redo System)
├── ValidationEngine (Chart Quality Checks)
└── TestPlayHandler (Integration with Gameplay)
```

### Architectural Patterns

#### Model-View-Controller (MVC)

- **Model**: `ChartDataModel` - Pure data layer with serialization
- **View**: `EditorViewport` + `EditorUI` - Visual representation
- **Controller**: `ChartEditorScene` - Coordinates between Model and View

#### Command Pattern for Undo/Redo

All editing operations are implemented as commands:

```gdscript
class_name EditorCommand extends RefCounted

var executed: bool = false

func execute(context: Dictionary) -> void:
    pass

func undo(context: Dictionary) -> void:
    pass

func get_description() -> String:
    return "Generic command"
```

Examples:
- `PlaceNoteCommand`
- `DeleteNoteCommand`
- `MoveNoteCommand`
- `ChangeBPMCommand`
- `AddEventCommand`

#### Observer Pattern for UI Updates

```gdscript
signal chart_modified(change_type: String, data: Dictionary)
signal playback_position_changed(position: float)
signal selection_changed(selected_notes: Array)
signal difficulty_changed(instrument: String, difficulty: String)
```

UI components subscribe to these signals to update automatically.

#### Factory Pattern for Note Creation

```gdscript
class_name NoteFactory

static func create_note(type: NoteType, tick: int, lane: int, length: int = 0) -> Dictionary:
    return {
        "tick": tick,
        "lane": lane,
        "type": get_type_string(type),
        "length": length,
        "id": generate_unique_id()
    }
```

---

## Core Systems

### 1. Audio System

#### Components

**AudioManager**
- Loads and manages audio streams
- Controls playback (play, pause, stop, seek)
- Supports playback speed adjustment (0.25x - 2.0x)
- Provides time synchronization for editor

**WaveformGenerator**
- Generates visual waveform from audio data
- Caches waveform data for performance
- Supports zoom levels (1x, 2x, 4x, 8x)
- Color-codes amplitude (quiet=blue, medium=green, loud=red)

#### Audio Synchronization

Critical for accurate charting:

```gdscript
func get_song_time() -> float:
    if audio_player.playing:
        return audio_player.get_playback_position() + offset
    else:
        return manual_seek_position

func tick_to_time(tick: int) -> float:
    # Convert tick position to seconds using tempo map
    var time = 0.0
    var current_bpm = 120.0
    var last_tick = 0
    
    for tempo_event in tempo_map:
        if tempo_event.tick > tick:
            break
        var elapsed_ticks = tempo_event.tick - last_tick
        time += (elapsed_ticks / resolution) * (60.0 / current_bpm)
        current_bpm = tempo_event.bpm
        last_tick = tempo_event.tick
    
    var remaining_ticks = tick - last_tick
    time += (remaining_ticks / resolution) * (60.0 / current_bpm)
    return time

func time_to_tick(time: float) -> int:
    # Inverse operation - find tick for given time
    # Used for placing notes at audio positions
```

#### Waveform Display

```gdscript
class_name WaveformDisplay extends Control

var waveform_data: PackedVector2Array  # Cached amplitude data
var zoom_level: float = 1.0
var pixels_per_second: float = 100.0

func generate_waveform(audio_stream: AudioStream):
    # Extract audio samples
    # Downsample for visualization
    # Store in waveform_data

func _draw():
    # Draw waveform bars
    # Highlight current playback position
    # Color-code by amplitude
```

### 2. Timeline System

The timeline is the heart of the editor, providing temporal navigation and visualization.

#### TimelineController

```gdscript
class_name EditorTimelineController extends Node

var current_time: float = 0.0
var song_duration: float = 0.0
var playing: bool = false
var loop_enabled: bool = false
var loop_start: float = 0.0
var loop_end: float = 0.0

# Grid snapping
var snap_enabled: bool = true
var snap_division: int = 16  # 1/16 notes

func snap_tick(tick: int) -> int:
    if not snap_enabled:
        return tick
    var snap_interval = resolution / snap_division
    return int(round(tick / float(snap_interval))) * snap_interval

func snap_time(time: float) -> float:
    var tick = time_to_tick(time)
    var snapped_tick = snap_tick(tick)
    return tick_to_time(snapped_tick)

func set_playback_rate(rate: float):
    # 0.25x, 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
    audio_manager.pitch_scale = rate
```

#### Snap Grid System

Common snap divisions:
- 1/4 notes (quarter notes)
- 1/8 notes (eighth notes)
- 1/12 notes (triplets)
- 1/16 notes (sixteenth notes)
- 1/24 notes (sixteenth triplets)
- 1/32 notes (thirty-second notes)
- 1/64 notes (sixty-fourth notes)

Visual indicators show snap positions on the highway.

### 3. Note Highway Visualization

The note highway displays lanes, notes, and grid lines in a scrolling view similar to gameplay.

#### EditorNoteHighway

```gdscript
class_name EditorNoteHighway extends Control

const LANE_COUNT = 5
const LANE_COLORS = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]

var scroll_position: float = 0.0  # Current timeline position
var zoom_level: float = 1.0       # Vertical zoom (time scale)
var pixels_per_beat: float = 100.0

func _draw():
    draw_background()
    draw_grid_lines()
    draw_bpm_markers()
    draw_notes()
    draw_sustains()
    draw_selection_box()
    draw_playback_cursor()

func draw_notes():
    var visible_start = scroll_position - 2.0  # 2 seconds buffer
    var visible_end = scroll_position + 2.0
    
    for note in get_visible_notes(visible_start, visible_end):
        var screen_y = time_to_screen_y(tick_to_time(note.tick))
        var lane_x = get_lane_x(note.lane)
        
        match note.type:
            "regular":
                draw_circle(Vector2(lane_x, screen_y), 10, LANE_COLORS[note.lane])
            "hopo":
                draw_circle(Vector2(lane_x, screen_y), 10, LANE_COLORS[note.lane])
                draw_circle(Vector2(lane_x, screen_y), 7, Color.WHITE)
            "tap":
                draw_rect(Rect2(lane_x - 8, screen_y - 8, 16, 16), LANE_COLORS[note.lane])

func time_to_screen_y(time: float) -> float:
    var relative_time = time - scroll_position
    return get_rect().size.y / 2.0 - relative_time * pixels_per_beat * (current_bpm / 60.0)

func screen_y_to_time(y: float) -> float:
    var relative_y = (get_rect().size.y / 2.0 - y) / (pixels_per_beat * (current_bpm / 60.0))
    return scroll_position + relative_y
```

### 4. Chart Data Model

Manages all chart data with efficient access and modification.

```gdscript
class_name ChartDataModel extends RefCounted

var metadata: Dictionary = {}
var sync_data: Dictionary = {}
var instruments: Dictionary = {}
var events: Array = []

# Current editing context
var current_instrument: String = "guitar"
var current_difficulty: String = "expert"

signal data_changed(change_type: String)

func get_notes(instrument: String, difficulty: String) -> Array:
    if not instruments.has(instrument):
        return []
    if not instruments[instrument].difficulties.has(difficulty):
        return []
    return instruments[instrument].difficulties[difficulty].notes

func add_note(note: Dictionary) -> void:
    var notes = get_notes(current_instrument, current_difficulty)
    notes.append(note)
    notes.sort_custom(func(a, b): return a.tick < b.tick)
    emit_signal("data_changed", "note_added")

func remove_note(note_id: String) -> void:
    var notes = get_notes(current_instrument, current_difficulty)
    for i in range(notes.size() - 1, -1, -1):
        if notes[i].id == note_id:
            notes.remove_at(i)
            emit_signal("data_changed", "note_removed")
            return

func get_notes_in_range(start_tick: int, end_tick: int) -> Array:
    var result = []
    var notes = get_notes(current_instrument, current_difficulty)
    for note in notes:
        if note.tick >= start_tick and note.tick <= end_tick:
            result.append(note)
    return result

func save_to_file(path: String) -> Error:
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    
    var data = {
        "version": "1.0",
        "metadata": metadata,
        "audio": get_audio_config(),
        "sync": sync_data,
        "instruments": instruments,
        "events": events,
        "chartMetadata": get_chart_metadata()
    }
    
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    return OK

func load_from_file(path: String) -> Error:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()
    
    var json = JSON.new()
    var parse_result = json.parse(file.get_as_text())
    file.close()
    
    if parse_result != OK:
        return parse_result
    
    var data = json.data
    metadata = data.metadata
    sync_data = data.sync
    instruments = data.instruments
    events = data.events
    
    emit_signal("data_changed", "chart_loaded")
    return OK
```

### 5. Input System

Handles keyboard and mouse input for efficient charting.

#### Keyboard Shortcuts

**Navigation:**
- `Space`: Play/Pause
- `Home`: Jump to start
- `End`: Jump to end
- `Arrow Up/Down`: Scroll timeline
- `Page Up/Down`: Jump by measure
- `[` / `]`: Decrease/Increase playback speed

**Editing:**
- `1-5`: Place note on lane 1-5
- `Shift + 1-5`: Place HOPO note
- `Ctrl + 1-5`: Place tap note
- `Delete`: Delete selected notes
- `Ctrl + C`: Copy selected notes
- `Ctrl + V`: Paste notes
- `Ctrl + X`: Cut notes
- `Ctrl + Z`: Undo
- `Ctrl + Y`: Redo
- `Ctrl + A`: Select all notes in view

**Tools:**
- `N`: Note placement mode
- `S`: Select mode
- `B`: BPM marker mode
- `E`: Event marker mode
- `L`: Set loop region
- `M`: Toggle metronome

**View:**
- `+` / `-`: Zoom in/out
- `Ctrl + 0`: Reset zoom
- `F`: Focus on selection
- `G`: Toggle grid lines
- `W`: Toggle waveform

#### Mouse Input

- **Left Click**: Place note (in note mode) or select (in select mode)
- **Right Click**: Delete note or open context menu
- **Click + Drag**: Create sustain note or select region
- **Middle Mouse Drag**: Pan timeline
- **Scroll Wheel**: Zoom timeline
- **Ctrl + Scroll**: Adjust playback position

### 6. Undo/Redo System

Implements comprehensive history tracking.

```gdscript
class_name EditorHistoryManager extends Node

const MAX_HISTORY_SIZE = 500

var undo_stack: Array[EditorCommand] = []
var redo_stack: Array[EditorCommand] = []
var command_in_progress: bool = false

signal history_changed(can_undo: bool, can_redo: bool)

func execute_command(command: EditorCommand, context: Dictionary):
    if command_in_progress:
        push_warning("Cannot execute command while another is in progress")
        return
    
    command_in_progress = true
    command.execute(context)
    command.executed = true
    
    undo_stack.push_back(command)
    redo_stack.clear()
    
    # Limit history size
    if undo_stack.size() > MAX_HISTORY_SIZE:
        undo_stack.pop_front()
    
    command_in_progress = false
    emit_signal("history_changed", can_undo(), can_redo())

func undo(context: Dictionary):
    if not can_undo() or command_in_progress:
        return
    
    command_in_progress = true
    var command = undo_stack.pop_back()
    command.undo(context)
    redo_stack.push_back(command)
    command_in_progress = false
    emit_signal("history_changed", can_undo(), can_redo())

func redo(context: Dictionary):
    if not can_redo() or command_in_progress:
        return
    
    command_in_progress = true
    var command = redo_stack.pop_back()
    command.execute(context)
    undo_stack.push_back(command)
    command_in_progress = false
    emit_signal("history_changed", can_undo(), can_redo())

func can_undo() -> bool:
    return not undo_stack.is_empty()

func can_redo() -> bool:
    return not redo_stack.is_empty()

func clear_history():
    undo_stack.clear()
    redo_stack.clear()
    emit_signal("history_changed", false, false)
```

### 7. Validation Engine

Checks chart quality and flags potential issues.

```gdscript
class_name ChartValidator extends RefCounted

enum IssueType {
    ERROR,      # Critical issues (impossible notes)
    WARNING,    # Questionable patterns
    INFO        # Suggestions for improvement
}

class ValidationIssue:
    var type: IssueType
    var message: String
    var tick: int
    var notes: Array  # Affected notes
    
    func _init(t: IssueType, msg: String, tk: int, nts: Array = []):
        type = t
        message = msg
        tick = tk
        notes = nts

func validate_chart(chart_data: ChartDataModel) -> Array[ValidationIssue]:
    var issues: Array[ValidationIssue] = []
    
    # Check for overlapping notes (same tick, same lane)
    issues.append_array(check_overlapping_notes(chart_data))
    
    # Check for impossible patterns (human playability)
    issues.append_array(check_impossible_patterns(chart_data))
    
    # Check for empty difficulties
    issues.append_array(check_empty_difficulties(chart_data))
    
    # Check for missing metadata
    issues.append_array(check_metadata(chart_data))
    
    # Check for BPM/sync issues
    issues.append_array(check_sync_track(chart_data))
    
    return issues

func check_overlapping_notes(chart_data: ChartDataModel) -> Array[ValidationIssue]:
    var issues: Array[ValidationIssue] = []
    var notes = chart_data.get_notes(chart_data.current_instrument, chart_data.current_difficulty)
    
    for i in range(notes.size() - 1):
        for j in range(i + 1, notes.size()):
            if notes[i].tick == notes[j].tick and notes[i].lane == notes[j].lane:
                issues.append(ValidationIssue.new(
                    IssueType.ERROR,
                    "Overlapping notes on lane %d" % notes[i].lane,
                    notes[i].tick,
                    [notes[i], notes[j]]
                ))
    
    return issues

func check_impossible_patterns(chart_data: ChartDataModel) -> Array[ValidationIssue]:
    var issues: Array[ValidationIssue] = []
    var notes = chart_data.get_notes(chart_data.current_instrument, chart_data.current_difficulty)
    
    # Check for triple notes (physically impossible for 5-lane)
    var tick_groups = {}
    for note in notes:
        if not tick_groups.has(note.tick):
            tick_groups[note.tick] = []
        tick_groups[note.tick].append(note)
    
    for tick in tick_groups:
        var group = tick_groups[tick]
        if group.size() > 2:
            issues.append(ValidationIssue.new(
                IssueType.ERROR,
                "Triple chord detected (max 2 notes simultaneous)",
                tick,
                group
            ))
    
    return issues
```

---

## User Interface Design

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│ File  Edit  View  Tools  Playback  Help                  [?] [−] [□] [×] │
├─────────────────────────────────────────────────────────────────────┤
│ ◄◄  ◄  ▶  ▶▶  ⏸  ●  [━━━━━━━━━━━━━━━━━━━━━━] 1:23.45 / 3:45.67   │
├──────┬──────────────────────────────────────────────────────┬───────┤
│      │                                                      │ Meta  │
│ Tool │                  Note Highway                        │ data  │
│ bar  │              (Waveform + Lanes)                      │ ─────  │
│      │                                                      │ •Info │
│ ──── │                                                      │ •Diff │
│ Note │                                                      │ •Prop │
│ HOPO │                                                      │       │
│ Tap  │                                                      │ Song  │
│ ──── │                                                      │ Title │
│ Sel  │                                                      │ ────  │
│ BPM  │                                                      │       │
│ Evt  │                                                      │ Diff: │
│      │                                                      │ Expert│
│      │                                                      │       │
└──────┴──────────────────────────────────────────────────────┴───────┘
│ Time: 1:23.456  BPM: 120.0  Snap: 1/16  Notes: 842  [Modified]   │
└─────────────────────────────────────────────────────────────────────┘
```

### Top Menu Bar

#### File Menu
- New Chart
- Open Chart...
- Open Recent >
- Save
- Save As...
- Import from .chart...
- Export to .chart...
- Exit

#### Edit Menu
- Undo
- Redo
- Cut
- Copy
- Paste
- Delete
- Select All
- Select None
- Preferences...

#### View Menu
- Zoom In
- Zoom Out
- Reset Zoom
- Focus Selection
- Toggle Waveform
- Toggle Grid
- Toggle Metronome
- Toggle Event Markers

#### Tools Menu
- BPM Calculator
- Sync Track Editor
- Bulk Note Editor
- Chart Statistics
- Validate Chart

#### Playback Menu
- Play/Pause
- Stop
- Play from Start
- Set Loop Region
- Clear Loop
- Playback Speed >
  - 0.25x
  - 0.5x
  - 0.75x
  - 1.0x
  - 1.25x
  - 1.5x
  - 2.0x
- Test Play Chart

### Playback Controls Bar

```
┌────────────────────────────────────────────────────────┐
│  ◄◄  ◄  ▶  ▶▶  ⏸  ●                                │
│  [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]                 │
│  0:00.00                            3:45.67            │
│                                                        │
│  Speed: [1.0x ▼]  Loop: [Off]  Metronome: [Off]     │
└────────────────────────────────────────────────────────┘
```

- Skip to previous/next measure
- Frame back/forward
- Play/Pause
- Jump to start
- Loop toggle
- Playback speed selector
- Metronome toggle

### Edit Toolbar

```
┌──────────────────────────────────────────┐
│ [✓] Note  [ ] HOPO  [ ] Tap  [ ] Select  │
│                                          │
│ Snap: [1/16 ▼]  Grid: [On]              │
│                                          │
│ Lane Mode: [◉ Individual  ○ Chord]      │
└──────────────────────────────────────────┘
```

- Note type selection (radio buttons)
- Snap division dropdown
- Grid on/off toggle
- Individual/Chord placement mode

### Side Panel Tabs

#### Metadata Tab
```
Title:    [____________________]
Artist:   [____________________]
Album:    [____________________]
Year:     [____________________]
Charter:  [____________________]
Genre:    [____________________]

Audio File: [song.ogg] [Browse...]
```

#### Difficulty Tab
```
Instrument:
  ◉ Guitar
  ○ Bass
  ○ Drums

Difficulty:
  ◉ Expert
  ○ Hard
  ○ Medium
  ○ Easy

[Copy from Expert ▼]
```

#### Properties Tab
```
Selected: 3 notes

Type: [Regular ▼]
Position: Tick 768
          1:23.456

[Apply to Selection]

[Delete Selection]
```

### Status Bar

Shows real-time information:
- Current timestamp (MM:SS.mmm)
- Current BPM
- Current snap division
- Total note count
- Selection count (if any)
- Modified indicator
- Validation issues count

---

## Workflow & User Experience

### New Chart Workflow

1. **File → New Chart**
   - Dialog prompts for:
     - Audio file selection (required)
     - Title, Artist (required)
     - BPM (auto-detect offered)
     - Resolution (default 192)

2. **Initial Setup**
   - Audio loads and waveform generates
   - BPM sync verification
     - User plays metronome
     - User taps beat
     - System calculates BPM
     - Visual beats overlay waveform
     - User confirms or adjusts

3. **Begin Charting**
   - Select instrument and difficulty
   - Place notes using keyboard or mouse
   - Listen and iterate

### Chart Editing Workflow

**Step 1: Navigate to Section**
- Scrub timeline or use keyboard shortcuts
- Use waveform to identify sections visually
- Set loop region for repetitive sections

**Step 2: Place Notes**
- Listen to audio
- Press lane keys (1-5) at the correct timing
- Hold key for sustain notes
- Use modifiers (Shift/Ctrl) for HOPO/Tap

**Step 3: Refine Timing**
- Select notes
- Use mouse to drag notes vertically (time adjustment)
- Snap-to-grid ensures consistent timing

**Step 4: Test Play**
- Press hotkey to instantly test from current position
- Gameplay opens with chart
- Return to editor maintains position

**Step 5: Validate & Save**
- Run validation (automatic on save)
- Address errors and warnings
- Save chart

### Testing Workflow

**Instant Test Play:**
```
1. Position timeline at desired test start
2. Press F5 (or Test Play button)
3. Gameplay scene loads with chart
4. Play from selected position
5. Press Escape to return to editor
6. Timeline resumes at last test position
```

**Full Chart Test:**
```
1. File → Test Play Full Chart
2. Gameplay starts from beginning
3. Complete song or press Escape
4. Results screen shows score
5. Return to editor button
```

---

## Technical Implementation

### Scene Structure

```
chart_editor.tscn
├── ChartEditorController (Script: chart_editor.gd)
├── UI (CanvasLayer)
│   ├── TopMenuBar (MenuBar)
│   ├── PlaybackControlsBar (HBoxContainer)
│   ├── MainContent (HSplitContainer)
│   │   ├── EditToolbar (VBoxContainer)
│   │   ├── EditorViewport (Control)
│   │   │   ├── WaveformDisplay (Control)
│   │   │   ├── NoteHighway (Control)
│   │   │   ├── GridOverlay (Control)
│   │   │   └── PlaybackCursor (Control)
│   │   └── SidePanel (TabContainer)
│   │       ├── MetadataPanel (VBoxContainer)
│   │       ├── DifficultyPanel (VBoxContainer)
│   │       └── PropertiesPanel (VBoxContainer)
│   └── StatusBar (HBoxContainer)
├── AudioManager (Node)
│   └── AudioStreamPlayer
├── TimelineController (Node)
├── InputManager (Node)
├── HistoryManager (Node)
└── TestPlayHandler (Node)
```

### Key Scripts

#### chart_editor.gd (Main Controller)

```gdscript
extends Node

signal chart_modified()
signal test_play_requested(start_time: float)

@onready var audio_manager = $AudioManager
@onready var timeline = $TimelineController
@onready var history = $HistoryManager
@onready var ui = $UI

var chart_data: ChartDataModel
var file_path: String = ""
var is_modified: bool = false

func _ready():
    chart_data = ChartDataModel.new()
    _connect_signals()
    _setup_input()
    _setup_ui()

func _connect_signals():
    chart_data.connect("data_changed", _on_chart_data_changed)
    timeline.connect("playback_position_changed", _on_playback_position_changed)
    audio_manager.connect("playback_finished", _on_audio_finished)

func new_chart():
    # Show new chart dialog
    var dialog = preload("res://Scenes/Editor/NewChartDialog.tscn").instantiate()
    ui.add_child(dialog)
    dialog.popup_centered()
    dialog.connect("chart_created", _on_new_chart_created)

func _on_new_chart_created(setup_data: Dictionary):
    chart_data = ChartDataModel.new()
    chart_data.metadata = setup_data.metadata
    chart_data.sync_data = setup_data.sync
    
    audio_manager.load_audio(setup_data.audio_path)
    timeline.song_duration = audio_manager.get_stream_length()
    
    file_path = ""
    is_modified = false
    _update_title()

func save_chart():
    if file_path.is_empty():
        save_chart_as()
        return
    
    var error = chart_data.save_to_file(file_path)
    if error == OK:
        is_modified = false
        _update_title()
        _show_notification("Chart saved successfully")
    else:
        _show_error("Failed to save chart: " + error_string(error))

func save_chart_as():
    var dialog = FileDialog.new()
    dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    dialog.filters = ["*.rgchart ; Rhythm Game Chart"]
    ui.add_child(dialog)
    dialog.popup_centered()
    dialog.connect("file_selected", _on_save_file_selected)

func test_play():
    # Save current state
    var test_start = timeline.current_time
    
    # Switch to gameplay scene
    var gameplay = preload("res://Scenes/gameplay.tscn").instantiate()
    gameplay.chart_path = _export_temp_chart()
    gameplay.instrument = chart_data.current_instrument
    gameplay.test_mode = true
    gameplay.test_start_time = test_start
    gameplay.connect("test_complete", _on_test_play_complete)
    
    # Hide editor, show gameplay
    get_tree().root.add_child(gameplay)
    visible = false

func _on_test_play_complete(return_time: float):
    # Remove gameplay
    # Restore editor
    # Resume at return_time
    timeline.seek(return_time)
    visible = true
```

#### waveform_display.gd

```gdscript
extends Control

class_name WaveformDisplay

var waveform_texture: ImageTexture
var waveform_data: PackedFloat32Array
var zoom_level: float = 1.0
var scroll_offset: float = 0.0

signal waveform_generated()

func generate_waveform(audio_stream: AudioStream):
    if audio_stream == null:
        return
    
    # This is computationally expensive, so do it in a thread
    var thread = Thread.new()
    thread.start(_generate_waveform_thread.bind(audio_stream))

func _generate_waveform_thread(audio_stream: AudioStream):
    var data = audio_stream.get_data()
    var sample_rate = audio_stream.mix_rate
    var sample_count = data.size() / 2  # Assuming 16-bit audio
    
    # Downsample for visualization
    var samples_per_pixel = 1000
    var pixel_count = sample_count / samples_per_pixel
    
    waveform_data = PackedFloat32Array()
    waveform_data.resize(pixel_count)
    
    for i in range(pixel_count):
        var start_sample = i * samples_per_pixel
        var max_amplitude = 0.0
        
        for j in range(samples_per_pixel):
            var sample_idx = start_sample + j
            if sample_idx >= sample_count:
                break
            var amplitude = abs(data[sample_idx * 2] / 32768.0)
            max_amplitude = max(max_amplitude, amplitude)
        
        waveform_data[i] = max_amplitude
    
    call_deferred("_on_waveform_generated")

func _on_waveform_generated():
    _create_texture()
    emit_signal("waveform_generated")
    queue_redraw()

func _create_texture():
    var width = waveform_data.size()
    var height = 128
    
    var image = Image.create(width, height, false, Image.FORMAT_RGB8)
    
    for x in range(width):
        var amplitude = waveform_data[x]
        var bar_height = int(amplitude * height / 2.0)
        
        var color = _get_amplitude_color(amplitude)
        
        for y in range(height / 2 - bar_height, height / 2 + bar_height):
            image.set_pixel(x, y, color)
    
    waveform_texture = ImageTexture.create_from_image(image)

func _get_amplitude_color(amplitude: float) -> Color:
    if amplitude < 0.3:
        return Color(0.2, 0.4, 0.8)  # Blue (quiet)
    elif amplitude < 0.6:
        return Color(0.2, 0.8, 0.4)  # Green (medium)
    else:
        return Color(0.8, 0.2, 0.2)  # Red (loud)

func _draw():
    if waveform_texture:
        var rect = get_rect()
        draw_texture_rect(waveform_texture, rect, false)
```

#### note_highway_editor.gd

```gdscript
extends Control

class_name EditorNoteHighway

const LANE_COUNT = 5
const LANE_WIDTH = 40
const LANE_COLORS = [
    Color(0.0, 0.8, 0.0),  # Green
    Color(0.8, 0.0, 0.0),  # Red
    Color(0.8, 0.8, 0.0),  # Yellow
    Color(0.0, 0.4, 0.8),  # Blue
    Color(0.8, 0.4, 0.0)   # Orange
]

var chart_data: ChartDataModel
var timeline: EditorTimelineController
var pixels_per_second: float = 100.0
var scroll_position: float = 0.0
var selected_notes: Array = []
var hover_note = null

signal note_clicked(note: Dictionary)
signal note_placement_requested(lane: int, tick: int)
signal selection_changed(notes: Array)

func _ready():
    set_process_input(true)
    set_clip_contents(true)

func _draw():
    _draw_background()
    _draw_lanes()
    _draw_grid_lines()
    _draw_notes()
    _draw_selection_overlay()
    _draw_playback_line()

func _draw_lanes():
    var rect = get_rect()
    var total_width = LANE_COUNT * LANE_WIDTH
    var start_x = (rect.size.x - total_width) / 2.0
    
    for i in range(LANE_COUNT):
        var x = start_x + i * LANE_WIDTH
        var color = LANE_COLORS[i]
        color.a = 0.3
        draw_rect(Rect2(x, 0, LANE_WIDTH, rect.size.y), color)
        
        # Lane separator
        if i < LANE_COUNT - 1:
            draw_line(Vector2(x + LANE_WIDTH, 0), Vector2(x + LANE_WIDTH, rect.size.y), Color.WHITE, 1.0)

func _draw_grid_lines():
    if not timeline.snap_enabled:
        return
    
    var rect = get_rect()
    var resolution = chart_data.sync_data.resolution
    var snap_interval = resolution / timeline.snap_division
    
    # Draw lines for each snap position
    var visible_start_tick = time_to_tick(scroll_position - 2.0)
    var visible_end_tick = time_to_tick(scroll_position + 2.0)
    
    var start_snap = int(visible_start_tick / snap_interval) * snap_interval
    var end_snap = int(visible_end_tick / snap_interval) * snap_interval
    
    for tick in range(start_snap, end_snap + snap_interval, snap_interval):
        var time = tick_to_time(tick)
        var y = time_to_screen_y(time)
        
        if y < 0 or y > rect.size.y:
            continue
        
        var is_beat = (tick % resolution) == 0
        var color = Color.WHITE if is_beat else Color.GRAY
        color.a = 0.5 if is_beat else 0.2
        var width = 2.0 if is_beat else 1.0
        
        draw_line(Vector2(0, y), Vector2(rect.size.x, y), color, width)

func _draw_notes():
    var visible_start = scroll_position - 2.0
    var visible_end = scroll_position + 2.0
    
    var start_tick = time_to_tick(visible_start)
    var end_tick = time_to_tick(visible_end)
    
    var notes = chart_data.get_notes_in_range(start_tick, end_tick)
    
    for note in notes:
        _draw_note(note)

func _draw_note(note: Dictionary):
    var time = tick_to_time(note.tick)
    var y = time_to_screen_y(time)
    var x = get_lane_x(note.lane)
    
    var radius = 15.0
    var color = LANE_COLORS[note.lane]
    
    # Highlight if selected
    if note in selected_notes:
        draw_circle(Vector2(x, y), radius + 3, Color.YELLOW)
    
    # Highlight if hovered
    if note == hover_note:
        draw_circle(Vector2(x, y), radius + 2, Color.WHITE)
    
    # Draw note based on type
    match note.type:
        "regular":
            draw_circle(Vector2(x, y), radius, color)
        "hopo":
            draw_circle(Vector2(x, y), radius, color)
            draw_circle(Vector2(x, y), radius - 4, Color.WHITE)
        "tap":
            draw_rect(Rect2(x - radius, y - radius, radius * 2, radius * 2), color)
    
    # Draw sustain tail
    if note.length > 0:
        var end_time = tick_to_time(note.tick + note.length)
        var end_y = time_to_screen_y(end_time)
        draw_line(Vector2(x, y), Vector2(x, end_y), color, 8.0)

func _draw_playback_line():
    var y = time_to_screen_y(timeline.current_time)
    draw_line(Vector2(0, y), Vector2(get_rect().size.x, y), Color.RED, 3.0)

func _input(event):
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _handle_mouse_click(event.position)

func _handle_mouse_click(pos: Vector2):
    var lane = screen_x_to_lane(pos.x)
    if lane < 0 or lane >= LANE_COUNT:
        return
    
    var time = screen_y_to_time(pos.y)
    var tick = time_to_tick(time)
    
    if timeline.snap_enabled:
        tick = timeline.snap_tick(tick)
    
    # Check if clicking existing note
    var clicked_note = _find_note_at_position(lane, tick)
    if clicked_note:
        emit_signal("note_clicked", clicked_note)
    else:
        emit_signal("note_placement_requested", lane, tick)

func time_to_screen_y(time: float) -> float:
    var rect = get_rect()
    var relative_time = time - scroll_position
    return rect.size.y / 2.0 - relative_time * pixels_per_second

func screen_y_to_time(y: float) -> float:
    var rect = get_rect()
    var relative_y = (rect.size.y / 2.0 - y) / pixels_per_second
    return scroll_position + relative_y

func get_lane_x(lane: int) -> float:
    var rect = get_rect()
    var total_width = LANE_COUNT * LANE_WIDTH
    var start_x = (rect.size.x - total_width) / 2.0
    return start_x + lane * LANE_WIDTH + LANE_WIDTH / 2.0

func screen_x_to_lane(x: float) -> int:
    var rect = get_rect()
    var total_width = LANE_COUNT * LANE_WIDTH
    var start_x = (rect.size.x - total_width) / 2.0
    var relative_x = x - start_x
    if relative_x < 0 or relative_x > total_width:
        return -1
    return int(relative_x / LANE_WIDTH)
```

### Integration with Existing Systems

#### Chart Loading Service Integration

The editor will use the existing `ChartLoadingService` to load `.chart` files:

```gdscript
func import_chart_file(path: String):
    var loading_service = ChartLoadingService.new()
    var chart_data_imported = loading_service.load_chart_data_sync(path, "Single")
    
    if chart_data_imported:
        # Convert to .rgchart format
        chart_data = _convert_chart_data(chart_data_imported)
        _update_ui()
```

#### Timeline Controller Integration

The editor's `EditorTimelineController` will share similar concepts with the gameplay `TimelineController` but simplified for editing (no command pattern needed).

#### Test Play Integration

```gdscript
func test_play():
    # Export current chart to temp file
    var temp_path = "user://temp_test_chart.rgchart"
    chart_data.save_to_file(temp_path)
    
    # Store editor state
    var editor_state = {
        "scroll_position": scroll_position,
        "playback_time": timeline.current_time,
        "selected_notes": selected_notes.duplicate()
    }
    
    # Switch scenes
    var gameplay = preload("res://Scenes/gameplay.tscn").instantiate()
    gameplay.chart_path = temp_path
    gameplay.instrument = chart_data.current_instrument
    gameplay.preloaded_data = {}  # Will load from file
    
    # Signal to return to editor
    gameplay.connect("tree_exited", func():
        # Restore editor state
        scroll_position = editor_state.scroll_position
        timeline.current_time = editor_state.playback_time
        selected_notes = editor_state.selected_notes
        _update_viewport()
    )
    
    SceneSwitcher.push_scene_instance(gameplay)
```

---

## Testing & Quality Assurance

### Testing Approach

#### Unit Tests

Test individual components in isolation:

```gdscript
# test/test_chart_data_model.gd
extends GdUnitTestSuite

func test_add_note():
    var model = ChartDataModel.new()
    model.current_instrument = "guitar"
    model.current_difficulty = "expert"
    
    var note = {"tick": 768, "lane": 2, "type": "regular", "length": 0}
    model.add_note(note)
    
    var notes = model.get_notes("guitar", "expert")
    assert_that(notes.size()).is_equal(1)
    assert_that(notes[0].tick).is_equal(768)

func test_notes_sorted_after_addition():
    var model = ChartDataModel.new()
    model.current_instrument = "guitar"
    model.current_difficulty = "expert"
    
    model.add_note({"tick": 960, "lane": 1, "type": "regular", "length": 0})
    model.add_note({"tick": 768, "lane": 2, "type": "regular", "length": 0})
    
    var notes = model.get_notes("guitar", "expert")
    assert_that(notes[0].tick).is_equal(768)
    assert_that(notes[1].tick).is_equal(960)
```

#### Integration Tests

Test component interactions:

```gdscript
# test/test_editor_integration.gd
extends GdUnitTestSuite

func test_note_placement_workflow():
    var editor = load("res://Scenes/chart_editor.tscn").instantiate()
    add_child(editor)
    
    # Simulate user input
    editor.new_chart()
    editor.chart_data.current_instrument = "guitar"
    editor.chart_data.current_difficulty = "expert"
    
    # Place note via highway click
    var highway = editor.get_node("UI/MainContent/EditorViewport/NoteHighway")
    highway.emit_signal("note_placement_requested", 2, 768)
    
    # Verify note was added
    var notes = editor.chart_data.get_notes("guitar", "expert")
    assert_that(notes.size()).is_equal(1)
```

#### Playtesting

Manual testing by actual users:

**Test Scenarios:**
1. Create new chart from audio file
2. Place 100 notes using keyboard shortcuts
3. Test play from middle of chart
4. Save, close, reload chart
5. Export to .chart format, import in Clone Hero, verify playability

**Metrics to Track:**
- Time to create first playable chart
- Number of errors/crashes per session
- User satisfaction rating
- Chart quality (validated by community)

### Quality Assurance Checklist

**Before Release:**
- [ ] All unit tests passing
- [ ] No memory leaks (tested with 30-minute sessions)
- [ ] Audio sync accurate within 5ms
- [ ] Waveform generation completes <3 seconds for typical song
- [ ] UI responsive at 60fps with 2000+ notes
- [ ] Undo/redo functional for all operations
- [ ] Auto-save recovers after crash
- [ ] Charts play identically in editor and gameplay
- [ ] Validation catches all common errors
- [ ] Export/import lossless for standard features
- [ ] Keyboard shortcuts work consistently
- [ ] Mouse operations precise and predictable

---

## Future Enhancements

### Phase 2 Features

1. **Advanced BPM Tools**
   - Visual BPM tapping
   - Automatic BPM detection
   - Variable BPM support (tempo changes)
   - Time signature changes

2. **Collaboration Features**
   - Cloud save/sync (via third-party service)
   - Chart sharing platform
   - Collaborative editing (real-time?)
   - Version history

3. **AI-Assisted Charting**
   - Auto-generate basic chart from audio
   - Suggest note placements
   - Pattern detection and repetition
   - Difficulty auto-balancing

4. **Additional Instruments**
   - Drums (5-lane + kick)
   - Keys (5-lane)
   - Vocals (pitch-based)
   - Pro Guitar (17-fret)

5. **Advanced Editing**
   - Bulk operations (shift all notes, scale timing)
   - Pattern library (save/reuse common patterns)
   - Macro recording (repeat action sequences)
   - Scripting API (automate tasks)

### Phase 3 Features

1. **Professional Tools**
   - Multi-track audio mixing
   - Audio stem separation
   - Crowd noise generation
   - Practice mode sections

2. **Analytics**
   - Heatmap of note density
   - Difficulty rating calculation
   - Playability simulation
   - Statistical analysis

3. **Community Integration**
   - Rating/review system
   - Leaderboards for charts
   - Featured chart rotation
   - Moderation tools

---

## Implementation Roadmap

### Milestone 1: Core Editor (4-6 weeks)

**Goals:**
- Basic UI and layout
- Audio playback
- Simple note placement
- Save/load .rgchart format

**Deliverables:**
- Functional chart editor scene
- ChartDataModel implementation
- File I/O working
- Manual testing shows proof of concept

### Milestone 2: Editing Features (3-4 weeks)

**Goals:**
- Waveform display
- Snap-to-grid
- Keyboard shortcuts
- Undo/redo

**Deliverables:**
- Waveform generation working
- Full keyboard workflow
- History manager functional
- Can create real chart in <1 hour

### Milestone 3: Testing Integration (2-3 weeks)

**Goals:**
- Test play from editor
- Chart validation
- Import/export .chart

**Deliverables:**
- Seamless gameplay testing
- Validation catches errors
- Compatible with Clone Hero
- Community beta testing begins

### Milestone 4: Polish & Release (2-3 weeks)

**Goals:**
- UI refinement
- Bug fixes
- Documentation
- Tutorial

**Deliverables:**
- Stable release
- User manual
- Video tutorial
- Community feedback incorporated

**Total Timeline: 11-16 weeks**

### Dependency Graph

```
Week 1-2:  Core UI Layout + Audio System
Week 3-4:  Chart Data Model + File I/O
Week 5-6:  Note Highway + Basic Placement
Week 7-8:  Waveform Display + Advanced Input
Week 9-10: Undo/Redo + Keyboard Shortcuts
Week 11:   Test Play Integration
Week 12:   Validation Engine
Week 13:   Import/Export .chart
Week 14-15: Bug Fixes + Polish
Week 16:   Release
```

---

## Conclusion

This design document provides a comprehensive blueprint for implementing a professional-quality chart editor for the rhythm game. The design emphasizes:

- **User-Centric**: Every feature designed around charting workflow
- **Technical Excellence**: Leveraging Godot's strengths (signals, scenes, nodes)
- **Community Compatible**: Interoperability with existing formats
- **Extensible**: Architecture supports future enhancements
- **Realistic**: Phased implementation over 3-4 months

The proposed `.rgchart` format provides a modern, extensible alternative to `.chart` while maintaining compatibility through import/export. The editor architecture follows established patterns (MVC, Command, Observer) for maintainability and testability.

By implementing this design, players will have the tools to create, share, and play custom content, dramatically extending the game's longevity and community engagement.

---

**Document Revision History:**
- v1.0 (2025-11-01): Initial design document

**Next Steps:**
1. Review and approve design
2. Create GitHub issues for milestones
3. Set up project structure
4. Begin Milestone 1 implementation

**Questions for Discussion:**
1. Should we support real-time collaborative editing in Phase 2 or 3?
2. What priority for AI-assisted charting features?
3. Should we build chart sharing platform or integrate with existing services?
4. Target platforms: Desktop only, or include web editor?
