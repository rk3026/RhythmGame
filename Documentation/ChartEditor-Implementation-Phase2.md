# Chart Editor Implementation - Phase 2: Note Selection & Manipulation

## Summary
Completed implementation of comprehensive note selection and manipulation features, including single/multi-select, drag-to-move, and keyboard-based operations. The editor now supports intuitive mouse and keyboard workflows for editing charts.

## New Features Implemented

### 1. Note Selection System

**Selection Methods**:
- **Single Click**: Click note to select (clears previous selection)
- **Ctrl+Click**: Toggle individual note selection (multi-select)
- **Shift+Click**: Start selection box drag
- **Selection Box**: Drag rectangle to select multiple notes
- **Ctrl+A**: Select all notes in current chart
- **Escape**: Clear all selections

**Visual Feedback**:
- Selected notes are brightened (lightened by 0.3)
- Yellow outline (3px thick) for selected notes vs white outline (2px) for unselected
- Selection box drawn with semi-transparent blue fill and blue outline
- Sustain tails also highlighted in yellow when selected

### 2. Note Dragging & Movement

**Drag Behavior**:
- Click and drag selected notes to new positions
- Automatically snaps to grid during drag
- Maintains relative positions of multiple selected notes
- Visual feedback during drag (notes follow mouse in real-time)
- Lane constrained to 0-4 (won't drag outside highway)
- Tick constrained to >= 0 (can't drag before song start)

**Movement Commands**:
- Each moved note creates a `MoveNoteCommand` for undo/redo support
- Original positions stored and restored on undo
- Multiple notes can be moved simultaneously
- Movement is committed when mouse button released

**Technical Implementation**:
- `_start_note_drag()`: Captures original positions of all selected notes
- `_update_note_drag()`: Updates visual positions in real-time during drag
- `_end_note_drag()`: Creates MoveNoteCommands and restores visual positions
- Temporary visual updates don't modify ChartDataModel until drag completes

### 3. Keyboard Shortcuts

**Selection Operations**:
- **Delete**: Delete all selected notes (creates RemoveNoteCommand for each)
- **Ctrl+A**: Select all notes
- **Escape**: Clear selection

**Existing Shortcuts** (still work):
- **Ctrl+Z**: Undo
- **Ctrl+Y** or **Ctrl+Shift+Z**: Redo
- **Space**: Play/pause
- **[ ]**: Adjust snap division
- **1-5**: Quick place note at playback position

### 4. Enhanced EditorNoteCanvas

**New State Variables**:
```gdscript
var selected_notes: Array[int] = []           # Currently selected note IDs
var is_dragging_selection: bool = false      # Selection box active
var selection_start_pos: Vector2             # Selection box start
var selection_rect: Rect2                    # Current selection box
var is_dragging_notes: bool = false          # Note drag active
var drag_start_pos: Vector2                  # Drag start position
var original_note_positions: Dictionary      # Stored positions for undo
```

**New Methods**:
- `select_note(note_id, add_to_selection)`: Select single note
- `toggle_note_selection(note_id)`: Toggle selection state
- `clear_selection()`: Deselect all notes
- `select_all()`: Select all visible notes
- `get_selected_notes()`: Returns array of selected IDs
- `_start_selection_box(pos)`: Begin selection box drag
- `_update_selection_box(pos)`: Update box during drag
- `_end_selection_box()`: Finalize selection based on box contents
- `_draw_selection_box()`: Render selection rectangle
- `_start_note_drag(pos, lane, tick)`: Begin note drag operation
- `_update_note_drag(pos)`: Update note positions during drag
- `_end_note_drag()`: Commit note movements

**New Signal**:
```gdscript
signal notes_moved(note_ids: Array, offset_lane: int, offset_tick: int, original_positions: Dictionary)
```

### 5. Enhanced Input Handling

**Mouse Input** (_gui_input):
- **Left-click on note**:
  - Regular: Select only that note (clear others), start drag
  - Ctrl+Click: Toggle note in selection
  - Click on already selected: Start drag of all selected notes
- **Left-click on empty**:
  - Regular: Clear selection, place note (if NOTE tool active)
  - Shift+Click: Start selection box
- **Right-click on note**: Delete note (unchanged)
- **Right-click on empty**: Place note (unchanged)
- **Mouse drag**: Update selection box or note positions
- **Mouse release**: Commit drag operation

**Keyboard Input** (chart_editor.gd):
- Delete key handler calls `_delete_selected_notes()`
- Ctrl+A handler calls `note_canvas.select_all()`
- Escape handler calls `note_canvas.clear_selection()`

### 6. Chart Editor Integration

**New Handler Methods**:
```gdscript
func _on_notes_moved(note_ids, offset_lane, offset_tick, original_positions):
    # Creates MoveNoteCommand for each moved note
    # Executes via history_manager for undo support

func _delete_selected_notes():
    # Gets selected notes from canvas
    # Creates RemoveNoteCommand for each
    # Clears selection when done
```

**Signal Connections**:
- Connected `note_canvas.notes_moved` to `_on_notes_moved()`
- Note selection handled internally by canvas (no signal to editor needed)

## User Workflows

### Workflow 1: Select and Delete Multiple Notes
1. Shift+Click and drag to create selection box around notes
2. Release mouse - notes within box are selected (yellow outline)
3. Press Delete key - all selected notes removed
4. Press Ctrl+Z to undo if needed

### Workflow 2: Move Notes to Different Position
1. Click on a note to select it (or Ctrl+Click multiple notes)
2. Click and drag any selected note
3. All selected notes move together, snapping to grid
4. Release mouse - notes committed to new positions
5. Each moved note can be individually undone

### Workflow 3: Select All and Shift Timing
1. Press Ctrl+A to select all notes
2. Drag selection up or down to shift all timing
3. Release - all notes moved by same tick offset
4. Undo history tracks each note's movement

### Workflow 4: Multi-Select with Ctrl
1. Click first note to select
2. Ctrl+Click other notes to add to selection
3. Drag any selected note - all move together
4. Or press Delete to remove all selected

## Technical Details

### Selection Box Algorithm
```gdscript
# During drag: Update rectangle from start to current position
selection_rect = Rect2(
    Vector2(min(start.x, current.x), min(start.y, current.y)),
    Vector2(abs(size.x), abs(size.y))
)

# On release: Find notes whose positions are inside rect
for note_id in visual_notes:
    var note_pos = Vector2(lane_to_x(lane), tick_to_y(tick))
    if selection_rect.has_point(note_pos):
        notes_in_box.append(note_id)
```

### Note Drag Algorithm
```gdscript
# Store original positions at drag start
for note_id in selected_notes:
    original_note_positions[note_id] = {lane, tick}

# During drag: Calculate offset from start
offset_lane = current_lane - start_lane
offset_tick = snapped_current_tick - start_tick

# Apply offset to each note (visual only)
new_lane = clamp(original.lane + offset_lane, 0, 4)
new_tick = max(0, original.tick + offset_tick)

# On release: Create MoveNoteCommands with final positions
# Restore visual positions (commands will handle actual movement)
```

### Undo/Redo Integration
- Each moved note gets its own `MoveNoteCommand`
- History manager tracks all commands separately
- Can undo/redo individual note movements
- All commands from one drag operation are sequential in history
- Future enhancement: Could batch into composite command

## Visual Design

**Selected Note Appearance**:
- Base color lightened by 30%
- 3px thick yellow outline
- Sustain tails also outlined in yellow
- Clearly distinguishable from unselected notes

**Selection Box**:
- Semi-transparent blue fill (Color(0.5, 0.5, 1.0, 0.2))
- Solid blue outline (Color(0.5, 0.5, 1.0, 0.8), 2px)
- Updates in real-time during drag
- Disappears after selection finalized

**Drag Feedback**:
- Notes follow mouse position in real-time
- Grid snapping visible during drag
- All selected notes maintain relative positions
- Visual update only (not saved until release)

## Performance Considerations

- Selection box hit testing is O(n) where n = visible notes
- Drag updates all selected notes each frame (acceptable for typical chart sizes)
- Visual-only updates during drag avoid ChartDataModel signals until committed
- Selection array uses int IDs (minimal memory overhead)

## Known Behaviors

**Multi-Note Movement**:
- Each note creates separate command (not batched)
- Means undo will remove notes one at a time from moved group
- Could be enhanced with composite command pattern in future

**Selection Persistence**:
- Selection cleared on canvas click (when not Shift+clicking)
- Selection persists during drag operations
- Selection cleared automatically after delete operation
- Selection NOT cleared during undo/redo (notes may become unselected if deleted/recreated)

**Drag Constraints**:
- Notes constrained to valid lane range (0-4)
- Notes constrained to non-negative ticks (>= 0)
- Group drag maintains constraints per-note (some may hit boundary while others don't)
- No collision detection (notes can overlap)

## Testing Scenarios

### Test 1: Basic Selection
1. ✅ Single click selects one note
2. ✅ Clicking another note deselects first
3. ✅ Ctrl+click adds to selection
4. ✅ Ctrl+click on selected toggles off
5. ✅ Escape clears all selection

### Test 2: Selection Box
1. ✅ Shift+click and drag creates blue box
2. ✅ Box updates as mouse moves
3. ✅ Notes inside box selected on release
4. ✅ Empty box click clears selection

### Test 3: Note Dragging
1. ✅ Click and drag selected note moves it
2. ✅ Movement snaps to grid
3. ✅ Multiple selected notes move together
4. ✅ Notes can't go below tick 0
5. ✅ Notes can't go outside lanes 0-4

### Test 4: Delete Operations
1. ✅ Delete key removes all selected notes
2. ✅ Ctrl+Z undoes deletions
3. ✅ Can redo deletions with Ctrl+Y
4. ✅ Selection cleared after delete

### Test 5: Undo/Redo with Movement
1. ✅ Move notes, undo restores original positions
2. ✅ Redo re-applies movement
3. ✅ Each note tracked separately in history

## Future Enhancements (Not Yet Implemented)

### Copy/Paste
- Ctrl+C to copy selected notes
- Ctrl+V to paste at current playback position
- Maintain relative positions during paste
- Store in clipboard as note data array

### Batch Command for Moves
- Create composite command for multi-note moves
- Single undo/redo operation for entire group
- More intuitive undo behavior

### Selection Refinement
- Add to selection with Ctrl+drag box
- Subtract from selection with Alt+drag box
- Invert selection command

### Smart Snapping
- Hold Shift while dragging to disable grid snap
- Visual feedback for snap divisions during drag
- Snap to nearby notes option

### Note Overlap Detection
- Visual warning when notes overlap
- Option to auto-merge overlapping notes
- Sustain collision detection

## Code Statistics

**Lines Added**:
- EditorNoteCanvas.gd: +260 lines (selection/drag logic)
- chart_editor.gd: +35 lines (handlers and keyboard shortcuts)

**New Methods**: 17
- Selection: 5 methods
- Selection Box: 4 methods  
- Note Dragging: 3 methods
- Integration: 2 handlers
- Drawing: 1 method
- Keyboard: 2 shortcuts

## Comparison to Moonscraper

| Feature | Moonscraper | Our Implementation | Status |
|---------|-------------|-------------------|--------|
| Click to select | ✅ | ✅ | Complete |
| Ctrl+Click multi-select | ✅ | ✅ | Complete |
| Drag to move | ✅ | ✅ | Complete |
| Selection box | ✅ | ✅ | Complete |
| Delete key | ✅ | ✅ | Complete |
| Copy/Paste | ✅ | ❌ | Not yet |
| Undo move | ✅ | ✅ | Complete |
| Snap to grid | ✅ | ✅ | Complete |
| Yellow selection color | ✅ | ✅ | Complete |

## Summary

Phase 2 successfully implements the core interactive editing workflow. Users can now:
- Select notes with mouse (click, Ctrl+click, selection box)
- Move notes by dragging with automatic grid snapping
- Delete selected notes with Delete key
- Use Ctrl+A to select all notes
- All operations fully undoable/redoable

The editor now matches the fundamental interaction patterns of Moonscraper, providing an intuitive and familiar charting experience. Next priorities are file I/O (save/load charts) and timeline scrubbing integration.
