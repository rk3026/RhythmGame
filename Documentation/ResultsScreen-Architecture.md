# Results Screen Component Architecture

## Component Hierarchy

```
ResultsScreen (Control)
│
├── [Data Layer]
│   ├── score: int
│   ├── max_combo: int
│   ├── total_notes: int
│   ├── hits_per_grade: Dictionary
│   ├── song_title: String
│   ├── difficulty: String
│   ├── chart_path: String
│   └── instrument: String
│
├── [UI Components]
│   │
│   ├── RankDisplay
│   │   ├── Purpose: Show rank (S/A/B/C/D/F)
│   │   ├── Methods:
│   │   │   ├── set_rank(rank, animate)
│   │   │   ├── show_new_record_badge()
│   │   │   └── calculate_rank_from_accuracy(accuracy)
│   │   └── Visual: Gold star banner with badge
│   │
│   ├── StatCard (x3 instances)
│   │   │
│   │   ├── ScoreCard
│   │   │   ├── Displays: Formatted score
│   │   │   └── Comparison: ±points
│   │   │
│   │   ├── AccuracyCard
│   │   │   ├── Displays: Percentage
│   │   │   └── Comparison: ±percent
│   │   │
│   │   └── ComboCard
│   │       ├── Displays: Max combo
│   │       └── Comparison: ±combo count
│   │
│   ├── JudgmentBreakdown
│   │   ├── Purpose: Visual breakdown of hits
│   │   ├── Methods:
│   │   │   └── set_judgments(perfect, great, good, miss, total)
│   │   └── Visual: 4 colored progress bars with labels
│   │
│   ├── ProgressionDisplay
│   │   ├── Purpose: Show XP, level, achievements
│   │   ├── Methods:
│   │   │   ├── set_xp_earned(xp, animate)
│   │   │   ├── set_level_up(old, new, animate)
│   │   │   ├── set_achievements(array)
│   │   │   └── hide_all()
│   │   └── Visual: Stacked sections that show/hide
│   │
│   └── Buttons
│       ├── RetryButton → _on_retry()
│       └── MenuButton → _on_menu()
│
└── [Integration Layer]
    ├── ScoreHistoryManager
    │   ├── get_score_data()
    │   └── update_score()
    │
    ├── ProfileManager
    │   ├── record_song_completion()
    │   ├── add_xp()
    │   └── save_profile()
    │
    └── AchievementManager
        ├── load_profile_achievements()
        └── check_achievements_after_song()
```

## Data Flow

```
GamePlay (scene)
    ↓
    [Exports data]
    ↓
ResultsScreen._ready()
    ↓
    ├─→ Calculate accuracy
    ├─→ Format display values
    ├─→ Update ScoreHistoryManager
    └─→ Update ProfileManager
    
    ↓ [Populate Components]
    
    ├─→ RankDisplay
    │   └─→ Shows rank + badge
    │
    ├─→ StatCards
    │   └─→ Show metrics + comparisons
    │
    ├─→ JudgmentBreakdown
    │   └─→ Animate progress bars
    │
    └─→ ProgressionDisplay
        └─→ Show XP/Level/Achievements

    ↓ [User Input]
    
    Retry → Reload gameplay
    Menu  → Return to song select
```

## Component Communication

### One-Way Data Binding (Parent → Child)

```gdscript
# ResultsScreen (Parent)
@onready var rank_display = $ScrollContainer/MainVBox/RankDisplay
@onready var score_card = $ScrollContainer/MainVBox/StatsHBox/ScoreCard

func _ready():
    # Parent calculates data
    var accuracy = calculate_accuracy()
    var rank = rank_display.calculate_rank_from_accuracy(accuracy)
    
    # Parent pushes data to children
    rank_display.set_rank(rank, true)
    score_card.set_stat("SCORE", _format_score(score))
    
    # Children never communicate back to parent
    # Children never modify parent's state
```

### No Cross-Component Communication

```gdscript
# ✅ GOOD: Parent coordinates all children
results_screen.rank_display.set_rank(...)
results_screen.score_card.set_stat(...)

# ❌ BAD: Components talking to each other directly
# (Not possible in this architecture - components are isolated)
```

## Styling Architecture

### Scene-Based Styling (Preferred)

```gdscript
# All styling happens in .tscn files via StyleBoxFlat resources

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_card"]
bg_color = Color(0.15, 0.15, 0.2, 0.95)
corner_radius_top_left = 8
corner_radius_bottom_right = 8
shadow_color = Color(0, 0, 0, 0.3)
shadow_size = 4

# No hardcoded colors/sizes in scripts!
```

### Dynamic Styling (When Necessary)

```gdscript
# Only for state-dependent colors (e.g., rank colors)
var rank_colors = {
    Rank.S: Color.GOLD,
    Rank.A: Color(0.5, 1.0, 0.5),
    # ...
}
rank_label.modulate = rank_colors[rank]

# Or comparison indicators (green = good, red = bad)
if difference > 0:
    comparison_label.modulate = Color(0.5, 1.0, 0.5)
else:
    comparison_label.modulate = Color(1.0, 0.5, 0.5)
```

## Animation Patterns

### Component-Level Animations

Each component manages its own animations:

```gdscript
# RankDisplay
func _play_rank_animation():
    rank_label.scale = Vector2.ZERO
    var tween = create_tween()
    tween.tween_property(rank_label, "scale", Vector2.ONE, 0.6)\
        .set_ease(Tween.EASE_OUT)\
        .set_trans(Tween.TRANS_ELASTIC)

# JudgmentBreakdown
func _animate_bars():
    for i in range(bars.size()):
        var tween = create_tween()
        tween.tween_property(bars[i], "value", targets[i], 0.8)\
            .set_delay(i * 0.1)  # Staggered!

# ProgressionDisplay
func _animate_level_up():
    var tween = create_tween()
    tween.set_loops()  # Infinite pulse
    tween.tween_property(level_up_label, "scale", Vector2(1.1, 1.1), 0.4)
    tween.tween_property(level_up_label, "scale", Vector2(1.0, 1.0), 0.4)
```

### Global Coordination

Parent can trigger animations by calling component methods:

```gdscript
# Parent decides WHEN to animate
rank_display.set_rank(rank, animate=true)  # true = play animation
progression_display.set_xp_earned(xp, animate=true)

# Components decide HOW to animate
# Parent doesn't know implementation details
```

## State Management

### Component State (Internal)

```gdscript
# Each component manages its own visibility/state
class ProgressionDisplay:
    func _ready():
        xp_label.visible = false  # Hidden by default
        level_up_container.visible = false
        achievements_container.visible = false
    
    func set_xp_earned(xp: int, animate: bool):
        if xp <= 0:
            xp_label.visible = false  # Handles its own state
            return
        xp_label.visible = true
        # ...
```

### Parent State (Shared)

```gdscript
# Parent holds shared game state
class ResultsScreen:
    @export var score: int
    @export var max_combo: int
    # ...
    
    var xp_earned: int = 0  # Calculated state
    var leveled_up: bool = false
    var unlocked_achievements: Array = []
```

## Testing Strategy

### Unit Testing Components

```gdscript
# test/components/test_stat_card.gd
func test_set_stat():
    var card = StatCard.new()
    card.set_stat("SCORE", "1,234,567")
    assert_eq(card.value_label.text, "1,234,567")

func test_comparison_positive():
    var card = StatCard.new()
    card.set_comparison(100, false)
    assert_true(card.comparison_label.visible)
    assert_eq(card.comparison_label.text, "+100 ↑")
    assert_eq(card.comparison_label.modulate, Color(0.5, 1.0, 0.5))
```

### Integration Testing

```gdscript
# test/scenes/test_results_screen.gd
func test_results_screen_displays_data():
    var results = ResultsScreen.new()
    results.score = 100000
    results.max_combo = 50
    results.total_notes = 100
    results.hits_per_grade = {"perfect": 80, "great": 15, "good": 5, "miss": 0}
    
    results._ready()
    
    # Verify components were updated
    assert_true(results.rank_display.rank_label.text.contains("A"))
    assert_true(results.score_card.value_label.text == "100,000")
```

## File Organization

```
RhythmGame/
├── Scenes/
│   ├── results_screen.tscn          # Main scene
│   └── Components/                   # ← New folder
│       ├── rank_display.tscn
│       ├── stat_card.tscn
│       ├── judgment_breakdown.tscn
│       └── progression_display.tscn
│
├── Scripts/
│   ├── results_screen.gd            # Main controller
│   └── Components/                   # ← New folder
│       ├── rank_display.gd
│       ├── stat_card.gd
│       ├── judgment_breakdown.gd
│       └── progression_display.gd
│
└── Documentation/
    ├── ResultsScreen-UI-Refactor.md
    ├── ResultsScreen-Comparison.md
    └── ResultsScreen-Architecture.md # ← This file
```

## Benefits Recap

1. **Single Responsibility:** Each component does ONE thing well
2. **Open/Closed:** Easy to extend (add components) without modifying existing code
3. **Dependency Inversion:** Parent depends on component interfaces, not implementations
4. **DRY (Don't Repeat Yourself):** StatCard used 3 times with different data
5. **Testable:** Each component can be tested independently
6. **Maintainable:** Changes are localized to specific components

## Future Extensions

### Adding a New Component

```gdscript
# 1. Create component scene/script
# Scenes/Components/leaderboard_card.tscn
# Scripts/Components/leaderboard_card.gd

# 2. Add to results scene
# results_screen.tscn → Drag in leaderboard_card.tscn

# 3. Reference in parent script
@onready var leaderboard_card = $ScrollContainer/MainVBox/LeaderboardCard

# 4. Populate in _ready()
leaderboard_card.set_rank(global_rank, player_count)

# That's it! No modifications to existing components needed.
```

This architecture scales well for complex UI requirements while keeping code organized and maintainable.
