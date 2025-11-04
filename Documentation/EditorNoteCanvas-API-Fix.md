# EditorNoteCanvas API Fix

## Problem
The `EditorNoteCanvas` was using incorrect API calls and property access for the `ChartDataModel` and `ChartDifficulty` classes, causing runtime errors.

## Errors Fixed

### 1. **Nonexistent `get_all_notes()` method**
**Error:** `Invalid call. Nonexistent function 'get_all_notes' in base 'RefCounted (ChartDifficulty)'`

**Root Cause:** `ChartDifficulty` doesn't have a `get_all_notes()` method. Instead, it has a public `notes` array.

**Fix in `_rebuild_visual_notes()`:**
```gdscript
# BEFORE (incorrect)
var notes = chart.get_all_notes()
for note in notes:
    visual_notes[note.id] = {
        "tick": note.tick,
        "lane": note.lane,
        "note_type": note.note_type,
        "length": note.length
    }

# AFTER (correct)
for note in chart.notes:
    visual_notes[note["id"]] = {
        "tick": note["tick"],
        "lane": note["lane"],
        "note_type": note["type"],
        "length": note["length"]
    }
```

### 2. **Incorrect Signal Parameters**
**Root Cause:** Signal handlers expected wrong parameters based on incorrect signal definitions.

**Actual ChartDataModel signals:**
- `signal note_added(note: Dictionary)` - Emits the entire note dictionary
- `signal note_removed(note_id: int)` - Emits only the note ID
- `signal note_modified(note_id: int)` - Emits only the note ID
- `signal bpm_changed(tick: int, bpm: float)` - Emits tick and BPM value

**Fixes:**

#### `_on_note_added()`:
```gdscript
# BEFORE (incorrect)
func _on_note_added(instrument: String, difficulty: String, note_id: int) -> void:
    if instrument != current_instrument or difficulty != current_difficulty:
        return
    var note = chart_data.get_note(instrument, difficulty, note_id)
    # ...

# AFTER (correct)
func _on_note_added(note: Dictionary) -> void:
    # Note already contains all data: id, tick, lane, type, length
    visual_notes[note["id"]] = {
        "tick": note["tick"],
        "lane": note["lane"],
        "note_type": note["type"],
        "length": note["length"]
    }
    queue_redraw()
```

#### `_on_note_removed()`:
```gdscript
# BEFORE (incorrect)
func _on_note_removed(instrument: String, difficulty: String, note_id: int) -> void:
    if instrument != current_instrument or difficulty != current_difficulty:
        return
    visual_notes.erase(note_id)
    queue_redraw()

# AFTER (correct)
func _on_note_removed(note_id: int) -> void:
    visual_notes.erase(note_id)
    # Also remove from selection if selected
    if note_id in selected_notes:
        selected_notes.erase(note_id)
    queue_redraw()
```

#### `_on_note_modified()`:
```gdscript
# BEFORE (incorrect)
func _on_note_modified(instrument: String, difficulty: String, note_id: int) -> void:
    if instrument != current_instrument or difficulty != current_difficulty:
        return
    var note = chart_data.get_note(instrument, difficulty, note_id)
    if note:
        visual_notes[note_id] = {
            "tick": note.tick,
            "lane": note.lane,
            # ...

# AFTER (correct)
func _on_note_modified(note_id: int) -> void:
    var chart = chart_data.get_chart(current_instrument, current_difficulty)
    if not chart:
        return
    var note = chart.get_note(note_id)
    if not note.is_empty():
        visual_notes[note_id] = {
            "tick": note["tick"],
            "lane": note["lane"],
            "note_type": note["type"],
            "length": note["length"]
        }
        queue_redraw()
```

#### `_on_bpm_changed()`:
```gdscript
# BEFORE (incorrect)
func _on_bpm_changed() -> void:

# AFTER (correct)
func _on_bpm_changed(_tick: int, _bpm: float) -> void:
```

### 3. **Dictionary Access vs Object Properties**
**Root Cause:** Notes are stored as `Dictionary` objects, not custom classes with properties.

**Property Access Pattern:**
- ❌ `note.tick` (object property access)
- ✅ `note["tick"]` (dictionary key access)

**Note Dictionary Structure:**
```gdscript
{
    "id": int,
    "tick": int,
    "lane": int,
    "type": int,    # 0 = normal, 1 = HOPO, 2 = tap
    "length": int   # 0 for regular notes, > 0 for sustains
}
```

## Summary of Changes
1. Changed `chart.get_all_notes()` → `chart.notes` (direct array access)
2. Fixed all signal handler parameters to match actual signal definitions
3. Changed all note property access from `.property` to `["property"]` syntax
4. Added proper cleanup in `_on_note_removed()` to remove from selection
5. Added parameter names to `_on_bpm_changed()` to match signal definition

## Result
✅ All API calls now match the actual ChartDataModel and ChartDifficulty implementation  
✅ Signal handlers correctly receive and process emitted data  
✅ Notes are properly accessed as Dictionary objects  
✅ No more runtime errors related to nonexistent methods or properties
