# Component Diagrams - Rhythm Game Architecture

**Version:** 1.0  
**Date:** October 13, 2025  
**Project:** Godot 4 3D Rhythm Game

---

## Table of Contents

- [Component Diagrams - Rhythm Game Architecture](#component-diagrams---rhythm-game-architecture)
  - [Table of Contents](#table-of-contents)
  - [System Context Diagram](#system-context-diagram)
  - [Component Overview](#component-overview)
  - [Gameplay Scene Component Diagram](#gameplay-scene-component-diagram)
  - [Parser Subsystem](#parser-subsystem)
  - [Note Lifecycle Components](#note-lifecycle-components)

---

## System Context Diagram

This shows the highest-level view of the system and its external interactions.

```
┌─────────────────────────────────────────────────────────────────┐
│                         EXTERNAL ACTORS                          │
└─────────────────────────────────────────────────────────────────┘

     ┌──────────┐              ┌──────────────┐        ┌──────────┐
     │  Player  │              │ Chart Files  │        │  Audio   │
     │          │              │  (.chart,    │        │  Files   │
     │ [Inputs] │              │   .mid, .ini)│        │  (.ogg)  │
     └─────┬────┘              └──────┬───────┘        └────┬─────┘
           │                          │                     │
           │ Keyboard                 │ File System         │ File System
           │ Events                   │ Read                │ Read
           │                          │                     │
           ▼                          ▼                     ▼
┌──────────────────────────────────────────────────────────────────┐
│                                                                   │
│                  GODOT 4 RHYTHM GAME SYSTEM                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Core Game Engine                        │ │
│  │  • Gameplay Controller                                     │ │
│  │  • Input Handler                                           │ │
│  │  • Note Spawner                                            │ │
│  │  • Score Manager                                           │ │
│  │  • Chart Parser System                                     │ │
│  │  • Timeline Controller                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Persistent Systems                       │ │
│  │  • Settings Manager (Autoload)                             │ │
│  │  • Scene Switcher (Autoload)                               │ │
│  │  • Resource Cache (Autoload)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                            │ Display/Audio Output
                            ▼
                    ┌───────────────┐
                    │   Screen &    │
                    │   Speakers    │
                    │  [Feedback]   │
                    └───────────────┘

                    ┌───────────────┐
                    │   Settings    │
                    │   Storage     │
                    │ (user://)     │
                    └───────────────┘
```

---

## Component Overview

High-level organization of the system's major components and their relationships.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          APPLICATION LAYERS                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    PRESENTATION LAYER                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │  Main Menu   │  │ Song Select  │  │   Gameplay   │      │   │
│  │  │    Scene     │  │    Scene     │  │    Scene     │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │   Results    │  │   Settings   │  │  Loading     │      │   │
│  │  │    Scene     │  │    Scene     │  │   Screen     │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────────┐  │   │
│  │  │           3D Rendering Components                     │  │   │
│  │  │  • Board Renderer  • Note Visuals  • Hit Effects     │  │   │
│  │  └──────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     GAME LOGIC LAYER                         │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │   Gameplay   │  │    Input     │  │    Note      │      │   │
│  │  │ Orchestrator │  │   Handler    │  │   Spawner    │      │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │   │
│  │         │                 │                 │                │   │
│  │  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐      │   │
│  │  │    Score     │  │   Timeline   │  │  Animation   │      │   │
│  │  │   Manager    │  │  Controller  │  │   Director   │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                       DATA LAYER                             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │   Parser     │  │   Chart      │  │     Ini      │      │   │
│  │  │   Factory    │  │   Parser     │  │   Parser     │      │   │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘      │   │
│  │         │          ┌──────────────┐                         │   │
│  │         └─────────▶│     Midi     │                         │   │
│  │                    │   Parser     │                         │   │
│  │                    └──────────────┘                         │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │              Object Pools                            │   │   │
│  │  │  • Note Pool    • Hit Effect Pool                   │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  INFRASTRUCTURE LAYER                        │   │
│  │            (Autoload Singletons - Always Active)             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │   Settings   │  │    Scene     │  │   Resource   │      │   │
│  │  │   Manager    │  │   Switcher   │  │    Cache     │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Gameplay Scene Component Diagram

Detailed view of the gameplay scene and its internal components.

```
┌──────────────────────────────────────────────────────────────────────┐
│                      GAMEPLAY SCENE (gameplay.tscn)                   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │            GAMEPLAY ORCHESTRATOR (gameplay.gd)                │   │
│  │  [Root Script - Coordinates All Subsystems]                   │   │
│  │                                                                │   │
│  │  Properties:                                                   │   │
│  │  • chart_path: String                                         │   │
│  │  • instrument: String                                         │   │
│  │  • num_lanes: int                                             │   │
│  │  • audio_player: AudioStreamPlayer                            │   │
│  │  • preloaded_data: Dictionary                                 │   │
│  │                                                                │   │
│  │  Methods:                                                      │   │
│  │  • _ready() → Initialize all systems                          │   │
│  │  • start_countdown(callback) → 3-2-1 countdown               │   │
│  │  • _start_note_spawning() → Begin note execution             │   │
│  │  • _process(delta) → Audio sync, end detection               │   │
│  │  • _show_results() → Transition to results                    │   │
│  └─────────┬────────────────────────────────────────────────────┘   │
│            │                                                          │
│            │ Manages & Connects                                      │
│            │                                                          │
│  ┌─────────┴─────────┬────────────────┬──────────────┬──────────┐  │
│  │                   │                │              │          │  │
│  ▼                   ▼                ▼              ▼          ▼  │
│ ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────┐ │
│ │  Input   │  │   Note   │  │  Score   │  │ Timeline │  │ Board│ │
│ │ Handler  │  │ Spawner  │  │ Manager  │  │  Ctrl    │  │Render│ │
│ └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┘ │
│      │             │              │              │                  │
│      │             │              │              │                  │
│  ┌───▼─────────────▼──────────────▼──────────────▼───────────────┐ │
│  │                      SIGNAL CONNECTIONS                        │ │
│  ├────────────────────────────────────────────────────────────────┤ │
│  │  input_handler.note_hit → note_spawner._on_note_hit           │ │
│  │  input_handler.note_hit → gameplay._on_note_hit               │ │
│  │  note_spawner.note_spawned → gameplay._on_note_spawned        │ │
│  │  score_manager.combo_changed → gameplay._on_combo_changed     │ │
│  │  score_manager.score_changed → gameplay._on_score_changed     │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                        UI LAYER                                │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │  │
│  │  │ Score Label │  │ Combo Label │  │  Judgement  │           │  │
│  │  │             │  │             │  │    Label    │           │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘           │  │
│  │  ┌─────────────┐  ┌──────────────────────────────┐           │  │
│  │  │Pause Button │  │      Pause Menu              │           │  │
│  │  │             │  │  [Resume/End/Select/Menu]    │           │  │
│  │  └─────────────┘  └──────────────────────────────┘           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                      3D WORLD                                  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │  │
│  │  │   Runway    │  │  Hit Zones  │  │   Notes     │           │  │
│  │  │   (Mesh)    │  │ (MeshInst)  │  │ (Sprite3D)  │           │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘           │  │
│  │  ┌─────────────┐  ┌─────────────┐                            │  │
│  │  │ Lane Lines  │  │   Camera    │                            │  │
│  │  │   (Mesh)    │  │             │                            │  │
│  │  └─────────────┘  └─────────────┘                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    HELPER SYSTEMS                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │  │
│  │  │  Animation   │  │  Hit Effect  │  │   Note Pool  │        │  │
│  │  │   Director   │  │     Pool     │  │              │        │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘

LEGEND:
┌────┐
│    │  Component/Node
└────┘

  │     Relationship/Connection
  ▼     Direction of control/data flow
```

---

## Parser Subsystem

The parser subsystem handles loading and interpreting different chart file formats.

```
┌──────────────────────────────────────────────────────────────────┐
│                      PARSER SUBSYSTEM                             │
└──────────────────────────────────────────────────────────────────┘

                        ┌────────────────────┐
                        │  ParserFactory     │
                        │  (Factory Pattern) │
                        ├────────────────────┤
                        │ Methods:           │
                        │ • create_parser_   │
                        │   for_file()       │
                        │ • create_metadata_ │
                        │   parser()         │
                        │ • is_supported_    │
                        │   file()           │
                        └──────┬─────────────┘
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
                 ▼             ▼             ▼
        ┌────────────┐  ┌────────────┐  ┌────────────┐
        │   Chart    │  │    Midi    │  │    Ini     │
        │   Parser   │  │   Parser   │  │   Parser   │
        ├────────────┤  ├────────────┤  ├────────────┤
        │ .chart     │  │ .mid/.midi │  │ song.ini   │
        │ files      │  │ files      │  │ metadata   │
        └──────┬─────┘  └──────┬─────┘  └──────┬─────┘
               │                │                │
               │ implements     │ implements     │ implements
               ▼                ▼                ▼
        ┌──────────────────────────────────────────────┐
        │         ParserInterface (Protocol)           │
        ├──────────────────────────────────────────────┤
        │ • load_chart(path) → Dictionary              │
        │ • get_resolution(sections) → int             │
        │ • get_offset(sections) → float               │
        │ • get_tempo_events(sections) → Array         │
        │ • get_notes(sections, instrument) → Array    │
        │ • get_music_stream(sections) → String        │
        └──────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│              CHART PARSER INTERNAL STRUCTURE                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  INPUT: notes.chart file                                          │
│  ┌────────────────────────────────────────┐                      │
│  │ [Song]                                 │                      │
│  │ {                                      │                      │
│  │   Name = "Song Title"                  │                      │
│  │   Resolution = 192                     │                      │
│  │   Offset = 0                           │                      │
│  │ }                                      │                      │
│  │ [SyncTrack]                            │                      │
│  │ {                                      │                      │
│  │   0 = TS 4                            │                      │
│  │   0 = B 120000                        │                      │
│  │   768 = B 140000                      │                      │
│  │ }                                      │                      │
│  │ [ExpertSingle]                         │                      │
│  │ {                                      │                      │
│  │   0 = N 0 0                           │                      │
│  │   192 = N 1 0                         │                      │
│  │ }                                      │                      │
│  └────────────────────────────────────────┘                      │
│                      │                                            │
│                      │ Parse                                      │
│                      ▼                                            │
│  ┌────────────────────────────────────────┐                      │
│  │ PARSED STRUCTURE (Dictionary)          │                      │
│  ├────────────────────────────────────────┤                      │
│  │ {                                      │                      │
│  │   "Song": [                            │                      │
│  │     "Name = \"Song Title\"",           │                      │
│  │     "Resolution = 192",                │                      │
│  │     "Offset = 0"                       │                      │
│  │   ],                                   │                      │
│  │   "SyncTrack": [                       │                      │
│  │     "0 = TS 4",                        │                      │
│  │     "0 = B 120000",                    │                      │
│  │     "768 = B 140000"                   │                      │
│  │   ],                                   │                      │
│  │   "ExpertSingle": [                    │                      │
│  │     "0 = N 0 0",                       │                      │
│  │     "192 = N 1 0"                      │                      │
│  │   ]                                    │                      │
│  │ }                                      │                      │
│  └────────────────────────────────────────┘                      │
│                      │                                            │
│                      │ Extract & Convert                          │
│                      ▼                                            │
│  ┌────────────────────────────────────────┐                      │
│  │ PROCESSED DATA                          │                      │
│  ├────────────────────────────────────────┤                      │
│  │ resolution: 192                         │                      │
│  │ offset: 0.0                             │                      │
│  │ tempo_events: [                         │                      │
│  │   {tick: 0, bpm: 120.0},               │                      │
│  │   {tick: 768, bpm: 140.0}              │                      │
│  │ ]                                       │                      │
│  │ notes: [                                │                      │
│  │   {pos: 0, fret: 0, length: 0,         │                      │
│  │    is_hopo: false, is_tap: false},     │                      │
│  │   {pos: 192, fret: 1, length: 0,       │                      │
│  │    is_hopo: true, is_tap: false}       │                      │
│  │ ]                                       │                      │
│  └────────────────────────────────────────┘                      │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    HOPO DETECTION ALGORITHM                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  For each note pair (prev_note, current_note):                   │
│                                                                    │
│  1. Calculate tick distance:                                      │
│     tick_diff = current_note.pos - prev_note.pos                 │
│                                                                    │
│  2. Check HOPO threshold:                                         │
│     hopo_threshold = resolution / 4  (48 ticks if res=192)       │
│                                                                    │
│  3. Natural HOPO conditions:                                      │
│     if tick_diff <= hopo_threshold AND                            │
│        current_note.fret != prev_note.fret:                       │
│         current_note.is_hopo = true                               │
│                                                                    │
│  4. Special fret modifiers (at same tick):                        │
│     • Fret 5 at same tick → Force HOPO on                        │
│     • Fret 6 at same tick → Force HOPO off                       │
│     • Fret 7 at same tick → Mark as TAP, convert to fret 5       │
│                                                                    │
│  5. Open note normalization:                                      │
│     if note.fret == 7:                                            │
│         note.fret = 5  (internal open representation)            │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Note Lifecycle Components

Detailed view of how notes are created, managed, and destroyed.

```
┌──────────────────────────────────────────────────────────────────┐
│                      NOTE LIFECYCLE SYSTEM                        │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 1: SPAWN DATA GENERATION (Initialization)                   │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │            NoteSpawner.start_spawning()                   │     │
│  └────────────┬─────────────────────────────────────────────┘     │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  For each parsed note:                                      │   │
│  │                                                             │   │
│  │  1. Convert tick position → hit_time (seconds)             │   │
│  │     hit_time = get_note_times(note.pos, tempo_events)     │   │
│  │                                                             │   │
│  │  2. Calculate travel parameters:                           │   │
│  │     distance = abs(runway_begin_z)  // 25 units           │   │
│  │     travel_time = distance / note_speed  // e.g., 1.25s   │   │
│  │     spawn_time = hit_time - travel_time                   │   │
│  │                                                             │   │
│  │  3. Determine note type:                                   │   │
│  │     note_type = get_note_type(note)                       │   │
│  │     // REGULAR, HOPO, TAP, or OPEN                        │   │
│  │                                                             │   │
│  │  4. Handle sustains:                                       │   │
│  │     if note.length > 0:                                    │   │
│  │       sustain_length = (length/res) * (60/BPM)           │   │
│  │                                                             │   │
│  │  5. Create spawn_data entry:                              │   │
│  │     spawn_data.append({                                    │   │
│  │       spawn_time: float,                                   │   │
│  │       lane: int,                                           │   │
│  │       hit_time: float,                                     │   │
│  │       note_type: int,                                      │   │
│  │       is_sustain: bool,                                    │   │
│  │       sustain_length: float,                               │   │
│  │       travel_time: float                                   │   │
│  │     })                                                      │   │
│  └────────────────────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Sort spawn_data by spawn_time (ascending)                 │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 2: COMMAND GENERATION (Timeline Integration)                │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │       NoteSpawner.build_spawn_commands()                  │     │
│  └────────────┬─────────────────────────────────────────────┘     │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  For each spawn_data entry:                                │   │
│  │    cmd = SpawnNoteCommand.new(spawn_data_entry)           │   │
│  │    commands.append(cmd)                                    │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  TimelineController.setup(ctx, commands, end_time)         │   │
│  │  • Stores commands in sorted log                           │   │
│  │  • Executes when current_time >= scheduled_time            │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 3: NOTE INSTANTIATION (Runtime Spawning)                    │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Timeline reaches spawn_time                                        │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  SpawnNoteCommand.execute(ctx)                             │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  spawner._command_spawn_note(...)                          │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  note = note_pool.get_note()                               │   │
│  │  • Reuse existing note from pool                           │   │
│  │  • OR instantiate new note.tscn                            │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Configure Note Instance:                                  │   │
│  │  • position = Vector3(lane_x, 0, initial_z)               │   │
│  │  • expected_hit_time = hit_time                            │   │
│  │  • note_type = REGULAR/HOPO/TAP/OPEN                      │   │
│  │  • fret = lane_index                                       │   │
│  │  • is_sustain = bool                                       │   │
│  │  • sustain_length = float                                  │   │
│  │  • travel_time = float                                     │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  note.update_visuals()                                     │   │
│  │  • Load texture based on fret and note_type                │   │
│  │  • Create sustain tail if needed                           │   │
│  │  • Set render priority                                     │   │
│  └────────────┬───────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  active_notes.append(note)                                 │   │
│  │  emit_signal("note_spawned", note)                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 4: NOTE MOVEMENT (Per-Frame Update)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Note._process(delta)                                      │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  direction = -1 if reverse_mode else 1               │ │   │
│  │  │  position.z += note_speed * delta * direction        │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│               │                                                     │
│               │ Position Timeline:                                 │
│               │                                                     │
│               │  Z = -25      Z = 0 (hit)     Z = 5 (miss)        │
│               │    │            │                │                  │
│               │    ▼            ▼                ▼                  │
│               │  [Spawn]────>[Hit Line]────>[Expired]              │
│               │                                                     │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Miss Detection (if z >= 5 and not was_hit):              │   │
│  │    emit_signal("note_miss", self)                          │   │
│  │    was_hit = true                                          │   │
│  │    visible = false                                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 5: NOTE DESTRUCTION (Hit or Miss)                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  HIT PATH:                                                          │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  InputHandler detects key press                            │   │
│  │    ▼                                                        │   │
│  │  emit_signal("note_hit", note, grade)                      │   │
│  │    ▼                                                        │   │
│  │  NoteSpawner._on_note_hit(note, grade)                     │   │
│  │    ▼                                                        │   │
│  │  If not sustain:                                           │   │
│  │    active_notes.erase(note)                                │   │
│  │    note_pool.return_note(note)                             │   │
│  │    _spawn_hit_effect(note)                                 │   │
│  │  Else (sustain):                                           │   │
│  │    note.was_hit = true                                     │   │
│  │    Keep in active_notes until tail completes               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  MISS PATH:                                                         │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Note detects z >= miss_threshold                          │   │
│  │    ▼                                                        │   │
│  │  emit_signal("note_miss", self)                            │   │
│  │    ▼                                                        │   │
│  │  Gameplay._on_note_miss(note)                              │   │
│  │    ▼                                                        │   │
│  │  ScoreManager.add_miss() // Reset combo                    │   │
│  │    ▼                                                        │   │
│  │  Note marked invisible, will be cleaned up next frame      │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  CLEANUP PASS (Every Frame):                                       │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  NoteSpawner._cleanup_pass()                               │   │
│  │  For each note in active_notes (reverse iteration):        │   │
│  │    If not is_instance_valid(note):                         │   │
│  │      active_notes.remove_at(i)                             │   │
│  │    If note.position.z > runway_end_z:                      │   │
│  │      active_notes.remove_at(i)                             │   │
│  │      note_pool.return_note(note)                           │   │
│  │    If not note.visible:                                    │   │
│  │      active_notes.remove_at(i)                             │   │
│  │      note_pool.return_note(note)                           │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

---

## Input Processing Components

Detailed view of the input handling and hit detection system.

```
┌──────────────────────────────────────────────────────────────────┐
│                  INPUT PROCESSING ARCHITECTURE                    │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  INPUT HANDLER COMPONENT (input_handler.gd)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  STATE DATA                                               │     │
│  │  ├─────────────────────────────────────────────────────┐ │     │
│  │  │ lane_keys: Array[int]                               │ │     │
│  │  │   Example: [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L]     │ │     │
│  │  │                                                      │ │     │
│  │  │ key_states: Array[bool]                             │ │     │
│  │  │   Example: [false, true, false, true, false]       │ │     │
│  │  │            (F and K are pressed)                    │ │     │
│  │  │                                                      │ │     │
│  │  │ lanes: Array[float]                                 │ │     │
│  │  │   Lane X positions in 3D space                      │ │     │
│  │  │                                                      │ │     │
│  │  │ original_materials: Array[Material]                 │ │     │
│  │  │   For hit zone visual feedback                      │ │     │
│  │  │                                                      │ │     │
│  │  │ key_changed_this_frame: bool                        │ │     │
│  │  │   Flag to optimize processing                       │ │     │
│  │  │                                                      │ │     │
│  │  │ processed_frame_id: int                             │ │     │
│  │  │   Prevents duplicate processing                     │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 1: KEY STATE TRACKING (_input event handler)                │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  OS/Godot Input System                                              │
│         │                                                            │
│         │ InputEventKey                                             │
│         ▼                                                            │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  InputHandler._input(event)                                │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  if event is InputEventKey and not event.echo:       │ │   │
│  │  │                                                       │ │   │
│  │  │    for i in range(lane_keys.size()):                │ │   │
│  │  │      if event.keycode == lane_keys[i]:              │ │   │
│  │  │                                                       │ │   │
│  │  │        if event.pressed:                            │ │   │
│  │  │          // KEY DOWN                                │ │   │
│  │  │          key_states[i] = true                       │ │   │
│  │  │          light_up_zone(i, true)                     │ │   │
│  │  │          key_changed_this_frame = true              │ │   │
│  │  │                                                       │ │   │
│  │  │        else:                                         │ │   │
│  │  │          // KEY UP                                  │ │   │
│  │  │          key_states[i] = false                      │ │   │
│  │  │          light_up_zone(i, false)                    │ │   │
│  │  │          key_changed_this_frame = true              │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  RESULT: Immediate visual feedback + state tracking                │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 2: HIT DETECTION (_process per frame)                       │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  InputHandler._process(delta)                              │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  // Frame deduplication                              │ │   │
│  │  │  frame_id = Engine.get_frames_drawn()               │ │   │
│  │  │  if frame_id == processed_frame_id: return          │ │   │
│  │  │  processed_frame_id = frame_id                      │ │   │
│  │  │                                                       │ │   │
│  │  │  // Only process if keys changed (optimization)     │ │   │
│  │  │  if key_changed_this_frame:                         │ │   │
│  │  │    for i in range(key_states.size()):              │ │   │
│  │  │      if key_states[i]:  // Key is pressed          │ │   │
│  │  │        check_hit(i)     // Check this lane         │ │   │
│  │  │    key_changed_this_frame = false                  │ │   │
│  │  │                                                       │ │   │
│  │  │  // Sustain scoring (continuous)                    │ │   │
│  │  │  for i in range(key_states.size()):                │ │   │
│  │  │    if key_states[i] and has_sustain_held(i):       │ │   │
│  │  │      score_manager.add_sustain_score(delta)        │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  KEY INSIGHT: All pressed keys checked in same frame                │
│              → Enables accurate chord detection                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  PHASE 3: HIT GRADING (check_hit algorithm)                        │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  check_hit(lane_index)                                     │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  STEP 1: Get current time                            │ │   │
│  │  │  current_time = gameplay._get_song_time()            │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 2: Get timing windows from SettingsManager    │ │   │
│  │  │  perfect_window = 0.025s  (±25ms)                   │ │   │
│  │  │  great_window = 0.05s     (±50ms)                   │ │   │
│  │  │  good_window = 0.1s       (±100ms)                  │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 3: Find candidate notes in this lane          │ │   │
│  │  │  lane_x = lanes[lane_index]                         │ │   │
│  │  │  best_note = null                                    │ │   │
│  │  │  best_diff = 9999.0                                  │ │   │
│  │  │                                                       │ │   │
│  │  │  for note in note_spawner.active_notes:             │ │   │
│  │  │    if note.was_hit: continue  // Skip hit notes     │ │   │
│  │  │    if abs(note.position.x - lane_x) < 0.1:          │ │   │
│  │  │      // Note is in this lane                        │ │   │
│  │  │      diff = abs(current_time - note.expected_hit)   │ │   │
│  │  │      if diff <= good_window and diff < best_diff:   │ │   │
│  │  │        best_diff = diff                             │ │   │
│  │  │        best_note = note                             │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 4: Grade the best candidate                   │ │   │
│  │  │  if best_note:                                       │ │   │
│  │  │    grade = BAD                                       │ │   │
│  │  │    if best_diff <= perfect_window:                  │ │   │
│  │  │      grade = PERFECT                                │ │   │
│  │  │    elif best_diff <= great_window:                  │ │   │
│  │  │      grade = GREAT                                  │ │   │
│  │  │    elif best_diff <= good_window:                   │ │   │
│  │  │      grade = GOOD                                   │ │   │
│  │  │                                                       │ │   │
│  │  │    STEP 5: Emit hit signal                          │ │   │
│  │  │    emit_signal("note_hit", best_note, grade)        │ │   │
│  │  │    best_note.was_hit = true                         │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  TIMING WINDOW VISUALIZATION                                        │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Time relative to expected_hit_time:                                │
│                                                                      │
│  ◄────────┼────────┼────────┼────────┼────────┼────────┼────────► │
│  -100ms  -50ms   -25ms     0ms     +25ms    +50ms   +100ms         │
│           │        │        │        │        │        │             │
│   ┌───────┴────────┴────────┴────────┴────────┴────────┴───────┐   │
│   │                                                             │   │
│   │         ┌──────────────────────────────────┐              │   │
│   │         │         GOOD WINDOW              │              │   │
│   │         │      ±100ms (0.1 seconds)        │              │   │
│   │         ├──────────────────────────────────┤              │   │
│   │         │    ┌────────────────────────┐    │              │   │
│   │         │    │    GREAT WINDOW         │   │              │   │
│   │         │    │  ±50ms (0.05 seconds)  │    │              │   │
│   │         │    ├────────────────────────┤    │              │   │
│   │         │    │  ┌──────────────────┐  │    │              │   │
│   │         │    │  │ PERFECT WINDOW   │  │    │              │   │
│   │         │    │  │±25ms (0.025 sec) │  │    │              │   │
│   │         │    │  └──────────────────┘  │    │              │   │
│   │         │    └────────────────────────┘    │              │   │
│   │         └──────────────────────────────────┘              │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Outside GOOD window = MISS (note expires)                          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  CHORD DETECTION EXAMPLE                                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Scenario: Player presses D and F keys simultaneously               │
│           (Green and Red notes)                                     │
│                                                                      │
│  Frame N:                                                            │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  _input(event) - D key pressed:                            │   │
│  │    key_states[0] = true                                    │   │
│  │    key_changed_this_frame = true                           │   │
│  │                                                             │   │
│  │  _input(event) - F key pressed:                            │   │
│  │    key_states[1] = true                                    │   │
│  │    key_changed_this_frame = true (already set)            │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Frame N+1:                                                          │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  _process(delta):                                           │   │
│  │    key_changed_this_frame is true                          │   │
│  │    ▼                                                        │   │
│  │    check_hit(0)  // Check lane 0 (Green)                   │   │
│  │      → Finds note in lane 0 at correct time               │   │
│  │      → Emits note_hit for Green note                       │   │
│  │    ▼                                                        │   │
│  │    check_hit(1)  // Check lane 1 (Red)                     │   │
│  │      → Finds note in lane 1 at correct time               │   │
│  │      → Emits note_hit for Red note                         │   │
│  │    ▼                                                        │   │
│  │    RESULT: Both notes hit in same frame = CHORD DETECTED!  │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  This is why frame-based processing is critical!                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  VISUAL FEEDBACK SYSTEM (light_up_zone)                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  light_up_zone(lane_index, is_pressed)                     │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  // Get hit zone mesh node                           │ │   │
│  │  │  zone = gameplay.get_node("HitZone" + str(index))   │ │   │
│  │  │                                                       │ │   │
│  │  │  if is_pressed:                                      │ │   │
│  │  │    // Light up                                       │ │   │
│  │  │    mat = original_materials[index].duplicate()      │ │   │
│  │  │    mat.albedo_color = mat.albedo_color.lightened()  │ │   │
│  │  │    zone.material_override = mat                     │ │   │
│  │  │    animation_director.animate_lane_press(zone, true)│ │   │
│  │  │  else:                                               │ │   │
│  │  │    // Restore original                              │ │   │
│  │  │    zone.material_override = original_materials[i]   │ │   │
│  │  │    animation_director.animate_lane_press(zone, false)│ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  VISUAL RESULT:                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Key Released:         Key Pressed:                        │   │
│  │  ┌────────┐            ┌────────┐                          │   │
│  │  │ Green  │ Normal     │ Green  │ Brighter + Scale 1.08   │   │
│  │  │  Zone  │ Color      │  Zone  │                          │   │
│  │  └────────┘            └────────┘                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Scoring System Components

Detailed view of the scoring calculation and combo tracking system.

```
┌──────────────────────────────────────────────────────────────────┐
│                    SCORING SYSTEM ARCHITECTURE                    │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCORE MANAGER COMPONENT (ScoreManager.gd)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  STATE DATA                                               │     │
│  │  ├─────────────────────────────────────────────────────┐ │     │
│  │  │ combo: int = 0                                       │ │     │
│  │  │ score: float = 0                                     │ │     │
│  │  │ max_combo: int = 0                                   │ │     │
│  │  │ grade_counts: Dictionary = {                         │ │     │
│  │  │   "perfect": 0,                                      │ │     │
│  │  │   "great": 0,                                        │ │     │
│  │  │   "good": 0,                                         │ │     │
│  │  │   "bad": 0,                                          │ │     │
│  │  │   "miss": 0                                          │ │     │
│  │  │ }                                                     │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  │                                                            │     │
│  │  SIGNALS:                                                  │     │
│  │  • combo_changed(combo: int)                              │     │
│  │  • score_changed(score: float)                            │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCORE CALCULATION ALGORITHM                                        │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  add_hit(grade: int, note_type: NoteType.Type)             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  STEP 1: Increase combo                              │ │   │
│  │  │  combo += 1                                          │ │   │
│  │  │  if combo > max_combo:                               │ │   │
│  │  │    max_combo = combo                                 │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 2: Get base score from grade                  │ │   │
│  │  │  base_score = match grade:                           │ │   │
│  │  │    PERFECT: 10                                       │ │   │
│  │  │    GREAT:    8                                       │ │   │
│  │  │    GOOD:     5                                       │ │   │
│  │  │    BAD:      3                                       │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 3: Update grade counts                        │ │   │
│  │  │  grade_counts[grade_name] += 1                       │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 4: Get type multiplier                        │ │   │
│  │  │  type_multiplier = get_type_multiplier(note_type)   │ │   │
│  │  │    REGULAR: 1x                                       │ │   │
│  │  │    HOPO:    2x                                       │ │   │
│  │  │    TAP:     2x                                       │ │   │
│  │  │    OPEN:    1x                                       │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 5: Calculate final score                      │ │   │
│  │  │  score += base_score × combo × type_multiplier      │ │   │
│  │  │                                                       │ │   │
│  │  │  STEP 6: Emit signals                               │ │   │
│  │  │  emit_signal("combo_changed", combo)                │ │   │
│  │  │  emit_signal("score_changed", score)                │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCORING EXAMPLE CALCULATIONS                                       │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Example 1: PERFECT hit on REGULAR note, combo = 5                 │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  base_score = 10 (PERFECT)                                 │   │
│  │  type_multiplier = 1 (REGULAR)                             │   │
│  │  combo = 5                                                  │   │
│  │  points_added = 10 × 5 × 1 = 50                            │   │
│  │  new_score = old_score + 50                                │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example 2: GREAT hit on HOPO note, combo = 10                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  base_score = 8 (GREAT)                                    │   │
│  │  type_multiplier = 2 (HOPO)                                │   │
│  │  combo = 10                                                 │   │
│  │  points_added = 8 × 10 × 2 = 160                           │   │
│  │  new_score = old_score + 160                               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example 3: GOOD hit on TAP note, combo = 50                       │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  base_score = 5 (GOOD)                                     │   │
│  │  type_multiplier = 2 (TAP)                                 │   │
│  │  combo = 50                                                 │   │
│  │  points_added = 5 × 50 × 2 = 500                           │   │
│  │  new_score = old_score + 500                               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SUSTAIN SCORING                                                    │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  add_sustain_score(delta: float)                           │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  // Called every frame while sustain is held         │ │   │
│  │  │  sustain_points = delta × combo                      │ │   │
│  │  │  score += sustain_points                             │ │   │
│  │  │  emit_signal("score_changed", score)                 │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example: Holding sustain for 2 seconds at combo 20                │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Frame rate: 60 FPS                                        │   │
│  │  delta per frame: ~0.0167 seconds                          │   │
│  │  Frames in 2 seconds: 120 frames                           │   │
│  │                                                             │   │
│  │  Per frame: 0.0167 × 20 = 0.334 points                    │   │
│  │  Total: 0.334 × 120 = ~40 points                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  MISS HANDLING                                                      │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  add_miss()                                                 │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  combo = 0                                           │ │   │
│  │  │  grade_counts.miss += 1                              │ │   │
│  │  │  emit_signal("combo_changed", combo)                 │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  NOTE: Misses reset combo but do NOT deduct score                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  REVERSIBLE OPERATIONS (Timeline Support)                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For timeline scrubbing, ScoreManager provides undo operations:    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  remove_hit(grade, note_type, prev_combo, score_delta)     │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  // Reverse a hit                                    │ │   │
│  │  │  combo = prev_combo                                  │ │   │
│  │  │  score -= score_delta                                │ │   │
│  │  │  grade_counts[grade] -= 1                            │ │   │
│  │  │  emit signals                                        │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  remove_miss(prev_combo)                                   │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  // Reverse a miss                                   │ │   │
│  │  │  grade_counts.miss -= 1                              │ │   │
│  │  │  combo = prev_combo                                  │ │   │
│  │  │  emit signals                                        │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Used by HitNoteCommand and MissNoteCommand during timeline undo  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCORING FLOW DIAGRAM                                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Input Handler                                                      │
│       │                                                              │
│       │ note_hit(note, grade)                                       │
│       ▼                                                              │
│  ┌─────────────────────────────────┐                               │
│  │  Gameplay._on_note_hit()        │                               │
│  └────────┬───────────┬────────────┘                               │
│           │           │                                              │
│           │           └──────────────────────┐                      │
│           │                                  │                      │
│           ▼                                  ▼                      │
│  ┌─────────────────────────┐    ┌──────────────────────────┐      │
│  │ ScoreManager.add_hit()  │    │  Visual Feedback:        │      │
│  │                         │    │  • Judgment Label        │      │
│  │ • Increment combo       │    │  • Hit Effect            │      │
│  │ • Calculate points      │    │  • Animation             │      │
│  │ • Update grade_counts   │    └──────────────────────────┘      │
│  │ • Emit signals          │                                        │
│  └────────┬────────────────┘                                        │
│           │                                                          │
│           │ combo_changed / score_changed                          │
│           ▼                                                          │
│  ┌─────────────────────────────────┐                               │
│  │  UI Updates:                    │                               │
│  │  • $UI/ScoreLabel.text          │                               │
│  │  • $UI/ComboLabel.text          │                               │
│  │  • Animation Director effects   │                               │
│  └─────────────────────────────────┘                               │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Timeline & Command System

Detailed view of the timeline controller and command pattern implementation.

```
┌──────────────────────────────────────────────────────────────────┐
│              TIMELINE CONTROLLER ARCHITECTURE                     │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  TIMELINE CONTROLLER COMPONENT (TimelineController.gd)             │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  STATE DATA                                               │     │
│  │  ├─────────────────────────────────────────────────────┐ │     │
│  │  │ command_log: Array[ICommand]                        │ │     │
│  │  │   Sorted by scheduled_time                          │ │     │
│  │  │                                                      │ │     │
│  │  │ executed_count: int                                 │ │     │
│  │  │   Boundary between executed/not-executed            │ │     │
│  │  │                                                      │ │     │
│  │  │ current_time: float                                 │ │     │
│  │  │   Current song position in seconds                  │ │     │
│  │  │                                                      │ │     │
│  │  │ direction: int                                      │ │     │
│  │  │   1 = forward playback, -1 = reverse               │ │     │
│  │  │                                                      │ │     │
│  │  │ ctx: Dictionary                                     │ │     │
│  │  │   Shared context for commands                       │ │     │
│  │  │   {note_spawner, note_pool, score_manager, ...}    │ │     │
│  │  │                                                      │ │     │
│  │  │ song_end_time: float                                │ │     │
│  │  │   Total song duration                               │ │     │
│  │  │                                                      │ │     │
│  │  │ active: bool                                        │ │     │
│  │  │   Timeline processing enabled                       │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  COMMAND LOG STRUCTURE                                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  command_log = [                                                    │
│    ┌───────────────────────────────────────────────────┐           │
│    │ SpawnNoteCommand                                  │           │
│    │ scheduled_time: 0.5                               │           │
│    │ lane: 0, hit_time: 1.75, note_type: REGULAR      │           │
│    ├───────────────────────────────────────────────────┤           │
│    │ SpawnNoteCommand                                  │           │
│    │ scheduled_time: 0.7                               │           │
│    │ lane: 1, hit_time: 1.95, note_type: HOPO         │           │
│    ├───────────────────────────────────────────────────┤           │
│    │ SpawnNoteCommand                                  │           │
│    │ scheduled_time: 1.0                               │           │
│    │ lane: 2, hit_time: 2.25, note_type: TAP          │           │
│    ├───────────────────────────────────────────────────┤           │
│    │ HitNoteCommand (added at runtime)                │           │
│    │ scheduled_time: 1.75                              │           │
│    │ grade: PERFECT, prev_combo: 4                    │           │
│    ├───────────────────────────────────────────────────┤           │
│    │ HitNoteCommand (added at runtime)                │           │
│    │ scheduled_time: 1.95                              │           │
│    │ grade: GREAT, prev_combo: 5                      │           │
│    └───────────────────────────────────────────────────┘           │
│  ]                                                                   │
│                                                                      │
│  executed_count = 3  (first 3 commands executed)                   │
│  current_time = 1.0  (at third command)                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  TIMELINE EXECUTION ALGORITHM (advance_to)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  advance_to(target_time: float)                            │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  FORWARD EXECUTION:                                  │ │   │
│  │  │  while executed_count < command_log.size():          │ │   │
│  │  │    cmd = command_log[executed_count]                │ │   │
│  │  │    if cmd.scheduled_time <= target_time:            │ │   │
│  │  │      cmd.execute(ctx)                               │ │   │
│  │  │      executed_count += 1                            │ │   │
│  │  │    else:                                             │ │   │
│  │  │      break  // Haven't reached this command yet    │ │   │
│  │  │                                                       │ │   │
│  │  │  BACKWARD UNDO:                                      │ │   │
│  │  │  while executed_count > 0:                           │ │   │
│  │  │    cmd = command_log[executed_count - 1]            │ │   │
│  │  │    if cmd.scheduled_time > target_time:             │ │   │
│  │  │      executed_count -= 1                            │ │   │
│  │  │      cmd.undo(ctx)                                  │ │   │
│  │  │    else:                                             │ │   │
│  │  │      break  // Can't go back further               │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  TIMELINE VISUALIZATION                                             │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Time: 0.0s───────1.0s───────2.0s───────3.0s───────4.0s           │
│        │          │          │          │          │                │
│        ▼          ▼          ▼          ▼          ▼                │
│  ┌────●──────────●──────────●──────────●──────────●────────┐      │
│  │    │          │          │          │          │        │      │
│  │  Spawn    Spawn    Hit      Spawn    Miss     End      │      │
│  │  Note1    Note2    Note1    Note3    Note2             │      │
│  └────┼──────────┼──────────┼──────────┼──────────┼────────┘      │
│       │          │          │          │          │                 │
│       ▼          ▼          ▼          ▼          ▼                 │
│  executed_count progression:                                        │
│       0          1          2          3          4                 │
│                                                                      │
│  Scrubbing backward from 3.0s to 1.5s:                             │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  current_time = 3.0                                       │     │
│  │  executed_count = 4                                       │     │
│  │                                                            │     │
│  │  scrub_to(1.5)                                            │     │
│  │    ▼                                                       │     │
│  │  advance_to(1.5):                                         │     │
│  │    Undo command at 3.0s → executed_count = 3             │     │
│  │    Undo command at 2.0s → executed_count = 2             │     │
│  │    Stop (next command at 1.0s < 1.5s)                    │     │
│  │                                                            │     │
│  │  reposition_active_notes(1.5)                             │     │
│  │                                                            │     │
│  │  Result: Note1 and Note2 exist, positioned correctly     │     │
│  │          for time 1.5s                                    │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  COMMAND PATTERN IMPLEMENTATION                                     │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  BASE INTERFACE (Scripts/Commands/ICommand.gd)                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  extends RefCounted                                        │   │
│  │  class_name ICommand                                       │   │
│  │                                                             │   │
│  │  var scheduled_time: float                                 │   │
│  │                                                             │   │
│  │  func execute(ctx: Dictionary) -> void:                   │   │
│  │    assert(false, "Override in child")                     │   │
│  │                                                             │   │
│  │  func undo(ctx: Dictionary) -> void:                      │   │
│  │    assert(false, "Override in child")                     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SPAWNNOTECOMMAND STRUCTURE                                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  extends ICommand                                           │   │
│  │  class_name SpawnNoteCommand                               │   │
│  │                                                             │   │
│  │  var lane: int                                             │   │
│  │  var hit_time: float                                       │   │
│  │  var note_type: NoteType.Type                              │   │
│  │  var is_sustain: bool                                      │   │
│  │  var sustain_length: float                                 │   │
│  │  var travel_time: float                                    │   │
│  │  var spawned_note: Node = null  // Track for undo         │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func execute(ctx: Dictionary) -> void:             │ │   │
│  │  │    var pool = ctx.note_pool                          │ │   │
│  │  │    var spawner = ctx.note_spawner                    │ │   │
│  │  │                                                       │ │   │
│  │  │    spawned_note = pool.acquire()                     │ │   │
│  │  │    spawned_note.expected_hit_time = hit_time        │ │   │
│  │  │    spawned_note.note_type = note_type               │ │   │
│  │  │    spawned_note.lane = lane                          │ │   │
│  │  │                                                       │ │   │
│  │  │    if is_sustain:                                    │ │   │
│  │  │      spawned_note.set_sustain(sustain_length)       │ │   │
│  │  │                                                       │ │   │
│  │  │    // Position note at spawn point                  │ │   │
│  │  │    spawner.position_note(spawned_note, lane)        │ │   │
│  │  │    spawner.add_child(spawned_note)                  │ │   │
│  │  │    spawner.active_notes.append(spawned_note)        │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func undo(ctx: Dictionary) -> void:                │ │   │
│  │  │    if spawned_note:                                  │ │   │
│  │  │      var spawner = ctx.note_spawner                  │ │   │
│  │  │      var pool = ctx.note_pool                        │ │   │
│  │  │                                                       │ │   │
│  │  │      spawner.active_notes.erase(spawned_note)       │ │   │
│  │  │      spawned_note.get_parent().remove_child(...)    │ │   │
│  │  │      pool.release(spawned_note)                      │ │   │
│  │  │      spawned_note = null                             │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  HITNOTECOMMAND STRUCTURE                                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  extends ICommand                                           │   │
│  │  class_name HitNoteCommand                                 │   │
│  │                                                             │   │
│  │  var note: Node                                            │   │
│  │  var grade: int                                            │   │
│  │  var note_type: NoteType.Type                              │   │
│  │  var prev_combo: int                                       │   │
│  │  var score_delta: float                                    │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func execute(ctx: Dictionary) -> void:             │ │   │
│  │  │    var score_mgr = ctx.score_manager                 │ │   │
│  │  │                                                       │ │   │
│  │  │    // Store previous state                          │ │   │
│  │  │    prev_combo = score_mgr.combo                      │ │   │
│  │  │    var prev_score = score_mgr.score                 │ │   │
│  │  │                                                       │ │   │
│  │  │    // Apply hit                                      │ │   │
│  │  │    score_mgr.add_hit(grade, note_type)              │ │   │
│  │  │                                                       │ │   │
│  │  │    // Calculate what was added                      │ │   │
│  │  │    score_delta = score_mgr.score - prev_score       │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func undo(ctx: Dictionary) -> void:                │ │   │
│  │  │    var score_mgr = ctx.score_manager                 │ │   │
│  │  │    score_mgr.remove_hit(grade, note_type,           │ │   │
│  │  │                         prev_combo, score_delta)    │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  MISSNOTECOMMAND STRUCTURE                                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  extends ICommand                                           │   │
│  │  class_name MissNoteCommand                                │   │
│  │                                                             │   │
│  │  var note: Node                                            │   │
│  │  var prev_combo: int                                       │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func execute(ctx: Dictionary) -> void:             │ │   │
│  │  │    var score_mgr = ctx.score_manager                 │ │   │
│  │  │    prev_combo = score_mgr.combo                      │ │   │
│  │  │    score_mgr.add_miss()                              │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  func undo(ctx: Dictionary) -> void:                │ │   │
│  │  │    var score_mgr = ctx.score_manager                 │ │   │
│  │  │    score_mgr.remove_miss(prev_combo)                 │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  LATE-SPAWN POSITIONING ALGORITHM                                   │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Used when scrubbing forward requires spawning notes that should   │
│  already be partially along their path.                            │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  reposition_active_notes(current_time: float)               │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  for note in active_notes:                           │ │   │
│  │  │    // Calculate how long note has been traveling    │ │   │
│  │  │    time_since_spawn = current_time - spawn_time     │ │   │
│  │  │                                                       │ │   │
│  │  │    // Calculate position based on elapsed time      │ │   │
│  │  │    distance_traveled = note_speed × time_since_spawn │ │   │
│  │  │    new_z = runway_begin_z + distance_traveled       │ │   │
│  │  │                                                       │ │   │
│  │  │    // Apply position                                 │ │   │
│  │  │    note.position.z = new_z                          │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example:                                                            │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  runway_begin_z = -25                                      │   │
│  │  note_speed = 20 units/sec                                 │   │
│  │  spawn_time = 1.0s                                         │   │
│  │  current_time = 1.5s                                       │   │
│  │                                                             │   │
│  │  time_since_spawn = 1.5 - 1.0 = 0.5s                      │   │
│  │  distance_traveled = 20 × 0.5 = 10 units                  │   │
│  │  new_z = -25 + 10 = -15                                    │   │
│  │                                                             │   │
│  │  Note positioned at z=-15 (halfway to hit line at z=0)    │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## UI & Scene Management

System for managing scenes, transitions, and UI layer components.

```
┌──────────────────────────────────────────────────────────────────┐
│                   SCENE MANAGEMENT SYSTEM                         │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCENESWITCHER SINGLETON (SceneSwitcher.gd - Autoload)             │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  STATE DATA                                               │     │
│  │  ├─────────────────────────────────────────────────────┐ │     │
│  │  │ scene_stack: Array[Dictionary]                      │ │     │
│  │  │   Each entry: {scene: PackedScene, data: Dictionary}│ │     │
│  │  │                                                      │ │     │
│  │  │ current_scene: Node = null                          │ │     │
│  │  │   Currently active scene                            │ │     │
│  │  │                                                      │ │     │
│  │  │ is_transitioning: bool = false                      │ │     │
│  │  │   Prevents multiple simultaneous transitions        │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  │                                                            │     │
│  │  METHODS:                                                  │     │
│  │  • goto_scene(path: String, data: Dictionary = {})       │     │
│  │  • push_scene(path: String, data: Dictionary = {})       │     │
│  │  • pop_scene() -> void                                     │     │
│  │  • reload_scene() -> void                                  │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCENE STACK VISUALIZATION                                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Example: Main Menu → Song Select → Gameplay → Results             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Initial State:                                           │     │
│  │  scene_stack = []                                         │     │
│  │  current_scene = main_menu.tscn                           │     │
│  │                                                            │     │
│  │  User clicks "Play":                                      │     │
│  │  ▼                                                         │     │
│  │  goto_scene("res://Scenes/song_select.tscn")             │     │
│  │    scene_stack = []  (cleared)                            │     │
│  │    current_scene = song_select.tscn                       │     │
│  │                                                            │     │
│  │  User selects song:                                       │     │
│  │  ▼                                                         │     │
│  │  goto_scene("res://Scenes/gameplay.tscn", {              │     │
│  │    track_path = "res://Assets/Tracks/...",               │     │
│  │    chart_file = "notes.chart",                            │     │
│  │    difficulty = "Expert"                                  │     │
│  │  })                                                        │     │
│  │    scene_stack = []  (cleared)                            │     │
│  │    current_scene = gameplay.tscn                          │     │
│  │                                                            │     │
│  │  Song completes:                                          │     │
│  │  ▼                                                         │     │
│  │  push_scene("res://Scenes/results_screen.tscn", {        │     │
│  │    score = 125000,                                        │     │
│  │    max_combo = 287,                                       │     │
│  │    grade_counts = {...}                                   │     │
│  │  })                                                        │     │
│  │    scene_stack = [                                        │     │
│  │      {scene: gameplay.tscn, data: {...}}                 │     │
│  │    ]                                                       │     │
│  │    current_scene = results_screen.tscn                    │     │
│  │                                                            │     │
│  │  User clicks "Back":                                      │     │
│  │  ▼                                                         │     │
│  │  pop_scene()                                              │     │
│  │    scene_stack = []  (popped gameplay)                    │     │
│  │    current_scene = gameplay.tscn (restored)               │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SCENE TRANSITION FLOW                                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  goto_scene(path: String, data: Dictionary)                │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  if is_transitioning:                                │ │   │
│  │  │    return  // Prevent overlap                        │ │   │
│  │  │                                                       │ │   │
│  │  │  is_transitioning = true                             │ │   │
│  │  │                                                       │ │   │
│  │  │  // Clear scene stack (full replacement)            │ │   │
│  │  │  scene_stack.clear()                                 │ │   │
│  │  │                                                       │ │   │
│  │  │  // Load new scene                                   │ │   │
│  │  │  var new_scene = load(path).instantiate()           │ │   │
│  │  │                                                       │ │   │
│  │  │  // Remove current scene                             │ │   │
│  │  │  if current_scene:                                   │ │   │
│  │  │    current_scene.queue_free()                        │ │   │
│  │  │                                                       │ │   │
│  │  │  // Add new scene to tree                           │ │   │
│  │  │  get_tree().root.add_child(new_scene)               │ │   │
│  │  │  current_scene = new_scene                           │ │   │
│  │  │                                                       │ │   │
│  │  │  // Pass data if scene has _set_data method         │ │   │
│  │  │  if new_scene.has_method("_set_data"):              │ │   │
│  │  │    new_scene._set_data(data)                        │ │   │
│  │  │                                                       │ │   │
│  │  │  is_transitioning = false                            │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  UI LAYER ARCHITECTURE                                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Gameplay Scene UI Hierarchy:                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Gameplay                                                   │   │
│  │  └── UI (CanvasLayer)                                       │   │
│  │      ├── ScoreLabel (Label)                                │   │
│  │      │   Text: "Score: 125000"                             │   │
│  │      │   Position: Top-right                               │   │
│  │      │                                                      │   │
│  │      ├── ComboLabel (Label)                                │   │
│  │      │   Text: "Combo: 287"                                │   │
│  │      │   Position: Top-center                              │   │
│  │      │                                                      │   │
│  │      ├── JudgmentLabel (Label)                             │   │
│  │      │   Text: "PERFECT!"                                  │   │
│  │      │   Position: Center (fades after showing)           │   │
│  │      │                                                      │   │
│  │      ├── CountdownLabel (Label)                            │   │
│  │      │   Text: "3..." "2..." "1..." "GO!"                 │   │
│  │      │   Position: Center (only during countdown)         │   │
│  │      │                                                      │   │
│  │      ├── SongInfoLabel (Label)                             │   │
│  │      │   Text: "Artist - Title"                           │   │
│  │      │   Position: Top-left                                │   │
│  │      │                                                      │   │
│  │      └── ProgressBar (ProgressBar)                         │   │
│  │          Value: current_time / song_duration               │   │
│  │          Position: Bottom edge                             │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  RESULTS SCREEN DATA FLOW                                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Gameplay._show_results()                                   │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  var results_data = {                                │ │   │
│  │  │    "score": score_manager.score,                    │ │   │
│  │  │    "max_combo": score_manager.max_combo,            │ │   │
│  │  │    "grade_counts": score_manager.grade_counts,      │ │   │
│  │  │    "total_notes": total_notes,                      │ │   │
│  │  │    "track_name": track_name,                        │ │   │
│  │  │    "difficulty": difficulty                          │ │   │
│  │  │  }                                                    │ │   │
│  │  │                                                       │ │   │
│  │  │  SceneSwitcher.push_scene(                           │ │   │
│  │  │    "res://Scenes/results_screen.tscn",              │ │   │
│  │  │    results_data                                      │ │   │
│  │  │  )                                                    │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│               │                                                     │
│               ▼                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  ResultsScreen._set_data(data: Dictionary)                 │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  $ScoreLabel.text = "Score: %d" % data.score        │ │   │
│  │  │  $ComboLabel.text = "Max Combo: %d" % data.max_combo│ │   │
│  │  │  $TrackLabel.text = data.track_name                  │ │   │
│  │  │  $DifficultyLabel.text = data.difficulty             │ │   │
│  │  │                                                       │ │   │
│  │  │  // Populate grade breakdown                        │ │   │
│  │  │  $PerfectCount.text = str(data.grade_counts.perfect)│ │   │
│  │  │  $GreatCount.text = str(data.grade_counts.great)    │ │   │
│  │  │  $GoodCount.text = str(data.grade_counts.good)      │ │   │
│  │  │  $BadCount.text = str(data.grade_counts.bad)        │ │   │
│  │  │  $MissCount.text = str(data.grade_counts.miss)      │ │   │
│  │  │                                                       │ │   │
│  │  │  // Calculate accuracy                              │ │   │
│  │  │  var hit_notes = total_notes - data.grade_counts.miss│ │   │
│  │  │  var accuracy = (hit_notes / total_notes) * 100.0   │ │   │
│  │  │  $AccuracyLabel.text = "%.1f%%" % accuracy          │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  LOADING SCREEN SYSTEM                                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Used when loading large assets (audio, charts, textures)          │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  LoadingScreen.show_with_message(msg: String)              │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  $Label.text = msg                                   │ │   │
│  │  │  $AnimationPlayer.play("pulse")  // Spinner         │ │   │
│  │  │  visible = true                                      │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  LoadingScreen.hide()                                       │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │  visible = false                                     │ │   │
│  │  │  $AnimationPlayer.stop()                             │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example Usage:                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  func _ready():                                             │   │
│  │    LoadingScreen.show_with_message("Loading chart...")     │   │
│  │    await get_tree().process_frame                           │   │
│  │                                                              │   │
│  │    var parser = ChartParser.new()                           │   │
│  │    var sections = parser.load_chart(chart_path)             │   │
│  │                                                              │   │
│  │    LoadingScreen.show_with_message("Loading audio...")      │   │
│  │    await get_tree().process_frame                           │   │
│  │                                                              │   │
│  │    audio_stream = load(audio_path)                          │   │
│  │                                                              │   │
│  │    LoadingScreen.hide()                                     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Data Structures

Key data structures used throughout the system.

```
┌──────────────────────────────────────────────────────────────────┐
│                      DATA STRUCTURE REFERENCE                     │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SPAWN_DATA ENTRY (note_spawner.gd)                                │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Array of dictionaries, each representing a scheduled note spawn   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  {                                                          │   │
│  │    "spawn_time": float,                                    │   │
│  │      // Absolute time when note should appear              │   │
│  │      // = hit_time - travel_time                           │   │
│  │                                                             │   │
│  │    "lane": int,                                            │   │
│  │      // 0-4 (or 0-5 for 6-lane charts)                    │   │
│  │                                                             │   │
│  │    "hit_time": float,                                      │   │
│  │      // Absolute time when note should be hit              │   │
│  │                                                             │   │
│  │    "note_type": NoteType.Type,                             │   │
│  │      // REGULAR, HOPO, TAP, or OPEN                       │   │
│  │                                                             │   │
│  │    "is_sustain": bool,                                     │   │
│  │      // Whether note has sustain tail                      │   │
│  │                                                             │   │
│  │    "sustain_length": float,                                │   │
│  │      // Duration in seconds (0 if no sustain)             │   │
│  │                                                             │   │
│  │    "travel_time": float                                    │   │
│  │      // Time to travel from spawn to hit line              │   │
│  │      // = abs(runway_begin_z) / note_speed                │   │
│  │  }                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Example:                                                            │
│  spawn_data[0] = {                                                  │
│    spawn_time: 0.75,                                                │
│    lane: 2,                                                          │
│    hit_time: 2.0,                                                    │
│    note_type: NoteType.HOPO,                                        │
│    is_sustain: true,                                                │
│    sustain_length: 0.5,                                             │
│    travel_time: 1.25                                                │
│  }                                                                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  NOTE DICTIONARY (ChartParser.gd output)                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Parser output before conversion to spawn_data                     │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  {                                                          │   │
│  │    "pos": int,                                             │   │
│  │      // Tick position in chart                             │   │
│  │                                                             │   │
│  │    "fret": int,                                            │   │
│  │      // 0-7 (0-4 = lanes, 5-7 = special modifiers)       │   │
│  │                                                             │   │
│  │    "length": int,                                          │   │
│  │      // Sustain length in ticks (0 if no sustain)        │   │
│  │                                                             │   │
│  │    "is_hopo": bool,                                        │   │
│  │      // Marked as HOPO (forced or natural)                │   │
│  │                                                             │   │
│  │    "is_tap": bool                                          │   │
│  │      // Marked as TAP note                                 │   │
│  │  }                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  SECTIONS DICTIONARY (ChartParser.gd)                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Raw parsed .chart file structure                                  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  {                                                          │   │
│  │    "Song": [                                               │   │
│  │      "Name = \"Track Title\"",                             │   │
│  │      "Artist = \"Artist Name\"",                           │   │
│  │      "Charter = \"Charter Name\"",                         │   │
│  │      "Offset = 0",                                         │   │
│  │      "Resolution = 192",                                   │   │
│  │      "MusicStream = song.ogg"                              │   │
│  │    ],                                                       │   │
│  │                                                             │   │
│  │    "SyncTrack": [                                          │   │
│  │      "0 = TS 4",              // Time signature           │   │
│  │      "0 = B 120000",           // BPM (120 * 1000)        │   │
│  │      "768 = B 140000"          // BPM change at tick 768  │   │
│  │    ],                                                       │   │
│  │                                                             │   │
│  │    "ExpertSingle": [                                       │   │
│  │      "384 = N 2 0",            // Note at tick 384, fret 2│   │
│  │      "480 = N 3 192",          // Note at 480, sustain 192│   │
│  │      "576 = N 5 0"             // Special flag at 576     │   │
│  │    ],                                                       │   │
│  │                                                             │   │
│  │    "HardSingle": [...],                                    │   │
│  │    "MediumSingle": [...],                                  │   │
│  │    "EasySingle": [...]                                     │   │
│  │  }                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  TEMPO_EVENT ARRAY (ChartParser.gd)                                │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  [                                                          │   │
│  │    {                                                        │   │
│  │      "pos": 0,           // Starting tick                  │   │
│  │      "bpm": 120.0        // Tempo in BPM                   │   │
│  │    },                                                       │   │
│  │    {                                                        │   │
│  │      "pos": 768,         // Tempo change at tick 768       │   │
│  │      "bpm": 140.0                                          │   │
│  │    },                                                       │   │
│  │    {                                                        │   │
│  │      "pos": 1920,                                          │   │
│  │      "bpm": 180.0                                          │   │
│  │    }                                                        │   │
│  │  ]                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Used for tick-to-time conversion in varying tempo charts          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  COMMAND_LOG ARRAY (TimelineController.gd)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Array of ICommand instances, sorted by scheduled_time             │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  [                                                          │   │
│  │    SpawnNoteCommand {                                      │   │
│  │      scheduled_time: 0.5,                                  │   │
│  │      lane: 0,                                              │   │
│  │      hit_time: 1.75,                                       │   │
│  │      note_type: REGULAR                                    │   │
│  │    },                                                       │   │
│  │    SpawnNoteCommand { ... },                               │   │
│  │    HitNoteCommand {                                        │   │
│  │      scheduled_time: 1.75,                                 │   │
│  │      grade: PERFECT,                                       │   │
│  │      prev_combo: 5                                         │   │
│  │    },                                                       │   │
│  │    MissNoteCommand { ... }                                 │   │
│  │  ]                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Supports bidirectional execution via execute() and undo()         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  GRADE_COUNTS DICTIONARY (ScoreManager.gd)                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  {                                                          │   │
│  │    "perfect": 145,       // Count of perfect hits          │   │
│  │    "great": 38,          // Count of great hits            │   │
│  │    "good": 12,           // Count of good hits             │   │
│  │    "bad": 3,             // Count of bad hits              │   │
│  │    "miss": 5             // Count of misses                │   │
│  │  }                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Total notes = sum of all counts                                   │
│  Accuracy = (total - miss) / total × 100                           │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  ACTIVE_NOTES ARRAY (note_spawner.gd)                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Array of currently visible note Node instances                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  [                                                          │   │
│  │    <Note instance> {                                       │   │
│  │      expected_hit_time: 1.75,                              │   │
│  │      note_type: REGULAR,                                   │   │
│  │      lane: 0,                                              │   │
│  │      position: Vector3(x, 0, -15),                         │   │
│  │      is_hit: false                                         │   │
│  │    },                                                       │   │
│  │    <Note instance> { ... },                                │   │
│  │    <Note instance> { ... }                                 │   │
│  │  ]                                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Managed by NotePool for recycling                                 │
│  Cleared when notes are hit or pass end zone                       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

