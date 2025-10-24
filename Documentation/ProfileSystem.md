# Profile System Documentation

**Version:** 1.0  
**Date:** October 22, 2025  
**Project:** Godot 4 3D Rhythm Game

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Data Structures](#data-structures)
4. [Storage Strategy](#storage-strategy)
5. [Profile Manager API](#profile-manager-api)
6. [Achievement System](#achievement-system)
7. [Progression System](#progression-system)
8. [Integration Guide](#integration-guide)
9. [Migration Guide](#migration-guide)

---

## Overview

The Profile System provides comprehensive player identity, progression, and customization features for the rhythm game. It tracks player statistics, achievements, unlockables, and preferences across play sessions.

### Key Features
- **Multiple Profile Support**: Create and switch between multiple player profiles
- **Statistics Tracking**: Comprehensive lifetime statistics and play history
- **Achievement System**: Unlockable achievements with progress tracking
- **Progression System**: XP-based leveling with rewards
- **Customization**: Avatars, themes, titles, and visual customization
- **Data Portability**: Export/import profiles for backup and transfer

---

## Architecture

### Singleton Pattern
The Profile System uses autoload singletons following the project's existing pattern:

- **ProfileManager**: Core profile management, data persistence, profile switching
- **AchievementManager**: Achievement definitions, unlocking, progress tracking
- **ProgressionManager**: XP calculation, level progression, rewards

### Integration Points
- **ScoreHistoryManager**: Profile-specific score storage
- **SettingsManager**: Profile-specific settings (future enhancement)
- **Results Screen**: XP/achievement updates post-gameplay
- **Main Menu**: Profile display and navigation

---

## Data Structures

### Profile Core Data

```gdscript
# Profile data structure (stored in profile.cfg)
{
	# Identity
	"profile_id": String,           # UUID for profile
	"username": String,              # Display username (3-20 chars)
	"display_name": String,          # Optional display name
	"bio": String,                   # Profile bio (max 200 chars)
	"created_at": String,            # ISO 8601 timestamp
	"last_played": String,           # ISO 8601 timestamp
	
	# Progression
	"level": int,                    # Current level (1-100)
	"xp": int,                       # Current XP
	"total_xp": int,                 # Lifetime XP earned
	
	# Customization
	"avatar_id": String,             # Selected avatar identifier
	"theme_id": String,              # Selected theme identifier
	"title_id": String,              # Equipped title identifier
	"profile_color_primary": String, # Hex color code
	"profile_color_accent": String,  # Hex color code
	
	# Privacy Settings
	"privacy_stats": String,         # "public", "friends", "private"
	"privacy_activity": String,      # "public", "friends", "private"
	
	# Statistics (lifetime)
	"stats": {
		"total_playtime_seconds": int,
		"total_songs_played": int,
		"total_songs_completed": int,
		"total_notes_hit": int,
		"total_notes_missed": int,
		"highest_combo": int,
		"total_perfect": int,
		"total_great": int,
		"total_good": int,
		"total_miss": int,
		"play_streak_current": int,   # Days played consecutively
		"play_streak_best": int,
		"favorite_song": String,       # Chart path
		"favorite_instrument": String,
		"sessions_played": int,
		"last_session_date": String,
		
		# Difficulty distribution (songs played per difficulty)
		"difficulty_distribution": {
			"Easy": int,
			"Medium": int,
			"Hard": int,
			"Expert": int
		}
	}
}
```

### Achievement Data Structure

```gdscript
# Achievement definition (in achievements.json)
{
	"achievement_id": String,        # Unique identifier
	"name": String,                  # Display name
	"description": String,           # Description
	"icon": String,                  # Icon resource path
	"category": String,              # "score", "combo", "completion", "accuracy", "special"
	"requirement": {
		"type": String,              # "total", "single", "condition"
		"target": int,               # Target value
		"stat": String               # Stat to track
	},
	"reward": {
		"xp": int,                   # XP reward
		"unlocks": Array[String]     # Avatar IDs, theme IDs, title IDs
	},
	"hidden": bool                   # Hidden until unlocked
}

# Achievement progress (stored in achievements.cfg per profile)
{
	"achievements": {
		"achievement_id": {
			"unlocked": bool,
			"progress": int,         # Current progress toward target
			"unlocked_at": String    # Timestamp
		}
	}
}
```

### Activity Feed Entry

```gdscript
# Activity entry (stored in activity.cfg per profile)
{
	"timestamp": String,             # ISO 8601 timestamp
	"type": String,                  # "song_complete", "new_record", "achievement", "level_up"
	"data": {
		# Type-specific data
		# For song_complete: chart_path, difficulty, score, grade
		# For new_record: record_type, old_value, new_value
		# For achievement: achievement_id, name
		# For level_up: new_level, xp_earned
	}
}
```

---

## Storage Strategy

### Directory Structure

```
user://
├── profiles/
│   ├── profiles_list.cfg          # List of all profiles
│   └── [profile_id]/              # Individual profile directory
│       ├── profile.cfg            # Core profile data
│       ├── scores.cfg             # Profile-specific scores (migrated from ScoreHistoryManager)
│       ├── achievements.cfg       # Achievement progress
│       ├── activity.cfg           # Recent activity feed
│       └── stats_history.cfg      # Historical stats for graphing (optional)
└── exports/                       # Profile export backups
    └── profile_backup_[timestamp].zip
```

### ConfigFile Format

All data is stored using Godot's `ConfigFile` format for consistency with existing systems (SettingsManager, ScoreHistoryManager).

**Example profile.cfg:**
```ini
[identity]
profile_id="550e8400-e29b-41d4-a716-446655440000"
username="Player1"
display_name="The Rhythm Master"
bio="Love rhythm games!"
created_at="2025-10-22T10:30:00Z"
last_played="2025-10-22T15:45:00Z"

[progression]
level=15
xp=12500
total_xp=45000

[customization]
avatar_id="avatar_guitar"
theme_id="theme_neon"
title_id="title_prodigy"
profile_color_primary="#FF6B6B"
profile_color_accent="#4ECDC4"

[privacy]
privacy_stats="public"
privacy_activity="public"

[stats]
total_playtime_seconds=72000
total_songs_played=350
total_songs_completed=320
total_notes_hit=125000
total_notes_missed=8500
highest_combo=1250
# ... more stats
```

---

## Profile Manager API

### Core Functions

```gdscript
# Profile Creation & Management
ProfileManager.create_profile(username: String) -> Dictionary
ProfileManager.load_profile(profile_id: String) -> bool
ProfileManager.save_profile() -> bool
ProfileManager.delete_profile(profile_id: String) -> bool
ProfileManager.get_all_profiles() -> Array[Dictionary]
ProfileManager.switch_profile(profile_id: String) -> bool

# Profile Data Access
ProfileManager.get_current_profile() -> Dictionary
ProfileManager.update_profile_field(field: String, value: Variant) -> void
ProfileManager.get_profile_stat(stat_name: String) -> Variant

# Statistics Updates
ProfileManager.record_song_completion(chart_path: String, difficulty: String, stats: Dictionary) -> void
ProfileManager.add_playtime(seconds: float) -> void
ProfileManager.update_play_streak() -> void
ProfileManager.record_note_hit(grade: int) -> void

# Customization
ProfileManager.set_avatar(avatar_id: String) -> bool
ProfileManager.set_theme(theme_id: String) -> bool
ProfileManager.set_title(title_id: String) -> bool
ProfileManager.set_profile_colors(primary: Color, accent: Color) -> void

# Profile Export/Import
ProfileManager.export_profile(profile_id: String, export_path: String) -> bool
ProfileManager.import_profile(import_path: String) -> Dictionary
```

### Signals

```gdscript
signal profile_created(profile_id: String)
signal profile_loaded(profile_id: String)
signal profile_updated(field: String, value: Variant)
signal profile_switched(old_id: String, new_id: String)
signal profile_deleted(profile_id: String)
signal stat_updated(stat_name: String, new_value: Variant)
signal level_up(new_level: int, xp_earned: int)
```

---

## Achievement System

### Achievement Categories

1. **Score Achievements**: Total score milestones, single song scores
2. **Combo Achievements**: Max combo milestones, perfect combos
3. **Completion Achievements**: Songs completed, difficulty tiers
4. **Accuracy Achievements**: Accuracy percentages, perfect accuracy
5. **Collection Achievements**: Play all songs, play all difficulties
6. **Special Achievements**: Hidden conditions, easter eggs

### Achievement Checking

Achievements are checked automatically after:
- Song completion (results screen)
- Stat updates (ProfileManager)
- Manual triggers (special conditions)

### Example Achievement Definitions

```json
{
  "achievements": [
    {
      "achievement_id": "first_steps",
      "name": "First Steps",
      "description": "Complete your first song",
      "icon": "res://Assets/Achievements/first_steps.png",
      "category": "completion",
      "requirement": {
        "type": "total",
        "target": 1,
        "stat": "total_songs_completed"
      },
      "reward": {
        "xp": 100,
        "unlocks": ["avatar_beginner"]
      },
      "hidden": false
    },
    {
      "achievement_id": "combo_master",
      "name": "Combo Master",
      "description": "Achieve a 500 note combo",
      "icon": "res://Assets/Achievements/combo_master.png",
      "category": "combo",
      "requirement": {
        "type": "single",
        "target": 500,
        "stat": "highest_combo"
      },
      "reward": {
        "xp": 500,
        "unlocks": ["title_combo_master", "avatar_lightning"]
      },
      "hidden": false
    }
  ]
}
```

---

## Progression System

### XP Calculation

XP is earned from gameplay with the following formula:

```gdscript
# Base XP from notes hit
base_xp = (perfect_count * 10) + (great_count * 7) + (good_count * 4)

# Completion bonus
completion_bonus = 500 if song_completed else 0

# Difficulty multiplier
difficulty_mult = {
	"Easy": 1.0,
	"Medium": 1.5,
	"Hard": 2.0,
	"Expert": 2.5
}

# Accuracy bonus
accuracy_bonus = base_xp * 0.5 if accuracy >= 95% else 0

# Total XP
total_xp = (base_xp + completion_bonus) * difficulty_mult + accuracy_bonus
```

### Level Progression

```gdscript
# Level calculation (exponential curve)
func calculate_level(total_xp: int) -> int:
	# Level = floor(0.1 * sqrt(total_xp))
	return floor(0.1 * sqrt(total_xp))

# XP required for next level
func xp_for_next_level(current_level: int) -> int:
	return pow((current_level + 1) * 10, 2)

# Example progression:
# Level 1: 0 XP
# Level 2: 400 XP
# Level 3: 900 XP
# Level 10: 10,000 XP
# Level 50: 250,000 XP
# Level 100: 1,000,000 XP
```

### Level Rewards

Rewards are granted at specific level milestones:
- **Level 5**: Unlock first custom avatar
- **Level 10**: Unlock profile theme customization
- **Level 15**: Unlock first title
- **Level 25**: Unlock advanced avatars
- **Level 50**: Unlock prestige option
- **Level 100**: Max level badge and special avatar

---

## Integration Guide

### Integrating Profile Updates in Gameplay

**In results_screen.gd:**

```gdscript
func _update_score_history():
	# Existing score history update
	var stats = {
		"score": score,
		"max_combo": max_combo,
		"grade_counts": hits_per_grade,
		"total_notes": total_notes,
		"completed": true
	}
	
	var is_new_record = ScoreHistoryManager.update_score(chart_path, instrument, stats)
	
	# NEW: Update profile statistics
	ProfileManager.record_song_completion(chart_path, instrument, stats)
	
	# NEW: Check for achievements
	AchievementManager.check_achievements_after_song(stats)
	
	# NEW: Calculate and display XP earned
	var xp_earned = ProgressionManager.calculate_xp(stats, difficulty)
	var leveled_up = ProfileManager.add_xp(xp_earned)
	
	if leveled_up:
		_show_level_up_animation(ProfileManager.get_current_level())
	
	_show_xp_earned(xp_earned)
```

### Adding Profile Display to Main Menu

**In main_menu.gd:**

```gdscript
func _ready():
	_connect_buttons()
	_setup_profile_display()

func _setup_profile_display():
	var profile = ProfileManager.get_current_profile()
	
	# Display avatar and username in header
	var avatar_icon = $Header/ProfileDisplay/Avatar
	avatar_icon.texture = load(ProfileManager.get_avatar_path(profile.avatar_id))
	
	var username_label = $Header/ProfileDisplay/Username
	username_label.text = profile.username
	
	var level_label = $Header/ProfileDisplay/Level
	level_label.text = "Lv. " + str(profile.level)
	
	# Connect to profile button
	$Header/ProfileDisplay/Button.pressed.connect(_on_profile_button_pressed)

func _on_profile_button_pressed():
	SceneSwitcher.push_scene("res://Scenes/profile_view.tscn")
```

---

## Migration Guide

### For Existing Players

When the profile system is first introduced, existing score data must be migrated.

**Migration Process:**

1. **First Launch Detection**: Check if `user://profiles/profiles_list.cfg` exists
2. **Automatic Default Profile Creation**: Create "Player" profile with UUID
3. **Score Data Migration**: Copy `user://score_history.cfg` to `user://profiles/[profile_id]/scores.cfg`
4. **Statistics Backfill**: Calculate lifetime stats from existing score history
5. **Backup Original**: Keep original `score_history.cfg` as backup

**Migration Code (in ProfileManager._ready()):**

```gdscript
func _ready():
	_check_and_migrate_legacy_data()
	_load_profile_list()
	
	if profiles.is_empty():
		# First time setup - create default profile
		var default_profile = create_profile("Player")
		load_profile(default_profile.profile_id)
	else:
		# Load last active profile
		var last_active = _get_last_active_profile()
		load_profile(last_active)

func _check_and_migrate_legacy_data():
	var legacy_scores = "user://score_history.cfg"
	
	if FileAccess.file_exists(legacy_scores) and not FileAccess.file_exists("user://profiles/migrated.flag"):
		print("ProfileManager: Migrating legacy score data...")
		
		# Create default profile
		var profile = create_profile("Player")
		
		# Copy scores to profile directory
		var src = legacy_scores
		var dst = "user://profiles/" + profile.profile_id + "/scores.cfg"
		DirAccess.copy_absolute(src, dst)
		
		# Backfill statistics from scores
		_backfill_stats_from_scores(profile.profile_id)
		
		# Mark migration complete
		var flag = FileAccess.open("user://profiles/migrated.flag", FileAccess.WRITE)
		flag.store_string(Time.get_datetime_string_from_system())
		flag.close()
		
		print("ProfileManager: Migration complete!")
```

---

## Best Practices

### Performance Considerations
- Save profile data on significant events (song completion, achievement unlock)
- Batch stat updates during gameplay, save on results screen
- Use signals for async updates to avoid blocking UI
- Cache frequently accessed data (current profile, unlocked items)

### Data Validation
- Validate all user input (usernames, display names, bio)
- Sanitize file paths and profile IDs
- Verify data integrity on load, use defaults for corrupted values
- Implement version checking for future profile format changes

### Future Online Integration
- Profile IDs use UUID format for global uniqueness
- Privacy settings prepared for friend/public visibility
- Activity feed structure compatible with social features
- Export/import system prepares for cloud sync

---

**Document Version:** 1.0  
**Last Updated:** October 22, 2025  
**Maintained By:** Development Team
