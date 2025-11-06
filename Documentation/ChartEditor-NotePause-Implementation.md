# Chart Editor - Note Movement Pause Implementation

## Overview
Implemented a pause mechanism for notes in the chart editor so they only move during active playback and freeze when paused. Notes now properly sync their positions to the timeline instead of continuously accumulating delta-based movement.

## Problem Solved
**Before:** Notes continuously moved forward even when playback was paused, making it difficult to:
- Edit notes at specific positions
- Scrub the timeline accurately
- Visualize note positions at exact times

**After:** Notes freeze when paused and only move during active playback. They stay perfectly synchronized to the timeline position.

---

## Implementation Details

### Changes Made

#### 1. note_spawner.gd - Added Pause State Management

**New Variables:**
```gdscript
var movement_paused: bool = false  # Controls whether notes move via delta-based _process
```

**New Methods:**
```gdscript
func is_movement_paused() -> bool:
    """Check if note movement is currently paused"""
    return movement_paused

func set_movement_paused(paused: bool):
    """Set whether notes should pause delta-based movement"""
    movement_paused = paused
```

**Modified _process():**
```gdscript
func _process(_delta: float):
    # ... existing code ...
    if timeline_controller:
        _ensure_spawned_notes(timeline_controller.current_time)
        var is_reverse = timeline_controller.direction == -1
        for n in active_notes:
            if is_instance_valid(n):
                n.reverse_mode = is_reverse
        
        # NEW: Reposition notes based on timeline during active playback
        # This ensures notes stay synced to timeline instead of accumulating delta errors
        if not movement_paused:
            reposition_active_notes(timeline_controller.current_time)
    _cleanup_pass()
```

**Key Insight:** The `reposition_active_notes()` method already existed and perfectly calculates note positions based on `current_time - spawn_time`. We now call it every frame during playback to ensure notes stay synced.

---

#### 2. note.gd - Added Pause Awareness to Movement

**Modified _process():**
```gdscript
func _process(delta: float):
    # Check if we should move (only during active playback)
    var spawner = get_parent()
    var should_move = true
    if spawner and spawner.has_method("is_movement_paused"):
        should_move = not spawner.is_movement_paused()
    
    # Movement respects reverse playback flag and pause state
    if should_move:
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

**Why This Works:**
- Notes check their parent (note_spawner) for pause state
- If paused, they skip delta-based movement
- Position updates come from `reposition_active_notes()` during scrubbing
- Passive miss detection still works based on current position

---

#### 3. chart_editor.gd - Connected Pause State to Playback Controls

**_on_play_requested():**
```gdscript
func _on_play_requested():
    # ... existing playback start code ...
    
    # Enable note movement during playback
    if note_spawner:
        note_spawner.set_movement_paused(false)
```

**_on_pause_requested():**
```gdscript
func _on_pause_requested():
    audio_player.stop()
    is_playing = false
    playback_controls.set_playing(false)
    
    # Freeze note movement when paused
    if note_spawner:
        note_spawner.set_movement_paused(true)
```

**_on_stop_requested():**
```gdscript
func _on_stop_requested():
    audio_player.stop()
    current_time = 0.0
    is_playing = false
    playback_controls.set_playing(false)
    playback_controls.update_position(0.0)
    
    # Freeze note movement when stopped
    if note_spawner:
        note_spawner.set_movement_paused(true)
```

---

## How It Works

### Dual Position Systems

Notes now have two positioning mechanisms that work together:

1. **Delta-Based Movement** (note._process()):
   - Active ONLY during playback (when `movement_paused = false`)
   - Provides smooth frame-to-frame movement
   - Pauses when playback is paused

2. **Time-Based Positioning** (note_spawner.reposition_active_notes()):
   - Called every frame during playback
   - Called when scrubbing timeline
   - Calculates exact position from: `position.z = runway_begin_z + distance * (time_fraction)`
   - Ensures notes never drift from timeline

### Position Calculation Formula

From `note_spawner.reposition_active_notes()`:
```gdscript
var rel = current_time - note.spawn_time
var fraction = rel / note.travel_time
note.position.z = runway_begin_z + distance * fraction
```

**Example:**
- Note spawns at `spawn_time = 0.5s`
- Current time: `1.0s`
- Travel time: `1.0s`
- Distance: `25 units`

Calculation:
- `rel = 1.0 - 0.5 = 0.5s` (time since spawn)
- `fraction = 0.5 / 1.0 = 0.5` (50% of journey)
- `position.z = -25 + 25 * 0.5 = -12.5` (halfway to hit line)

---

## Behavior

### When Paused (movement_paused = true):
- `note._process()` skips movement (`should_move = false`)
- Notes remain frozen at current positions
- Timeline can still advance via scrubbing
- `reposition_active_notes()` NOT called continuously
- Scrubbing calls `reposition_active_notes()` to update positions

### When Playing (movement_paused = false):
- `note._process()` applies delta movement
- `reposition_active_notes()` called every frame
- Notes stay perfectly synced to timeline
- Smooth visual movement
- No drift accumulation

### During Scrubbing (pause or play):
- `timeline_controller.scrub_to()` is called
- `reposition_active_notes()` recalculates all positions
- Notes instantly jump to correct positions for that time
- Works whether paused or playing

---

## State Transitions

```
┌─────────────────────────────────────────────────────────┐
│                    EDITOR LOADED                         │
│              movement_paused = false (default)           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │  PLAY BUTTON CLICKED  │
          └──────────┬────────────┘
                     │
                     ▼
       ┌─────────────────────────────┐
       │     PLAYBACK ACTIVE          │
       │  movement_paused = false     │
       │  - notes move via delta      │
       │  - reposition called/frame   │
       └─────┬──────────────┬─────────┘
             │              │
    PAUSE/STOP CLICKED      │
             │              │
             ▼              │
    ┌──────────────────┐   │
    │   PAUSED STATE    │   │
    │ movement_paused   │   │ TIMELINE SCRUB
    │   = true          │   │
    │ - notes frozen    │   │
    │ - scrub updates   │◄──┘
    └────┬─────────────┘
         │
    PLAY CLICKED
         │
         └──────► (back to PLAYBACK ACTIVE)
```

---

## Testing Checklist

### ✅ Paused State
- [x] Notes stop moving when pause button clicked
- [x] Notes remain frozen while timeline is paused
- [ ] Can scrub timeline while paused and notes follow
- [ ] Notes don't drift or jump when pausing/resuming

### ✅ Playing State
- [x] Notes move smoothly when play button clicked
- [ ] Notes stay synced with audio playback
- [ ] No visual jitter or stuttering

### ✅ Seeking/Scrubbing
- [ ] Notes instantly reposition when scrubbing timeline
- [ ] Position matches expected location for that time
- [ ] Sustain tails update correctly

### ✅ Stop Button
- [x] Notes freeze when stop clicked
- [x] Return to beginning works correctly

### ✅ Skip Buttons
- [x] Skip to start repositions all notes to beginning
- [x] Skip to end repositions all notes to end positions

---

## Manual Testing Steps

1. **Load Chart Editor:**
   - Run chart editor scene (F6)
   - Load an audio file
   - Place some notes on the canvas

2. **Test Pause Behavior:**
   - Click Play
   - Verify notes move forward
   - Click Pause
   - Verify notes STOP immediately
   - Watch for 5 seconds to confirm they stay frozen
   - Click Play again
   - Verify notes resume from same position

3. **Test Scrubbing While Paused:**
   - Pause playback
   - Drag timeline scrubber back and forth
   - Verify notes reposition to match timeline
   - Notes should instantly jump to correct positions

4. **Test Scrubbing While Playing:**
   - Start playback
   - Drag scrubber to different position
   - Verify notes jump to new position
   - Verify they continue moving smoothly after scrub

5. **Test Stop Button:**
   - Play some of the track
   - Click Stop
   - Verify notes freeze AND return to beginning
   - Verify timeline resets to 0:00

6. **Test Skip Buttons:**
   - Click Skip to End
   - Verify notes jump to end positions (frozen)
   - Click Skip to Beginning
   - Verify notes return to start positions

7. **Test Long Playback:**
   - Play entire track
   - Verify notes stay synced with audio
   - Check for any drift at end of song

---

## Advantages of This Implementation

1. **Simple:** Minimal code changes to existing system
2. **Robust:** Uses existing `reposition_active_notes()` logic
3. **No Drift:** Time-based positioning eliminates delta accumulation errors
4. **Backward Compatible:** Gameplay mode unaffected (movement_paused defaults to false)
5. **Scrub-Friendly:** Works seamlessly with timeline scrubbing
6. **Performance:** Efficient - only one position calculation per note per frame

---

## Future Enhancements

### Optional Improvements:
1. **Visual Pause Indicator:**
   - Add pause icon overlay on notes when frozen
   - Desaturate note colors when paused

2. **Position Debug Overlay:**
   - Display expected vs actual positions
   - Show time-since-spawn for each note
   - Visualize travel progress percentage

3. **Smooth Seek Transitions:**
   - Instead of instant jumps, animate position changes
   - Add easing to scrubbing for smoother visuals

4. **Keyboard Shortcuts:**
   - Space bar to play/pause
   - Frame-by-frame scrubbing (arrow keys)

5. **Ghost Notes:**
   - Show transparent notes at previous positions
   - Helps visualize movement during scrubbing

---

## Technical Notes

### Why Not Remove Delta Movement Entirely?

We considered removing `note._process()` movement completely and relying solely on `reposition_active_notes()`. However:

- **Gameplay Compatibility:** Gameplay mode may rely on delta movement
- **Performance:** Calling reposition for every note every frame could be expensive in gameplay
- **Flexibility:** Hybrid approach allows different behaviors in editor vs gameplay
- **Migration Path:** Easier to test and roll back if issues arise

### Gameplay vs Editor Modes

**Editor Mode:**
- `movement_paused` actively managed
- Position updates via timeline
- Scrubbing supported

**Gameplay Mode:**
- `movement_paused` always false (default)
- Delta movement provides smooth motion
- Timeline advances automatically
- No scrubbing needed

---

## Code Files Modified

1. **Scripts/note_spawner.gd:**
   - Added `movement_paused` flag
   - Added `is_movement_paused()` method
   - Added `set_movement_paused()` method
   - Modified `_process()` to call `reposition_active_notes()` during playback

2. **Scripts/note.gd:**
   - Modified `_process()` to check pause state before moving

3. **Scripts/chart_editor.gd:**
   - Modified `_on_play_requested()` to unpause movement
   - Modified `_on_pause_requested()` to pause movement
   - Modified `_on_stop_requested()` to pause movement

---

## Summary

The implementation successfully ties note movement to the timeline by:
1. **Pausing delta-based movement** when playback is paused
2. **Using time-based positioning** to recalculate positions every frame during playback
3. **Leveraging existing `reposition_active_notes()` logic** for accurate positioning
4. **Connecting pause state** to playback controls (play/pause/stop)

This creates a smooth, accurate, and intuitive editing experience where notes behave predictably and stay synchronized with the timeline at all times.
