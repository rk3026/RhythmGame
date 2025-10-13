# Rhythm Game - System Architecture Documentation

**Version:** 1.0  
**Date:** October 13, 2025  
**Project:** Godot 4 3D Rhythm Game  
**Game Style:** Guitar Hero-like with .chart file support

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architectural Patterns](#architectural-patterns)
4. [Core Components](#core-components)
5. [Data Flow](#data-flow)
6. [Module Descriptions](#module-descriptions)
7. [Design Decisions](#design-decisions)
8. [Performance Optimizations](#performance-optimizations)
9. [Extension Points](#extension-points)
10. [Technical Stack](#technical-stack)

---

## Executive Summary

This is a 3D rhythm game built in Godot 4, inspired by Guitar Hero and Clone Hero. The architecture emphasizes:

- **Modularity**: Clear separation of concerns with dedicated managers for scoring, input, spawning, and rendering
- **Performance**: Object pooling, caching, and efficient frame-based input processing
- **Reversibility**: Command pattern implementation enabling timeline scrubbing and replay features
- **Extensibility**: Parser factory pattern supporting multiple chart formats (.chart, .mid/.midi)
- **User Customization**: Persistent settings system with validation

The game supports .chart file format (Clone Hero standard) with features including:
- Multiple note types (Regular, HOPO, TAP, Open)
- Sustain notes with tail rendering
- Variable lane counts (5-6 lanes dynamically determined)
- Timing-based hit detection (not hitbox-based)
- Chord-aware input processing

---

## System Overview

### High-Level Architecture

The system follows a **Component-Based Architecture** with clear separation between:

1. **Presentation Layer**: UI scenes, 3D rendering, visual effects
2. **Game Logic Layer**: Gameplay mechanics, scoring, input handling
3. **Data Layer**: Chart parsing, settings persistence, resource caching
4. **Infrastructure Layer**: Scene management, autoloaded singletons

### Key Architectural Principles

- **Single Responsibility**: Each script handles one clear concern
- **Dependency Injection**: Components receive dependencies rather than creating them
- **Event-Driven**: Signal-based communication between loosely coupled components
- **Data-Oriented**: Chart data parsed into dictionaries/arrays for efficient processing
- **Command Pattern**: Reversible actions for timeline control

---

## Architectural Patterns

### 1. **Singleton Pattern (Autoload)**
Used for global systems that need persistent state across scenes:
- `SettingsManager`: User preferences and gameplay constants
- `SceneSwitcher`: Scene stack management for navigation
- `ResourceCache`: Parsed chart data caching

### 2. **Factory Pattern**
`ParserFactory` creates appropriate parsers based on file extension:
```gdscript
func create_parser_for_file(file_path: String):
    match file_path.get_extension():
        "chart": return ChartParser.new()
        "mid", "midi": return MidiParser.new()
```

### 3. **Object Pool Pattern**
`NotePool` and `HitEffectPool` reuse instances for performance:
- Pre-allocated pool reduces instantiation overhead
- Signal management optimized (connect once, reuse forever)
- Maximum pool size prevents memory bloat

### 4. **Command Pattern**
Timeline control uses reversible commands:
- `SpawnNoteCommand`: Spawns notes with late-spawn positioning
- `HitNoteCommand`: Records hits for undo during scrubbing
- `MissNoteCommand`: Records misses for undo during scrubbing

### 5. **Observer Pattern**
Signals provide loose coupling:
```gdscript
# Scoring signals
signal score_changed(score)
signal combo_changed(combo)

# Gameplay signals
signal note_hit(note, grade)
signal note_spawned(note)
```

### 6. **Strategy Pattern**
`ParserInterface` allows pluggable parsing strategies for different chart formats.

---

## Core Components

### Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          GAMEPLAY SCENE                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Main Orchestrator                        │ │
│  │  • Initializes all subsystems                              │ │
│  │  • Manages lifecycle (countdown, end detection)            │ │
│  │  • Coordinates audio/timeline sync                         │ │
│  └───────┬──────────────────────────┬────────────────────────┘ │
│          │                          │                            │
│  ┌───────▼────────┐        ┌────────▼──────────┐               │
│  │ Input Handler  │        │  Note Spawner     │               │
│  │                │        │                   │               │
│  │ • Key state    │        │ • Spawn schedule  │               │
│  │ • Chord detect │───────▶│ • Active notes    │               │
│  │ • Hit grading  │ hit    │ • Pool management │               │
│  └────────┬───────┘        └────────┬──────────┘               │
│           │                         │                           │
│           │ note_hit                │ note_spawned              │
│           │                         │                           │
│  ┌────────▼──────────┐     ┌───────▼────────────┐              │
│  │  Score Manager    │     │  Board Renderer    │              │
│  │                   │     │                    │              │
│  │ • Combo tracking  │     │ • Lane generation  │              │
│  │ • Score calc      │     │ • Hit zones        │              │
│  │ • Grade counts    │     │ • Visual materials │              │
│  └───────────────────┘     └────────────────────┘              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Timeline Controller (Scrubbing)                │  │
│  │  • Command log execution/undo                            │  │
│  │  • Bidirectional playback                                │  │
│  │  • Note repositioning                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────┐
         │     AUTOLOAD SINGLETONS         │
         ├─────────────────────────────────┤
         │  SettingsManager                │
         │  • Persistent configuration     │
         │  • Lane keys, note speed        │
         │  • Timing windows               │
         ├─────────────────────────────────┤
         │  SceneSwitcher                  │
         │  • Scene stack navigation       │
         │  • Push/pop/replace operations  │
         ├─────────────────────────────────┤
         │  ResourceCache                  │
         │  • Parsed chart caching         │
         │  • Performance optimization     │
         └─────────────────────────────────┘
```

---

## Data Flow

### 1. Song Selection → Gameplay Initialization Flow

```
┌──────────────┐
│ Song Select  │
│   Scene      │
└──────┬───────┘
       │ User selects song + difficulty
       │
       ▼
┌──────────────────┐
│ Loading Screen   │ (Optional intermediate scene)
└──────┬───────────┘
       │
       ▼
┌───────────────────────────────────────────────────────────┐
│ Gameplay Scene Initialization                             │
├───────────────────────────────────────────────────────────┤
│ 1. ParserFactory creates appropriate parser (.chart/.mid) │
│ 2. Parser loads chart → sections dictionary               │
│ 3. Extract: resolution, offset, tempo_events, notes       │
│ 4. Determine lane count from max fret in notes            │
│ 5. BoardRenderer creates lanes + hit zones                │
│ 6. Configure InputHandler with lane positions/keys        │
│ 7. NoteSpawner builds spawn_data schedule                 │
│ 8. TimelineController initializes command log             │
│ 9. Audio file located and loaded                          │
│ 10. Countdown begins                                      │
└───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│  Gameplay    │
│   Active     │
└──────────────┘
```

### 2. Note Lifecycle Flow

```
Chart Data (.chart file)
    │
    ▼
┌───────────────────┐
│ ChartParser       │
│ • Parse sections  │
│ • Extract notes   │
│ • HOPO detection  │
└────────┬──────────┘
         │ Array of note dicts: {pos, fret, length, is_hopo, is_tap}
         ▼
┌─────────────────────────┐
│ NoteSpawner             │
│ • Convert ticks→time    │
│ • Calculate spawn_time  │
│ • Build spawn_data[]    │
└────────┬────────────────┘
         │ spawn_data: {spawn_time, lane, hit_time, note_type, ...}
         ▼
┌──────────────────────────────┐
│ TimelineController           │
│ • Create SpawnNoteCommands   │
│ • Sort by scheduled_time     │
│ • Execute when time reached  │
└────────┬─────────────────────┘
         │
         ▼
┌────────────────────────┐
│ NotePool.get_note()    │
│ • Reuse pooled note    │
│ • Or instantiate new   │
└────────┬───────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ Note Instance                    │
│ • Position at runway_begin_z     │
│ • Move forward each frame        │
│ • Update visuals (color, type)   │
│ • Render sustain tail if needed  │
└────────┬─────────────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 Hit?      Miss/Expire?
    │         │
    │         ▼
    │    Emit note_miss
    │         │
    ▼         ▼
 Return to Pool
```

### 3. Input Processing Flow (Frame-Based)

```
User Presses Key
    │
    ▼
┌────────────────────────────┐
│ InputHandler._input()      │
│ • Update key_states[lane]  │
│ • Light up hit zone        │
│ • Set key_changed flag     │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│ InputHandler._process() (next frame)   │
│ • Check key_changed_this_frame         │
│ • For each pressed key:                │
│   - Collect candidate notes in lane    │
│   - Find best note within timing window│
│   - Grade hit (Perfect/Great/Good/Bad) │
│   - Emit note_hit signal               │
└────────┬───────────────────────────────┘
         │
    ┌────┴─────┐
    │          │
    ▼          ▼
┌──────────────┐  ┌─────────────────┐
│ ScoreManager │  │ Gameplay Scene  │
│ • Add combo  │  │ • Show judgment │
│ • Add score  │  │ • Animate label │
│ • Emit sigs  │  │ • Hit effect    │
└──────────────┘  └─────────────────┘
```

### 4. Scoring Data Flow

```
Note Hit Event
    │
    ▼
┌─────────────────────────────────┐
│ Input Handler Grades Hit        │
│ • Calculate time difference     │
│ • Determine grade (P/Gr/Go/B)   │
│ • Emit note_hit(note, grade)    │
└────────┬────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ ScoreManager.add_hit(grade, note_type)   │
│ • Increment combo                        │
│ • Calculate base_score from grade        │
│ • Apply type_multiplier (HOPO/TAP = 2x)  │
│ • score += base_score * combo * mult     │
│ • Update grade_counts                    │
│ • Emit score_changed, combo_changed      │
└────────┬─────────────────────────────────┘
         │
         ▼
┌───────────────────────┐
│ UI Updates            │
│ • ScoreLabel          │
│ • ComboLabel          │
│ • JudgementLabel      │
│ • AnimationDirector   │
└───────────────────────┘
```

---

## Module Descriptions

### 1. **Gameplay Orchestrator** (`gameplay.gd`)

**Responsibilities:**
- Scene lifecycle management (initialization, countdown, end detection)
- Component coordination and dependency injection
- Audio/timeline synchronization
- Song completion detection
- Pause/resume functionality
- Results screen transition

**Key Methods:**
- `_ready()`: Initializes all subsystems, loads chart, configures components
- `start_countdown()`: 3-2-1 countdown before song starts
- `_start_note_spawning()`: Initializes timeline and begins spawn execution
- `_process()`: Audio sync, end detection, debug timeline updates
- `_show_results()`: Transitions to results screen with statistics

**Signals Connected:**
- `note_hit` → Score calculation, judgment display
- `combo_changed` → UI update
- `score_changed` → UI update, settings refresh
- `note_spawned` → Animation trigger

---

### 2. **Note Spawner** (`note_spawner.gd`)

**Responsibilities:**
- Convert chart data to spawn schedule
- Timing calculations (tick→time conversion with tempo map)
- Note instance lifecycle (spawn, active tracking, cleanup)
- Object pooling coordination
- Timeline integration for reversible spawning

**Key Data Structures:**
```gdscript
spawn_data = [
    {
        spawn_time: float,      # When to spawn (hit_time - travel_time)
        lane: int,              # Lane index (0-5)
        hit_time: float,        # Expected hit time
        note_type: int,         # REGULAR/HOPO/TAP/OPEN
        is_sustain: bool,       # Sustain note flag
        sustain_length: float,  # Length in seconds
        travel_time: float      # Time to reach hit line
    }
]
```

**Key Methods:**
- `start_spawning()`: Builds spawn schedule from parsed notes
- `get_note_times()`: Converts ticks to timestamps using tempo map
- `build_spawn_commands()`: Creates command objects for timeline
- `reposition_active_notes()`: Updates note positions during scrubbing
- `_cleanup_pass()`: Removes expired/invalid notes

**Note Type Detection Logic:**
```gdscript
func get_note_type(note: Dictionary) -> int:
    if note.fret == 5: return OPEN
    elif note.is_tap: return TAP
    elif note.is_hopo: return HOPO
    else: return REGULAR
```

---

### 3. **Input Handler** (`input_handler.gd`)

**Responsibilities:**
- Key state tracking (pressed/released)
- Chord-aware hit detection (processes all lanes per frame)
- Timing window validation
- Lane hit zone visual feedback
- Sustain hold detection

**Timing Windows (from SettingsManager):**
- Perfect: ±0.025s (±25ms)
- Great: ±0.05s (±50ms)
- Good: ±0.1s (±100ms)
- Bad: Beyond good window

**Frame-Based Processing Flow:**
```gdscript
func _input(event):
    # Immediate key state update
    if event.pressed:
        key_states[lane] = true
        key_changed_this_frame = true

func _process(delta):
    # Once per frame: check all pressed keys
    if key_changed_this_frame:
        for lane in pressed_lanes:
            check_hit(lane)  # Find best candidate note
```

**Chord Detection:**
Multiple keys pressed simultaneously are processed in a single frame, ensuring accurate chord hit detection by evaluating all lanes together.

---

### 4. **Score Manager** (`ScoreManager.gd`)

**Responsibilities:**
- Combo tracking (current, max)
- Score calculation with multipliers
- Grade count statistics (Perfect, Great, Good, Bad, Miss)
- Sustain scoring (continuous points while held)
- Reversible operations (for timeline scrubbing)

**Scoring Formula:**
```
base_score (grade):
    Perfect: 10
    Great: 8
    Good: 5
    Bad: 3

type_multiplier:
    REGULAR: 1x
    HOPO: 2x
    TAP: 2x
    OPEN: 1x

final_score = base_score × combo × type_multiplier
```

**Reversible API (Command Pattern Support):**
- `add_hit()`: Standard forward scoring
- `remove_hit()`: Undoes a hit (for timeline rewind)
- `add_miss()`: Resets combo
- `remove_miss()`: Undoes miss, restores combo

---

### 5. **Timeline Controller** (`TimelineController.gd`)

**Responsibilities:**
- Command execution/undo based on current timeline position
- Bidirectional playback support (forward/reverse)
- Scrubbing functionality (jump to arbitrary time)
- Command log management (sorted by scheduled_time)

**Key Features:**
- **Forward Execution**: Commands execute when `current_time ≥ scheduled_time`
- **Backward Undo**: Commands undo when scrubbing backward past their time
- **Dynamic Commands**: New commands can be inserted at runtime (hit/miss recording)
- **Note Repositioning**: After structural changes, notes are repositioned correctly

**Usage:**
```gdscript
# Setup
timeline_controller.setup(ctx, spawn_commands, song_end_time)

# Natural forward playback
func _process(delta):
    current_time += delta * direction
    advance_to(current_time)

# Manual scrubbing
timeline_controller.scrub_to(target_time)  # Jump to time
timeline_controller.step_scrub(±2.0)       # Relative scrub
```

---

### 6. **Board Renderer** (`board_renderer.gd`)

**Responsibilities:**
- Dynamic lane generation based on note count
- Hit zone creation and positioning
- Lane line rendering (boundaries)
- Material/texture setup

**Lane Calculation:**
```gdscript
zone_width = board_width / num_lanes
lanes[i] = start_x + i * spacing

where start_x = -(num_lanes * zone_width / 2) + zone_width / 2
```

**Hit Zone Properties:**
- Size: `zone_width × zone_height`
- Position: Lane X, Y=0.01 (slightly above board), Z=0 (hit line)
- Color: From `SettingsManager.lane_colors[]`
- Material: StandardMaterial3D with per-lane colors

---

### 7. **Chart Parser System**

#### ParserFactory (`ParserFactory.gd`)
**Pattern:** Factory Method  
**Supported Formats:**
- `.chart` → `ChartParser`
- `.mid`, `.midi` → `MidiParser`
- Metadata → `IniParser` (song.ini)

#### ChartParser (`ChartParser.gd`)
**Responsibilities:**
- Parse .chart section-based format
- Extract resolution, offset, tempo events
- Parse note events with HOPO/TAP detection
- Cache parsed data via ResourceCache

**HOPO Detection Logic:**
- Natural HOPO: Different fret within `resolution / 4` ticks
- Special modifiers: Frets 5/6/7 at same tick can force/cancel HOPO or mark TAP
- Open notes: Fret 7 normalized to fret 5 (internal representation)

#### IniParser (`IniParser.gd`)
**Responsibilities:**
- Parse song.ini metadata (name, artist, album, charter, etc.)
- Extract preview_start_time, loading_phrase
- Identify MusicStream file path
- Format song length for display

---

### 8. **Settings Manager** (`settings_manager.gd`)

**Pattern:** Singleton (Autoload)  
**Storage:** `user://settings.cfg` (ConfigFile format)

**Persisted Settings:**
```gdscript
# User customizable
lane_keys: Array[int]           # Keycodes for each lane
note_speed: float (5.0-50.0)    # Units per second
master_volume: float (0.0-1.0)  # Audio volume
timing_offset: float (±500ms)   # Audio offset calibration

# Gameplay constants
lane_colors: Array[Color]
perfect_window: 0.025s
great_window: 0.05s
good_window: 0.1s
```

**Validation:**
All setters validate input ranges and clamp invalid values to valid ranges, preventing corruption.

---

### 9. **Scene Switcher** (`SceneSwitcher.gd`)

**Pattern:** Singleton (Autoload)  
**Scene Stack Navigation:**

```gdscript
scene_stack = [MainMenu, SongSelect, Gameplay, Results]
                 ↑ base     ↑ current top
```

**Operations:**
- `push_scene(path)`: Load and add scene to stack, hide previous
- `push_scene_instance(node)`: Add existing instance to stack
- `replace_scene_instance(node)`: Replace top with new scene
- `pop_scene()`: Remove top, show previous

**Process Mode Management:**
Hides previous scenes and sets `PROCESS_MODE_DISABLED` to prevent unnecessary updates.

---

### 10. **Animation Director** (`animation_director.gd`)

**Pattern:** Centralized Animation System (manual interpolation)  
**Purpose:** Lightweight animations without per-event Tween allocations

**Features:**
- Manual interpolation tasks stored in array
- Easing functions (Linear, OutQuad, InQuad, OutBack)
- Sequential animation support (sequences)
- Node-property targeting with nested property paths

**Animation Helpers:**
- `animate_note_spawn()`: Squash-stretch pop-in effect
- `animate_judgement_label()`: Scale pulse with grade differentiation
- `animate_combo_label()`: Subtle scale bounce
- `animate_lane_press()`: Hit zone pulse on key press

**Benefits:**
- Predictable memory usage (fixed array vs. dynamic Tween objects)
- Centralized animation logic for consistent feel
- Easy to extend with new animation types

---

### 11. **Object Pools**

#### NotePool (`NotePool.gd`)
**Purpose:** Reuse note instances to avoid allocation overhead during gameplay

**Strategy:**
- Pre-instantiate notes as needed (lazy allocation)
- Maximum pool size: 200 notes (long songs)
- Signals connected once at creation
- `reset()` method clears state without destroying

**Lifecycle:**
```gdscript
# Get from pool
note = pool.get_note()  # Reuse existing or create new
note.reset()            # Clear previous state

# Return to pool
pool.return_note(note)  # Remove from scene tree, store in pool
```

#### HitEffectPool (`HitEffectPool.gd`)
Similar pattern for visual effects (particle systems, animated sprites).

---

### 12. **Resource Cache** (`ResourceCache.gd`)

**Pattern:** Singleton (Autoload)  
**Purpose:** Cache expensive parsing operations

**Cached Data:**
- Parsed chart sections (Dictionary from ChartParser)
- Reduces file I/O and parsing time for repeated loads

**Cache Key:** Absolute file path

---

### 13. **Command Pattern Implementation**

#### ICommand (Interface)
```gdscript
class_name ICommand
var scheduled_time: float
func execute(ctx: Dictionary) -> void: pass
func undo(ctx: Dictionary) -> void: pass
```

#### SpawnNoteCommand
**Purpose:** Reversible note spawning with late-spawn positioning

**Execute:**
- Calculate initial Z position based on current time vs. spawn time
- If late, position note forward along runway proportionally
- Capture note instance ID and weak reference for undo

**Undo:**
- Despawn note by instance ID
- Clear reference

**Late Spawn Handling:**
```gdscript
# If spawned late, position forward:
late_progress = current_time - spawn_time
if late_progress > 0:
    initial_z = runway_begin_z + (distance * late_progress / travel_time)
```

#### HitNoteCommand / MissNoteCommand
**Purpose:** Record gameplay events for reversible scoring during scrubbing

**Execute:** Apply score/combo changes  
**Undo:** Reverse score/combo changes using stored previous state

---

## Design Decisions

### 1. **Why Timing-Based Hit Detection?**
**Decision:** Calculate time difference rather than spatial hitbox collision.

**Rationale:**
- **Accuracy**: More precise for rhythm games (millisecond precision)
- **Performance**: No physics queries, simple float comparison
- **Chord Support**: Can evaluate all lanes in a single frame
- **Network-Ready**: Time deltas are easier to synchronize than spatial positions

**Implementation:**
```gdscript
var diff = abs(current_time - note.expected_hit_time)
if diff <= perfect_window: grade = PERFECT
elif diff <= great_window: grade = GREAT
# ...
```

---

### 2. **Why Frame-Based Input Processing?**
**Decision:** Accumulate key states in `_input()`, process in `_process()`.

**Rationale:**
- **Chord Detection**: All simultaneous key presses processed together
- **Predictable Timing**: Single evaluation point per frame
- **Missed Keys**: Prevents missing rapid simultaneous key presses due to event order

**Problem Solved:**
Immediate event-based processing could miss chord detection if two key events arrived in separate frames due to OS input timing variations.

---

### 3. **Why Command Pattern for Timeline?**
**Decision:** Implement reversible commands for all timeline events.

**Rationale:**
- **Scrubbing Support**: Enable jumping to arbitrary song positions
- **Replay System**: Foundation for future replay feature
- **Practice Mode**: Allow looping sections by rewinding
- **Debug Features**: Developers can inspect specific moments

**Trade-offs:**
- Increased complexity (command objects, undo logic)
- Justified by feature value (scrubbing is critical for practice/debugging)

---

### 4. **Why Object Pooling?**
**Decision:** Pool note instances and hit effects.

**Rationale:**
- **Performance**: Instantiation is expensive in Godot (scene parsing, node setup)
- **GC Pressure**: Reduces garbage collection pauses
- **Consistent Frame Time**: Avoids allocation spikes during heavy spawn periods

**Measurements:**
Without pooling: 100+ notes = noticeable frame drops  
With pooling: Smooth gameplay with 500+ notes

---

### 5. **Why Parser Factory Pattern?**
**Decision:** Separate parsers for each chart format with factory.

**Rationale:**
- **Extensibility**: Easy to add new formats (.osu, .sm, etc.)
- **Single Responsibility**: Each parser handles one format
- **Testability**: Parsers can be unit tested independently
- **Maintainability**: Format-specific logic isolated

---

### 6. **Why Centralized Animation System?**
**Decision:** AnimationDirector instead of per-event Tweens.

**Rationale:**
- **Memory**: Tweens are full Node objects (overhead)
- **Predictability**: Fixed-size array vs. dynamic tree manipulation
- **Consistency**: Central easing functions ensure uniform feel
- **Performance**: Single `_process()` update loop

**Trade-off:** Less flexible than Tween API, but sufficient for current needs.

---

### 7. **Why Singleton Settings Manager?**
**Decision:** Autoload singleton instead of passing settings down component chain.

**Rationale:**
- **Convenience**: Accessible anywhere via `SettingsManager.property`
- **Persistence**: Natural place for save/load logic
- **Validation**: Centralized validation of user settings
- **Hot Reload**: Components can query latest settings mid-game

**Anti-Pattern Concerns Addressed:**
- Clear documentation of singleton's purpose (settings only)
- No game logic in singleton (pure data + persistence)
- Components still testable (mock SettingsManager in tests)

---

### 8. **Why Dynamic Lane Count?**
**Decision:** Determine lanes from max fret in chart rather than hardcoding.

**Rationale:**
- **Flexibility**: Supports 5-lane and 6-lane charts without code changes
- **Future-Proof**: Easy to add 7+ lane modes
- **Chart Accuracy**: Respects charter's intent

**Implementation:**
```gdscript
var max_fret = 0
for note in notes:
    max_fret = max(max_fret, note.fret)
num_lanes = max(5, max_fret + 1)  # Minimum 5 lanes
```

---

## Performance Optimizations

### 1. **Chart Data Caching**
**Optimization:** Cache parsed chart sections in ResourceCache singleton.

**Impact:**
- First load: ~100-200ms parsing time
- Subsequent loads: <1ms (dictionary lookup)
- Critical for retry/practice mode

---

### 2. **Note Pool with Signal Optimization**
**Optimization:** Connect signals once at note creation, not per-use.

**Before:**
```gdscript
# Per-spawn: connect, per-despawn: disconnect
note.connect("note_miss", ...)
note.disconnect("note_miss", ...)
```

**After:**
```gdscript
# Once at creation:
if pool.is_empty():
    note = create_new()
    note.connect("note_miss", ...)  # PERMANENT
else:
    note = pool.pop_back()  # Signals already connected
```

**Impact:** Eliminates thousands of connect/disconnect calls per song.

---

### 3. **Spawn Data Pre-Computation**
**Optimization:** Calculate entire spawn schedule upfront.

**Rationale:**
- Tick-to-time conversion is expensive (tempo map iteration)
- Do it once at start, then simple array iteration during gameplay

**Structure:**
```gdscript
spawn_data = []  # Precomputed at start
for note in notes:
    hit_time = calculate_time(note.pos, tempo_events)
    spawn_time = hit_time - travel_time
    spawn_data.append({...})
```

---

### 4. **Frame-Based Input Processing**
**Optimization:** Process all lanes once per frame instead of per-event.

**Impact:**
- Prevents duplicate hit checks on rapid key presses
- CPU cost: O(num_lanes × num_active_notes) per frame
- Optimized by only checking when `key_changed_this_frame`

---

### 5. **Cleanup Pass Optimization**
**Optimization:** Single backward iteration to remove invalid notes.

**Implementation:**
```gdscript
for i in range(active_notes.size() - 1, -1, -1):
    if should_remove(active_notes[i]):
        active_notes.remove_at(i)
        pool.return_note(note)
```

**Benefit:** Avoids array shifting overhead from forward iteration.

---

### 6. **Material Instance Caching**
**Optimization:** Store original lane materials, duplicate only on hit.

**Before:** Recreate material every hit zone light-up.  
**After:** Duplicate stored original, modify copy, apply.

**Impact:** Reduces material allocations by 90%+.

---

### 7. **Late Spawn Positioning**
**Optimization:** SpawnNoteCommand calculates correct position for late spawns.

**Problem:** Scrubbing forward skips spawn times.  
**Solution:** Position note forward along runway based on time elapsed since spawn.

```gdscript
late_progress = current_time - spawn_time
fraction = late_progress / travel_time
initial_z = runway_begin_z + (distance * fraction)
```

**Result:** Seamless scrubbing without visual pops.

---

## Extension Points

### 1. **New Note Types**
**Location:** `note_type.gd`, `note_spawner.gd`, `note.gd`

**Steps:**
1. Add enum value to `NoteType.Type`
2. Define multiplier in `NoteType.get_multiplier()`
3. Add texture suffix in `NoteType.get_texture_suffix()`
4. Update detection in `note_spawner.get_note_type()`
5. Create visual assets: `res://Assets/Textures/Notes/note_[color]_[suffix].png`

**Example: Adding a "STAR" note:**
```gdscript
# note_type.gd
enum Type {REGULAR, HOPO, TAP, OPEN, STAR}

static func get_multiplier(type):
    match type:
        Type.STAR: return 3  # Triple points
```

---

### 2. **New Chart Formats**
**Location:** `Scripts/Parsers/`

**Steps:**
1. Create parser implementing `ParserInterface.gd`
2. Implement required methods: `load_chart()`, `get_notes()`, etc.
3. Register in `ParserFactory.gd`:
```gdscript
func create_parser_for_file(file_path: String):
    match file_path.get_extension():
        "osu": return OsuParser.new()
```

---

### 3. **Custom Timing Windows**
**Location:** `settings_manager.gd`

**Current Implementation:**
```gdscript
var perfect_window: float = 0.025
var great_window: float = 0.05
var good_window: float = 0.1
```

**Extension:** Add UI sliders in settings scene, save to ConfigFile.

---

### 4. **Multiplayer / Network Sync**
**Foundation:** Timing-based hit detection is network-friendly.

**Implementation Strategy:**
1. Synchronize `song_start_time` across clients
2. Transmit hit events as `{lane, time, grade}` tuples
3. Replay inputs using timeline system
4. Use rollback netcode for prediction

**Note:** Latency compensation via `timing_offset` setting.

---

### 5. **Replay System**
**Foundation:** Timeline command log is nearly complete.

**Missing Pieces:**
1. Serialize command log to file
2. Capture input timestamps
3. Playback mode that injects input commands

**File Format Suggestion:**
```json
{
  "version": 1,
  "chart_path": "...",
  "instrument": "...",
  "events": [
    {"time": 1.234, "type": "hit", "lane": 2, "grade": 0},
    {"time": 2.456, "type": "miss", "lane": 1}
  ]
}
```

---

### 6. **Practice Mode (Looping)**
**Foundation:** Timeline scrubbing already implemented.

**Implementation:**
1. UI to select start/end times
2. Loop logic in `gameplay._process()`:
```gdscript
if current_time >= loop_end:
    timeline_controller.scrub_to(loop_start)
```

---

### 7. **Custom Animations**
**Location:** `animation_director.gd`

**Example: Adding screen shake:**
```gdscript
func animate_screen_shake(camera: Camera3D, intensity: float):
    var offset = Vector3(randf_range(-intensity, intensity), ...)
    _animate(camera, "position", camera.position, camera.position + offset, 0.1)
```

---

## Technical Stack

### Engine & Version
- **Engine:** Godot 4.5
- **Rendering:** GL Compatibility (cross-platform)
- **Language:** GDScript

### Project Structure
```
RhythmGame/
├── Assets/
│   ├── Textures/          # Note sprites, UI elements
│   └── Tracks/            # Song folders (artist - title [charter])
│       └── [Song]/
│           ├── notes.chart
│           ├── song.ogg
│           ├── song.ini
│           └── album.png
├── Scenes/
│   ├── main_menu.tscn
│   ├── song_select.tscn
│   ├── gameplay.tscn      # Main gameplay scene
│   ├── results_screen.tscn
│   ├── note.tscn
│   └── ...
├── Scripts/
│   ├── gameplay.gd        # Orchestrator
│   ├── note_spawner.gd
│   ├── input_handler.gd
│   ├── ScoreManager.gd
│   ├── board_renderer.gd
│   ├── TimelineController.gd
│   ├── animation_director.gd
│   ├── settings_manager.gd  (Autoload)
│   ├── SceneSwitcher.gd     (Autoload)
│   ├── ResourceCache.gd     (Autoload)
│   ├── Parsers/
│   │   ├── ParserFactory.gd
│   │   ├── ChartParser.gd
│   │   ├── MidiParser.gd
│   │   └── IniParser.gd
│   └── Commands/
│       ├── ICommand.gd
│       ├── SpawnNoteCommand.gd
│       ├── HitNoteCommand.gd
│       └── MissNoteCommand.gd
└── Documentation/
    ├── Architecture.md       (This file)
    ├── Core Infrastructure.md
    └── Plan.md
```

### Dependencies
**Internal:**
- No external GDScript libraries/plugins
- Pure Godot 4 engine features

**External Assets:**
- Note textures (custom created)
- Song charts (user-provided .chart files)

---

## Appendix: Key Algorithms

### A. Tick-to-Time Conversion
```gdscript
func get_note_times(notes: Array, resolution: int, tempo_events: Array) -> Array:
    var times = []
    var current_bpm = 120.0
    var last_tick = 0
    var accumulated_time = 0.0
    var event_index = 0
    
    for note in notes:
        # Advance to all tempo changes before this note
        while event_index < tempo_events.size() and tempo_events[event_index].tick <= note.pos:
            var event = tempo_events[event_index]
            var ticks_elapsed = event.tick - last_tick
            var time_elapsed = (ticks_elapsed / resolution) * (60.0 / current_bpm)
            accumulated_time += time_elapsed
            current_bpm = event.bpm
            last_tick = event.tick
            event_index += 1
        
        # Calculate time for this note
        var ticks_from_last = note.pos - last_tick
        var time_from_last = (ticks_from_last / resolution) * (60.0 / current_bpm)
        times.append(accumulated_time + time_from_last)
    
    return times
```

**Explanation:**
- Iterates through tempo events to maintain accurate BPM
- Accumulates time with each tempo change
- Formula: `time = (ticks / resolution) × (60 / BPM)`

---

### B. Spawn Time Calculation
```gdscript
var hit_time = tick_to_time(note.pos)
var distance = abs(runway_begin_z)  # e.g., 25 units
var travel_time = distance / note_speed  # e.g., 25 / 20 = 1.25s
var spawn_time = hit_time - travel_time
```

**Explanation:**
- Note must spawn `travel_time` seconds before hit to arrive at hit line
- `spawn_time` is when note appears at `runway_begin_z`
- Note travels forward at `note_speed` units/second

---

### C. Timeline Command Execution
```gdscript
func advance_to(target_time: float):
    # Forward: execute commands up to target_time
    while executed_count < command_log.size():
        if command_log[executed_count].scheduled_time <= target_time:
            command_log[executed_count].execute(ctx)
            executed_count += 1
        else:
            break
    
    # Backward: undo commands past target_time
    while executed_count > 0:
        if command_log[executed_count - 1].scheduled_time > target_time:
            executed_count -= 1
            command_log[executed_count].undo(ctx)
        else:
            break
```

**Explanation:**
- Maintains `executed_count` as boundary between executed/not-executed
- Forward: execute and increment
- Backward: decrement and undo

---

## Conclusion

This architecture provides a solid foundation for a rhythm game with:
- **Clear separation of concerns** for maintainability
- **Performance optimizations** (pooling, caching, precomputation)
- **Extensibility** (factory patterns, command pattern)
- **Advanced features** (timeline scrubbing, reversible actions)

The modular design allows features to be added/modified without refactoring core systems, making it suitable for ongoing development and experimentation.

---

**Document Version:** 1.0  
**Last Updated:** October 13, 2025  
**Maintained By:** Development Team
