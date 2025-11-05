# Chart Editor Playback - Visual Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CHART EDITOR                                 │
└─────────────────────────────────────────────────────────────────────┘

USER ACTIONS:
    [Press Space] or [Click Play Button]
           ↓
    _on_play_requested()
           ↓
    ┌──────────────────────────────────────┐
    │  First Play Only:                     │
    │  _initialize_playback_system()        │
    │                                       │
    │  1. Get chart data                    │
    │     chart_data.get_chart(...)         │
    │                                       │
    │  2. Convert formats                   │
    │     notes → spawner format            │
    │     BPM → tempo events                │
    │                                       │
    │  3. Configure NoteSpawner             │
    │     spawner.notes = converted         │
    │     spawner.tempo_events = tempo      │
    │     spawner.start_spawning()          │
    │                                       │
    │  4. Create TimelineController         │
    │     timeline = TimelineController()   │
    │                                       │
    │  5. Build Commands                    │
    │     cmds = spawner.build_commands()   │
    │                                       │
    │  6. Setup Timeline                    │
    │     timeline.setup(ctx, cmds, end)    │
    └──────────────────────────────────────┘
           ↓
    audio_player.play(current_time)
    timeline_controller.active = true
           ↓
    ┌──────────────────────────────────────┐
    │  EVERY FRAME:                         │
    │  _process(delta)                      │
    │                                       │
    │  Timeline advances ───────────────┐   │
    │  current_time = timeline.get_time()│  │
    │                                    │   │
    │  Audio syncs ──────────────────────┤  │
    │  _sync_audio_to_timeline(false)    │  │
    │                                    │   │
    │  UI updates ───────────────────────┤  │
    │  playback_controls.update(...)     │  │
    │  status_bar.update(...)            │  │
    │                                    │   │
    │  Canvas updates ───────────────────┤  │
    │  note_canvas.update_playback(...)  │  │
    │  note_canvas.scroll_to_tick(...)   │  │
    └────────────────────────────────────┘  │
                                            │
    ┌───────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────┐
│                   TIMELINE CONTROLLER                       │
│                                                             │
│  command_log: Array[SpawnNoteCommand]                      │
│  executed_count: int                                       │
│  current_time: float                                       │
│                                                             │
│  Each frame:                                               │
│    current_time += delta                                   │
│    while command_log[executed_count].time <= current_time: │
│        command_log[executed_count].execute(ctx)            │
│        executed_count++                                    │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                   SPAWN NOTE COMMAND                        │
│                                                             │
│  lane: int                                                 │
│  hit_time: float                                           │
│  note_type: int                                            │
│  spawn_time: float  (scheduled_time)                       │
│                                                             │
│  execute(ctx):                                             │
│    spawner = ctx["note_spawner"]                           │
│    note = spawner._command_spawn_note(...)                 │
│    _note_instance_id = note.get_instance_id()              │
│                                                             │
│  undo(ctx):                                                │
│    spawner._command_despawn_note(...)                      │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                     NOTE SPAWNER                            │
│                                                             │
│  spawn_data: Array[{spawn_time, lane, hit_time, ...}]     │
│  active_notes: Array[Note]                                 │
│  note_pool: NotePool                                       │
│  timeline_controller: TimelineController                   │
│                                                             │
│  build_spawn_commands():                                   │
│    for each in spawn_data:                                 │
│        cmd = SpawnNoteCommand.new(data)                    │
│        cmds.append(cmd)                                    │
│    return cmds                                             │
│                                                             │
│  _command_spawn_note(...):                                 │
│    note = note_pool.get_note()                             │
│    configure note (position, type, visuals)                │
│    active_notes.append(note)                               │
│    emit note_spawned signal                                │
│    return note                                             │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                       NOTE POOL                             │
│                                                             │
│  pool: Array[Note]                                         │
│  max_pool_size: int                                        │
│                                                             │
│  get_note():                                               │
│    if pool.empty():                                        │
│        create new note                                     │
│    else:                                                   │
│        reuse from pool                                     │
│    return note                                             │
│                                                             │
│  return_note(note):                                        │
│    note.reset()                                            │
│    pool.append(note)                                       │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                         NOTE                                │
│                                                             │
│  position: Vector3                                         │
│  expected_hit_time: float                                  │
│  note_type: NoteType.Type                                  │
│  fret: int (lane)                                          │
│  is_sustain: bool                                          │
│                                                             │
│  _process(delta):                                          │
│    position.z += note_speed * delta                        │
│    if past hit zone and not hit:                           │
│        emit note_miss signal                               │
└────────────────────────────────────────────────────────────┘


DATA FLOW DIAGRAM:
═══════════════════

┌──────────────────┐
│  ChartDataModel  │  (Editor's internal data)
│                  │
│  notes: [        │
│    {id, tick,    │
│     lane, type,  │
│     length}      │
│  ]               │
│                  │
│  bpm_changes: [  │
│    {tick, bpm}   │
│  ]               │
└──────────────────┘
         │
         │ _convert_chart_notes_to_spawner_format()
         │ _convert_bpm_changes_to_tempo_events()
         ▼
┌──────────────────┐
│  Spawner Format  │  (Gameplay-compatible)
│                  │
│  notes: [        │
│    {fret, tick,  │
│     is_hopo,     │
│     is_tap,      │
│     sustain}     │
│  ]               │
│                  │
│  tempo_events: [ │
│    {tick, bpm}   │
│  ]               │
└──────────────────┘
         │
         │ NoteSpawner.start_spawning()
         ▼
┌──────────────────┐
│   Spawn Data     │  (Timing calculations)
│                  │
│  [{              │
│    spawn_time,   │  ← When to spawn (time - travel_time)
│    hit_time,     │  ← When player should hit
│    lane,         │
│    note_type,    │
│    travel_time   │  ← How long to reach hit line
│  }]              │
└──────────────────┘
         │
         │ build_spawn_commands()
         ▼
┌──────────────────┐
│ Spawn Commands   │  (Timeline-ready)
│                  │
│  [               │
│    SpawnNote1,   │  Each has scheduled_time
│    SpawnNote2,   │  Sorted by time
│    SpawnNote3,   │  Ready for timeline
│    ...           │
│  ]               │
└──────────────────┘
         │
         │ TimelineController.setup()
         ▼
┌──────────────────┐
│  Timeline Ready  │
│                  │
│  Commands sorted │
│  Context set up  │
│  Active = true   │
│                  │
│  ▶ PLAYBACK!     │
└──────────────────┘


PARALLEL UPDATES DURING PLAYBACK:
═════════════════════════════════

                    _process(delta)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
  ┌──────────┐      ┌──────────┐     ┌──────────┐
  │ Timeline │      │  Audio   │     │ Canvas   │
  │ Updates  │      │  Syncs   │     │ Updates  │
  └──────────┘      └──────────┘     └──────────┘
        │                 │                 │
        │                 │                 │
        ▼                 ▼                 ▼
   Commands          AudioStream      Playback Line
   Execute           Plays            Shows Position
        │                 │                 │
        ▼                 │                 │
   Notes Spawn           │                 │
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                    ▼
              Everything in sync!


CONVERSION EXAMPLE:
═══════════════════

ChartDataModel Note:
{
    "id": 42,
    "tick": 192,           ← One beat at 192 resolution
    "lane": 2,             ← Yellow lane (0-indexed)
    "type": 1,             ← HOPO type
    "length": 96           ← Half beat sustain
}

         ↓ _convert_chart_notes_to_spawner_format()

Spawner Format:
{
    "fret": 2,             ← Same as lane
    "tick": 192,           ← Unchanged
    "is_hopo": true,       ← type == 1
    "is_tap": false,       ← type != 2
    "sustain": 96          ← Same as length
}

         ↓ NoteSpawner.start_spawning()

Spawn Data:
{
    "spawn_time": 0.5,     ← hit_time - travel_time
    "hit_time": 1.0,       ← tick_to_time(192) = 1.0s @ 120 BPM
    "lane": 2,
    "note_type": 1,        ← HOPO
    "travel_time": 0.5,    ← distance / note_speed
    "is_sustain": true,
    "sustain_length": 0.5  ← tick_to_time(96) = 0.5s
}

         ↓ build_spawn_commands()

SpawnNoteCommand:
{
    scheduled_time: 0.5,   ← When to execute
    lane: 2,
    hit_time: 1.0,
    note_type: 1,
    is_sustain: true,
    sustain_length: 0.5,
    travel_time: 0.5
}

         ↓ Timeline executes at t=0.5

Note Object Spawned:
    position = Vector3(lane_x, 0, -25)  ← Far end of runway
    expected_hit_time = 1.0
    note_type = HOPO
    visual texture = yellow HOPO
    tail_instance created (for sustain)
    
         ↓ _process moves note each frame

Note Travels:
    t=0.5: z = -25
    t=0.6: z = -23
    t=0.7: z = -21
    ...
    t=1.0: z = 0   ← Hit line!


SEEK/SCRUB BEHAVIOR:
══════════════════

User seeks to t=5.0
         │
         ▼
_on_seek_requested(5.0)
         │
         ├─► current_time = 5.0
         │
         ├─► timeline_controller.scrub_to(5.0)
         │         │
         │         ├─► Execute all commands with time <= 5.0
         │         │   (spawns notes that should exist)
         │         │
         │         └─► Undo all commands with time > 5.0
         │             (despawns notes that shouldn't exist)
         │
         ├─► audio_player.seek(5.0)
         │
         └─► note_canvas.scroll_to_tick(...)


This gives instant seeking with proper note state!
```
