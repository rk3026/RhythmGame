# Chart Editor - Note Movement Pause Analysis & Implementation Plan

## Problem Statement
Currently, notes continuously move forward in the chart editor even when playback is paused. This makes it difficult to:
- Edit notes while paused (they keep moving away)
- Scrub the timeline accurately (notes don't stay synced to scrubber position)
- Visualize exact note positions at specific times

**Required Behavior:**
- Notes should ONLY move when playback is actively playing
- When paused, notes should freeze in place
- When scrubbing the timeline, notes should reposition to match the timeline position
- Notes should resume smooth movement when playback starts again

---

## Current Implementation Analysis

### How Notes Currently Move

**Location:** `Scripts/note.gd` - `_process(delta)`

```gdscript
func _process(delta: float):
    # Movement respects reverse playback flag
    var dir = -1.0 if reverse_mode else 1.0
    position.z += SettingsManager.note_speed * delta * dir
```

**Problem:** Notes ALWAYS move in `_process()` every frame regardless of playback state.

### Current Architecture

**Timeline Controller** (`Scripts/TimelineController.gd`):
- Has `active` flag that controls whether time advances
- Updates `current_time` in `_process()` when `active = true`
- Executes SpawnNoteCommands at scheduled times
- Supports scrubbing via `scrub_to(target_time)`

**Note Spawner** (`Scripts/note_spawner.gd`):
- Has `reposition_active_notes(current_time)` method that calculates note positions based on time
- This method IS already implemented and ties note positions to timeline!
- Called when scrubbing timeline via `scrub_to()`

**Position Calculation Logic** (from `note_spawner.gd`):
```gdscript
func reposition_active_notes(current_time: float):
    var distance = abs(runway_begin_z)
    for note in active_notes:
        if note.travel_time <= 0:
            continue
        var rel = current_time - note.spawn_time
        if rel <= 0:
            note.position.z = runway_begin_z  # At spawn position
            continue
        var speed = distance / note.travel_time
        if rel < note.travel_time:
            var fraction = rel / note.travel_time
            note.position.z = runway_begin_z + distance * fraction
        else:
            var extra = rel - note.travel_time
            var forward_z = min(runway_end_z, speed * extra)
            note.position.z = forward_z
```

**This calculation is PERFECT!** It positions notes based purely on time, not delta accumulation.

---

## Root Cause

The issue is that notes have TWO position systems fighting each other:

1. **Time-Based Positioning** (correct, used during scrubbing):
   - `note_spawner.reposition_active_notes()` calculates position from `current_time - spawn_time`
   - Only called when scrubbing, not during normal playback

2. **Delta-Based Movement** (problematic):
   - `note._process(delta)` continuously adds `note_speed * delta` to position
   - Runs EVERY FRAME regardless of playback state
   - Causes drift and movement even when paused

**The Solution:** Notes should ALWAYS use time-based positioning, not delta-based movement.

---

## Implementation Plan

### Option A: Disable note._process(), Use Timeline-Based Positioning (RECOMMENDED)

**Strategy:**
1. Add a `paused` flag or check to notes
2. When paused, skip movement in `_process()`
3. Call `note_spawner.reposition_active_notes()` every frame during playback
4. This ties ALL note movement to the timeline, not delta accumulation

**Advantages:**
- Simple to implement
- Notes stay perfectly synced to timeline
- No drift between audio/timeline/notes
- Scrubbing already works via `reposition_active_notes()`
- Same code path for playback and scrubbing

**Implementation Steps:**

1. **Add paused tracking to note_spawner.gd**
   - Add `var is_paused: bool = false`
   - Add `func set_paused(paused: bool)` method

2. **Modify note._process() to respect pause**
   - Check if parent note_spawner is paused
   - Skip movement if paused
   - Keep passive miss detection active

3. **Call reposition_active_notes() during playback**
   - In `note_spawner._process()`, call `reposition_active_notes(current_time)`
   - This ensures notes move smoothly based on timeline

4. **Connect pause state to playback controls**
   - In `chart_editor.gd`, update note_spawner pause state
   - Set `is_paused = true` when playback stops/pauses
   - Set `is_paused = false` when playback starts

### Option B: Only Use Time-Based Positioning (IDEAL, but more complex)

**Strategy:**
1. Remove delta-based movement from `note._process()` entirely
2. Always calculate positions from timeline
3. Call `reposition_active_notes()` every frame

**Advantages:**
- Eliminates drift completely
- Single source of truth (timeline)
- More robust for scrubbing/seeking

**Disadvantages:**
- Larger change to existing system
- May affect gameplay.gd (needs separate analysis)
- Requires testing in both editor and gameplay

---

## Recommended Approach: Option A (Pause Flag)

This is safer and requires minimal changes:

### Changes Required

**1. note.gd** - Add pause awareness:
```gdscript
func _process(delta: float):
    # Check if we should move (only during active playback)
    var spawner = get_parent()
    var should_move = true
    if spawner and spawner.has_method("is_movement_paused"):
        should_move = not spawner.is_movement_paused()
    
    if should_move:
        # Movement respects reverse playback flag
        var dir = -1.0 if reverse_mode else 1.0
        position.z += SettingsManager.note_speed * delta * dir
    
    # Passive miss detection still works (checks current position)
    if position.z >= 5 and not was_hit and not was_missed and not reverse_mode:
        was_missed = true
        emit_signal("note_miss", self)
        visible = false
        if tail_instance:
            tail_instance.visible = false
```

**2. note_spawner.gd** - Add pause state management:
```gdscript
var movement_paused: bool = false

func is_movement_paused() -> bool:
    return movement_paused

func set_movement_paused(paused: bool):
    movement_paused = paused

func _process(_delta):
    # Existing timeline sync code...
    if timeline_controller:
        _ensure_spawned_notes(timeline_controller.current_time)
        var is_reverse = timeline_controller.direction == -1
        for n in active_notes:
            if is_instance_valid(n):
                n.reverse_mode = is_reverse
        
        # NEW: Reposition notes based on timeline during active playback
        if not movement_paused:
            reposition_active_notes(timeline_controller.current_time)
    
    _cleanup_pass()
```

**3. chart_editor.gd** - Connect pause state to playback:
```gdscript
func _on_play_requested():
    # ... existing code ...
    note_spawner.set_movement_paused(false)  # Enable movement
    is_playing = true

func _on_pause_requested():
    # ... existing code ...
    note_spawner.set_movement_paused(true)  # Freeze notes
    is_playing = false

func _on_stop_requested():
    # ... existing code ...
    note_spawner.set_movement_paused(true)  # Freeze notes
    is_playing = false

func _on_seek_requested(seek_position: float):
    # ... existing code ...
    # Note: scrub_to() already calls reposition_active_notes()
    # Notes will update to correct position for the seek
```

---

## Expected Behavior After Implementation

### When Paused:
- Notes remain stationary at their current positions
- Timeline scrubber can be dragged to reposition notes
- Notes instantly update to match timeline position during scrubbing

### When Playing:
- Notes move smoothly forward (or backward in reverse mode)
- Position is recalculated each frame from timeline
- Notes stay perfectly synced to audio and timeline

### During Seeking:
- Notes instantly jump to positions matching the new time
- No gradual "catching up" or drift

---

## Testing Checklist

After implementation, verify:

1. **Paused State:**
   - [ ] Notes stop moving when pause button clicked
   - [ ] Notes remain frozen while timeline is paused
   - [ ] Can scrub timeline while paused and notes follow
   - [ ] Notes don't drift or jump when pausing/resuming

2. **Playing State:**
   - [ ] Notes move smoothly when play button clicked
   - [ ] Notes stay synced with audio playback
   - [ ] No visual jitter or stuttering

3. **Seeking/Scrubbing:**
   - [ ] Notes instantly reposition when scrubbing timeline
   - [ ] Position matches expected location for that time
   - [ ] Sustain tails update correctly

4. **Stop Button:**
   - [ ] Notes freeze when stop clicked
   - [ ] Return to beginning works correctly

5. **Skip Buttons:**
   - [ ] Skip to start repositions all notes to beginning
   - [ ] Skip to end repositions all notes to end positions

---

## Alternative: Gameplay Compatibility

**Question:** Will this affect gameplay.gd?

**Answer:** No, if implemented carefully:
- In gameplay mode, `movement_paused` would always be `false`
- Notes move normally during gameplay
- The `reposition_active_notes()` call during playback is optional in gameplay
- Current delta-based movement can continue in gameplay

**To ensure compatibility:**
- Only set `movement_paused = true` in chart editor
- Default value is `false` (normal gameplay behavior)
- Editor explicitly sets pause state based on playback controls

---

## Implementation Priority

**High Priority Changes:**
1. Add `movement_paused` flag to note_spawner.gd ✓
2. Add pause check to note._process() ✓
3. Connect pause state in chart_editor.gd ✓
4. Call reposition_active_notes() during playback ✓

**Optional Enhancements:**
- Add visual indicator when notes are paused
- Display current timeline position on notes
- Add debug overlay showing note positions vs expected positions

---

## Summary

The existing `reposition_active_notes()` method already has the perfect logic for time-based positioning. We just need to:

1. **Pause delta-based movement** when playback is paused
2. **Use time-based positioning** during active playback
3. **Connect pause state** to the playback controls

This will give us smooth, accurate note movement tied to the timeline with the ability to pause and scrub as needed.
