# Rhythm Game Chart Editor Research Document

**Document Purpose:** Comprehensive research on existing rhythm game chart editors to inform the design and implementation of our chart creation system for RhythmGame.

**Date Created:** November 3, 2025  
**Author:** Research conducted via web analysis  
**Status:** Complete - Ready for design reference

---

## Executive Summary

This document provides an in-depth analysis of chart editing tools used across the rhythm game ecosystem. The research covers standalone editors like Moonscraper Chart Editor, integrated editors like StepMania's built-in tools, and modern editors from games like osu! and Rhythm Doctor. The goal is to identify best practices, common patterns, and innovative features that should inform our own chart editor implementation.

### Key Findings

1. **Interface Patterns:** Most successful editors use a vertical scrolling "highway" or "timeline" view with snap-to-grid, playback controls, and keyboard shortcuts for rapid note placement
2. **File Formats:** Industry standard formats (.chart, .mid) are text-based and human-readable for version control
3. **Workflow:** Successful editors emphasize quick iteration - place notes, test immediately, adjust, repeat
4. **Essential Features:** Audio waveform display, adjustable playback speed (0.25x-2.0x), comprehensive undo/redo, and metronome/click track
5. **Advanced Features:** Auto-charting tools, difficulty generators, note density visualization, and chart validation

---

## Table of Contents

1. [Tool Analysis Overview](#tool-analysis-overview)
2. [Moonscraper Chart Editor](#moonscraper-chart-editor-detailed-analysis)
3. [StepMania Editor](#stepmania-editor-detailed-analysis)
4. [osu! Beatmap Editor](#osu-beatmap-editor-detailed-analysis)
5. [Rhythm Doctor Level Editor](#rhythm-doctor-level-editor)
6. [Clone Hero Ecosystem](#clone-hero-ecosystem)
7. [YARG (Yet Another Rhythm Game)](#yarg-yet-another-rhythm-game)
8. [Common Design Patterns](#common-design-patterns)
9. [Feature Comparison Matrix](#feature-comparison-matrix)
10. [Best Practices for Implementation](#best-practices-for-implementation)
11. [Lessons for Our Editor](#lessons-for-our-editor)
12. [References and Resources](#references-and-resources)

---

## Tool Analysis Overview

### Tools Researched

| Tool | Type | Target Game(s) | Open Source | Active Development |
|------|------|---------------|-------------|-------------------|
| Moonscraper Chart Editor | Standalone | Clone Hero, Guitar Hero | Yes (BSD-3) | Active (v1.5.12, Oct 2024) |
| StepMania Editor | Integrated | StepMania, DDR-style | Yes (MIT) | Active (v5.1 beta) |
| osu! Beatmap Editor | Integrated | osu! | Partial | Active |
| Rhythm Doctor Editor | Integrated | Rhythm Doctor | No | Active |
| Chorus | Database/Search | Clone Hero | Yes (GPL-3) | Archived (Feb 2025) |
| YARG | Full Game | Clone Hero-like | Yes (Custom) | Active |

### Research Methodology

Information was gathered from:
- GitHub repositories and documentation
- Official wiki pages and tutorials
- Community forums and Discord servers
- Video tutorials and demonstrations
- Wikipedia articles on rhythm games

---

## Moonscraper Chart Editor (Detailed Analysis)

### Overview

**Developer:** Alexander "FireFox" Ong  
**Latest Version:** v1.5.12 (October 3, 2024)  
**License:** BSD-3-Clause  
**Engine:** Unity 2018.4.23f1  
**Languages:** C# (28.1%), C (55.9%), RenderScript (8.7%)  
**Notable Users:** Clone Hero (uses Moonscraper code), Everhood (uses as song editor)

### Key Statistics

- **GitHub Stars:** 259
- **Forks:** 68
- **Contributors:** 8
- **Total Commits:** 1,959
- **Releases:** 26 versions

### Core Features

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

### Community Reception

- **Active Discord:** https://discord.gg/bjsKTwd
- **YouTube Tutorials:** Popular tutorial series by various community members
- **Used by Chartists:** Standard tool for Clone Hero chart creation
- **Integration:** Clone Hero directly uses parts of Moonscraper's codebase

---

## StepMania Editor (Detailed Analysis)

### Overview

**Type:** Integrated editor within StepMania game engine  
**Latest Version:** 5.0.12 (stable), 5.1 beta 2 (development)  
**License:** MIT  
**Original Purpose:** DDR (Dance Dance Revolution) clone  
**Languages:** C++ (73.4%), Assembly (3.3%), Lua (0.9%)

### Historical Context

StepMania has been developed since 2001 as an open-source DDR clone. The built-in editor has evolved significantly:
- **Version 3.9 (2005):** Basic editor with manual BPM detection
- **Version 4 (2010):** Improved UI, better timing tools
- **Version 5 (2011+):** Modern editor with advanced features
- **Project OutFox (fork):** Modernized version with enhanced editor

### Core Features

#### 1. **Edit Mode Interface**
- **Note Field:** Vertical scrolling lanes (4-panel DDR, 5-panel PIU, etc.)
- **Quantization Display:** Visual indicators for beat divisions
- **Waveform View:** Audio waveform overlay on note field
- **Timing Panel:** BPM/Stop management tools

#### 2. **Step Editor Capabilities**
- **Multiple Game Modes:**
  - dance-single (4 panel)
  - dance-double (8 panel)
  - pump-single (5 panel)
  - pump-double (10 panel)
  - kb7-single (7 key beatmania-style)
- **Note Types:**
  - Tap notes (standard arrows)
  - Hold notes (freeze arrows)
  - Roll notes (rapid tap holds)
  - Mines (penalty objects)
  - Lift notes (release timing)

#### 3. **Timing System**
- **BPM Detection:** Semi-automatic beat detection from audio
- **Stop Segments:** Create pauses in chart
- **Warps:** Skip sections of timeline
- **Delays:** Adjust timing mid-song
- **Multiple BPM Support:** Complex tempo changes

#### 4. **Workflow Features**
- **Record Mode:** Place steps while playing with keyboard/pad
- **Playback Mode:** Test chart directly in editor
- **Copy/Paste:** Duplicate patterns across difficulties
- **Mirror/Flip:** Transform note patterns
- **Quantize Adjustment:** Snap existing notes to new divisions

### File Format

**Simfile Format (.sm, .ssc):**
```
#TITLE:Song Title;
#ARTIST:Artist Name;
#TITLETRANSLIT:;
#ARTISTTRANSLIT:;
#GENRE:Genre;
#CREDIT:Charter Name;
#BANNER:banner.png;
#BACKGROUND:background.png;
#MUSIC:audio.ogg;
#OFFSET:0.000;
#SAMPLESTART:30.000;
#SAMPLELENGTH:12.000;
#BPMS:0.000=120.000,4.000=140.000;
#STOPS:;
#NOTES:
     dance-single:
     :
     Expert:
     8:
     0.000,0.000,0.000,0.000,0.000:
0000
1000
0100
0010
...
```

### Keyboard Shortcuts (Edit Mode)

| Action | Shortcut | Description |
|--------|----------|-------------|
| Play/Pause | Tab | Toggle preview playback |
| Place Note | Arrow Keys | Place arrows on current beat |
| Snap Up/Down | PgUp/PgDn | Change quantization |
| Seek Forward | Right Arrow | Move forward one beat |
| Seek Backward | Left Arrow | Move backward one beat |
| Delete Note | Backspace | Remove note at cursor |
| Record Mode | R | Enter live recording mode |
| Area Select | Shift+Arrows | Select multiple notes |
| Copy | Ctrl+C | Copy selected notes |
| Paste | Ctrl+V | Paste copied notes |

### Timing Setup Workflow

1. **Audio Import:** Load audio file (.ogg, .mp3)
2. **Beat Detection:** Use automatic BPM detector (hit spacebar on beats)
3. **Offset Calibration:** Adjust global offset to sync first beat
4. **BPM Changes:** Place markers at tempo changes
5. **Verification:** Play through with metronome to confirm sync

### Community Tools

StepMania's ecosystem includes many external tools:
- **ArrowVortex:** Popular third-party editor (easier UI)
- **SM5 Theme Customization:** Lua scripting for UI modification
- **Batch Converters:** Tools to convert between .sm and .ssc
- **Chart Preview Generators:** Create videos of charts

### Strengths

1. ✅ **Fully Integrated:** Editor within game means instant testing
2. ✅ **Multiple Game Types:** Support for many rhythm game styles
3. ✅ **Mature System:** 20+ years of development
4. ✅ **Open Source:** MIT license, fully customizable
5. ✅ **Large Community:** Extensive documentation and tutorials

### Weaknesses

1. ❌ **Dated UI:** Interface shows its age, not intuitive for beginners
2. ❌ **Steep Learning Curve:** Complex timing system
3. ❌ **C++ Codebase:** Difficult to modify or extend
4. ❌ **Performance Issues:** Large charts can cause lag in editor
5. ❌ **Limited Visualization:** Basic waveform display only

### Notable Commercial Implementations

Several commercial games have used StepMania as their base:
- **In The Groove (ITG):** Arcade game series
- **Pump It Up Pro:** Pump It Up spinoff
- **Pump It Up Infinity:** Another PIU variant
- **StepManiaX:** Spiritual successor to ITG

---

## osu! Beatmap Editor (Detailed Analysis)

### Overview

**Type:** Integrated editor within osu! game client  
**Game Type:** Multi-mode rhythm game (osu!standard, osu!taiko, osu!catch, osu!mania)  
**License:** Mostly closed-source (some components open)  
**Developer:** Dean "peppy" Herbert  
**Active Development:** Continuous updates since 2007

### Editor Structure

The osu! editor is divided into four main tabs:

#### 1. **Compose Tab** (Main Editing)
- **Timeline:** Horizontal timeline showing timing points and objects
- **Playfield:** Visual representation of hit objects
- **Tool Palette:** Select, place, and modify objects
- **Timing Panel:** BPM and offset controls
- **Layers:** Background, hit objects, approach circles

#### 2. **Design Tab** (Storyboarding)
- **Visual Effects:** Add background animations and effects
- **Storyboard Scripting:** Advanced scripting language for complex visuals
- **Sprite Management:** Import and animate images
- **Video Support:** Background video playback

#### 3. **Timing Tab** (Synchronization)
- **Timing Points:** Set BPM, offset, and meter
- **Inherited Timing:** Volume, sample set changes
- **Metronome:** Audio click for timing verification
- **BPM Tapper:** Manual BPM detection tool

#### 4. **Song Setup Tab** (Metadata)
- **General Info:** Title, artist, creator, source
- **Difficulty Settings:** HP drain, circle size, approach rate, overall difficulty
- **Audio:** Lead-in, preview point
- **Colors:** Combo colors and slider borders
- **Design:** Background, video, skin settings

### Core Features

#### Beat Snap Divisor
- **Purpose:** Determines how objects snap to timeline
- **Common Values:** 1/1, 1/2, 1/3, 1/4, 1/6, 1/8, 1/12, 1/16
- **Visual Indicators:** Different colors for different divisions
- **Keyboard Shortcuts:** Ctrl+Mouse Wheel to adjust

#### Distance Snap
- **Purpose:** Controls spacing between consecutive hit objects
- **Multiplier:** Adjusts how close/far objects are placed
- **Time-Distance Relationship:** Objects spaced based on time between them
- **Toggle:** Alt key to enable/disable while placing

#### Object Types (osu!standard mode)
1. **Hit Circles:** Basic tap objects
2. **Sliders:** Follow path objects with controllable speed
3. **Spinners:** Rotate mouse to build score
4. **Stream Spacing:** Rapid consecutive hit circles

#### Timing System
- **Red Lines (Uninherited):** Define BPM and time signature
- **Green Lines (Inherited):** Modify SV (slider velocity), volume, sample sets
- **Kiai Time:** Special timing sections with visual emphasis
- **Preview Point:** Where song preview starts in song select

### Workflow

1. **New Beatmap:**
   - Select song from library or add new audio
   - Enter metadata (title, artist, etc.)
   - Set preview point and audio lead-in

2. **Timing Setup:**
   - Use Timing tab to detect BPM
   - Set offset by placing first beat on strong downbeat
   - Add timing points for BPM/meter changes

3. **Mapping:**
   - Use Compose tab to place objects
   - Follow rhythm and melody of song
   - Adjust difficulty through spacing and patterns

4. **Hitsounding:**
   - Add custom hit sounds to objects
   - Use inherited points to control volume
   - Layer multiple sounds for emphasis

5. **Testing:**
   - Use Test mode (F5) to play map
   - Adjust based on gameplay feel
   - Get feedback from community

6. **Polish:**
   - Add storyboard elements (optional)
   - Set difficulty settings for balance
   - Run AiMod to check for issues

7. **Submission:**
   - Upload to osu! website
   - Receive community feedback
   - Iterate based on modding feedback
   - Aim for ranked status

### Notable Features

#### AiMod (Automated Modding)
- **Purpose:** Detect common mapping issues
- **Checks:**
  - Objects too close to screen edge
  - Inconsistent spacing
  - Incorrect timing setup
  - Missing hitsounds
  - Unusual difficulty spikes
- **Severity Levels:** Problems, Warnings, Minor Issues

#### Keyboard Shortcuts

| Action | Shortcut | Description |
|--------|----------|-------------|
| Play/Pause | Spacebar | Toggle preview from current position |
| Test Mode | F5 | Launch game to test current difficulty |
| Timing Setup | F6 | Open Timing Setup Panel |
| Quick Save | Ctrl+S | Save beatmap |
| New Combo | Q | Toggle new combo on object |
| Hitsound | W/E/R | Add Whistle/Finish/Clap |
| Select All | Ctrl+A | Select all objects |
| Grid Snap | T | Toggle grid snap |
| Distance Snap | Y | Toggle distance snap |
| Lock Notes | L | Lock object positions |
| Seek Forward | → | Skip forward 1 beat |
| Seek Backward | ← | Skip backward 1 beat |
| Increase Snap | Ctrl+↑ | Increase beat snap divisor |
| Decrease Snap | Ctrl+↓ | Decrease beat snap divisor |

### File Format

**osu! Beatmap Format (.osu):**
```
osu file format v14

[General]
AudioFilename: audio.mp3
AudioLeadIn: 0
PreviewTime: 40000
Countdown: 0
SampleSet: Normal
StackLeniency: 0.7
Mode: 0
LetterboxInBreaks: 0
WidescreenStoryboard: 0

[Metadata]
Title:Song Title
TitleUnicode:Song Title
Artist:Artist Name
ArtistUnicode:Artist Name
Creator:Mapper Name
Version:Difficulty Name
Source:
Tags:genre tags keywords
BeatmapID:0
BeatmapSetID:-1

[Difficulty]
HPDrainRate:5
CircleSize:4
OverallDifficulty:7
ApproachRate:9
SliderMultiplier:1.6
SliderTickRate:1

[TimingPoints]
0,500,4,2,0,50,1,0
2000,-100,4,2,0,50,0,0

[HitObjects]
256,192,1000,1,0,0:0:0:0:
400,192,1500,2,0,L|450:192,1,50,4|0,0:0|0:0,0:0:0:0:
```

### Strengths

1. ✅ **Polished UI:** Modern, intuitive interface
2. ✅ **Comprehensive Tools:** Everything needed in one place
3. ✅ **Instant Testing:** F5 to test in-game immediately
4. ✅ **Rich Community:** Extensive mapping community and resources
5. ✅ **AiMod Validation:** Automated error checking
6. ✅ **Multiple Modes:** Support for different play styles

### Weaknesses

1. ❌ **Closed Source:** Limited community modifications
2. ❌ **Game-Specific:** Tied to osu! ecosystem only
3. ❌ **Complex Ranking:** Lengthy process to get maps officially ranked
4. ❌ **Learning Curve:** Many features to master
5. ❌ **Windows-Focused:** Best experience on Windows

---

## Rhythm Doctor Level Editor

### Overview

**Type:** Integrated level editor  
**Game Type:** One-button rhythm game  
**Developer:** 7th Beat Games (Hafiz Azman, Winston Lee, Giacomo Preciado, Jose Cahuana, Kyle Labrio)  
**Platform:** Steam, Xbox Series X/S  
**Early Access:** Available now, Full Release: December 6, 2025

### Key Features

Rhythm Doctor takes a unique approach to rhythm games:
- **One-Button Gameplay:** Single button press on 7th beat
- **Visual Rhythm Mechanics:** Uses visual cues instead of traditional notes
- **Level Editor:** Allows creation of custom levels with:
  - Custom audio tracks
  - Visual event scripting
  - Pattern creation tools
  - Timing calibration

### Awards and Recognition

- **INDIE PRIZE SHOWCASE 2017:** Best Game Audio Winner
- **BICFEST 2017:** Best Audio Winner
- **LEVEL UP KL 2017:** Best Audio Winner
- **BIG FESTIVAL 2018:** Best Sound Winner
- **INDIECADE FESTIVAL 2017:** Official Nominee
- **DAY OF THE DEVS 2017:** Official Selection

### Editor Philosophy

Unlike traditional note-highway editors, Rhythm Doctor's level editor focuses on:
1. **Event-Based System:** Trigger visual and audio events at specific times
2. **Pattern Templates:** Reusable rhythm patterns
3. **Visual Programming:** Connect events visually rather than code
4. **Audio-Reactive:** Tie visual effects to audio amplitude

### Strengths

1. ✅ **Innovative Approach:** Different paradigm from traditional editors
2. ✅ **Accessibility:** Simple one-button gameplay makes charting easier
3. ✅ **Visual Focus:** Emphasis on visual design and rhythm
4. ✅ **Integrated:** Editor within game for quick testing

### Weaknesses

1. ❌ **Niche Genre:** One-button gameplay limits broader applicability
2. ❌ **Less Documentation:** Smaller community compared to osu!/Clone Hero
3. ❌ **Closed Source:** Proprietary editor

---

## Clone Hero Ecosystem

### Overview

Clone Hero is not just a single tool but an entire ecosystem of related tools and services:

#### 1. **Clone Hero (Game)**
- **Type:** Free rhythm game (Guitar Hero/Rock Band clone)
- **Platform:** Windows, Mac, Linux
- **License:** Closed source (game), but uses open-source libraries
- **Notable:** Uses Moonscraper Chart Editor code internally

#### 2. **Chorus (Chart Database)**
- **Type:** Web-based chart search and aggregation
- **Status:** Archived (Feb 22, 2025) but still accessible
- **Charts Indexed:** 20,000+ custom charts
- **License:** GPL-3.0

##### Chorus Features

**Search Capabilities:**
- **Query System:** Advanced search with filters:
  - `name="song name"` - Search by song title
  - `artist="artist name"` - Filter by artist
  - `charter="charter name"` - Find charts by specific charter
  - `tier_guitar=lt3` - Find charts easier than tier 3
  - `diff_guitar=8` - Find charts with expert difficulty
  - `hasForced=1` - Charts with forced notes
  - `hasSections=1` - Charts with practice sections

**API Endpoints:**
```
/api/count - Total chart count
/api/random - Get 20 random charts
/api/latest - Get 20 newest charts
/api/search?query=... - Search with filters
```

**Metadata Provided:**
- Song info (name, artist, album, genre, year)
- Charter information
- Difficulty tiers and available parts
- Chart features (forced notes, open notes, tap notes)
- Length and effective length
- MD5 checksums for verification
- Direct download links

##### Chorus Workflow

1. User searches for charts using web interface
2. Results show detailed information and preview
3. Click download link to get chart bundle
4. Extract to Clone Hero songs folder
5. Refresh song cache in game
6. Play chart

### Clone Hero Chart Format

**Standard .chart Format:**
```
[Song]
{
  Name = "Song Title"
  Artist = "Artist Name"
  Charter = "Charter Name"
  Album = "Album Name"
  Year = ", 2024"
  Offset = 0
  Resolution = 192
  Player2 = bass
  Difficulty = 6
  PreviewStart = 0
  PreviewEnd = 0
  Genre = "rock"
  MediaType = "cd"
  MusicStream = "song.ogg"
}

[SyncTrack]
{
  0 = TS 4
  0 = B 120000
}

[Events]
{
  768 = E "section Intro"
  3840 = E "section Verse 1"
}

[ExpertSingle]
{
  768 = N 0 0
  960 = N 1 0
  1152 = N 2 0
  1344 = N 3 0
  1536 = N 4 0
}
```

### Strengths of Ecosystem

1. ✅ **Massive Library:** 20,000+ charts available
2. ✅ **Active Community:** Discord servers, Reddit, forums
3. ✅ **Tool Integration:** Multiple tools work together seamlessly
4. ✅ **Free and Open:** Most tools are open-source
5. ✅ **Cross-Platform:** Works on Windows, Mac, Linux

### Weaknesses

1. ❌ **Fragmented Tools:** Need multiple applications for full workflow
2. ❌ **Quality Variance:** Chart quality varies widely
3. ❌ **Legal Gray Area:** Copyright concerns with covers/charts
4. ❌ **Chorus Archived:** Main database no longer actively maintained

---

## YARG (Yet Another Rhythm Game)

### Overview

**Full Name:** Yet Another Rhythm Game  
**Type:** Full rhythm game with integrated editor  
**License:** Custom YARG License (open source, restricted branding)  
**Engine:** Unity 2021.3.21f1  
**Status:** Active development, early access on Steam  
**Notable:** Uses Moonscraper Chart Editor library for parsing

### Key Features

#### Multi-Instrument Support
- Five Fret Guitar
- Bass
- Drums
- Vocals (Microphone)
- Six Fret (Guitar Hero Live style)
- Keys

#### Controller Support
- Official Guitar Hero/Rock Band controllers
- MIDI instruments
- Keyboard emulation
- PlasticBand-Unity library for HID support
- HIDrogen for Linux controller support

#### File Format Support
Uses extensive parsing libraries:
- **.chart files:** Moonscraper library
- **.mid files:** DryWetMidi library
- **song.ini:** ini-parser library
- **.dta files:** DtxCS library
- **Audio metadata:** TagLibSharp

### Architecture Insights

YARG's architecture reveals best practices for rhythm game editors:

#### Parsing Layer
```csharp
// Pseudocode based on YARG's external libraries
class ChartParser
{
    public Chart ParseChart(string filePath)
    {
        if (filePath.EndsWith(".chart"))
            return ParseChartFile(filePath);
        else if (filePath.EndsWith(".mid"))
            return ParseMidiFile(filePath);
    }
    
    private Chart ParseChartFile(string path)
    {
        // Uses Moonscraper's parsing logic
        var sections = ReadChartSections(path);
        return ConvertToChartData(sections);
    }
}
```

#### Song Management
```csharp
class SongLibrary
{
    private List<SongEntry> songs;
    
    public void ScanFolder(string folderPath)
    {
        // Recursively search for song.ini files
        // Parse metadata
        // Cache results for fast loading
    }
    
    public void RefreshCache()
    {
        // Re-scan all folders
        // Update song database
    }
}
```

### Editor Implications

While YARG doesn't have a full built-in editor yet, its architecture suggests best practices:

1. **Modular Parsing:** Separate parsers for each file format
2. **Metadata Caching:** Fast song browsing through pre-indexed data
3. **Preview System:** Generate song previews at specific timestamps
4. **Multi-Format Support:** Import from various rhythm game formats

### External Libraries Used

| Library | Purpose | License |
|---------|---------|---------|
| Moonscraper | .chart parsing | BSD-3-Clause |
| DryWetMidi | .mid parsing | MIT |
| ini-parser | song.ini parsing | MIT |
| DtxCS | .dta parsing | Licenseless |
| TagLibSharp | Audio metadata | LGPL |
| PlasticBand-Unity | Controller support | MIT |
| FuzzySharp | Search functionality | MIT |
| DOTween | Animations | Free/Pro |
| UniTask | Async operations | MIT |
| NuGet for Unity | Package management | MIT |

### Strengths

1. ✅ **Modern Tech Stack:** Unity 2021, C# .NET
2. ✅ **Open Source:** Full source code available
3. ✅ **Multi-Platform:** Windows, Mac, Linux, future consoles
4. ✅ **Active Development:** Frequent updates on GitHub
5. ✅ **Community Driven:** Discord with 11,318 members

### Weaknesses

1. ❌ **Early Development:** Still missing some features
2. ❌ **No Built-in Editor:** Must use external tools for charting
3. ❌ **Unity License:** Requires Unity for modifications
4. ❌ **Complex Codebase:** Large codebase can be overwhelming

---

## Common Design Patterns

After analyzing all the tools, several design patterns emerge as industry standard:

### 1. **Note Highway Visualization**

**Pattern:** Vertical scrolling lanes with notes moving toward target line

**Implementation:**
- **2D Rendering:** Most editors use 2D orthographic projection
- **Lane Count:** Fixed based on instrument (5 for guitar, 4 for DDR, etc.)
- **Target Line:** Horizontal line where notes should be hit
- **Scroll Speed:** User-configurable for comfortable editing
- **Visual Feedback:** Different colors/shapes for different note types

**Example Structure:**
```
┌─────────────────────────────────────┐
│  [Song Title - Artist]              │  ← Header
├─────────────────────────────────────┤
│  ♪ Audio Waveform                   │  ← Waveform Display
├─────────────────────────────────────┤
│                                     │
│  Lane 1  Lane 2  Lane 3  Lane 4    │
│    │       │       │       │       │
│    ◯       ◯       ◯       ◯       │  ← Notes scrolling
│    │       │       │       │       │
│           ◉               ◯        │
│    │       │       │       │       │
│  ═════  ═════  ═════  ═════       │  ← Target Line (Judgement)
│                                     │
│    │       │       │       │       │
├─────────────────────────────────────┤
│  ◀ ▶ ⏯ ⏸ ⏹    🔊 ⏱ Snap:1/16    │  ← Transport Controls
└─────────────────────────────────────┘
```

### 2. **Timeline System**

**Pattern:** Horizontal timeline below or above note highway

**Features:**
- **Measures:** Vertical lines marking bar boundaries
- **Beats:** Smaller divisions within measures
- **Sections:** Named sections (Intro, Verse, Chorus, etc.)
- **BPM Changes:** Visual indicators of tempo changes
- **Playhead:** Moving cursor showing current playback position

**Implementation:**
```gdscript
class_name Timeline extends Control

var beats_per_measure: int = 4
var pixels_per_beat: float = 50.0
var current_time: float = 0.0

func _draw():
    var measure_count = get_measure_count()
    for i in range(measure_count):
        var x = i * beats_per_measure * pixels_per_beat
        # Draw measure line (thick)
        draw_line(Vector2(x, 0), Vector2(x, height), Color.WHITE, 2.0)
        
        # Draw beat lines (thin)
        for beat in range(1, beats_per_measure):
            var beat_x = x + beat * pixels_per_beat
            draw_line(Vector2(beat_x, 0), Vector2(beat_x, height), 
                     Color.GRAY, 1.0)
```

### 3. **Snap-to-Grid System**

**Pattern:** Constrain note placement to musically meaningful divisions

**Common Snap Values:**
- 1/1 (Whole note)
- 1/2 (Half note)
- 1/4 (Quarter note) ← Most common
- 1/8 (Eighth note)
- 1/12 (Triplet eighth)
- 1/16 (Sixteenth note)
- 1/24 (Triplet sixteenth)
- 1/32 (Thirty-second note)
- 1/64 (Sixty-fourth note)

**Color Coding (Industry Standard):**
```gdscript
const SNAP_COLORS = {
    1: Color.WHITE,      # 1/1
    2: Color.RED,        # 1/2
    3: Color.PURPLE,     # 1/3
    4: Color.BLUE,       # 1/4
    6: Color.PINK,       # 1/6
    8: Color.YELLOW,     # 1/8
    12: Color.ORANGE,    # 1/12
    16: Color.GREEN,     # 1/16
    32: Color.CYAN,      # 1/32
    64: Color.GRAY,      # 1/64
}
```

### 4. **Playback Control Architecture**

**Pattern:** Transport controls with variable speed and precise seeking

**Essential Controls:**
- Play/Pause (Space)
- Stop (Return to start)
- Seek Forward (Arrow Right or custom increment)
- Seek Backward (Arrow Left or custom decrement)
- Speed Control (0.25x, 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x)
- Loop Section (Optional)

**Implementation:**
```gdscript
class_name PlaybackController extends Node

signal playback_started
signal playback_paused
signal playback_stopped
signal playback_position_changed(position: float)

var audio_player: AudioStreamPlayer
var is_playing: bool = false
var playback_speed: float = 1.0

func play():
    if not is_playing:
        audio_player.play()
        audio_player.pitch_scale = playback_speed
        is_playing = true
        playback_started.emit()

func pause():
    if is_playing:
        audio_player.stream_paused = true
        is_playing = false
        playback_paused.emit()

func seek(time_seconds: float):
    audio_player.seek(time_seconds)
    playback_position_changed.emit(time_seconds)

func set_speed(speed: float):
    playback_speed = clamp(speed, 0.25, 2.0)
    if is_playing:
        audio_player.pitch_scale = playback_speed
```

### 5. **Command Pattern for Undo/Redo**

**Pattern:** Every edit operation is a command object that can be undone/redone

**Base Command:**
```gdscript
class_name EditorCommand extends RefCounted

func execute() -> void:
    pass  # Override in subclass

func undo() -> void:
    pass  # Override in subclass

func get_description() -> String:
    return "Command"  # Override in subclass
```

**Example Commands:**
```gdscript
class_name PlaceNoteCommand extends EditorCommand

var note_data: Dictionary
var chart: ChartData

func _init(chart_ref: ChartData, note: Dictionary):
    chart = chart_ref
    note_data = note

func execute():
    chart.add_note(note_data)

func undo():
    chart.remove_note(note_data)

func get_description() -> String:
    return "Place Note"


class_name DeleteNoteCommand extends EditorCommand

var note_data: Dictionary
var chart: ChartData

func _init(chart_ref: ChartData, note: Dictionary):
    chart = chart_ref
    note_data = note

func execute():
    chart.remove_note(note_data)

func undo():
    chart.add_note(note_data)

func get_description() -> String:
    return "Delete Note"
```

**History Manager:**
```gdscript
class_name HistoryManager extends Node

var undo_stack: Array[EditorCommand] = []
var redo_stack: Array[EditorCommand] = []
const MAX_HISTORY = 100

func execute_command(command: EditorCommand):
    command.execute()
    undo_stack.push_back(command)
    redo_stack.clear()  # Clear redo stack when new action performed
    
    # Limit stack size
    if undo_stack.size() > MAX_HISTORY:
        undo_stack.pop_front()

func undo():
    if undo_stack.is_empty():
        return
    
    var command = undo_stack.pop_back()
    command.undo()
    redo_stack.push_back(command)

func redo():
    if redo_stack.is_empty():
        return
    
    var command = redo_stack.pop_back()
    command.execute()
    undo_stack.push_back(command)

func can_undo() -> bool:
    return not undo_stack.is_empty()

func can_redo() -> bool:
    return not redo_stack.is_empty()

func get_undo_description() -> String:
    if can_undo():
        return undo_stack.back().get_description()
    return ""

func get_redo_description() -> String:
    if can_redo():
        return redo_stack.back().get_description()
    return ""
```

### 6. **Waveform Display**

**Pattern:** Visual representation of audio amplitude over time

**Benefits:**
- Helps identify beats visually
- Assists with BPM detection
- Shows silence/gaps in audio
- Aids in timing note placement

**Implementation Approaches:**
1. **Pre-rendered:** Generate waveform texture on load (fast display, slow load)
2. **Real-time:** Calculate waveform data on-the-fly (slower, more flexible)
3. **Cached:** Generate once, cache to file (best of both)

**Example (Simplified):**
```gdscript
class_name WaveformDisplay extends Control

var audio_stream: AudioStream
var waveform_data: PackedFloat32Array
var samples_per_pixel: int = 512

func generate_waveform():
    if not audio_stream:
        return
    
    var data = audio_stream.get_data()
    var sample_count = data.size()
    var pixel_count = sample_count / samples_per_pixel
    
    waveform_data.resize(pixel_count)
    
    for i in range(pixel_count):
        var start_sample = i * samples_per_pixel
        var end_sample = min(start_sample + samples_per_pixel, sample_count)
        
        # Find peak amplitude in this window
        var peak = 0.0
        for j in range(start_sample, end_sample):
            peak = max(peak, abs(data[j]))
        
        waveform_data[i] = peak

func _draw():
    var width = size.x
    var height = size.y
    var center_y = height / 2.0
    
    for i in range(waveform_data.size()):
        var x = (i / float(waveform_data.size())) * width
        var amplitude = waveform_data[i]
        var bar_height = amplitude * center_y
        
        draw_line(
            Vector2(x, center_y - bar_height),
            Vector2(x, center_y + bar_height),
            Color.CYAN,
            1.0
        )
```

### 7. **File Format Structure**

**Pattern:** Human-readable, text-based format with clear sections

**Common Elements:**
- **[Header]** - Song metadata
- **[SyncTrack]** - Timing information (BPM, time signature)
- **[Events]** - Section markers, special events
- **[Difficulty]** - Note data per difficulty per instrument

**Benefits:**
- Version control friendly (git diff works)
- Easy to parse
- Debuggable (can open in text editor)
- Extensible (add new sections without breaking old parsers)

---

## Feature Comparison Matrix

| Feature | Moonscraper | StepMania | osu! | Rhythm Doctor | Our Target |
|---------|-------------|-----------|------|---------------|------------|
| **Core Features** |
| Note Highway | ✅ 5-lane | ✅ 4/5/8-lane | ✅ Radial | ❌ Event-based | ✅ 5-lane |
| Waveform Display | ✅ Yes | ⚠️ Basic | ✅ Yes | ⚠️ Limited | ✅ Yes |
| Playback Speed | ✅ 5%-100% | ✅ Variable | ✅ 25%-100% | ✅ Yes | ✅ 25%-200% |
| Undo/Redo | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Input Methods** |
| Keyboard Shortcuts | ✅ Extensive | ✅ Many | ✅ Many | ⚠️ Limited | ✅ Extensive |
| Mouse Placement | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| MIDI Input | ❌ No | ⚠️ Limited | ✅ Yes | ❌ No | 🎯 Future |
| Live Recording | ❌ No | ✅ Yes | ❌ No | ❌ No | 🎯 Future |
| **Timing Features** |
| BPM Detection | ⚠️ Manual | ✅ Semi-auto | ✅ Yes | ✅ Yes | ✅ Semi-auto |
| Multiple BPMs | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Time Signatures | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Limited | ✅ Yes |
| Offset Adjustment | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Chart Management** |
| Multiple Difficulties | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Multiple Instruments | ✅ 6 types | ✅ Game modes | ❌ Single | ❌ Single | ✅ Future |
| Copy/Paste Patterns | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Limited | ✅ Yes |
| Mirror/Transform | ⚠️ Limited | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **Validation** |
| Error Checking | ✅ Yes | ⚠️ Basic | ✅ AiMod | ⚠️ Limited | ✅ Yes |
| Play Testing | ✅ Preview | ✅ In-game | ✅ F5 Test | ✅ In-game | ✅ In-game |
| Difficulty Rating | ⚠️ Manual | ⚠️ Manual | ✅ Calculated | ⚠️ Manual | 🎯 Calculated |
| **File Formats** |
| Primary Format | .chart | .sm/.ssc | .osu | Proprietary | .rgchart |
| Import Formats | .mid, .chart | .sm, .dwi | .osu | N/A | .chart, .mid |
| Export Formats | .chart | .sm, .ssc | .osu | Proprietary | .rgchart |
| Human Readable | ✅ Yes | ✅ Yes | ✅ Yes | ❌ Binary | ✅ Yes |
| **Collaboration** |
| Version Control | ✅ Git-friendly | ✅ Git-friendly | ✅ Git-friendly | ❌ Binary | ✅ Git-friendly |
| Sharing | Manual | Manual | ✅ Web upload | ✅ Workshop | 🎯 Export |
| **Advanced Features** |
| Audio Sync Tools | ⚠️ Basic | ✅ Advanced | ✅ Advanced | ✅ Yes | ✅ Advanced |
| Metronome | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Section Markers | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Storyboarding | ❌ No | ⚠️ Limited | ✅ Yes | ✅ Yes | ❌ No |
| Auto-Charting | ❌ No | ❌ No | ⚠️ Community | ❌ No | 🎯 Future |
| **User Experience** |
| Learning Curve | ⚠️ Moderate | ⚠️ Steep | ⚠️ Moderate | ✅ Easy | ✅ Easy-Moderate |
| Documentation | ⚠️ Community | ✅ Good | ✅ Excellent | ⚠️ Limited | ✅ Good |
| Tutorial | ⚠️ Video-based | ⚠️ Scattered | ✅ Built-in | ⚠️ Limited | 🎯 Built-in |
| UI Polish | ⚠️ Functional | ❌ Dated | ✅ Modern | ✅ Modern | ✅ Modern |

**Legend:**
- ✅ = Fully supported/implemented
- ⚠️ = Partially supported or needs improvement
- ❌ = Not supported
- 🎯 = Planned for future

---

## Best Practices for Implementation

Based on analysis of successful editors, here are the top best practices:

### 1. **Start with Core Workflow**

**Priority Order:**
1. Load audio file
2. Set BPM and offset
3. Place notes with keyboard
4. Play back chart
5. Export to file

Everything else is enhancement.

### 2. **Keyboard-First Design**

**Why:** Fastest way to place notes is keyboard while audio plays

**Implementation:**
- Number keys (1-5) for lane placement
- Space for play/pause
- Arrow keys for seeking
- Ctrl+Z/Y for undo/redo
- Bracket keys [/] for snap adjustment

**Example Config:**
```gdscript
const KEYBOARD_SHORTCUTS = {
    KEY_1: "place_note_lane_0",
    KEY_2: "place_note_lane_1",
    KEY_3: "place_note_lane_2",
    KEY_4: "place_note_lane_3",
    KEY_5: "place_note_lane_4",
    KEY_SPACE: "toggle_playback",
    KEY_UP: "seek_forward",
    KEY_DOWN: "seek_backward",
    KEY_BRACKETLEFT: "decrease_snap",
    KEY_BRACKETRIGHT: "increase_snap",
    KEY_DELETE: "delete_selected",
}
```

### 3. **Visual Feedback is Critical**

**Requirements:**
- Immediate visual confirmation of note placement
- Clear indication of selected notes
- Visual snap grid
- Playback cursor position
- Beat/measure lines

### 4. **Performance Optimization**

**Challenges:**
- Rendering thousands of notes
- Real-time audio playback
- Smooth scrolling

**Solutions:**
- Object pooling for notes
- Viewport culling (only render visible notes)
- Separate audio thread
- Frame rate limiting on editor (60 FPS is plenty)

### 5. **File Format Design**

**Best Practices:**
- Use JSON or INI format (human-readable)
- Include version number for future compatibility
- Store minimal data (calculate derived values)
- Use relative paths for audio files
- Support comments for manual editing

### 6. **Error Handling**

**Common User Errors:**
- Missing audio file
- Invalid BPM (0 or negative)
- Notes at negative time
- Overlapping notes in same lane
- Very long sustain notes

**Handling:**
- Validate on load and save
- Show clear error messages
- Provide auto-fix options where possible
- Don't corrupt file on error

### 7. **Testing Workflow**

**Integration:**
- One-click test from editor
- Load into gameplay directly
- Preserve editor state on return
- Show stats after test (accuracy, misses, etc.)

### 8. **Autosave**

**Implementation:**
- Save every N minutes (default 5)
- Save on successful test
- Keep backup of last N saves
- Don't overwrite manual saves

### 9. **Accessibility**

**Considerations:**
- Colorblind mode for snap colors
- Adjustable UI scale
- Keyboard-only operation
- Screen reader support (future)

### 10. **Documentation**

**Essential Docs:**
- Quick start guide (5 minutes to first chart)
- Keyboard shortcut reference
- File format specification
- Tutorial for common patterns
- FAQ for troubleshooting

---

## Lessons for Our Editor

Based on this research, here are specific recommendations for our Godot rhythm game chart editor:

### Must-Have Features (MVP)

1. **✅ Already Designed:**
   - Vertical scrolling note highway (5 lanes)
   - Playback controls with speed adjustment
   - Snap-to-grid system
   - Undo/redo with command pattern
   - Basic UI layout (MenuBar, PlaybackControls, EditToolbar, Viewport, SidePanel, StatusBar)

2. **🎯 Need to Implement:**
   - Waveform display for audio
   - Keyboard shortcuts for note placement
   - BPM detection helper tool
   - Chart validation checks
   - In-game testing integration

### Should-Have Features (Post-MVP)

1. **Pattern Tools:**
   - Copy/paste note sections
   - Mirror patterns (flip lanes)
   - Quantize existing notes to new snap
   - Generate difficulty variations

2. **Advanced Timing:**
   - Semi-automatic BPM detection (tap tempo)
   - Visual beat markers on waveform
   - Offset calibration wizard
   - Multiple BPM support with transitions

3. **Quality of Life:**
   - Note density visualization
   - Difficulty calculator (algorithmic)
   - Chart statistics (notes per second, etc.)
   - Minimap of full chart

### Nice-to-Have Features (Future)

1. **Automation:**
   - AI-assisted note placement
   - Auto-generate easy/medium from expert
   - Pattern recognition and suggestions

2. **Collaboration:**
   - Export to common formats (.chart)
   - Import from Clone Hero/Guitar Hero
   - Share charts to community hub

3. **Advanced Features:**
   - Multiple instrument support
   - Special note types (HOPO, tap, etc.)
   - Event scripting (lighting, camera)
   - Practice mode markers

### Implementation Priorities

**Phase 1 (Weeks 1-4): Core Editing**
- Note placement with keyboard
- Basic playback controls
- Simple save/load
- Target: Can create a basic chart

**Phase 2 (Weeks 5-8): Enhanced UX**
- Waveform display
- Snap-to-grid visualization
- Undo/redo system
- Keyboard shortcut system
- Target: Comfortable editing experience

**Phase 3 (Weeks 9-12): Testing & Validation**
- In-game testing integration
- Chart validation
- Error detection
- Difficulty stats
- Target: Can create quality charts

**Phase 4 (Weeks 13-16): Polish & Advanced**
- Pattern tools (copy/paste/mirror)
- BPM detection
- Tutorial system
- Export to .chart format
- Target: Production-ready editor

### Specific Design Decisions

#### 1. **File Format: .rgchart (JSON)**

**Rationale:**
- JSON is human-readable (can edit in text editor)
- Git-friendly (meaningful diffs)
- Easy to parse in GDScript
- Extensible (add new fields without breaking old parsers)
- Industry standard (see: all researched editors use text formats)

#### 2. **Keyboard Shortcuts: Follow Moonscraper**

**Rationale:**
- Moonscraper is the de facto standard for Clone Hero
- Many users will be familiar with these shortcuts
- Proven to be efficient in practice
- Well-documented

#### 3. **Architecture: MVC Pattern**

**Rationale:**
- Clear separation of concerns
- Easier to test
- Modular design allows incremental development
- Follows existing ChartEditor-Design.md spec

#### 4. **Integration: Use Existing Gameplay Components**

**Rationale:**
- Reuse runway/note visuals for consistency
- Testing integration is simpler
- Less code to maintain
- Users see exactly what they'll get in-game

#### 5. **Audio: Use Godot's AudioStreamPlayer**

**Rationale:**
- No external dependencies
- Cross-platform by default
- Good enough performance for editor use
- Built-in pitch shifting for speed control

### Technical Considerations

#### Godot-Specific Advantages

1. **Scene System:** Perfect for modular UI
2. **Signals:** Clean event handling for UI updates
3. **Resource System:** Easy asset management
4. **Built-in Audio:** No need for external libraries
5. **GDScript:** Fast iteration, good for tools

#### Potential Challenges

1. **Audio Latency:** May need buffering for precise timing
2. **Performance:** Many notes could stress rendering
   - **Solution:** Object pooling, viewport culling
3. **Waveform Generation:** Can be CPU-intensive
   - **Solution:** Generate once, cache to file
4. **File I/O:** Large charts could be slow
   - **Solution:** Background loading, progress indicators

### User Experience Priorities

1. **Fast Iteration:** Place note → Play → Adjust → Repeat
2. **Minimal Friction:** One click to test in-game
3. **Forgiving:** Generous undo/redo, autosave
4. **Guided:** Clear visual feedback, tooltips, tutorials
5. **Professional:** Polished UI, smooth animations

### Learning from Mistakes

**Common Pitfalls (from research):**

1. **❌ Too Many Features Too Soon**
   - Focus on core workflow first
   - Add features based on user feedback

2. **❌ Ignoring Keyboard Shortcuts**
   - Mouse-only is too slow for serious charting
   - Keyboard shortcuts must be first-class

3. **❌ Poor Testing Integration**
   - Editor should launch directly into gameplay
   - Quick iteration is essential for quality charts

4. **❌ Complex UI**
   - Simple, clean interface beats feature-packed
   - Progressive disclosure (advanced features hidden until needed)

5. **❌ Inadequate Documentation**
   - Users won't discover features without docs
   - In-app tooltips and tutorials are essential

---

## References and Resources

### Primary Sources

1. **Moonscraper Chart Editor**
   - GitHub: https://github.com/FireFox2000000/Moonscraper-Chart-Editor
   - Discord: https://discord.gg/bjsKTwd
   - Latest Release: v1.5.12 (October 3, 2024)

2. **StepMania**
   - Website: http://www.stepmania.com/
   - GitHub: https://github.com/stepmania/stepmania
   - Wikipedia: https://en.wikipedia.org/wiki/StepMania
   - Latest: v5.0.12 stable, v5.1 beta 2

3. **osu!**
   - Website: https://osu.ppy.sh/
   - Wiki: https://osu.ppy.sh/wiki/en/Beatmap_Editor
   - Documentation: Extensive wiki with editor guides

4. **Rhythm Doctor**
   - Website: https://rhythmdr.com/
   - Steam: https://store.steampowered.com/app/774181/Rhythm_Doctor/
   - Discord: https://discord.gg/2H9cAku8n9 (7th Beat Games Café)

5. **Clone Hero**
   - Website: https://clonehero.net/
   - Community: Large Discord and subreddit

6. **Chorus (Archive)**
   - GitHub: https://github.com/Paturages/chorus
   - Website: https://chorus.fightthe.pw/ (archived)
   - 20,000+ indexed charts

7. **YARG**
   - GitHub: https://github.com/YARC-Official/YARG
   - Discord: https://discord.gg/sqpu4R552r
   - Active development, Unity-based

### Technical Documentation

1. **.chart File Format**
   - GuitarGame_ChartFormats repo (referenced by YARG)
   - Moonscraper source code
   - Community documentation

2. **Simfile Format (.sm/.ssc)**
   - StepMania wiki
   - Community documentation
   - Open-source parsers

3. **.osu File Format**
   - osu! wiki: Beatmap file format documentation
   - Well-documented with examples

### Community Resources

1. **Clone Hero Discord**
   - Charting channels
   - Tool recommendations
   - Chart feedback

2. **StepMania Forums**
   - Stepfile creation guides
   - Editor tutorials
   - Community tools

3. **osu! Forums**
   - Mapping discussion
   - Beatmap feedback
   - Ranking criteria

### Video Tutorials

1. **Moonscraper Tutorials**
   - YouTube: Search "Moonscraper Chart Editor tutorial"
   - FireFox2000000's channel: https://www.youtube.com/user/FireFox2000000

2. **StepMania Tutorials**
   - Various community creators
   - Editor-specific guides

3. **osu! Mapping School**
   - Community-driven mapping education
   - Video series on editor usage

### Related Tools

1. **ArrowVortex**
   - Alternative StepMania editor
   - More modern UI

2. **Feedback Editor**
   - Clone Hero chart editor
   - Alternative to Moonscraper

3. **Frets on Fire Editor**
   - Older but still referenced
   - Similar design patterns

### Academic/Technical Papers

1. **"Music Information Retrieval for Rhythm Games"**
   - BPM detection algorithms
   - Beat tracking systems

2. **"Procedural Content Generation in Rhythm Games"**
   - Auto-charting approaches
   - Difficulty balancing

3. **"User Interface Design for Music Creation Tools"**
   - Workflow optimization
   - Keyboard vs. mouse interaction

---

## Conclusion

This research has revealed that successful chart editors share common design principles:

1. **Fast Workflow:** Keyboard-driven note placement while audio plays
2. **Visual Clarity:** Clear note highway, waveform, and timeline
3. **Flexible Timing:** Support for BPM changes, various time signatures
4. **Quality Tools:** Validation, testing, and iteration support
5. **Open Formats:** Text-based, version-control friendly file formats

Our editor should follow these established patterns while adding our own innovations:
- Modern Godot-based architecture
- Integrated with existing gameplay
- Clean, approachable UI
- Extensible design for future features

The next step is to use this research to refine our existing ChartEditor-Design.md specification and begin implementation with a focus on the core editing workflow.

---

**End of Research Document**

*Last Updated: November 3, 2025*
*Research Status: Complete*
*Next Step: Review findings and update implementation plan*
