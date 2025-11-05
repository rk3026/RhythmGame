# Chart Editor - Skip to Beginning/End Implementation

## Overview
Added functionality for the "Skip to Beginning" (|◀) and "Skip to End" (▶|) buttons in the EditorPlaybackControls component.

## Implementation Details

### Signal Connections
**Location:** `Scripts/chart_editor.gd` - `_connect_component_signals()`

Connected two new signals from EditorPlaybackControls:
```gdscript
playback_controls.skip_to_start_requested.connect(_on_skip_to_start_requested)
playback_controls.skip_to_end_requested.connect(_on_skip_to_end_requested)
```

### Handler Functions

#### `_on_skip_to_start_requested()`
Skips playback to the beginning (0:00):
- Sets `current_time` to 0.0
- Updates timeline controller to position 0
- If playing, restarts audio from beginning
- Updates UI to show 0:00
- Scrolls note canvas to tick 0

#### `_on_skip_to_end_requested()`
Skips playback to the end of the audio:
- Retrieves audio stream length
- Sets `current_time` to end time
- Updates timeline controller to end position
- If playing, seeks audio to end (will likely stop)
- Updates UI to show end time
- Scrolls note canvas to the last tick

## UI Components
**Location:** `Scenes/Components/EditorPlaybackControls.tscn`

### Skip to Start Button
- Node: `SkipStartButton`
- Text: "|◀"
- Tooltip: "Skip to Start"
- Position: First button in playback controls

### Skip to End Button
- Node: `SkipEndButton`
- Text: "▶|"
- Tooltip: "Skip to End"
- Position: After Stop button, before timeline

## Usage
1. **Skip to Beginning:** Click the |◀ button
   - Instantly jumps to 0:00
   - Works whether playing or paused
   - Canvas scrolls to show beginning of chart

2. **Skip to End:** Click the ▶| button
   - Instantly jumps to end of audio
   - Works whether playing or paused
   - Canvas scrolls to show end of chart

## Testing Checklist
- [x] Skip to start button exists and is clickable
- [x] Skip to end button exists and is clickable
- [x] Signals properly connected in chart_editor.gd
- [x] Handler functions implemented
- [x] No compilation errors

### Manual Testing Steps
1. Load the chart editor scene (F6)
2. Load an audio file
3. Click Play to start playback
4. Click Skip to End (▶|) - should jump to end time
5. Click Skip to Beginning (|◀) - should return to 0:00
6. Verify timeline slider updates correctly
7. Verify time label shows correct times
8. Verify note canvas scrolls to correct positions
9. Test while paused - should still work
10. Test with no audio loaded - should handle gracefully

## Integration
These skip buttons work seamlessly with the existing playback system:
- **Timeline Controller:** Properly updates via `scrub_to()`
- **Audio Player:** Seeks to correct position if playing
- **Note Canvas:** Scrolls to show the target position
- **Playback Controls UI:** Updates time labels and slider position

## Future Enhancements
- Add keyboard shortcuts (e.g., Home for start, End for end)
- Add "Skip to Selected Note" functionality
- Implement skip forward/backward by time intervals (±5s, ±30s)
- Add "Skip to Next/Previous Measure" buttons
