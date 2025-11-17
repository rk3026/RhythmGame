# MIDI System User Guide

## Overview
The rhythm game now supports MIDI format songs with multiple instrument audio tracks. This guide explains how to add MIDI songs to your game and troubleshoot common issues.

## Supported MIDI Format
The game uses **Guitar Hero MIDI format** with the following specifications:
- Standard MIDI file format (.mid or .midi extension)
- Instrument tracks: PART GUITAR, PART BASS, PART DRUMS, PART KEYS
- Difficulty levels: Expert (notes 96-103), Hard (84-91), Medium (72-79), Easy (60-67)
- Separate audio files for each instrument track

## File Structure Requirements

### MIDI Song Folder Layout
Each MIDI song should be in its own folder with the following structure:

```
Song Folder/
├── notes.mid          # MIDI chart file (required)
├── song.ini           # Song metadata (required)
├── guitar.ogg         # Guitar audio track
├── bass.ogg           # Bass audio track
├── drums_1.ogg        # Drums audio track (or drums.ogg)
├── drums_2.ogg        # Additional drum tracks (optional)
├── drums_3.ogg
├── drums_4.ogg
├── vocals.ogg         # Vocals audio track
├── keys.ogg           # Keys audio track (optional)
├── crowd.ogg          # Crowd/backing audio (optional)
└── album.png          # Album art (optional)
```

### Required Files
1. **notes.mid**: The MIDI file containing note data for all instruments and difficulties
2. **song.ini**: Metadata file with song information (title, artist, etc.)
3. **Audio files**: At least one .ogg audio file for playback

### Audio File Naming Conventions
The system automatically detects audio files based on their names:

| File Name Pattern | Track Type | Default Volume |
|-------------------|------------|----------------|
| drum*, drums*     | DRUMS      | 1.0            |
| bass*             | BASS       | 1.0            |
| guitar*, gtr*     | GUITAR     | 1.0            |
| vocal*, vox*      | VOCALS     | 0.9            |
| key*, keys*, piano* | KEYS     | 0.8            |
| crowd*            | BACKING    | 0.6            |
| song*             | SONG       | 1.0 (fallback) |

**Note**: File names are case-insensitive. Patterns use wildcards, so `Drums_1.ogg`, `DRUMS.ogg`, and `drum_track.ogg` all match.

## How to Add a MIDI Song

### Step 1: Prepare Your Files
1. Obtain a Guitar Hero MIDI file (.mid or .midi)
2. Export separate audio tracks for each instrument in .ogg format
3. Name audio files according to the conventions above
4. Create a song.ini file with metadata

### Step 2: Create Song Folder
1. Navigate to `Assets/Tracks/` in your project
2. Create a new folder: `Artist - Song Title [Charter Name]`
3. Place all files in this folder

### Step 3: Verify MIDI Chart
Your MIDI file should contain:
- Track names: "PART GUITAR", "PART BASS", "PART DRUMS", or "PART KEYS"
- Notes in the correct ranges for each difficulty
- Tempo events (SET_TEMPO meta events)

### Step 4: Test in Game
1. Launch the game
2. Navigate to Song Select
3. Your MIDI song should appear in the list
4. Select the song and choose an instrument
5. Play and verify all audio tracks sync correctly

## MIDI Note Mapping

### Guitar Hero MIDI Standard
Each difficulty uses a specific range of MIDI notes:

| Difficulty | Green | Red | Yellow | Blue | Orange | Open |
|------------|-------|-----|--------|------|--------|------|
| Expert     | 96    | 97  | 98     | 99   | 100    | 103  |
| Hard       | 84    | 85  | 86     | 87   | 88     | 91   |
| Medium     | 72    | 73  | 74     | 75   | 76     | 79   |
| Easy       | 60    | 61  | 62     | 63   | 64     | 67   |

### Special Note Modifiers
- **HOPO (Hammer-On/Pull-Off)**: Base note + 5
- **TAP**: Base note + 6
- **Star Power**: MIDI note 116 (activates on current note)

## Troubleshooting

### Song Doesn't Appear in Song Select
**Possible Causes:**
- MIDI file is not named `notes.mid` or `notes.midi`
- Folder is not in `Assets/Tracks/`
- MIDI file is corrupted or invalid format

**Solutions:**
- Verify file naming matches exactly
- Check folder location
- Open MIDI file in a MIDI editor to verify it's valid

### No Audio Plays During Gameplay
**Possible Causes:**
- Audio files are not in .ogg format
- Audio file names don't match naming conventions
- Audio files are corrupted

**Solutions:**
- Convert audio to .ogg format using Audacity or similar tool
- Rename files to match patterns (e.g., `guitar.ogg`, `bass.ogg`)
- Re-export audio files and test in media player first

### Audio Tracks Are Out of Sync
**Possible Causes:**
- Audio files have different start times or durations
- MIDI offset is incorrect
- Audio sample rates differ between tracks

**Solutions:**
- Ensure all audio files start at the same point (0:00)
- Adjust offset in song.ini if needed
- Re-export all audio with same sample rate (44100 Hz recommended)

### Notes Don't Spawn or Spawn Incorrectly
**Possible Causes:**
- MIDI notes are outside expected ranges
- Wrong difficulty selected
- Instrument track missing or misnamed in MIDI

**Solutions:**
- Verify note ranges match the table above
- Check MIDI track names include "PART GUITAR", "PART BASS", etc.
- Use a MIDI editor to verify notes are on correct tracks

### Only Some Instrument Tracks Play
**Possible Causes:**
- Missing audio files for certain instruments
- Audio file naming doesn't match conventions

**Solutions:**
- Check all expected audio files are present
- Verify file names match patterns exactly
- Ensure files are not hidden or have wrong extensions

## Advanced Features

### Multi-Track Audio Sync
The `MidiTrackManager` automatically synchronizes all audio tracks:
- Tracks are synced every frame within 50ms tolerance
- Automatic resyncing if drift exceeds threshold
- Pause/resume maintains sync across all tracks

### Individual Track Volume Control
Volume multipliers are applied per track type:
- Use MidiTrackManager.set_track_volume(track_index, volume)
- Volume range: 0.0 (mute) to 1.0 (full)
- Changes apply immediately during playback

### Track Enable/Disable
Individual tracks can be enabled or disabled:
- Use MidiTrackManager.set_track_enabled(track_index, enabled)
- Useful for practice modes (mute specific instruments)
- Changes apply without restarting audio

## Example: Franz Ferdinand - Take Me Out

This song demonstrates the full MIDI multi-track system:

```
Franz Ferdinand - Take Me Out/
├── notes.mid
├── song.ini
├── bass.ogg
├── drums_1.ogg
├── drums_2.ogg
├── drums_3.ogg
├── drums_4.ogg
├── guitar.ogg
├── vocals.ogg
└── album.png
```

**Instruments Available:** Guitar, Bass, Drums  
**Difficulties:** Expert, Hard, Medium, Easy  
**Audio Tracks:** 7 synchronized streams

## Technical Details

### Audio Loading Process
1. ChartLoadingService detects .mid/.midi extension
2. MidiAudioLoader scans folder for audio files
3. Files are classified by name pattern
4. AudioTrackInfo objects created with path, type, volume
5. MidiTrackManager loads and synchronizes all tracks

### MIDI Parsing Flow
1. MidiFileParser loads and parses MIDI file
2. MidiParser extracts instrument tracks by name
3. Note events filtered by difficulty range
4. Notes converted to game format (tick, lane, type)
5. Tempo events extracted for timing calculations

### Performance Considerations
- Each audio track uses one AudioStreamPlayer node
- All tracks synced in _process() loop
- Drift correction only triggers if >50ms out of sync
- Memory usage scales with number of audio tracks

## Best Practices

### For Charters
1. Always include tempo events in MIDI for accurate timing
2. Use consistent track naming: "PART [INSTRUMENT]"
3. Export audio at same sample rate and bit depth
4. Align audio start times precisely
5. Include multiple difficulties for better player experience

### For Players
1. Verify audio files play correctly before importing
2. Keep song folders organized with clear naming
3. Backup original files before editing
4. Test new songs in-game before competitive play

### For Developers
1. Use MidiAudioLoader for consistent audio detection
2. Let MidiTrackManager handle all sync logic
3. Check chart_data.is_midi before accessing audio_tracks
4. Always provide fallback for missing audio files

## Related Documentation
- [MIDI-System-Architecture.md](./MIDI-System-Architecture.md) - Technical architecture and design
- [Core Infrastructure.md](./Core%20Infrastructure.md) - Game infrastructure overview
- [Plan.md](./Plan.md) - Development roadmap

## Support
For issues or questions:
1. Check troubleshooting section above
2. Review MIDI file in editor for correctness
3. Verify audio files play correctly in media player
4. Consult MIDI-System-Architecture.md for technical details
