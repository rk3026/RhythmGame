# Chart Editor Input & Note Creation Refactoring

## Overview
This refactoring separates concerns for keyboard input handling and note creation in the chart editor, fixing the broken hold note functionality during playback.

## Problem Analysis
The original implementation had several issues:
1. **Input handling used `_unhandled_key_input`** which doesn't properly capture key release events
2. **Hold note logic was embedded in the main chart_editor.gd** making it hard to maintain
3. **Key release detection was broken** - attempting to check `event.pressed == false` in a key press handler
4. **State management was scattered** across multiple methods

## New Architecture

### 1. EditorInputManager (Scripts/Editor/Services/editor_input_manager.gd)
**Responsibility:** Handle all keyboard input for the chart editor

**Key Features:**
- Uses `_input()` to capture ALL keyboard events including key releases
- Properly tracks which lane keys are currently held down using `_keys_held` dictionary
- Emits signals for all editor actions instead of directly calling methods
- Handles both key press and key release events correctly
- Automatically clears held keys when playback stops or sustain mode is disabled

**Signals Emitted:**
- `note_placement_requested(lane, is_hold_start)` - For placing notes or starting hold notes
- `note_hold_released(lane)` - When a hold note key is released
- `tool_change_requested(tool_name)` - Tool selection shortcuts (Q/W/E/R)
- `note_type_change_requested(note_type)` - Note type shortcuts (Shift+1-4)
- `timeline_navigation_requested(direction, modifier)` - Arrow key navigation
- `playback_toggle_requested()` - Spacebar
- `snap_division_change_requested(increase)` - Bracket keys
- `save_requested()` - Ctrl+S
- `undo_requested()` / `redo_requested()` - Ctrl+Z / Ctrl+Y
- `delete_requested()` - Delete key

### 2. EditorNoteCreationService (Scripts/Editor/Services/editor_note_creation_service.gd)
**Responsibility:** Handle all note creation logic including hold notes

**Key Features:**
- Manages hold note state with `_active_hold_notes` dictionary
- Provides clean API for starting and finishing hold notes
- Calculates sustain lengths based on playback time
- Validates note placement (checks for duplicates, lane bounds)
- Emits `note_created` signal when a note is ready to be added

**Key Methods:**
- `place_note_at_time(lane, time)` - Place a regular note
- `start_hold_note(lane)` - Begin tracking a hold note
- `finish_hold_note(lane)` - Complete a hold note and create it
- `cancel_all_hold_notes()` - Finalize all active holds (called when playback stops)

### 3. ChartEditor (Scripts/Editor/chart_editor.gd)
**Responsibility:** Coordinate between services and manage editor state

**Changes:**
- Removed all keyboard input handling code (delegated to EditorInputManager)
- Removed hold note tracking arrays (delegated to EditorNoteCreationService)
- Added signal handlers to connect services together
- Simplified note placement logic

**New Signal Handlers:**
- `_on_input_note_placement_requested()` - Routes to note creation service
- `_on_input_note_hold_released()` - Routes to note creation service
- `_on_note_created_by_service()` - Executes add note command
- `_on_input_timeline_navigation()` - Routes to appropriate navigation method
- `_on_playback_state_changed()` - Handles playback stop to finalize hold notes

## How Hold Notes Now Work

### During Playback with Sustain Mode:

1. **User presses lane key (e.g., "1")**
   - EditorInputManager detects key press in `_input()`
   - Marks lane as held in `_keys_held[0] = true`
   - Emits `note_placement_requested(0, true)` ← `true` means hold start
   - ChartEditor routes to EditorNoteCreationService.start_hold_note()
   - Service stores start time and tick in `_active_hold_notes[0]`

2. **User releases lane key**
   - EditorInputManager detects key release in `_input()`
   - Marks lane as released `_keys_held[0] = false`
   - Emits `note_hold_released(0)`
   - ChartEditor routes to EditorNoteCreationService.finish_hold_note()
   - Service calculates sustain length from start time to current time
   - Service emits `note_created` signal with complete note data
   - ChartEditor executes AddNoteCommand via command stack

3. **Playback stops**
   - EditorPlaybackController emits `playback_state_changed(false)`
   - ChartEditor's `_on_playback_state_changed()` is called
   - Calls EditorNoteCreationService.cancel_all_hold_notes()
   - Any held notes are automatically finalized

### Regular Note Placement (Not During Sustain Mode):

1. **User presses lane key**
   - EditorInputManager emits `note_placement_requested(lane, false)` ← `false` means regular note
   - ChartEditor determines time (playback time or cursor time)
   - Routes to EditorNoteCreationService.place_note_at_time()
   - Service validates and emits `note_created`
   - ChartEditor executes AddNoteCommand

## Benefits of New Architecture

1. **Separation of Concerns**
   - Input handling is isolated in EditorInputManager
   - Note creation logic is isolated in EditorNoteCreationService
   - ChartEditor just coordinates between them

2. **Testability**
   - Each service can be tested independently
   - Mock services can be injected for testing

3. **Maintainability**
   - Changes to input handling don't affect note creation
   - Changes to note creation don't affect input handling
   - Clear responsibilities for each component

4. **Correctness**
   - Proper key release detection using `_input()`
   - State is properly managed in dedicated dictionaries
   - Automatic cleanup when playback stops

5. **Extensibility**
   - Easy to add new input shortcuts (just emit new signals)
   - Easy to add new note types or creation modes
   - Service pattern allows for easy replacement or mocking

## Testing Checklist

- [ ] Place regular notes with number keys while paused (should snap to grid)
- [ ] Place regular notes with number keys during playback (should place at playback time)
- [ ] Enable sustain mode and hold number keys during playback (should create hold notes)
- [ ] Release keys quickly (< 100ms) - should create regular notes, not hold notes
- [ ] Release keys after holding - should create hold notes with correct sustain length
- [ ] Stop playback while holding keys - should automatically finalize all hold notes
- [ ] Disable sustain mode while holding keys - should clear held state
- [ ] Use keyboard shortcuts (Q/W/E/R, arrows, space, etc.) - should still work

## Files Modified

1. **Created:**
   - `Scripts/Editor/Services/editor_input_manager.gd`
   - `Scripts/Editor/Services/editor_note_creation_service.gd`

2. **Modified:**
   - `Scripts/Editor/chart_editor.gd`

## Migration Notes

- All keyboard input handling code was removed from chart_editor.gd
- Old methods removed: `_unhandled_key_input()`, `_handle_keyboard_shortcut()`, `_on_hold_key_pressed()`, `_on_hold_key_released()`, `_finalize_all_hold_notes()`, `_place_note_at_time()`, `_place_note_at_cursor_time()`
- Old state removed: `_hold_notes` array
- Services must be properly configured in `_ready()` for the system to work
- Existing UI components (miniaudio, waveform, BPM detection) are unchanged
