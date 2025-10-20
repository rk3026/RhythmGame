
# RhythmGame (Name Subject to Change) - Project Phase Implementation

## Course: CptS 483 Special Topic - Coding with Agentic AI
## Student: Ross Kugler
## Track: Game Dev
## Project Phase: Weeks 8-14 (Individual Project)

---

## Overview

RhythmGame (Name Subject to Change) is a 3D rhythm game inspired by Guitar Hero, built with Godot 4.
Players hit moving notes to the beat of songs. It features track selection, gameplay with scoring, and results screens, as well as a full chart editor for creating note maps for songs.

### Features

- 3D gameplay with moving notes
- Multiple tracks with different format (.chart, .mid, etc.)
- Scoring system with combos
- Customizable settings (note speed, key bindings)
- Chart creation system

### Target Users
- Fans of rhythm games
- Gamers
- Music fans

### Core Use Cases
1. **Competitive Gameplay Session**: Sarah, a rhythm game veteran, launches the game on her desktop after work. She navigates to the song library, filters by difficulty level "Expert," and selects a high-BPM electronic track. The game counts down (3-2-1), and notes begin spawning down the 3D runway in sync with the music. She focuses intensely, achieving a 98% perfect hit rate and building a 347-note combo before missing a complex chord pattern. The results screen displays her score, grade (A+), and detailed statistics (Perfect: 347, Great: 12, Good: 3, Miss: 1). She views the online leaderboard integration showing she ranked 8th globally, motivating her to retry for a perfect score.

2. **Custom Content Creation**: Marcus, a musician, wants to chart his band's latest song. He exports the audio as an MP3 and places it in the game's custom songs folder. In the game, he navigates to "Chart Editor" and selects "Create New Chart." The editor loads with his song's waveform visualization and a timeline. He uses the in-game tools to place notes synchronized to the beat, utilizing keyboard shortcuts to efficiently map complex sections. He tests his chart with the integrated playback feature, adjusting note timings based on how they feel in actual gameplay. Once satisfied, he exports the .chart file and shares it with the community, where other players can download and play his creation seamlessly.

3. **AI-Assisted Chart Generation**: Emma, new to chart creation, has a favorite song she wants to play. She uses the "Auto-Generate Chart" feature, uploading her audio file. The AI analysis agent processes the song, detecting beats, rhythms, and musical patterns, then generates a basic chart with three difficulty levels. Emma reviews the auto-generated chart in the editor, making minor adjustments to note placements that feel awkward. She saves the chart and immediately plays it, enjoying her favorite song as a fully playable level she helped create in just 15 minutes.

4. **Progress Tracking & Customization**: David has been playing the game for weeks. He opens his user profile to review his statistics: 47 songs played, average score 89%, total notes hit 15,234, and his longest combo streak of 521. He customizes his experience by adjusting note speed to 1.5x (he's improved!), changing the note runway texture to a neon cyberpunk theme, and resizing note markers for better visibility on his phone screen. These personalized settings sync to his account, providing a consistent experience whether he plays on his PC or Android device.

---

## Project Goals & Success Criteria

#### Core Features

These features define the **Minimum Viable Product (MVP)**—without them, RhythmGame (Name Subject to Change) cannot be considered a complete rhythm game:

1. **Rhythm Gameplay Mechanics**:
   - Note spawning synchronized to audio playback (Command pattern + object pooling)
   - Timing-based hit detection with accuracy tiers (Perfect/Great/Good/Miss)
   - Visual feedback for note hits (particle effects, UI updates)
   - Audio feedback (hit sounds, miss sounds)
   - Combo system with multiplier bonuses

2. **Scoring & Progression**:
   - Real-time score calculation based on accuracy and combo
   - Final results screen with grade (S/A/B/C/D), accuracy percentage, note statistics
   - User profiles with persistent high scores per song/difficulty

3. **Song Management**:
   - Song library UI with browsing and selection
   - Support for multiple difficulty levels per song
   - .chart file parsing for note data (Clone Hero compatibility)
   - At least 3-5 bundled songs with charts
   - Custom song support (user-provided audio + charts)

4. **User Interface & Navigation**:
   - Main menu (Play, Chart Editor, Settings, Quit)
   - Song selection menu with difficulty options
   - In-game pause menu with resume/restart/quit
   - Settings menu (note speed, key bindings, audio calibration)

5. **Chart Creation Tools**:
   - In-game chart editor with timeline and note placement
   - Waveform visualization for audio synchronization
   - Playback testing within editor
   - Save/load functionality for .chart files

6. **Cross-Platform Support**:
   - Desktop build (Windows at minimum, Mac/Linux via Godot export)
   - Responsive UI that scales for different resolutions

**Success Criteria**: A player can launch the game, select a song, play it with responsive note-hitting mechanics, view their score, and create/edit charts—all with polished UI and stable performance (60 FPS on desktop).

#### Stretch Goals (Nice-to-Have if Time Allows)

Prioritized list of features to implement if core development finishes ahead of schedule:

**High Priority Stretch Goals**:
1. **Mobile Build**: Android/iOS export with touch-optimized controls
2. **AI Chart Generation**: Automatic chart creation from audio analysis (beat detection, rhythm patterns)
3. **Advanced Visual Effects**: Background animations, stage lighting, camera shake, combo streak effects
4. **Tutorial System**: First-time user guidance explaining controls and gameplay mechanics
5. **Accessibility Features**: Colorblind mode, adjustable hit windows, visual cue customization

**Medium Priority Stretch Goals**:
6. **User Customization**: Note skins, runway textures, UI themes
7. **Achievements System**: Unlock badges for milestones (first perfect score, 500-note combo, etc.)
8. **Replay System**: Record and playback gameplay sessions
9. **Practice Mode**: Loop specific sections of songs, slow down playback for learning

**Low Priority Stretch Goals**:
10. **Local Multiplayer**: Split-screen or turn-based competitive modes
11. **Online Leaderboards**: Cloud-hosted score tracking and global rankings
12. **Steam Integration**: Achievements, cloud saves, workshop for sharing charts
13. **Animated Characters**: Background dancers or performers that react to gameplay

### Success Metrics
- **Functional Completeness**: Player can select a song, play through it with responsive note-hitting mechanics (< 50ms latency), view accurate score results, and create/edit custom charts with playback testing. All core gameplay systems (spawning, input, scoring, UI) working at 60 FPS on desktop.
- **Multi-Agent Coordination**: Documented evidence in `.github/copilot-logs.md` showing: (1) Coordinator Agent delegating tasks to specialized agents, (2) Visuals Agent creating scene files that Logic Agent successfully scripts, (3) Ideas Agent solutions implemented by other agents, (4) At least 10 documented multi-agent workflows with clear context handoffs.
- **Professional Quality**: Code follows Godot best practices with consistent naming conventions (`snake_case` for variables/functions, `PascalCase` for classes), design patterns implemented correctly (Command for input, Object Pool for notes, Observer for events), comprehensive inline documentation, no compiler warnings, and modular architecture with clear separation of concerns.
- **Portfolio Readiness**: Professional README with demo video/screenshots, clean commit history with meaningful messages, documented architecture with diagrams, playable build uploaded to itch.io or similar platform, and comprehensive AI coordination documentation demonstrating advanced workflow patterns suitable for showcasing technical sophistication to potential employers.

---

## Technical Architecture

### Technology Stack
- **Primary Language**: gdscript
- **Framework/Engine**: Godot 4
- **Database**: N/A
- **Key Libraries**: N/A
- **Deployment**: Desktop: Windows/Linux, Mobile: Android

### Multi-Agent System Design

**Agent 1: Visuals Agent (Scene Designer)**
```
Agent Name: Visuals Agent
Primary Responsibility: Designing visual elements and UI layouts by creating Godot .tscn (scene) files
Input: 
  - Scene requirements and specifications (e.g., "Create main menu with play button, settings, and quit")
  - UI/UX mockups or wireframes describing layout
  - References to existing scenes for consistency
  - Asset references (textures, models, fonts) to incorporate
Output: 
  - Complete .tscn files with proper node hierarchies
  - UI elements with appropriate anchors, margins, and responsive layouts
  - Scene configurations with scripts attached and properties set
  - Documentation of scene structure and node purposes
Coordination Pattern: Context Handoff
  - Receives game state requirements from Coordinator
  - Provides scene structure details to Logic Agent for script integration
  - Collaborates with Ideas Agent on visual concepts and user experience improvements
Failure Handling: 
  - Fallback to alternative AI model (e.g., switch from Claude to ChatGPT)
  - Manual scene design in Godot editor using visual tools
  - Request Logic Agent assistance for simpler scene structures
  - Consult existing template scenes as references
```

**Agent 2: Logic Agent (Systems Programmer)**
```
Agent Name: Logic Agent
Primary Responsibility: Implementing game logic and systems through GDScript (.gd) files
Input:
  - System design specifications (e.g., "Implement note spawning system with Command pattern")
  - Design patterns to apply (Command, State, Observer, etc.)
  - Scene structure from Visuals Agent for integration
  - Performance requirements (frame rate targets, memory constraints)
  - Existing codebase context for consistency
Output:
  - Complete .gd script files with proper class structure
  - Implementation of game systems following design patterns
  - Integration code connecting scripts to scene nodes
  - Code documentation with inline comments and function descriptions
  - Performance optimization notes and profiling considerations
Coordination Pattern: Context Handoff
  - Receives architectural decisions from Coordinator
  - Integrates with scenes created by Visuals Agent
  - Implements ideas generated by Ideas Agent
  - References ADR logs for consistency with prior decisions
Failure Handling:
  - Switch to alternative AI model for different approaches
  - Manual coding in VS Code with Copilot assistance
  - Request Visuals Agent to simplify scene structure if integration is complex
  - Break complex systems into smaller, manageable components
```

**Agent 3: Ideas Agent (Feature Designer)**
```
Agent Name: Ideas Agent
Primary Responsibility: Generating creative concepts, features, and solutions for design challenges
Input:
  - Open-ended questions about feature possibilities (e.g., "What visual effects would enhance combo streaks?")
  - Design problems needing creative solutions (e.g., "How should we handle note spawning on mobile touch screens?")
  - Requests for user experience improvements
  - Competitive analysis of similar games for inspiration
Output:
  - Structured lists of feature ideas with pros/cons
  - Creative solutions to design challenges
  - User experience improvement suggestions
  - Prioritized recommendations based on implementation complexity
  - References to industry best practices and successful patterns from other games
Coordination Pattern: Brainstorming & Validation
  - Proposes features that Coordinator evaluates for scope/feasibility
  - Provides creative direction to Visuals Agent for aesthetic decisions
  - Suggests algorithmic approaches to Logic Agent for system design
  - Can be consulted by any agent for creative problem-solving
Failure Handling:
  - Poll multiple AI models for diverse perspectives
  - Conduct user testing with peers for real-world feedback
  - Research similar games for proven patterns
  - Defer to developer's creative vision when AI suggestions don't align with goals
```

**Agent 4: Coordinator Agent (Development Manager)**
```
Agent Name: Coordinator Agent
Primary Responsibility: Orchestrating multi-agent workflows, maintaining context, and ensuring architectural consistency
Input:
  - High-level development goals and sprint objectives
  - ADR (Architecture Decision Record) logs documenting design decisions
  - Integration requirements between agents' outputs
  - Progress reports and blockers from specialized agents
Output:
  - Task delegation to appropriate specialized agents
  - Context packages for agent handoffs with relevant information
  - Updated ADR logs documenting decisions and rationale
  - Integration instructions ensuring agent outputs work together
  - Progress summaries and milestone tracking
Coordination Pattern: Central Orchestrator
  - Receives developer's high-level instructions
  - Delegates tasks to Visuals, Logic, or Ideas agents based on task type
  - Manages context handoffs by packaging relevant information for each agent
  - Resolves conflicts when agents produce incompatible outputs
  - Maintains architectural vision across all development activities
Failure Handling:
  - Developer directly manages agents if coordination breaks down
  - Simplify workflow to direct agent-to-agent communication without centralization
  - Use GitHub MCP for version control and rollback if integration fails
  - Implement "pairing" where two agents collaborate directly on complex tasks
```

### Architecture
[Insert architecture diagram or link to diagram in docs/ folder]

---

## Sprint Progress

### Sprint 1: Foundation & Core Setup (Weeks 8-9)
**Goal**: Establish project architecture with working .chart parsing, note spawning system, and basic input detection to validate core rhythm game pipeline.

**Completed**:
- [✓] Repository structure with Scripts/, Scenes/, Assets/, Documentation/ organization
- [✓] ChartParser.gd with .chart file parsing (resolution, tempo events, notes with HOPO/TAP detection)
- [✓] note_spawner.gd with spawn scheduling system (converts tick positions to hit times, precomputes spawn_data)
- [✓] note.gd and note.tscn for individual note behavior (travel down runway at configurable speed)
- [✓] input_handler.gd with chord-aware hit detection using timing windows
- [✓] game_config.gd with centralized constants (timing windows, note speed defaults)
- [✓] gameplay.gd orchestrating countdown, audio sync, lane setup
- [✓] ScoreManager.gd with combo system, score calculation, grade tracking
- [✓] board_renderer.gd for procedural lane mesh generation
- [✓] settings_manager.gd autoload for persistent user configuration
- [✓] song_select.tscn and main_menu.tscn for navigation UI
- [✓] Basic results_screen.tscn displaying post-song statistics

**In Progress**:
- Object pooling optimization (NotePool.gd, HitEffectPool.gd) to reduce instantiation overhead
- Advanced visual effects (hit effects, combo animations)
- Chart editor initial implementation

**Challenges**:
- **Chord detection**: Initial per-note event-driven input broke chords. Solution: Switched to frame-based candidate filtering in input_handler.gd, checking all active notes per lane once per frame with timing windows.
- **Timing accuracy**: Notes spawned off-sync with audio. Solution: Implemented travel_time calculation `abs(runway_begin_z) / note_speed` and spawn scheduling using `hit_time - travel_time`, with audio offset handling for pre-roll.
- **Variable lane count**: Hard-coded 5 lanes broke with open notes. Solution: Dynamically determine lane count from max fret in chart data before spawning.

**AI Coordination**: Used GitHub Copilot (Logic Agent) for implementing core systems (ChartParser, note_spawner, input_handler) with design pattern suggestions. Claude (Coordinator Agent) helped architect multi-script integration and timing pipeline. ChatGPT (Ideas Agent) provided solutions for chord detection algorithm and HOPO detection rules. All interactions logged in `.github/copilot-logs.md` (14+ entries documenting context handoffs and decision rationale).

---

### Sprint 2: Core Feature Implementation (Week 10)
**Goal**: Complete gameplay polish with sustain notes, visual/audio feedback, pause system, and finish chart editor basic functionality.

**Deliverables**:
- [ ] Sustain note rendering (note_tail.tscn) with hold detection
- [ ] Visual feedback system (hit effects, combo display animations, miss indicators)
- [ ] Audio feedback (hit sounds per grade, miss sounds, combo milestone sounds)
- [ ] Pause menu (pause_handler.gd) with resume/restart/quit functionality
- [ ] Chart editor: timeline view, note placement/deletion, waveform visualization
- [ ] Chart editor: playback testing within editor, save/load .chart files
- [ ] Object pooling fully integrated (reduce GC pressure during gameplay)

**AI Coordination Focus**: Visuals Agent creates hit_effect.tscn and chart editor UI layouts, Logic Agent implements sustain tracking and editor logic, Ideas Agent suggests visual effect patterns and editor UX improvements.

**Status**: Not started

---

### Sprint 3: Feature Expansion (Week 11)
**Goal**: Add advanced features including settings customization, tutorial system, and multiple difficulty support.

**Deliverables**:
- [ ] Advanced settings UI (audio calibration slider, visual customization options)
- [ ] Key rebinding interface with conflict detection
- [ ] Tutorial system (first-time user guidance, practice mode for sections)
- [ ] Multiple difficulty levels per song with auto-detection from .chart sections
- [ ] Improved song selection UI (search/filter, difficulty indicators, preview audio)
- [ ] Background visual effects (stage lighting, reactive animations)
- [ ] Performance profiling and optimization (maintain 60 FPS with effects)

**AI Coordination Focus**: Ideas Agent designs tutorial flow and UX patterns, Visuals Agent creates settings/tutorial scenes, Logic Agent implements rebinding system and difficulty switching, Coordinator Agent ensures feature integration doesn't break existing systems.

**Status**: Not started

---

### Sprint 4: Integration & Testing (Week 12)
**Goal**: Comprehensive testing, bug fixing, and cross-platform compatibility validation.

**Deliverables**:
- [ ] Unit tests for core systems (ChartParser, note_spawner, ScoreManager)
- [ ] Integration tests for full gameplay pipeline
- [ ] Performance testing with various song complexities
- [ ] User testing with 3-5 peers, collect feedback
- [ ] Bug triage and fixing based on testing results
- [ ] Cross-platform builds (Windows, Linux, Mac exports)
- [ ] Mobile build attempt (Android with touch controls)
- [ ] Memory profiling and leak detection

**AI Coordination Focus**: Logic Agent writes test cases, Coordinator Agent manages bug triage and prioritization, Ideas Agent suggests test scenarios and edge cases, all agents assist with debugging specific issues.

**Status**: Not started

---

### Sprint 5: Refinement & Advanced Features (Week 13)
**Goal**: Implement stretch goals (AI chart generation, advanced customization) and polish user experience.

**Deliverables**:
- [ ] AI chart generation: beat detection from audio analysis
- [ ] AI chart generation: note pattern generation based on difficulty
- [ ] User customization system (note skins, runway textures, UI themes)
- [ ] Achievements system with unlock tracking
- [ ] Replay system (record inputs, playback gameplay)
- [ ] Accessibility features (colorblind mode, adjustable hit windows)
- [ ] Documentation: architecture diagrams, API reference for extensibility
- [ ] Demo video recording (3-5 minutes showcasing features)

**AI Coordination Focus**: Ideas Agent designs AI chart generation algorithm, Logic Agent implements beat detection and pattern generation, Visuals Agent creates customization UI, Coordinator Agent ensures stretch goals don't compromise core stability.

**Status**: Not started

---

### Sprint 6: Final Polish & Presentation Preparation (Week 14)
**Goal**: Finalize all features, comprehensive testing, polish UI/UX, prepare presentation.

**Deliverables**:
- [ ] Final UI/UX polish (consistent styling, smooth transitions, responsive layouts)
- [ ] Sound design polish (balance audio levels, add ambient music to menus)
- [ ] Bundle 5-7 high-quality songs with fully tested charts
- [ ] Final performance optimization pass
- [ ] Professional README with screenshots, demo video embed, setup instructions
- [ ] itch.io build upload with description and screenshots
- [ ] Presentation preparation (5-minute demo script, backup plan for live demo)
- [ ] Portfolio documentation (AI coordination case study, technical architecture writeup)
- [ ] Final testing pass on all platforms

**AI Coordination Focus**: Coordinator Agent manages final checklist and ensures nothing is missed, all agents assist with polish tasks, Ideas Agent suggests presentation structure and demo flow, Visuals Agent polishes UI assets.

**Status**: Not started

---

## 🎤 Week 15: Live Presentation (5 minutes)
**Format**: Live demonstration during class
- 30 seconds: Project overview
- 2-3 minutes: Core functionality demo
- 1 minute: AI coordination approach
- 30 seconds: Reflection and learning

---

## 🚀 Getting Started

### Prerequisites
- **Godot Engine 4.x** (tested on 4.2+) - Download from [godotengine.org](https://godotengine.org/)
- **Git** for version control
- **Audio files**: .ogg format for song tracks
- **Chart files**: .chart format (Clone Hero compatible) or use the in-game chart editor

### Installation
```powershell
# Clone repository
git clone https://github.com/rk3026/RhythmGame.git
cd RhythmGame

# Open in Godot
# 1. Launch Godot Engine
# 2. Click "Import" on the Project Manager
# 3. Navigate to the cloned RhythmGame folder
# 4. Select project.godot
# 5. Click "Import & Edit"

# Run the game
# Press F5 in Godot Editor or click the Play button (top-right)
```

### Adding Custom Songs
```powershell
# Place song files in Assets/Tracks/ with the following structure:
# Assets/Tracks/Artist - Title [Charter]/
#   ├── notes.chart     (required)
#   ├── song.ogg        (required)
#   ├── album.png       (optional)
#   └── background.jpg  (optional)

# The game will auto-detect new tracks on the song selection screen
```

### Testing
```powershell
# Unit tests (when implemented in Sprint 4)
# Run from Godot script editor or command line:
godot --headless --script res://Tests/run_tests.gd

# Manual testing checklist:
# - Select a song and complete playthrough
# - Test all difficulty levels
# - Verify scoring accuracy with known note patterns
# - Test pause/resume functionality
# - Validate chart editor save/load
```

---

## 📚 Documentation

Detailed documentation is maintained in the `.context/` folder:
- **`.context/project-context.md`**: Architecture decisions, design patterns, tech stack rationale
- **`.context/ai-coordination-strategy.md`**: AI agent roles, coordination patterns, successful workflows
- **`.context/development-tracking.md`**: Detailed sprint progress, daily logs, problems/solutions

Additional technical documentation (diagrams, API docs) may be in the `docs/` folder.

---

## 🤖 AI Coordination Summary

### Primary Development Agent (Logic Agent)
**Tool**: GitHub Copilot (VS Code extension)
**Used For**: Real-time code generation for GDScript, implementation of game systems following design patterns (Command, Observer, Object Pool), debugging runtime errors, and writing inline documentation. Primary workhorse for script creation and refactoring.

### Architecture & Design Agent (Coordinator Agent)
**Tool**: Claude via Cursor IDE
**Used For**: High-level system architecture design, multi-script integration planning, reviewing complex logic for optimization opportunities, generating architectural documentation, and managing context handoffs between specialized agents. Maintains ADR (Architecture Decision Record) logs.

### Creative Solutions Agent (Ideas Agent)
**Tool**: ChatGPT (web interface)
**Used For**: Brainstorming feature implementations, solving design challenges (e.g., chord detection algorithm), researching Godot best practices, suggesting visual effect patterns, and providing domain-specific guidance on rhythm game mechanics. Consulted for creative problem-solving when Logic Agent approaches hit limitations.

### Scene Design Agent (Visuals Agent)
**Tool**: GitHub Copilot Chat (within VS Code)
**Used For**: Generating .tscn scene files with proper node hierarchies, designing UI layouts with responsive anchors, suggesting visual organization patterns, and creating scene documentation. Works in tandem with Logic Agent to ensure script integration compatibility.

**Coordination Approach**: Central orchestration via Coordinator Agent (Claude) which delegates tasks based on type: scene design → Visuals Agent, system implementation → Logic Agent, creative challenges → Ideas Agent. Context handoffs documented in `.github/copilot-logs.md` with full prompts and responses. All agents reference this log to maintain consistency. Pattern: (1) Coordinator breaks down feature, (2) specialized agents implement components, (3) Coordinator validates integration, (4) Logic Agent performs final integration. See `.github/copilot-instructions.md` for detailed workflow rules.

---

## 📝 License
MIT License - See LICENSE file for details. Assets (songs, charts) retain their original creators' licenses.

---

## 👤 Contact
**Ross Kugler** - ross.kugler@wsu.edu

**Course**: CptS 483 Special Topic - Coding with Agentic AI  
**Instructor**: Dr. David Dupre  
**Semester**: Fall 2025

**GitHub Repository**: https://github.com/rk3026/RhythmGame  
**Itch.io Page**: (TBD - will be added in Sprint 6)