# High-Level Architecture Diagrams

**Version:** 1.0  
**Date:** October 13, 2025  
**Project:** Godot 4 3D Rhythm Game

---

## System Architecture Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        UI[UI Manager]
        Scenes[Scene Switcher]
        Menu[Main Menu]
        Settings[Settings Screen]
        Results[Results Screen]
    end
    
    subgraph "Game Logic Layer"
        Gameplay[Gameplay Controller]
        Input[Input Handler]
        Scorer[Score Manager]
        Spawner[Note Spawner]
        Timeline[Timeline Controller]
    end
    
    subgraph "Data Processing Layer"
        Parser[Chart Parser Factory]
        ChartP[Chart Parser]
        MidiP[MIDI Parser]
        Cache[Resource Cache]
    end
    
    subgraph "Infrastructure Layer"
        SettingsM[Settings Manager]
        AudioM[Audio Manager]
        Pools[Object Pools]
        Renderer[Board Renderer]
    end
    
    subgraph "External Resources"
        Charts[.chart Files]
        Audio[Audio Files]
        Config[Settings Files]
    end
    
    UI --> Gameplay
    Scenes --> UI
    Gameplay --> Input
    Gameplay --> Scorer
    Gameplay --> Spawner
    Gameplay --> Timeline
    Spawner --> Pools
    Parser --> ChartP
    Parser --> MidiP
    ChartP --> Charts
    AudioM --> Audio
    SettingsM --> Config
    Cache --> Charts
    Renderer --> Spawner
```

---

## Data Flow Architecture

```mermaid
flowchart LR
    subgraph "Input Phase"
        A[Chart Files] --> B[Parser Factory]
        B --> C[Chart Parser]
        C --> D[Parsed Data]
    end
    
    subgraph "Processing Phase"
        D --> E[Note Spawner]
        E --> F[Spawn Schedule]
        F --> G[Timeline Controller]
    end
    
    subgraph "Execution Phase"
        G --> H[Active Notes]
        I[Player Input] --> J[Input Handler]
        J --> K[Hit Detection]
        H --> K
        K --> L[Score Manager]
    end
    
    subgraph "Output Phase"
        L --> M[UI Updates]
        L --> N[Audio Feedback]
        L --> O[Visual Effects]
    end
```

---

## Component Dependencies

```mermaid
graph TD
    A[Gameplay Controller] --> B[Input Handler]
    A --> C[Note Spawner]
    A --> D[Score Manager]
    A --> E[Timeline Controller]
    A --> F[Audio Manager]
    
    C --> G[Note Pool]
    C --> H[Board Renderer]
    
    B --> I[Settings Manager]
    D --> I
    
    E --> J[Command Pattern]
    J --> K[Spawn Commands]
    J --> L[Hit Commands]
    J --> M[Miss Commands]
    
    N[Parser Factory] --> O[Chart Parser]
    N --> P[MIDI Parser]
    O --> Q[Resource Cache]
    
    R[Scene Switcher] --> S[Loading Screen]
    R --> T[Song Select]
    R --> U[Results Screen]
    
    style A fill:#ff9999
    style I fill:#99ff99
    style N fill:#9999ff
    style R fill:#ffff99
```

---

## Signal Flow Diagram

```mermaid
sequenceDiagram
    participant P as Player
    participant IH as Input Handler
    participant GC as Gameplay Controller
    participant SM as Score Manager
    participant UI as UI Manager
    participant AE as Audio/Effects
    
    P->>IH: Key Press
    IH->>IH: Check Active Notes
    IH->>GC: note_hit(note, grade)
    GC->>SM: add_hit(grade, note_type)
    SM->>SM: Update Score/Combo
    SM->>UI: score_changed signal
    SM->>UI: combo_changed signal
    GC->>AE: Play hit sound
    GC->>AE: Show hit effect
    UI->>UI: Update score display
```

---

## State Management Architecture

```mermaid
stateDiagram-v2
    [*] --> MainMenu
    MainMenu --> SongSelect: Play Button
    SongSelect --> LoadingScreen: Song Selected
    LoadingScreen --> Gameplay: Data Loaded
    Gameplay --> Results: Song Complete
    Results --> SongSelect: Back Button
    SongSelect --> MainMenu: Menu Button
    MainMenu --> Settings: Settings Button
    Settings --> MainMenu: Back Button
    
    state Gameplay {
        [*] --> Countdown
        Countdown --> Playing: Timer Complete
        Playing --> Paused: Pause Input
        Paused --> Playing: Resume
        Playing --> Finished: Song End
        Finished --> [*]
    }
```

---

## Performance Architecture

```mermaid
graph LR
    subgraph "Memory Management"
        A[Object Pools] --> B[Note Recycling]
        A --> C[Effect Recycling]
        D[Resource Cache] --> E[Asset Preloading]
    end
    
    subgraph "Processing Optimization"
        F[Frame-based Input] --> G[Batch Hit Detection]
        H[Precomputed Spawns] --> I[O(1) Timeline Lookup]
        J[Spatial Culling] --> K[Render Only Visible]
    end
    
    subgraph "Threading"
        L[Main Thread] --> M[Gameplay Logic]
        N[Background Thread] --> O[Chart Parsing]
        P[Audio Thread] --> Q[Music Playback]
    end
    
    B --> G
    I --> M
    O --> E
```

---

## Extension Points Architecture

```mermaid
mindmap
  root((Extension Points))
    New Note Types
      Visual Components
      Scoring Rules
      Input Patterns
    Chart Formats
      Parser Interface
      Format Detection
      Data Conversion
    Game Modes
      Multiplayer
      Practice Mode
      Custom Rules
    UI Themes
      Scene Templates
      Style Resources
      Animation Sets
    Audio Systems
      Effects Pipeline
      Mixing Controls
      Format Support
```

---

## Key Design Patterns

```mermaid
classDiagram
    class Singleton {
        <<pattern>>
        +SettingsManager
        +SceneSwitcher
        +ResourceCache
    }
    
    class Factory {
        <<pattern>>
        +ParserFactory
        +create_parser()
    }
    
    class ObjectPool {
        <<pattern>>
        +NotePool
        +HitEffectPool
        +acquire()
        +release()
    }
    
    class Command {
        <<pattern>>
        +ICommand
        +SpawnNoteCommand
        +HitNoteCommand
        +execute()
        +undo()
    }
    
    class Observer {
        <<pattern>>
        +Signal System
        +score_changed
        +combo_changed
    }
    
    Factory --> ObjectPool
    Command --> Observer
    Singleton --> Factory
```