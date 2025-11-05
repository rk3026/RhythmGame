# Chart Editor - Quick Reference Card

## 🎮 Keyboard Shortcuts

### Playback
| Key | Action |
|-----|--------|
| `Space` | Play / Pause |

### Editing
| Key | Action |
|-----|--------|
| `1-5` | Quick place note at current time (lane 1-5) |
| `Delete` | Delete selected notes |
| `Ctrl + Z` | Undo |
| `Ctrl + Y` | Redo |
| `Ctrl + Shift + Z` | Redo (alternative) |
| `Ctrl + A` | Select all notes |
| `Escape` | Clear selection |
| `[` | Decrease snap division |
| `]` | Increase snap division |

### Mouse Controls
| Action | Result |
|--------|--------|
| `Left Click` (empty space) | Place note |
| `Left Click` (note) | Select note |
| `Ctrl + Left Click` (note) | Toggle note selection |
| `Right Click` (note) | Delete note |
| `Shift + Drag` | Selection box |
| `Drag` (selected notes) | Move notes |
| `Mouse Wheel` | Scroll canvas |

## 🎵 Workflow

### Creating a New Chart
1. Run chart editor scene (`F6`)
2. Click on canvas to place notes
3. Use `1-5` keys for quick placement
4. Select and drag to adjust timing

### Setting Up Playback
1. Go to Side Panel → Metadata tab
2. Set "Audio File" to your song (e.g., `song.ogg`)
3. Set BPM, Offset, etc.
4. Press `Space` to play

### Editing Notes
1. **Place**: Click empty space or press `1-5` keys
2. **Select**: Click note or `Shift+Drag` box
3. **Move**: Drag selected notes
4. **Delete**: `Right-click` or press `Delete`
5. **Undo**: `Ctrl+Z` if you make a mistake

## 📊 UI Overview

```
┌─────────────────────────────────────────────────┐
│ [File] [Edit] [View] [Playback]    Menu Bar    │
├─────────────────────────────────────────────────┤
│      Playback Controls                          │
│  ⏮ ▶️ ⏸ ⏹ ⏭  [━━━━━○━━━━━]  Speed: 1.0x      │
├─────┬───────────────────────────────┬───────────┤
│     │                               │           │
│ T   │      2D Note Canvas           │  Side     │
│ o   │   (Click to place notes)      │  Panel    │
│ o   │                               │           │
│ l   │   ═══════════════════════     │  Metadata │
│ b   │   Green Red Yel Blue Org      │  Tracks   │
│ a   │   ═══════════════════════     │  Settings │
│ r   │                               │           │
│     │   [Playback line moves here]  │           │
│     │                               │           │
└─────┴───────────────────────────────┴───────────┘
│ Time: 1:23.45 | BPM: 120 | Snap: 1/16 | Notes: 42│
└─────────────────────────────────────────────────┘
```

## 🎯 Common Tasks

### Add a Note
```
Method 1: Click on canvas where you want the note
Method 2: Press 1-5 key (places at current time)
```

### Delete Multiple Notes
```
1. Shift+Drag to select multiple notes
2. Press Delete key
```

### Move Notes in Time
```
1. Select notes
2. Drag up (earlier) or down (later)
```

### Change Note Lane
```
1. Select notes
2. Drag left or right
```

### Test Your Chart
```
1. Set audio file in Side Panel
2. Press Space to play
3. Watch notes spawn on 3D runway
4. Verify timing is correct
```

## ⚙️ Settings

### Snap Division (Toolbar)
- Controls grid snapping
- Common values: 1/4, 1/8, 1/16, 1/32
- Use `[` and `]` to adjust

### View Options (Toolbar)
- Grid toggle: Show/hide grid lines
- Tool selection: Note, Select, Erase (TODO)

### Side Panel Tabs
1. **Metadata**: Song info, audio file, BPM
2. **Tracks**: Enable/disable difficulties
3. **Settings**: Editor preferences (TODO)

## 🔧 Technical Details

### Data Structure
```
ChartDataModel
  ├── metadata (title, artist, audio_file, BPM, offset)
  ├── charts[instrument][difficulty]
  │     └── notes[] (id, tick, lane, type, length)
  └── bpm_changes[] (tick, bpm)
```

### Note Types
- `0` = Regular note
- `1` = HOPO (Hammer-on/Pull-off)
- `2` = TAP note
- Length: `0` for regular, `> 0` for sustain (in ticks)

### Timing
- **Resolution**: 192 ticks per beat (standard)
- **Tick**: Smallest timing unit
- **Beat**: 192 ticks (at standard resolution)
- **Measure**: 4 beats = 768 ticks

### Conversion
```gdscript
# Tick to Time
time = chart_data.tick_to_time(tick)

# Time to Tick
tick = chart_data.time_to_tick(time)

# BPM at Tick
bpm = chart_data.get_bpm_at_tick(tick)
```

## 🐛 Troubleshooting

### Notes Don't Show Up
- ✓ Check console for errors
- ✓ Verify chart is created: `chart_data.get_chart()`
- ✓ Check note count: Status bar bottom right

### Can't Play Audio
- ✓ Set audio file path in Side Panel → Metadata
- ✓ Verify file exists relative to chart location
- ✓ Supported formats: OGG, MP3

### Playback Out of Sync
- ✓ Adjust offset in metadata (milliseconds)
- ✓ Verify BPM is correct
- ✓ Check for BPM changes in song

### Undo Doesn't Work
- ✓ Check history state (menu buttons should enable)
- ✓ Verify commands are being created
- ✓ Console should log actions

## 💡 Tips & Tricks

### Efficient Workflow
1. **Use number keys**: Faster than clicking
2. **Set snap early**: Saves time adjusting later
3. **Test frequently**: Press Space often to verify
4. **Use selection box**: Faster than clicking individual notes
5. **Copy BPM from reference**: Use existing charts as guides

### Accurate Timing
1. **Listen carefully**: Sync to drum hits or melody
2. **Use BPM changes**: Many songs have tempo shifts
3. **Adjust offset**: Fine-tune sync with offset value
4. **Test in gameplay**: Editor preview should match game

### Organization
1. **Start with Easy**: Chart easier difficulties first
2. **Use metadata**: Fill in song info completely
3. **Save often**: File → Save (when implemented)
4. **Version control**: Use git for backups

## 📈 Performance

### Optimizations Built-In
- ✅ Object pooling for notes
- ✅ Viewport culling (offscreen notes not drawn)
- ✅ Command pattern (efficient undo/redo)
- ✅ Lazy timeline initialization

### If You Experience Lag
- Reduce zoom (less visible area)
- Close other applications
- Reduce window size
- Check note count (very high = slower)

## 🚀 Advanced Features

### Coming Soon
- [ ] Loop regions
- [ ] Variable playback speed
- [ ] Metronome click
- [ ] Waveform display
- [ ] MIDI recording
- [ ] Auto-save

### Extensibility
The chart editor uses a modular architecture:
- Commands for undo/redo
- Signals for decoupling
- Timeline system for playback
- Data model separate from visuals

Add new features by:
1. Creating new command classes
2. Adding signals to UI components
3. Extending ChartDataModel
4. Adding to timeline system

## 📚 Additional Resources

- **Setup Guide**: `ChartEditor-Setup-Complete.md`
- **Implementation**: `ChartEditor-Playback-Implementation.md`
- **Quick Start**: `ChartEditor-Playback-QuickStart.md`
- **Summary**: `ChartEditor-Playback-Summary.md`

## ✅ Quick Checklist

Starting a new chart:
- [ ] Run chart editor scene
- [ ] Set metadata (title, artist, BPM)
- [ ] Set audio file path
- [ ] Select snap division (usually 1/16)
- [ ] Start placing notes
- [ ] Test with Space key
- [ ] Adjust timing if needed
- [ ] Save chart (when implemented)

---

**Ready to create awesome charts!** 🎸🎵🎮
