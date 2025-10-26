# Sound Effect System Implementation

## Overview
A comprehensive sound effect system has been implemented for the rhythm game, featuring centralized audio management, object pooling for performance, and seamless integration with existing game systems.

## Architecture

### SoundEffectManager Singleton
**Location:** `Scripts/SoundEffectManager.gd`

A singleton autoload that manages all game audio effects with the following features:

#### Sound Categories (Enum)
- `HIT_PERFECT` - Perfect hit sounds
- `HIT_GREAT` - Great hit sounds  
- `HIT_GOOD` - Good hit sounds
- `HIT_BAD` - Bad hit sounds
- `MISS` - Miss sounds
- `COMBO_MILESTONE` - Combo achievement sounds (50x, 100x, FC)
- `COUNTDOWN` - Countdown tick and go sounds
- `UI_CLICK` - Button click sounds
- `UI_HOVER` - Button hover sounds
- `UI_BACK` - Back/cancel sounds
- `UI_SELECT` - Selection sounds
- `PAUSE_IN` - Pause enter sound
- `PAUSE_OUT` - Pause exit sound
- `AMBIENT` - Background/ambient effects
- `STINGER` - Musical stingers/accents

#### Audio Bus Hierarchy
```
Master (bus 0)
├── Music (bus 1) - Background music tracks
├── SFX (bus 2) - Main effects bus
│   ├── SFX/Hits (bus 3) - Note hit sounds
│   ├── SFX/Misses (bus 4) - Miss sounds
│   └── SFX/Impacts (bus 5) - Combo/impact effects
└── UI (bus 6) - Interface sounds
```

#### Core API Methods

**`play_sfx(sound_name: String, category: SoundCategory, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer`**
- Plays a sound effect by name from the sound library
- Automatically routes to appropriate audio bus based on category
- Returns the AudioStreamPlayer instance for further control

**`play_stream(stream: AudioStream, category: SoundCategory, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer`**
- Plays an AudioStream directly (for dynamic/runtime loaded sounds)
- Useful for custom or procedurally generated audio

**`play_sfx_variation(base_name: String, num_variations: int, category: SoundCategory, volume_db: float = 0.0) -> AudioStreamPlayer`**
- Randomly plays one of several sound variations
- Example: `play_sfx_variation("perfect", 2, HIT_PERFECT)` plays either "perfect_01" or "perfect_02"
- Adds variety to frequently played sounds

**`set_bus_volume(bus_name: String, volume_db: float)`**
- Sets the volume of an audio bus in decibels
- Used by SettingsManager to apply user volume preferences

**`preload_sounds(sound_names: Array[String])`**
- Preloads specific sounds into ResourceCache
- Prevents loading hitches during gameplay

**`preload_category(category: SoundCategory)`**
- Preloads all sounds in a specific category
- Called during gameplay initialization for hit/combo sounds

#### AudioPlayerPool System
An inner class that manages a pool of 16 AudioStreamPlayer instances per audio bus:

- **get_player()** - Returns an available or least-recently-used player
- **Automatic cleanup** - Players return to pool when audio finishes
- **Performance** - Eliminates frequent node instantiation/deletion
- **Bus-specific pools** - Separate pools for each audio bus ensure proper routing

### SettingsManager Integration
**Location:** `Scripts/settings_manager.gd`

Extended to support volume controls:

#### New Global Settings
- `sfx_volume: float` - Sound effects volume (0.0 - 1.0)
- `ui_volume: float` - UI sounds volume (0.0 - 1.0)
- `music_volume: float` - Music track volume (0.0 - 1.0)
- `master_volume: float` - Master volume (existing, now applies to all buses)

#### New Methods
- `set_sfx_volume(volume: float)` - Set SFX volume and apply to bus
- `set_ui_volume(volume: float)` - Set UI volume and apply to bus
- `set_music_volume(volume: float)` - Set music volume and apply to bus
- `_apply_volume_settings()` - Apply all volume settings to audio buses
- `_volume_to_db(volume: float)` - Convert linear (0-1) to decibels

Volume settings are:
- Persisted to `user://settings.cfg`
- Validated to stay within 0.0 - 1.0 range
- Automatically applied to SoundEffectManager audio buses
- Converted from linear to logarithmic (dB) scale for natural perception

## Integration Points

### Gameplay System
**File:** `Scripts/gameplay.gd`

#### _ready() Method
```gdscript
# Preload frequently used sounds for performance
SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.HIT_PERFECT)
SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.COMBO_MILESTONE)
SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.COUNTDOWN)
```

#### _on_note_hit() Method
Plays grade-appropriate hit sounds:
- `PERFECT` - Plays variation of perfect hit sounds (perfect_01 or perfect_02)
- `GREAT` - Plays great hit sound
- `GOOD` - Plays good hit sound
- `MISS` - Plays bad hit sound

#### _on_note_miss() Method
Plays miss sound when notes are not hit in time.

#### start_countdown() Method
- Plays "countdown_tick" sound on each countdown number (3, 2, 1)
- Plays "countdown_go" sound when countdown completes

### Score System
**File:** `Scripts/ScoreManager.gd`

#### add_hit() Method
Plays combo milestone sounds:
- Every 50 hits: "combo_50" sound
- Every 100 hits: "combo_100" sound
- Full combo detection: "combo_fc" sound

### UI System
**File:** `Scripts/main_menu.gd`

#### _connect_ui_sounds() Helper
Adds sound effects to all menu buttons:
- `mouse_entered` → plays "ui_hover" sound
- `pressed` → plays "ui_click" sound

Applied to all main menu buttons:
- Quickplay Button
- Online Button
- Practice Button
- News Button
- Settings Button
- Switch Profile Button
- Quit Button

## Asset Organization

### Folder Structure
**Location:** `Assets/Audio/`

```
Assets/Audio/
├── SFX/
│   ├── Hits/           # Note hit sounds (perfect, great, good, bad)
│   ├── Misses/         # Miss sounds
│   ├── Combo/          # Combo milestone sounds (50, 100, FC)
│   └── Ambient/        # Countdown, pause, ambient effects
├── UI/                 # Interface sounds (click, hover, select, back)
└── README.md           # Asset guidelines and recommendations
```

### Sound Library Mapping
The `SOUND_LIBRARY` dictionary in SoundEffectManager maps sound names to file paths:

**Hit Sounds:**
- "perfect" → "res://Assets/Audio/SFX/Hits/perfect_01.ogg"
- "perfect_02" → "res://Assets/Audio/SFX/Hits/perfect_02.ogg"
- "great" → "res://Assets/Audio/SFX/Hits/great_01.ogg"
- "good" → "res://Assets/Audio/SFX/Hits/good_01.ogg"
- "bad" → "res://Assets/Audio/SFX/Hits/bad_01.ogg"

**Miss Sounds:**
- "miss" → "res://Assets/Audio/SFX/Misses/miss_01.ogg"

**Combo Sounds:**
- "combo_50" → "res://Assets/Audio/SFX/Combo/combo_50.ogg"
- "combo_100" → "res://Assets/Audio/SFX/Combo/combo_100.ogg"
- "combo_fc" → "res://Assets/Audio/SFX/Combo/combo_fc.ogg"

**Countdown Sounds:**
- "countdown_tick" → "res://Assets/Audio/SFX/Ambient/countdown_tick.ogg"
- "countdown_go" → "res://Assets/Audio/SFX/Ambient/countdown_go.ogg"

**Pause Sounds:**
- "pause_in" → "res://Assets/Audio/SFX/Ambient/pause_in.ogg"
- "pause_out" → "res://Assets/Audio/SFX/Ambient/pause_out.ogg"

**UI Sounds:**
- "ui_click" → "res://Assets/Audio/UI/click.ogg"
- "ui_hover" → "res://Assets/Audio/UI/hover.ogg"
- "ui_back" → "res://Assets/Audio/UI/back.ogg"
- "ui_select" → "res://Assets/Audio/UI/select.ogg"

### Asset Guidelines
See `Assets/Audio/README.md` for detailed guidelines on:
- Recommended audio formats (OGG Vorbis preferred)
- Volume normalization standards
- Duration recommendations per sound type
- Suggested sources for free sound effects

## Performance Considerations

### Object Pooling
- AudioStreamPlayer nodes are pooled (16 per bus) to eliminate instantiation overhead
- Players are reused via LRU (Least Recently Used) strategy when pool is exhausted
- Automatic cleanup via `finished` signal connections

### Sound Preloading
- Critical sounds (hits, combos, countdown) are preloaded during gameplay initialization
- Uses ResourceCache singleton for efficient memory management
- Prevents audio loading hitches during gameplay

### Bus Architecture
- Separate buses allow independent volume control
- Sub-buses (Hits, Misses, Impacts) enable fine-grained mixing
- Efficient routing via category-to-bus mapping

## Usage Examples

### Playing a Simple Sound Effect
```gdscript
SoundEffectManager.play_sfx("ui_click", SoundEffectManager.SoundCategory.UI_CLICK)
```

### Playing with Custom Volume and Pitch
```gdscript
# Play louder and slightly higher pitched
SoundEffectManager.play_sfx("perfect", SoundEffectManager.SoundCategory.HIT_PERFECT, 3.0, 1.1)
```

### Playing Sound Variations
```gdscript
# Randomly play perfect_01 or perfect_02
SoundEffectManager.play_sfx_variation("perfect", 2, SoundEffectManager.SoundCategory.HIT_PERFECT)
```

### Preloading Sounds
```gdscript
# Preload specific sounds
SoundEffectManager.preload_sounds(["ui_click", "ui_hover"])

# Preload entire category
SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.HIT_PERFECT)
```

### Setting Volume
```gdscript
# Via SettingsManager (persisted)
SettingsManager.set_sfx_volume(0.8)
SettingsManager.set_ui_volume(0.6)

# Direct bus control (temporary)
SoundEffectManager.set_bus_volume(SoundEffectManager.BUS_SFX, -6.0)
```

### Adding Sounds to UI Buttons
```gdscript
func _ready():
    var my_button = $Button
    my_button.mouse_entered.connect(func():
        SoundEffectManager.play_sfx("ui_hover", SoundEffectManager.SoundCategory.UI_HOVER)
    )
    my_button.pressed.connect(func():
        SoundEffectManager.play_sfx("ui_click", SoundEffectManager.SoundCategory.UI_CLICK)
    )
```

## Testing Requirements

### Unit Tests (GdUnit4)
**Location:** `test/test_sound_effect_manager.gd` (to be created)

Recommended test cases:
1. **Test play_sfx returns valid AudioStreamPlayer**
2. **Test pool reuses players correctly**
3. **Test set_bus_volume updates AudioServer**
4. **Test preload_sounds adds to ResourceCache**
5. **Test play_sfx_variation picks random variation**
6. **Test category-to-bus mapping is correct**
7. **Test volume validation and clamping**

### Manual Testing Checklist
1. **Gameplay Sounds**
   - [ ] Hit sounds play for each grade (PERFECT, GREAT, GOOD, BAD)
   - [ ] Miss sound plays when notes are missed
   - [ ] Combo sounds play at 50x, 100x milestones
   - [ ] Countdown sounds play during start countdown

2. **UI Sounds**
   - [ ] Button hover sounds play on mouse enter
   - [ ] Button click sounds play on press
   - [ ] All menu buttons have sounds

3. **Volume Controls**
   - [ ] SFX volume slider affects hit/miss sounds
   - [ ] UI volume slider affects button sounds
   - [ ] Music volume slider affects track audio
   - [ ] Master volume affects all audio
   - [ ] Settings persist after restart

4. **Performance**
   - [ ] No audio stuttering during intense gameplay
   - [ ] Memory usage stable over long sessions
   - [ ] No audio delays or lag

## Future Enhancements

### Potential Additions
1. **Dynamic Audio Mixing**
   - Duck music volume during important sound effects
   - Adaptive mix based on gameplay intensity

2. **Audio Themes**
   - Multiple sound effect packs (retro, modern, electronic)
   - User-selectable audio themes via settings

3. **Positional Audio**
   - 3D audio for note spawning (panning based on lane)
   - Spatial audio for immersive experience

4. **Audio Feedback**
   - Real-time audio visualization
   - Beat-synced sound effects

5. **Advanced Pooling**
   - Dynamic pool sizing based on performance
   - Priority system for critical sounds

6. **Sound Effect Categories**
   - Enable/disable specific sound categories
   - Per-category volume controls

## Known Issues

### Compilation Warnings
The Godot editor may show "SoundEffectManager not declared" errors before the project is opened. These are false positives - autoload singletons are globally available once Godot loads the project.

### Asset Placeholders
Currently, the system references placeholder audio files that need to be replaced with actual sound assets. The folder structure and file naming conventions are in place for easy asset integration.

## Conclusion

The sound effect system provides a robust, performant, and maintainable foundation for all game audio needs. It follows the project's established patterns (singleton autoloads, object pooling, signal-based communication) and integrates seamlessly with existing systems. With proper audio assets, this system will significantly enhance player feedback and game feel.
