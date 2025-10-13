
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
- **Functional Completeness**: [Define what "working" means for your project]
- **Multi-Agent Coordination**: [How will you demonstrate effective agent coordination?]
- **Professional Quality**: [What standards define professional-quality code?]
- **Portfolio Readiness**: [What makes this portfolio-worthy?]

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
**Goal**: [What did you aim to achieve?]

**Completed**:
- [✓] [Completed task 1]
- [✓] [Completed task 2]

**In Progress**:
- [Major work item currently being implemented]

**Challenges**:
- [Challenge faced and how you addressed it]

**AI Coordination**: [Brief note on which agents you used and how - details in `.context/ai-coordination-strategy.md`]

---

### Sprint 2: Core Feature Implementation (Week 10)
**Goal**: [What you aim to achieve]

**Status**: [Not started / In progress / Complete]

---

### Sprint 3: Feature Expansion (Week 11)
**Goal**: [What you aim to achieve]

**Status**: [Not started / In progress / Complete]

---

### Sprint 4: Integration & Testing (Week 12)
**Goal**: [What you aim to achieve]

**Status**: [Not started / In progress / Complete]

---

### Sprint 5: Refinement & Advanced Features (Week 13)
**Goal**: [What you aim to achieve]

**Status**: [Not started / In progress / Complete]

---

### Sprint 6: Final Polish & Presentation Preparation (Week 14)
**Goal**: Finalize all features, comprehensive testing, polish UI/UX, prepare presentation

**Status**: [Not started / In progress / Complete]

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
[List software, tools, accounts needed]

### Installation
```bash
# Clone repository
git clone [your-repo-url]

# Install dependencies
[installation commands]

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run application
[run commands]
```

### Testing
```bash
# Run tests
[test commands]
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

### Primary Development Agent
**Tool**: [e.g., GitHub Copilot]
**Used For**: [Code generation, testing, debugging]

### Architecture & Design Agent
**Tool**: [e.g., Claude via Cursor]
**Used For**: [System design, code review, documentation]

### Domain Expert Agent
**Tool**: [e.g., ChatGPT]
**Used For**: [Domain-specific guidance, best practices]

**Coordination Approach**: [Brief overview - see `.context/ai-coordination-strategy.md` for details]

---

## 📝 License
[Choose an appropriate license for your project]

---

## 👤 Contact
[Your Name] - [Your Email]

**Course**: CptS 483 Special Topic - Coding with Agentic AI  
**Instructor**: [Instructor Name]  
**Semester**: Fall 2025