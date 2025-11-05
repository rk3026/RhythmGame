# Chart Editor - Audio Loading Implementation

## Feature Overview
Implemented the audio file loading functionality for the chart editor, connecting the existing UI (Browse button in the side panel) to the actual file selection and audio loading logic.

## Problem Addressed
Previously, users could not load audio files into the chart editor, which prevented playback testing. The UI had a "Browse..." button in the Metadata tab, but it wasn't connected to any functionality. When clicking Play, the console would show "No audio loaded for playback".

## Implementation Details

### 1. File Dialog Setup
Added a `FileDialog` instance to the chart editor that supports multiple audio formats:
- **OGG**: `.ogg` files (using `AudioStreamOggVorbis.load_from_file()`)
- **MP3**: `.mp3` files (using `load()`)
- **WAV**: `.wav` files (using `load()`)

```gdscript
func _setup_file_dialogs():
	audio_file_dialog = FileDialog.new()
	audio_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	audio_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_file_dialog.filters = PackedStringArray([
		"*.ogg ; OGG Audio Files", 
		"*.mp3 ; MP3 Audio Files", 
		"*.wav ; WAV Audio Files"
	])
	audio_file_dialog.title = "Select Audio File"
	audio_file_dialog.size = Vector2i(800, 600)
	audio_file_dialog.file_selected.connect(_on_audio_file_selected)
	add_child(audio_file_dialog)
```

### 2. Signal Connections
Connected the existing `audio_file_requested` signal from `EditorSidePanel`:

```gdscript
side_panel.audio_file_requested.connect(_on_audio_file_requested)
```

This signal is emitted when the user clicks the "Browse..." button in the Metadata tab.

### 3. File Selection Handler
When the user selects an audio file:

```gdscript
func _on_audio_file_selected(path: String):
	# 1. Load the audio stream based on file extension
	var audio_stream = null
	var extension = path.get_extension().to_lower()
	
	match extension:
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		"mp3", "wav":
			audio_stream = load(path)
	
	# 2. Set the audio player stream
	audio_player.stream = audio_stream
	
	# 3. Update chart metadata
	chart_data.set_metadata("audio_file", path)
	
	# 4. Update UI (side panel shows filename)
	side_panel.set_audio_file(path)
	
	# 5. Update playback controls with audio duration
	playback_controls.set_duration(audio_stream.get_length())
```

### 4. Data Flow
```
User Action: Click "Browse..." button
      ↓
EditorSidePanel emits: audio_file_requested signal
      ↓
ChartEditor: Shows FileDialog
      ↓
User Action: Select audio file
      ↓
FileDialog emits: file_selected(path) signal
      ↓
ChartEditor: 
  - Load AudioStream from file
  - Set AudioStreamPlayer.stream
  - Update ChartDataModel metadata
  - Update side panel UI
  - Set playback controls duration
```

## UI Integration

### Metadata Tab (EditorSidePanel)
The existing UI already had:
- **Label**: "Audio File:"
- **LineEdit**: Shows currently loaded audio file (read-only)
- **Button**: "Browse..." (triggers file dialog)

These components are now fully functional:
```
Audio File:
┌────────────────────────────────────────┐
│ C:/Music/song.ogg                      │ (shows selected file)
└────────────────────────────────────────┘
┌──────────────┐
│  Browse...   │ (opens file dialog)
└──────────────┘
```

## User Workflow

### Loading Audio
1. Open chart editor (F6)
2. Look at the right side panel
3. Click the "Metadata" tab (if not already selected)
4. Scroll to the "Audio File" section
5. Click the "Browse..." button
6. Navigate to your audio file (.ogg, .mp3, or .wav)
7. Select the file and click "Open"
8. The audio file path appears in the text field
9. Press Play button to start playback with notes

### Playback Testing
Once audio is loaded:
- The Play button will work (previously showed "No audio loaded for playback")
- The timeline scrubber shows the full audio duration
- Notes spawn and move in sync with the audio
- You can scrub through the timeline to test different sections

## Error Handling

The implementation includes error checking for:
1. **File existence**: Verifies file exists before loading
2. **Unsupported formats**: Shows error for non-audio files
3. **Loading failures**: Reports if audio stream creation fails

```gdscript
if not FileAccess.file_exists(path):
	push_error("Audio file not found: " + path)
	return

if not audio_stream:
	push_error("Failed to load audio file: " + path)
	return
```

## Benefits

### For Users
✅ **Easy audio loading**: One-click file dialog interface  
✅ **Multiple formats**: Support for OGG, MP3, and WAV  
✅ **Visual feedback**: Shows loaded filename in UI  
✅ **Playback testing**: Can immediately test charted notes with audio  
✅ **Timeline sync**: Scrubber automatically scales to audio duration  

### For Development
✅ **Reused existing UI**: No new scene components needed  
✅ **Leveraged signals**: Clean signal-based architecture  
✅ **Metadata integration**: Audio path stored in chart metadata  
✅ **Extensible**: Easy to add more audio formats in the future  

## Technical Notes

### Audio Format Loading
- **OGG files**: Use `AudioStreamOggVorbis.load_from_file()` for better performance
- **MP3/WAV files**: Use generic `load()` which handles both formats
- **Extension detection**: Case-insensitive via `.to_lower()`

### File Path Storage
The selected audio file path is stored in:
1. **ChartDataModel metadata**: `chart_data.metadata["audio_file"]`
2. **UI state**: `EditorSidePanel.audio_file_edit.text`

When saving the chart (future implementation), this path will be serialized so audio loads automatically when reopening the chart.

### Duration Sync
The playback controls automatically update their duration when audio is loaded:
```gdscript
playback_controls.set_duration(audio_stream.get_length())
```

This ensures the timeline scrubber's maximum value matches the audio length, enabling accurate seeking.

## Testing Checklist

- [x] Browse button opens file dialog
- [x] File dialog filters show only audio files
- [x] Selecting OGG file loads successfully
- [x] Selecting MP3 file loads successfully
- [x] Selecting WAV file loads successfully
- [x] Audio file path displays in side panel
- [x] Play button works after loading audio
- [x] Timeline duration matches audio length
- [x] Notes spawn during playback
- [x] Audio and notes stay synchronized

## Future Enhancements

### Potential Improvements
1. **Recent files list**: Show recently used audio files for quick access
2. **Drag-and-drop**: Allow dragging audio files directly onto the editor
3. **Audio preview**: Play a snippet before loading
4. **Waveform display**: Show audio waveform in the timeline
5. **Auto-load**: Remember last used audio file per chart
6. **Relative paths**: Store paths relative to chart file for portability

### Chart Saving Integration
When chart saving is implemented, the audio file path should:
- Be stored in the `.chart` file metadata
- Use relative paths when possible (for portability)
- Auto-load when opening a saved chart

---
**Date**: 2025-01-05  
**Feature**: Audio file loading for chart editor  
**Status**: ✅ IMPLEMENTED
