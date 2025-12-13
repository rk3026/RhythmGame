# Rhythm Game

A 3D rhythm game inspired by Guitar Hero and Rock Band, built with Godot 4. This project features a complete gameplay system with note highways, scoring mechanics, visual effects, and a comprehensive chart editor for creating custom songs.

## Description

This is a fully-featured 3D rhythm game where players hit notes in time with music as they travel down a 3D highway. The game includes a robust profile system with progression tracking, achievements, and customization options. Players can enjoy existing songs or create their own using the built-in chart editor. The game supports multiple chart formats including .chart files and MIDI format, with multi-track audio support for an authentic rhythm game experience.

## Key Features

### Gameplay
- 3D note highway with smooth animations and visual effects
- Comprehensive scoring system with combo multipliers and accuracy-based scoring
- Limit Break system for score multipliers (inspired by Final Fantasy VII)
- Multiple difficulty levels (Easy, Medium, Hard, Expert)
- Real-time hit feedback with particle effects and screen shake
- Lane lighting effects and note trails for enhanced visuals
- Sound effects for hits, misses, and UI interactions

### Profile System
- Multiple player profile support with individual progression
- XP-based leveling system with rewards
- Achievement tracking and unlocking
- Profile customization (avatars, themes, colors, titles)
- Comprehensive statistics tracking (total notes hit, accuracy, playtime, etc.)
- Profile export/import for backup and transfer between systems

### Chart Editor
- Full-featured in-game chart editor for creating custom songs
- Waveform visualization for precise note placement
- Grid snapping with customizable beat divisions
- Note placement, deletion, and editing tools
- Playback testing directly in the editor
- Support for hold notes (sustains)
- BPM and offset configuration
- Export to .chart format

### Audio System
- Multi-track MIDI audio support (guitar, bass, drums, keys, vocals)
- Individual instrument volume controls
- Synchronized playback with gameplay
- Support for .ogg and .wav audio formats
- MiniaudioGD extension for high-quality audio decoding

### Song Support
- .chart format support (Clone Hero compatible)
- MIDI format support (Guitar Hero format)
- Automatic chart parsing and validation
- Song metadata display (title, artist, charter, album art)
- Multiple song folders organization

### Visual Effects
- Dynamic camera shake based on gameplay intensity
- Post-processing effects during Limit Break
- Particle systems for note hits and special events
- Lane lighting synchronized with gameplay
- Animated UI elements with smooth transitions

## Technical Highlights

- Modular architecture with singleton managers for core systems
- Object pooling for performance optimization
- Custom GDExtension (MiniaudioGD) for advanced audio decoding
- Event-driven design with signal-based communication
- Comprehensive unit testing with GdUnit4
- Resource caching system for efficient asset loading

## Installation

### Download the Game
1. Go to the [Releases page](https://github.com/rk3026/RhythmGame/releases)
2. Download the latest Windows release (`.zip` file)
3. Extract the zip file to a folder of your choice
4. Run `RhythmGame.exe` to start the game

No additional software or dependencies required.

## How to Play

### First Time Setup
1. Launch the game by running `RhythmGame.exe`
2. Create a new profile or select an existing one
3. Configure your settings (key bindings, note speed, audio volume)
4. Select a song from the song select screen
5. Choose your difficulty and start playing

## How to Play

### Controls (Default)
- Green (F1): D
- Red (F2): F
- Yellow (F3): J
- Blue (F4): K
- Orange (F5): L
- Limit Break: Spacebar
- Pause: Escape/P

All key bindings can be customized in the Settings menu.

### Gameplay
1. Notes travel down the highway toward the strike line at the bottom
2. Press the corresponding key when the note reaches the strike line
3. Hold keys for sustain notes (long notes with tails)
4. Build combos by hitting consecutive notes without missing
5. Fill the Limit Break meter by hitting notes accurately
6. Activate Limit Break for a 2x score multiplier when the meter is full

### Scoring
- Perfect Hit: Full points, combo continues
- Great Hit: Reduced points, combo continues
- Good Hit: Further reduced points, combo continues
- Miss: No points, combo resets

## Adding Custom Songs

### .chart Format
1. Place your song folder in the `Assets/Tracks/` directory
2. Each song folder should contain:
   - `notes.chart` - The chart file with note data
   - `song.ini` - Metadata file with song information
   - `song.ogg` (or other audio format) - The audio file
   - `album.png` (optional) - Album artwork

### MIDI Format
1. Place your MIDI song folder in `Assets/Tracks/`
2. Required files:
   - `notes.mid` - MIDI chart file (Guitar Hero format)
   - `song.ini` - Song metadata
   - Audio tracks (.ogg format): `guitar.ogg`, `bass.ogg`, `drums.ogg`, etc.
3. The game automatically detects and mixes available instrument tracks

See the `Documentation/MIDI-System-User-Guide.md` for detailed instructions.

## Using the Chart Editor

1. From the main menu, navigate to the Chart Editor
2. Load an audio file or create a new chart
3. Set the BPM and audio offset
4. Place notes by clicking on the grid at the desired time and lane
5. Use the playback controls to test your chart
6. Save your chart to the `Assets/Tracks/` directory

## Project Structure

- `/Assets` - Game assets (audio, textures, data files, tracks)
- `/Scenes` - Godot scene files (.tscn)
- `/Scripts` - GDScript source files
- `/Documentation` - Technical documentation and architecture diagrams
- `/test` - Unit tests using GdUnit4
- `/addons` - Third-party plugins and extensions

## Development

### For Developers
If you want to modify the game for yourself:

1. Clone this repository:
   ```bash
   git clone https://github.com/rk3026/RhythmGame.git
   ```
2. Open the project in Godot Engine 4.5+
3. The project will automatically import all assets on first load

### Testing
The project uses GdUnit4 for unit testing. Tests are located in the `/test` folder and cover core gameplay mechanics, scoring systems, and data management.

## Development Status

This project is actively developed and currently in alpha.

## License

This project is available under the MIT License. See LICENSE file for details.

## Credits

Built with Godot Engine 4.5
Uses MiniaudioGD extension for audio decoding
Inspired by Guitar Hero, Rock Band, and Clone Hero