# Chart Editor Playback Implementation

## Overview
This document describes how the chart editor's playback system was implemented by adapting the existing gameplay system architecture.

## Gameplay System Analysis

### Architecture Components

1. **TimelineController** (`TimelineController.gd`)
   - Central command pattern implementation
   - Maintains sorted array of `ICommand` objects
   - Executes commands at scheduled times
   - Supports forward/backward playback via `execute()` and `undo()`
   - Can scrub to any time position instantly

2. **NoteSpawner** (`note_spawner.gd`)
   - Converts chart data into spawn timing information
   - Uses object pooling via `NotePool` for performance
   - Builds `SpawnNoteCommand` objects for timeline
   - Handles note repositioning during timeline scrubbing
   - Manages active notes lifecycle

3. **Note Objects** (`note.gd`)
   - Visual 3D sprites that move down the runway
   - Support sustain notes with tail visuals
   - Emit signals for hits, misses, and completion
   - Have `reverse_mode` flag for backward playback

4. **Gameplay Loop** (`gameplay.gd`)
   - Orchestrates all systems
   - Syncs audio with timeline position
   - Handles input through InputHandler
   - Manages scoring through ScoreManager

### Data Flow
```
Chart File → ChartLoadingService → Parsed Data
                                  ↓
                          NoteSpawner.start_spawning()
                                  ↓
                          Creates spawn_data array
                                  ↓
                       Builds SpawnNoteCommand array
                                  ↓
                          TimelineController.setup()
                                  ↓
               Timeline executes commands at scheduled_time
                                  ↓
                     Notes spawn and move down runway
```

## Chart Editor Playback Implementation

### Key Differences from Gameplay

1. **Chart Data Source**
   - Gameplay: Loads from `.chart` files via `ChartLoadingService`
   - Editor: Uses `ChartDataModel` (in-memory chart being edited)

2. **Note Data Format**
   - Gameplay: Uses parser-specific format (fret, tick, is_hopo, etc.)
   - Editor: Uses ChartDataModel format (lane, tick, type, length)
   - **Solution**: Conversion functions translate between formats

3. **Input Handling**
   - Gameplay: InputHandler processes lane key presses for gameplay
   - Editor: Direct note placement/editing via canvas
   - **Solution**: Timeline is read-only during playback

4. **Visual Feedback**
   - Gameplay: Notes move down 3D runway towards player
   - Editor: Both 3D preview AND 2D canvas with playback line
   - **Solution**: Both systems update in parallel

### Implementation Changes

#### 1. Added Timeline System to Chart Editor

```gdscript
var timeline_controller: TimelineController = null
var song_start_time: float = 0.0
var lanes: Array = []
```

#### 2. Playback Initialization (`_initialize_playback_system()`)

This method:
- Converts `ChartDataModel` notes to spawner format
- Converts BPM changes to tempo events
- Configures the note spawner
- Creates and sets up `TimelineController`
- Builds spawn commands from chart data
- Links timeline to spawner for scrubbing support

Key conversion functions:
- `_convert_chart_notes_to_spawner_format()`: Maps ChartDataModel notes to gameplay format
- `_convert_bpm_changes_to_tempo_events()`: Converts BPM changes to tempo events

#### 3. Process Loop Updates

The `_process()` function now:
- Updates timeline controller each frame
- Syncs audio to timeline position
- Updates both 3D preview and 2D canvas
- Auto-scrolls canvas to follow playback

```gdscript
func _process(_delta):
    if is_playing:
        # Get time from timeline
        current_time = timeline_controller.get_time()
        
        # Sync audio
        _sync_audio_to_timeline(false)
        
        # Update UI components
        playback_controls.update_position(current_time)
        status_bar.update_time(current_time)
        
        # Update note canvas
        var current_tick = chart_data.time_to_tick(current_time)
        note_canvas.update_playback_position(current_tick, true)
        note_canvas.scroll_to_tick(current_tick)
```

#### 4. Playback Control Handlers

**Play** (`_on_play_requested()`):
- Initializes playback system if needed
- Starts audio playback
- Activates timeline controller
- Scrubs to current position

**Pause** (`_on_pause_requested()`):
- Stops audio
- Deactivates timeline (via pause flag)
- Preserves current position

**Stop** (`_on_stop_requested()`):
- Stops audio
- Resets position to 0
- Can optionally despawn all notes

**Seek** (`_on_seek_requested()`):
- Updates current_time
- Scrubs timeline to position
- Seeks audio to match
- Scrolls canvas to show position

#### 5. Audio Loading

`_load_audio_for_chart()`:
- Reads audio file path from chart metadata
- Constructs full path relative to chart file
- Loads OGG/MP3 audio stream
- Updates playback controls with duration

### Data Format Conversions

#### ChartDataModel Note → Spawner Note

```gdscript
ChartDataModel:
{
    "id": int,
    "tick": int,
    "lane": int,      # 0-4
    "type": int,      # 0=normal, 1=HOPO, 2=tap
    "length": int     # sustain length in ticks
}

Spawner Format:
{
    "fret": int,      # lane value
    "tick": int,
    "is_hopo": bool,  # type == 1
    "is_tap": bool,   # type == 2
    "sustain": int    # length value
}
```

#### BPM Change Conversion

```gdscript
ChartDataModel:
{
    "tick": int,
    "bpm": float
}

Tempo Event:
{
    "tick": int,
    "bpm": float
}
# (Same format, but different array source)
```

## Integration Points

### With ChartDataModel
- Reads note data for playback
- Reads BPM changes for timing
- Reads metadata for audio file path
- Does NOT modify during playback (read-only)

### With EditorNoteCanvas
- Updates playback position to show current tick
- Auto-scrolls to follow playback
- Shows playback line when playing

### With NoteSpawner
- Reuses entire spawning logic from gameplay
- Uses same spawn command system
- Leverages note pooling for performance
- Benefits from scrubbing/repositioning features

### With TimelineController
- Commands execute notes at precise times
- Supports seeking/scrubbing
- Can be extended for forward/backward playback
- Maintains consistency between audio and visuals

## Benefits of This Approach

1. **Code Reuse**: Leverages 90% of gameplay spawning logic
2. **Consistency**: Editor preview matches actual gameplay exactly
3. **Performance**: Object pooling and command pattern are efficient
4. **Flexibility**: Timeline system supports advanced features (scrubbing, reverse)
5. **Maintainability**: Changes to gameplay automatically benefit editor

## Future Enhancements

### Potential Features
- **Variable Playback Speed**: Already supported by TimelineController direction
- **Loop Regions**: Select tick range and loop playback
- **Metronome**: Audio click track during editing
- **MIDI Input**: Record notes in real-time
- **Auto-save**: Detect playback issues and mark for review

### Advanced Timeline Features
- **Multiple Commands**: Add visual cues, events, lighting changes
- **Reverse Playback**: Already supported by timeline's undo system
- **Step Debugging**: Frame-by-frame note spawning

## Testing Checklist

- [ ] Playback starts at correct position
- [ ] Audio syncs with note spawns
- [ ] Notes spawn at correct lanes/times
- [ ] Canvas scrolls follow playback
- [ ] Pause preserves position
- [ ] Stop resets to beginning
- [ ] Seek updates both audio and visuals
- [ ] Sustain notes render correctly
- [ ] BPM changes affect timing
- [ ] Different difficulties switch correctly

## Known Limitations

1. **Editing During Playback**: Currently not supported (read-only)
   - Could add "hot reload" to rebuild timeline after edits

2. **Audio Format**: Requires OGG/MP3 files
   - Could add format detection/conversion

3. **Performance**: Large charts may have spawn lag
   - Already optimized via object pooling
   - Could add LOD system for distant notes

## References

- `gameplay.gd`: Original playback implementation
- `TimelineController.gd`: Command pattern timeline system  
- `note_spawner.gd`: Note spawning and lifecycle management
- `ChartDataModel.gd`: Editor's data model
- `SpawnNoteCommand.gd`: Command for spawning individual notes
