# Chart Editor - Quick Start Guide

## Opening the Editor

1. Open `Scenes/chart_editor.tscn` in Godot
2. Press F6 to run the scene

## Basic Controls

### Placing Notes

**Method 1: Keyboard (Quick)**
- Press keys **1, 2, 3, 4, 5** to place notes in lanes 0-4
- Notes are placed at the current playback position
- Automatically snaps to the current snap division

**Method 2: Mouse**
- **Left-click** on empty canvas to place note
- Click position determines lane and timing
- Snaps to grid automatically

### Selecting Notes

**Single Selection**
- **Click** on a note to select it
- Selected notes have yellow outline and brighter color

**Multi-Selection**
- **Ctrl+Click** on notes to add/remove from selection
- **Shift+Click and drag** to create selection box
- **Ctrl+A** to select all notes in chart

**Clear Selection**
- **Escape** to deselect all notes
- Click on empty canvas also clears selection

### Moving Notes

1. Select one or more notes
2. **Click and drag** any selected note
3. All selected notes move together
4. Automatically snaps to grid
5. Release mouse to commit movement

**Tips**:
- Notes stay in lanes 0-4 (won't go outside)
- Notes can't go below tick 0 (song start)
- Relative positions maintained when moving multiple notes

### Deleting Notes

**Method 1: Delete Key**
- Select notes (any method above)
- Press **Delete** key
- All selected notes removed

**Method 2: Right-Click**
- **Right-click** on any note to delete it immediately
- No selection needed

### Undo/Redo

- **Ctrl+Z**: Undo last action
- **Ctrl+Y** or **Ctrl+Shift+Z**: Redo
- Works for: placing notes, moving notes, deleting notes
- Each moved note can be undone individually

## Snap Division

### Changing Snap
- **[ key**: Decrease snap (more precise)
- **] key**: Increase snap (less precise)
- Or use toolbar dropdown

### Snap Values
- 4, 8, 12, 16, 24, 32, 48, 64, 96, 192
- Grid lines change color based on snap
- Notes automatically snap when placed or moved

## Playback

### Transport Controls
- **Space**: Play/Pause audio
- Playback controls in top bar also work
- Current position shown as white line on highway

### Note: Audio Loading Not Yet Implemented
- Audio playback will work once file I/O is added
- For now, can place notes without audio

## Visual Guide

### Note Colors (by Lane)
- Lane 0: **Green**
- Lane 1: **Red**
- Lane 2: **Yellow**
- Lane 3: **Blue**
- Lane 4: **Orange**

### Selection Indicators
- **White outline** (2px): Normal note
- **Yellow outline** (3px): Selected note
- **Brightened color**: Selected note
- **Blue rectangle**: Selection box (while dragging)

### Grid Lines
- **Thin gray**: Snap divisions
- **Medium gray**: Beat lines
- **Thick gray**: Measure lines (every 4 beats)

## Keyboard Shortcuts Summary

| Key | Action |
|-----|--------|
| 1-5 | Place note in lane |
| Left-click | Place/select note |
| Right-click | Delete note |
| Ctrl+Click | Multi-select toggle |
| Shift+Click drag | Selection box |
| Delete | Delete selected notes |
| Ctrl+A | Select all |
| Escape | Clear selection |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Space | Play/Pause |
| [ ] | Adjust snap |

## Common Workflows

### Workflow 1: Placing a Pattern
1. Adjust snap division with [ ] keys
2. Press 1, 2, 3, 4, 5 keys in rhythm
3. Notes appear at playback position
4. Use Ctrl+Z if you make a mistake

### Workflow 2: Fixing Timing
1. Shift+Click and drag box around notes
2. All notes selected (yellow outline)
3. Drag selection up or down
4. Release to commit - timing adjusted

### Workflow 3: Deleting Section
1. Shift+Click and drag to select range
2. Press Delete key
3. All notes in selection removed
4. Ctrl+Z to undo if needed

### Workflow 4: Copying Pattern (Coming Soon)
- Copy/paste not yet implemented
- For now: place notes manually or use undo/redo

## Tips & Tricks

**Precise Placement**
- Use smaller snap divisions ([ key) for detailed timing
- Use larger snap divisions (] key) for simple patterns

**Fast Editing**
- Keyboard 1-5 keys are fastest for rhythm sections
- Mouse for precise positioning and complex patterns

**Selection Shortcuts**
- Double-click could select all notes at same tick (not yet implemented)
- Ctrl+A then drag moves entire chart

**Undo Strategy**
- Each action is individually undoable
- Moving 10 notes creates 10 undo steps
- Experiment freely - always can undo

## Troubleshooting

**Notes Not Appearing**
- Check that you're in the chart view (not 3D preview)
- Try scrolling the canvas (not yet implemented - use mouse wheel once added)

**Can't Select Notes**
- Make sure you're clicking near the note position
- Try clicking exactly on the note rectangle
- Selection tolerance is half a snap division

**Drag Not Working**
- Click on a selected note to start drag
- If note isn't selected, click once to select, then drag

**Delete Key Not Working**
- Make sure editor window has focus
- Check that notes are actually selected (yellow outline)

## Known Limitations (Current Version)

- ❌ No scrolling with mouse wheel yet
- ❌ No zoom controls yet
- ❌ No copy/paste yet
- ❌ No sustain notes (all notes are instant)
- ❌ No file save/load yet
- ❌ No BPM changes yet
- ❌ No audio waveform display
- ❌ Selection box doesn't add to selection (always replaces)

## Coming Soon

**Next Features**:
- Mouse wheel scrolling
- Chart file save/load
- Sustain note creation (click and drag up)
- BPM change markers
- Timeline scrubbing
- Copy/paste notes
- Zoom in/out controls

## Getting Help

If you encounter issues:
1. Check this guide for common solutions
2. Review the implementation docs in Documentation/
3. Check the console for error messages (F4 in Godot)

## Learning the Interface

**5-Minute Quick Test**:
1. Press 1-2-3-4-5 to see notes appear
2. Shift+drag box around notes
3. Drag selected notes up/down
4. Press Delete
5. Press Ctrl+Z multiple times to undo

**10-Minute Practice**:
1. Set snap to 16 (toolbar or ]] keys)
2. Place a simple rhythm pattern with 1-5 keys
3. Select some notes with Ctrl+Click
4. Move them to different lanes
5. Create selection box to select range
6. Delete and undo several times

You should now be comfortable with the basic editing workflow!
