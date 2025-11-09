I want my chart editor to be almost exactly like Moonscraper, a Clone Hero chart editor tool.
Currently, I already have gameplay in my game. The gameplay scene already has a chart runway, and notes. The gameplay UI can be reused for the chart editing scene. I'd copy the gameplay runway setup, and then just add the chart editing UI features on. Gameplay also has playback logic (for spawning notes), so you could possibly reuse some of that logic as well.

For the chart editor scene, good design would be to have many of the UI separated into individual components (.gd and .tscn for each one) so that the chart editor scene doesn't have to be so large.

For important things in the chart editor, the basic logic of placing notes and then being able to TEST the song right after is VERY IMPORTANT. Also, there should be logic so the user can drag a playback timeline forwards and backwards, and the notes will move according to the scrubbing of the timeline.

Note placement should be snappy (1/4, 1/8, etc.). Also, there should be placement preview ON THE RUNWAY to show the user where they are placing notes (mainly if they are clicking and dragging). User should be able to select notes by click and drag. I also believe for things like hold notes, there is a tool in moonscraper to change the length and stuff.

Some things that may need to be addressed as we work on the chart editing system:
- The way notes work, they have movement logic in their own class in process. They update their own position. But with the chart editor, we obviously want a way to stop the movement, and also scrub the timeline (which would move the note positions).
- It may be beneficial to have a note controller and note visuals separated
- Note spawning and pooling. In gameplay this is fine, but with the editor, because the user is going to be moving the timeline alot and changing time in the song, we may need a different way of doing it. I am curious of how Moonscraper handles this, so I'd look into that.

All the other moonscraper features should be in my system, but I need the important ones to WORK correctly the first time.

### Moonscraper Core Features

#### 1. **User Interface**
- **Main View:** Vertical scrolling note highway (similar to gameplay view)
- **Lanes:** 5 lanes for guitar/bass (Green, Red, Yellow, Blue, Orange)
- **Timeline:** Horizontal timeline showing measures, beats, and time
- **Tool Panels:** 
  - Left side: Note type selection (Note, HOPO, Tap, Star Power, etc.)
  - Right side: Chart properties and metadata
  - Bottom: Playback controls and transport

#### 2. **Note Placement System**
- **Keyboard Shortcuts:** Number keys 1-5 to place notes in lanes
- **Mouse Placement:** Click and drag to place and adjust notes
- **Snap-to-Grid:** Configurable snap divisions (1/4, 1/8, 1/12, 1/16, 1/24, 1/32, 1/64 notes)
- **Multi-Note Chords:** Hold multiple keys to place chord notes
- **Sustain Notes:** Click and drag to create hold notes

#### 3. **Playback Controls**
- **Speed Control:** Adjustable from 5% to 100% speed
- **Seek Controls:** Click timeline to jump, or use skip forward/backward
- **Audio Sync:** Visual metronome and click track
- **Real-time Preview:** Notes scroll as in actual gameplay

#### 4. **Chart Management**
- **Multiple Difficulties:** Easy, Medium, Hard, Expert per instrument
- **Multiple Instruments:** Lead Guitar, Bass, Rhythm, Drums, Keys, GHL (Guitar Hero Live 6-button)
- **BPM Changes:** Visual BPM markers, support for tempo changes
- **Time Signature:** Support for various time signatures (4/4, 3/4, 7/8, etc.)

#### 5. **File Format Support**
- **Primary Format:** .chart (Clone Hero format)
- **Import:** .mid (MIDI), .chart
- **Export:** .chart
- **Audio Formats:** .ogg, .mp3, .wav

#### 6. **Advanced Features**
- **Section Markers:** Named sections for practice mode
- **Events:** Crowd events, lighting cues
- **Star Power Paths:** Optimize star power activation timing
- **Chart Validation:** Warns about common charting mistakes
- **Note Density Graphs:** Visual representation of difficulty over time

### Workflow

1. **Project Setup:**
   - Create new chart or load existing
   - Select audio file
   - Set initial BPM and time signature

2. **Sync Setup:**
   - Use audio waveform to identify beats
   - Place BPM markers at tempo changes
   - Set offset for audio alignment

3. **Charting:**
   - Select difficulty and instrument
   - Place notes using keyboard (1-5) while audio plays
   - Adjust note placement and sustain lengths
   - Add special notes (HOPO, tap, star power)

4. **Testing:**
   - Use preview mode to play chart
   - Adjust based on feel and playability
   - Iterate quickly with hotkeys

5. **Finalization:**
   - Add metadata (song name, artist, charter)
   - Validate chart for errors
   - Export to .chart format

### Notable Keyboard Shortcuts

| Action | Shortcut | Description |
|--------|----------|-------------|
| Play/Pause | Space | Toggle audio playback |
| Place Note | 1-5 | Place note in corresponding lane |
| Delete Note | Delete | Remove selected note |
| Snap Increment | ] | Increase snap division |
| Snap Decrement | [ | Decrease snap division |
| Undo | Ctrl+Z | Undo last action |
| Redo | Ctrl+Y | Redo last undone action |
| Save | Ctrl+S | Save chart |
| Select Tool | Q/W/E/R | Switch between note types |

### Technical Architecture

Built in Unity, Moonscraper uses:
- **Audio Engine:** BASS audio library (commercial, free for non-commercial)
- **File Parsing:** Custom .chart and .mid parsers
- **Rendering:** Unity's 2D rendering for highway view
- **Input System:** Unity's old input system with extensive key binding

### Strengths

1. ✅ **Mature and Stable:** Years of development, proven in production
2. ✅ **Feature-Complete:** Supports all Clone Hero features
3. ✅ **Fast Workflow:** Keyboard shortcuts make note placement very quick
4. ✅ **Good Visualization:** Clear note highway and waveform display
5. ✅ **Active Community:** Regular updates, Discord support

### Weaknesses

1. ❌ **Steep Learning Curve:** Many keyboard shortcuts to memorize
2. ❌ **Unity Dependency:** Requires Unity runtime and BASS license
3. ❌ **Windows-Centric:** Mac/Linux support exists but less polished
4. ❌ **UI Complexity:** Dense interface with many panels
5. ❌ **Limited Automation:** Manual note placement only