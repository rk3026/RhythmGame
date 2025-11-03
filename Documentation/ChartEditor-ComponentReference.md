# Chart Editor Component Quick Reference

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     ChartEditor (Main)                      │
│  - Coordinates all components                               │
│  - Manages ChartDataModel                                   │
│  - Handles keyboard shortcuts                               │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ EditorMenuBar│  │ EditorToolbar│  │EditorSidePanel│
│              │  │              │  │              │
│ File/Edit/   │  │ Tools, Snap  │  │ Metadata,    │
│ View/Playback│  │ Grid Toggle  │  │ Difficulty   │
└──────────────┘  └──────────────┘  └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                  ┌──────────────┐
                  │ChartDataModel│
                  │              │
                  │ Notes, BPM,  │
                  │ Metadata     │
                  └──────────────┘
```

## Component Communication

### EditorMenuBar → Main Editor
```gdscript
# Signals emitted:
new_chart_requested()
open_chart_requested()
save_requested()
save_as_requested()
undo_requested()
redo_requested()
cut_requested()
copy_requested()
paste_requested()
delete_requested()
zoom_in_requested()
zoom_out_requested()
toggle_grid_requested()
play_pause_requested()
stop_requested()
test_play_requested()

# Public methods:
set_undo_enabled(enabled: bool)
set_redo_enabled(enabled: bool)
set_grid_checked(checked: bool)
```

### EditorPlaybackControls → Main Editor
```gdscript
# Signals emitted:
play_requested()
pause_requested()
stop_requested()
seek_requested(position: float)
speed_changed(speed: float)
skip_to_start_requested()
skip_to_end_requested()

# Public methods:
set_playing(playing: bool)
set_duration(duration: float)
update_position(time_position: float)
get_selected_speed() -> float
set_speed(speed: float)
```

### EditorToolbar → Main Editor
```gdscript
# Tool types enum:
enum ToolType { NOTE, HOPO, TAP, SELECT, BPM, EVENT }

# Signals emitted:
tool_selected(tool_type: ToolType)
snap_changed(snap_division: int)
grid_toggled(enabled: bool)

# Public methods:
get_current_tool() -> ToolType
get_current_snap() -> int
get_snap_color(snap_division: int) -> Color
is_grid_enabled() -> bool
set_snap_division(division: int)
increase_snap()
decrease_snap()

# Available snap divisions:
[4, 8, 12, 16, 24, 32, 48, 64, 192]
```

### EditorSidePanel → Main Editor
```gdscript
# Signals emitted:
metadata_changed(metadata: Dictionary)
difficulty_changed(instrument: String, difficulty: String, enabled: bool)
property_changed(property_name: String, value: Variant)

# Public methods:
set_metadata(metadata: Dictionary)
get_metadata() -> Dictionary
set_difficulty_enabled(instrument: String, difficulty: String, enabled: bool)
update_selection_info(count: int, note_types: Array)
```

### EditorStatusBar (Display Only)
```gdscript
# Public methods:
update_time(time: float)
update_bpm(bpm: float)
update_snap(snap_division: int)
update_note_count(count: int)
set_modified(is_modified: bool)
update_selection(selection_count: int)
```

## ChartDataModel API

### Creating Charts
```gdscript
var chart_data = ChartDataModel.new()

# Create charts for different instruments/difficulties
chart_data.create_chart("guitar", "expert")
chart_data.create_chart("bass", "hard")

# Check if chart exists
if chart_data.has_chart("guitar", "expert"):
    print("Chart exists!")
```

### Managing Notes
```gdscript
# Add a note (returns note ID)
var note_id = chart_data.add_note("guitar", "expert", lane=2, tick=768, note_type=0)

# Modify a note
chart_data.modify_note("guitar", "expert", note_id, new_tick=800, new_lane=3)

# Remove a note
chart_data.remove_note("guitar", "expert", note_id)

# Get note count
var count = chart_data.get_note_count("guitar", "expert")
```

### BPM Management
```gdscript
# Add BPM change
chart_data.add_bpm_change(tick=0, bpm=120.0)
chart_data.add_bpm_change(tick=1920, bpm=140.0)

# Get BPM at specific tick
var bpm = chart_data.get_bpm_at_tick(1000)
```

### Time/Tick Conversion
```gdscript
# Convert tick to time (seconds)
var time = chart_data.tick_to_time(768)  # Returns time in seconds

# Convert time to tick
var tick = chart_data.time_to_tick(2.5)  # Returns tick position

# Resolution: 192 ticks per beat (standard)
var ticks_per_beat = chart_data.resolution
```

### Metadata
```gdscript
# Set individual metadata fields
chart_data.set_metadata("title", "My Song")
chart_data.set_metadata("artist", "Artist Name")
chart_data.set_metadata("bpm", 120.0)

# Get metadata
var title = chart_data.get_metadata("title")
var all_metadata = chart_data.get_all_metadata()
```

### Signals
```gdscript
# Connect to data changes
chart_data.data_changed.connect(_on_chart_modified)
chart_data.note_added.connect(_on_note_added)
chart_data.note_removed.connect(_on_note_removed)
chart_data.bpm_changed.connect(_on_bpm_changed)
```

## Keyboard Shortcuts (Implemented)

- **Space**: Play/Pause audio
- **[**: Decrease snap division
- **]**: Increase snap division

## Keyboard Shortcuts (Planned)

- **1-5**: Place note in lanes 1-5
- **N**: Select Note tool
- **H**: Select HOPO tool
- **T**: Select Tap tool
- **S**: Select Select tool
- **B**: Select BPM tool
- **E**: Select Event tool
- **Ctrl+Z**: Undo
- **Ctrl+Y**: Redo
- **Ctrl+S**: Save
- **Ctrl+N**: New chart
- **Ctrl+O**: Open chart
- **Delete**: Delete selected notes

## Color Coding (Moonscraper Style)

### Lane Colors
- Lane 1: Green
- Lane 2: Red
- Lane 3: Yellow
- Lane 4: Blue
- Lane 5: Orange

### Snap Division Colors
- 1/4 (4): Red - Quarter notes
- 1/8 (8): Blue - Eighth notes
- 1/12 (12): Magenta - Triplets
- 1/16 (16): Yellow - Sixteenth notes
- 1/24 (24): Cyan
- 1/32 (32): Orange
- 1/48 (48): Light green
- 1/64 (64): Light gray
- 1/192 (192): Gray

## File Structure

```
Scripts/Editor/
├── ChartDataModel.gd          # Central data management
├── EditorMenuBar.gd           # Menu actions
├── EditorPlaybackControls.gd  # Audio playback control
├── EditorToolbar.gd           # Tool & snap selection
├── EditorSidePanel.gd         # Metadata & properties
└── EditorStatusBar.gd         # Status display

Scenes/Components/
├── EditorMenuBar.tscn
├── EditorPlaybackControls.tscn
├── EditorToolbar.tscn
├── EditorSidePanel.tscn
└── EditorStatusBar.tscn

Scenes/
└── chart_editor.tscn          # Main editor scene
```

## Testing the Editor

1. Open `chart_editor.tscn` in Godot
2. Press F6 to run the scene
3. Test component interactions:
   - Click menu items (signals will print to console)
   - Use playback controls (no audio loaded yet)
   - Select different tools
   - Change snap division
   - Edit metadata in side panel
4. Check status bar updates

## Next Implementation Steps

1. **2D Canvas Note Highway**: Add vertical scrolling canvas overlay for charting
2. **Note Placement**: Implement keyboard/mouse input for placing notes
3. **Audio Loading**: Connect audio file browser to AudioStreamPlayer
4. **File I/O**: Implement save/load for .rgchart format
5. **Undo/Redo**: Implement command pattern history system
6. **Test Play**: Connect to gameplay scene for testing charts

## Common Patterns

### Adding a New Tool
```gdscript
# 1. Add to EditorToolbar.gd ToolType enum
enum ToolType { NOTE, HOPO, TAP, SELECT, BPM, EVENT, NEW_TOOL }

# 2. Add button in EditorToolbar.tscn

# 3. Connect signal in _connect_signals()
new_tool_button.pressed.connect(_on_new_tool_pressed)

# 4. Handle in main editor
toolbar.tool_selected.connect(_on_tool_selected)

func _on_tool_selected(tool_type):
    match tool_type:
        EditorToolbar.ToolType.NEW_TOOL:
            # Handle new tool
            pass
```

### Adding a New Menu Item
```gdscript
# 1. Add to EditorMenuBar.gd enum
enum FileMenuItems { NEW_CHART, OPEN_CHART, SAVE, NEW_ITEM }

# 2. Add item in EditorMenuBar.tscn PopupMenu

# 3. Add signal
signal new_item_requested()

# 4. Handle in _on_file_menu_id_pressed()
FileMenuItems.NEW_ITEM:
    new_item_requested.emit()

# 5. Connect in main editor
menu_bar.new_item_requested.connect(_on_new_item)
```

### Updating Status Bar
```gdscript
# From main editor:
status_bar.update_time(current_time)
status_bar.update_bpm(current_bpm)
status_bar.update_snap(snap_division)
status_bar.update_note_count(note_count)
status_bar.set_modified(true)
```

## Tips

- **Component Independence**: Each component should work without knowing about others
- **Signal-Based Communication**: Always use signals for component→main communication
- **Data Centralization**: All chart data goes through ChartDataModel
- **Keyboard First**: Design UI for keyboard-driven workflow (like Moonscraper)
- **Reuse Existing Code**: The runway already uses `board_renderer.gd` from gameplay
