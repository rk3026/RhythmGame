# Chart Editor Playback - Quick Start Guide

## What Was Added

The chart editor can now play back your chart with audio and visual note preview, just like in gameplay!

## How It Works

### Architecture
```
ChartDataModel (your edits)
        ↓
[Convert to Spawner Format]
        ↓
NoteSpawner + TimelineController
        ↓
Notes spawn on 3D runway + 2D canvas shows playback line
```

### Key Components

1. **Timeline Controller**: Executes spawn commands at precise times
2. **Note Spawner**: Manages note lifecycle (reused from gameplay)
3. **Audio Sync**: Keeps audio aligned with note spawns
4. **Canvas Updates**: Shows playback position on 2D editor

## Usage

### Starting Playback
1. Load or create a chart
2. Ensure chart has audio file in metadata
3. Press Space or click Play button
4. First play initializes the timeline system

### Controls
- **Space**: Play/Pause
- **Play Button**: Start playback
- **Pause Button**: Pause (preserves position)
- **Stop Button**: Stop and return to start
- **Timeline Slider**: Seek to position

### During Playback
- Notes spawn and move down the 3D runway
- 2D canvas shows white playback line
- Canvas auto-scrolls to follow playback
- All UI elements update in real-time

## Testing Your Implementation

### Quick Test
1. Open chart editor scene
2. Run the scene
3. Press Space to play
4. Check console for: "Playback system initialized with X note commands"
5. Verify notes spawn on runway
6. Verify audio plays in sync

### Full Test Checklist
```
□ Playback initializes without errors
□ Audio loads and plays
□ Notes spawn at correct times
□ Notes match lanes from chart
□ Canvas scrolls automatically
□ Playback line appears on canvas
□ BPM changes affect timing
□ Pause preserves position
□ Stop returns to start
□ Seeking updates position
□ Sustain notes render tails
```

## Troubleshooting

### "No audio loaded for playback"
- Check `chart_data.metadata["audio_file"]` is set
- Verify audio file exists in chart folder
- Call `_load_audio_for_chart()` after loading chart

### Notes don't spawn
- Check `chart_data.get_chart(instrument, difficulty)` has notes
- Verify runway lanes are initialized
- Check console for initialization messages

### Audio out of sync
- Verify `chart_data.metadata["offset"]` is correct
- Check BPM changes are loaded properly
- Monitor timeline time vs audio time

### Canvas doesn't scroll
- Ensure `note_canvas` is properly initialized
- Check `scroll_to_tick()` is being called
- Verify tick-to-time conversion is correct

## Code Entry Points

### To Start Playback
```gdscript
_on_play_requested()
  → _initialize_playback_system()  # First time only
  → audio_player.play()
  → timeline_controller.active = true
```

### To Load Audio
```gdscript
_load_audio_for_chart()
  → Reads metadata["audio_file"]
  → Loads AudioStreamOggVorbis
  → Sets audio_player.stream
```

### Main Update Loop
```gdscript
_process(delta)
  → timeline_controller updates
  → audio syncs to timeline
  → UI updates (controls, status bar)
  → canvas updates (playback line, scroll)
```

## Next Steps

### Recommended Enhancements
1. **Loop Region**: Select tick range to loop playback
2. **Playback Speed**: Add 0.5x, 0.75x, 1.5x, 2x options
3. **Metronome**: Audio click track during editing
4. **Waveform Display**: Show audio waveform on canvas

### Advanced Features
1. **Edit During Playback**: Rebuild timeline on-the-fly
2. **MIDI Recording**: Record notes from MIDI keyboard
3. **Auto-Save Points**: Mark timestamps with issues
4. **Practice Mode**: Loop difficult sections

## Performance Notes

### Optimizations Already in Place
- Object pooling for notes (NotePool)
- Command pattern for efficient spawning
- Lazy timeline initialization
- Viewport culling for 3D notes

### If You Have Performance Issues
- Reduce `note_pool.max_pool_size` if memory constrained
- Increase `pixels_per_tick` to show less canvas area
- Disable 3D preview (just use 2D canvas)
- Limit active note count in spawner

## Architecture Benefits

### Why This Approach?
1. **Reuses 90% of gameplay code** - Less duplication
2. **Preview matches gameplay exactly** - WYSIWYG editing
3. **Object pooling** - Efficient memory usage
4. **Timeline system** - Enables advanced features
5. **Easy maintenance** - Fix once, benefits both systems

### Design Patterns Used
- **Command Pattern**: SpawnNoteCommand
- **Object Pool**: NotePool for note reuse
- **Observer Pattern**: Signals for data changes
- **Model-View**: ChartDataModel separate from visuals
- **Strategy Pattern**: Pluggable parsers

## Common Modifications

### Change Playback Speed
```gdscript
# In TimelineController
timeline_controller.set_direction(1)  # Forward
timeline_controller.set_direction(-1)  # Reverse
```

### Add Custom Commands
```gdscript
# Create new command class
extends ICommand
class_name MyCustomCommand

var scheduled_time: float

func execute(ctx: Dictionary):
    # Your logic here
    pass

func undo(ctx: Dictionary):
    # Reverse your logic
    pass

# Add to timeline
timeline_controller.add_command(my_cmd)
```

### Modify Note Appearance
```gdscript
# In note_spawner._command_spawn_note()
note.modulate = Color.RED  # Change color
note.scale *= 1.5  # Make bigger
```

## Questions?

Check these files for reference:
- `gameplay.gd` - Original implementation
- `chart_editor.gd` - Adapted implementation  
- `TimelineController.gd` - Command execution
- `note_spawner.gd` - Note lifecycle
- `ChartEditor-Playback-Implementation.md` - Full details
