# MIDI System Architecture

## Overview
The MIDI system enables playback of rhythm game charts stored in MIDI format with multiple synchronized audio tracks (drums, bass, guitar, vocals, etc.).

## Key Challenges Solved
1. **Multiple Audio Tracks**: MIDI songs often have separate audio files for each instrument
2. **MIDI Note Mapping**: Converting MIDI note events to game lanes/frets
3. **Track Synchronization**: Keeping all audio tracks in sync during playback, pause, seek
4. **Track Detection**: Identifying which MIDI tracks contain playable notes vs metadata

## Architecture Components

### 1. MidiTrackManager (New)
**Location**: `Scripts/Audio/MidiTrackManager.gd`
**Responsibility**: Manages multiple audio tracks for MIDI songs

```gdscript
class_name MidiTrackManager
- Properties:
  - audio_tracks: Dictionary[String, AudioStreamPlayer] # "bass.ogg" -> player
  - master_time: float
  - is_playing: bool
  - is_paused: bool
  
- Methods:
  - load_tracks(folder_path: String, track_files: Array[String])
  - play(offset: float = 0.0)
  - pause()
  - resume()
  - stop()
  - seek(time: float)
  - get_playback_position() -> float
  - set_track_volume(track_name: String, volume_db: float)
  - set_track_enabled(track_name: String, enabled: bool)
```

### 2. MidiParser (Refactored)
**Location**: `Scripts/Parsers/MidiParser.gd`
**Changes**:
- Use `MidiFileParser` class from the example code
- Properly extract note events from MIDI tracks
- Map MIDI notes to game lanes based on standard Guitar Hero MIDI mapping:
  - Expert: Notes 96-100 (lanes 0-4), 103 (open)
  - Hard: Notes 84-88, 91 (open)
  - Medium: Notes 72-76, 79 (open)
  - Easy: Notes 60-64, 67 (open)
  - Forced HOPO: +5 from base note
  - Tap notes: +6 from base note

### 3. MidiAudioLoader (New)
**Location**: `Scripts/Audio/MidiAudioLoader.gd`
**Responsibility**: Scan and load audio files for MIDI songs

```gdscript
class_name MidiAudioLoader
- Methods:
  - scan_audio_files(folder_path: String) -> Array[AudioTrackInfo]
  - AudioTrackInfo:
    - file_path: String
    - track_type: TrackType (DRUMS, BASS, GUITAR, VOCALS, BACKING, SONG)
    - volume_multiplier: float
```

### 4. ChartLoadingService (Enhanced)
**Changes**:
- Add `audio_tracks: Array[AudioTrackInfo]` to ChartData class
- Detect MIDI files and call MidiAudioLoader
- Store multiple audio tracks instead of single music_stream

## Data Flow

### Loading Phase
```
1. ChartLoadingService.load_chart_data()
   ↓
2. Detect MIDI file (.mid/.midi)
   ↓
3. MidiParser.load_chart() using MidiFileParser
   ↓
4. Extract notes using proper MIDI note mapping
   ↓
5. MidiAudioLoader.scan_audio_files()
   ↓
6. Return ChartData with audio_tracks array
```

### Gameplay Phase
```
1. gameplay.gd checks if chart has multiple audio_tracks
   ↓
2. If MIDI: Create MidiTrackManager
   ↓
3. MidiTrackManager.load_tracks(audio_tracks)
   ↓
4. Start countdown
   ↓
5. MidiTrackManager.play()
   ↓
6. All tracks play in sync
   ↓
7. Timeline sync uses MidiTrackManager.get_playback_position()
```

## File Structure

MIDI songs follow this structure:
```
Assets/Tracks/Artist - Song Name/
├── notes.mid          # MIDI chart with note data
├── song.ini           # Metadata (title, artist, difficulties)
├── album.png          # Album art
├── song.ogg           # Full song mix (optional)
├── bass.ogg           # Bass track
├── drums_1.ogg        # Drums track 1 (kick/snare)
├── drums_2.ogg        # Drums track 2 (toms)
├── drums_3.ogg        # Drums track 3 (cymbals)
├── drums_4.ogg        # Drums track 4 (optional)
├── guitar.ogg         # Guitar track
├── vocals.ogg         # Vocal track
└── crowd.ogg          # Crowd noise (optional)
```

## MIDI Note Mapping (Guitar Hero Standard)

### Note Numbers by Difficulty
| Difficulty | Green | Red | Yellow | Blue | Orange | Open |
|-----------|-------|-----|--------|------|--------|------|
| Expert    | 96    | 97  | 98     | 99   | 100    | 103  |
| Hard      | 84    | 85  | 86     | 87   | 88     | 91   |
| Medium    | 72    | 73  | 74     | 75   | 76     | 79   |
| Easy      | 60    | 61  | 62     | 63   | 64     | 67   |

### Special Notes
- **HOPO (Hammer-on/Pull-off)**: Base note + 5
- **Tap**: Base note + 6
- **Star Power**: Note 116 (any difficulty)

### Track Assignment
- **PART GUITAR**: MIDI Track labeled "PART GUITAR"
- **PART BASS**: MIDI Track labeled "PART BASS"  
- **PART DRUMS**: MIDI Track labeled "PART DRUMS"
- **PART KEYS**: MIDI Track labeled "PART KEYS"

## Implementation Priority

1. ✅ Design architecture
2. Create MidiTrackManager
3. Refactor MidiParser
4. Create MidiAudioLoader
5. Update ChartLoadingService
6. Integrate into gameplay.gd
7. Update song_select.gd
8. Test with example song
9. Documentation

## Testing Strategy

Test with "Franz Ferdinand - Take Me Out":
- Verify all 7 audio tracks load
- Verify tracks stay synchronized
- Verify seeking works across all tracks
- Verify pause/resume works
- Verify notes spawn at correct times
- Verify note mapping is accurate

## Future Enhancements
- Per-track volume controls in settings
- Track muting/soloing during gameplay
- Visual track level meters
- Support for RB3 CON format
- Support for Phase Shift format
