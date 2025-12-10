# Chart Editor Architecture - Hold Note Flow

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Chart Editor                             │
│  (Orchestrates services, manages editor state)                  │
└───────────┬─────────────────────────────────────────┬───────────┘
            │                                         │
            │ Signals                                 │ Signals
            │                                         │
┌───────────▼──────────────┐              ┌──────────▼────────────┐
│   EditorInputManager     │              │ EditorNoteCreation    │
│                          │              │      Service          │
│ - Captures keyboard      │              │                       │
│   input (_input)         │              │ - Manages hold notes  │
│ - Tracks held keys       │              │ - Validates placement │
│ - Emits action signals   │              │ - Calculates sustain  │
│                          │              │ - Emits note_created  │
└──────────────────────────┘              └───────────────────────┘
```

## Hold Note Sequence Diagram

```
User          InputManager       ChartEditor      NoteCreationService    ChartDocument
 │                 │                  │                    │                   │
 │ Press "1" key   │                  │                    │                   │
 ├────────────────>│                  │                    │                   │
 │                 │ note_placement_  │                    │                   │
 │                 │  requested(0, T) │                    │                   │
 │                 ├─────────────────>│ start_hold_note(0) │                   │
 │                 │                  ├───────────────────>│                   │
 │                 │                  │                    │ Store start time  │
 │                 │                  │                    │ & tick in dict    │
 │                 │                  │                    │                   │
 │                 │                  │    [Time passes]   │                   │
 │                 │                  │                    │                   │
 │ Release "1" key │                  │                    │                   │
 ├────────────────>│                  │                    │                   │
 │                 │ note_hold_       │                    │                   │
 │                 │  released(0)     │                    │                   │
 │                 ├─────────────────>│ finish_hold_note(0)│                   │
 │                 │                  ├───────────────────>│                   │
 │                 │                  │                    │ Calculate sustain │
 │                 │                  │                    │ length            │
 │                 │                  │     note_created   │                   │
 │                 │                  │<───────────────────┤                   │
 │                 │                  │ execute_add_note() │                   │
 │                 │                  ├───────────────────────────────────────>│
 │                 │                  │                    │                   │
 │                 │                  │                    │       Add note    │
 │                 │                  │                    │       to chart    │
```

## Key Press Detection Flow

```
┌──────────────────────┐
│ Godot Input System   │
│   (OS-level events)  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  _input(event)       │
│  (EditorInputManager)│
└──────────┬───────────┘
           │
           ├─── Is key press? ───> Mark key as held in _keys_held[lane]
           │                       Emit note_placement_requested(lane, true)
           │
           └─── Is key release? ─> Mark key as released in _keys_held[lane]
                                   Emit note_hold_released(lane)
```

## State Management

### EditorInputManager State
```
_keys_held: Dictionary = {
    0: false,  # Lane 0 (key "1")
    1: false,  # Lane 1 (key "2")
    2: false,  # Lane 2 (key "3")
    3: false,  # Lane 3 (key "4")
    4: false   # Lane 4 (key "5")
}
```

### EditorNoteCreationService State
```
_active_hold_notes: Dictionary = {
    0: {
        "start_time": 45.234,
        "start_tick": 8686
    }
    # Other lanes only present if actively holding
}
```

## Signal Flow Map

```
EditorInputManager Signals → ChartEditor Handlers → Actions
─────────────────────────────────────────────────────────────
note_placement_requested    → _on_input_note_placement_requested
                              ├─ If hold start: note_creation_service.start_hold_note()
                              └─ If regular: note_creation_service.place_note_at_time()

note_hold_released          → _on_input_note_hold_released
                              └─ note_creation_service.finish_hold_note()

tool_change_requested       → _on_tool_selected()
note_type_change_requested  → _on_note_type_selected()
timeline_navigation_req.    → _on_input_timeline_navigation()
playback_toggle_requested   → _on_input_playback_toggle()
snap_division_change_req.   → _on_input_snap_division_change()
save_requested              → _on_file_save()
undo_requested              → _undo_editor_action()
redo_requested              → _redo_editor_action()
delete_requested            → _delete_selected_notes()


EditorNoteCreationService Signals → ChartEditor Handlers
─────────────────────────────────────────────────────────
note_created                → _on_note_created_by_service()
                              └─ _execute_add_note(note_data)


EditorPlaybackController Signals → ChartEditor Handlers
───────────────────────────────────────────────────────
playback_state_changed      → _on_playback_state_changed()
                              └─ If stopped: note_creation_service.cancel_all_hold_notes()
```

## Configuration Flow

```
ChartEditor._ready()
    │
    ├─> Create EditorInputManager
    │   └─> configure({tool, sustain_mode, num_lanes, is_playing})
    │
    ├─> Create EditorNoteCreationService
    │   └─> configure({chart_document, playback_controller, tempo_events, ...})
    │
    └─> Connect all signals between services
```

## Why This Architecture Works

1. **Clear Ownership**
   - InputManager owns keyboard state
   - NoteCreationService owns hold note state
   - ChartEditor owns editor state

2. **Unidirectional Data Flow**
   - User input → InputManager → ChartEditor → NoteCreationService → ChartDocument

3. **Loose Coupling via Signals**
   - Services don't know about each other
   - ChartEditor acts as mediator
   - Easy to mock/test

4. **Proper Event Handling**
   - `_input()` captures all events including releases
   - State is tracked explicitly in dictionaries
   - No reliance on event.pressed for release detection
