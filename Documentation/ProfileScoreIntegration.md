# Profile-Specific Score History Integration

## Overview
This document details the changes made to integrate profile-specific score tracking into the rhythm game. Previously, all profiles shared a single global score history file, which defeated the purpose of having multiple profiles. Now each profile maintains its own independent score history.

---

## Changes Made

### 1. ScoreHistoryManager.gd Refactoring ✅

**Location:** `Scripts/ScoreHistoryManager.gd`

**Key Changes:**

#### Added Profile-Aware Variables
```gdscript
const LEGACY_HISTORY_PATH := "user://score_history.cfg"  # Old global path (for migration)
const PROFILES_DIR := "user://profiles/"

var current_profile_id: String = ""
var history_path: String = ""
```

#### Added Profile Management Method
```gdscript
func set_profile(profile_id: String):
    """
    Set the active profile and load its score history.
    Called by ProfileManager when a profile is loaded or switched.
    """
    # Saves old profile scores if switching
    # Sets new profile path: user://profiles/[profile_id]/scores.cfg
    # Loads new profile scores
    # Emits profile_changed signal
```

#### Updated Score Storage
- **Old Path:** `user://score_history.cfg` (global, shared by all profiles)
- **New Path:** `user://profiles/[profile_id]/scores.cfg` (per-profile)

#### Updated Methods
- `load_score_history()` - Now uses profile-specific `history_path`
- `save_score_history()` - Now uses profile-specific `history_path`
- `_ready()` - No longer auto-loads scores, waits for ProfileManager

#### Added New Signal
```gdscript
signal profile_changed(profile_id: String)
```

---

### 2. ProfileManager.gd Integration ✅

**Location:** `Scripts/ProfileManager.gd`

**Key Changes:**

#### Updated load_profile() Method
```gdscript
# OLD (line 182):
_load_profile_scores(profile_id)

# NEW:
ScoreHistoryManager.set_profile(profile_id)
```

#### Removed Stub Method
Removed the placeholder `_load_profile_scores()` method (was at line 945) since we now use `ScoreHistoryManager.set_profile()` directly.

---

## How It Works

### Profile Loading Flow
1. User selects a profile in profile_select.gd
2. `ProfileManager.load_profile(profile_id)` is called
3. ProfileManager loads profile data from `user://profiles/[profile_id]/profile.cfg`
4. ProfileManager calls `ScoreHistoryManager.set_profile(profile_id)`
5. ScoreHistoryManager:
   - Saves current profile's scores (if switching profiles)
   - Sets new profile path: `user://profiles/[profile_id]/scores.cfg`
   - Loads new profile's scores
   - Emits `profile_changed` signal

### Score Saving Flow
1. Player completes a song in gameplay
2. results_screen.gd calls `ScoreHistoryManager.update_score()`
3. ScoreHistoryManager updates in-memory score_data
4. ScoreHistoryManager saves to current profile's `scores.cfg` file
5. **Each profile maintains completely separate score history**

### Profile Switching Flow
1. User switches from Profile A to Profile B
2. `ProfileManager.switch_profile(profile_b_id)` is called
3. ProfileManager saves Profile A's data
4. ProfileManager calls `ScoreHistoryManager.set_profile(profile_b_id)`
5. ScoreHistoryManager:
   - Saves Profile A's scores to `user://profiles/profile_a_id/scores.cfg`
   - Loads Profile B's scores from `user://profiles/profile_b_id/scores.cfg`
6. **Profile A's scores are now hidden, Profile B's scores are active**

---

## File Structure

### Before (Global Scores)
```
user://
├── score_history.cfg          ❌ Shared by all profiles
└── profiles/
    ├── profiles_list.cfg
    ├── [profile_a_id]/
    │   └── profile.cfg
    └── [profile_b_id]/
        └── profile.cfg
```

### After (Profile-Specific Scores)
```
user://
├── score_history.cfg          ⚠️ Legacy file (will be migrated by ProfileManager)
└── profiles/
    ├── profiles_list.cfg
    ├── [profile_a_id]/
    │   ├── profile.cfg
    │   └── scores.cfg         ✅ Profile A's scores only
    └── [profile_b_id]/
        ├── profile.cfg
        └── scores.cfg         ✅ Profile B's scores only
```

---

## Testing Plan

### Test 1: Multi-Profile Score Separation ⚠️ NEEDS TESTING

**Steps:**
1. Launch game, create Profile A ("Alice")
2. Play a song (e.g., "Re:Re:"), get score of 50,000
3. Check song_select.gd - should show 50,000 as high score
4. Go to main menu, select "Switch Profile"
5. Create Profile B ("Bob")
6. Check song_select.gd - should show NO high score for "Re:Re:" (never played)
7. Play "Re:Re:" with Profile B, get score of 60,000
8. Switch back to Profile A
9. Check song_select.gd - should show 50,000 (NOT 60,000)
10. Switch to Profile B
11. Check song_select.gd - should show 60,000

**Expected Results:**
- ✅ Profile A sees only its own 50,000 score
- ✅ Profile B sees only its own 60,000 score
- ✅ Scores do NOT leak between profiles

**If Test Fails:**
- Check `user://profiles/` directory structure
- Verify each profile has separate `scores.cfg` file
- Check console logs for "Loading scores for profile: [id]"

---

### Test 2: Profile Switching During Gameplay ⚠️ NEEDS TESTING

**Steps:**
1. Start with Profile A
2. Play a song, finish gameplay
3. On results screen, go back to main menu
4. Switch to Profile B
5. Verify Profile B's stats are shown (not Profile A's)
6. Switch back to Profile A
7. Verify Profile A's previous score is still there

**Expected Results:**
- ✅ No score corruption during profile switches
- ✅ Each profile maintains its own data

---

### Test 3: New Profile Starts Fresh ⚠️ NEEDS TESTING

**Steps:**
1. Create a brand new Profile C
2. Go to song_select.gd
3. Verify NO songs show high scores (all "Not Played")
4. Check `user://profiles/[profile_c_id]/` directory
5. Verify `scores.cfg` does NOT exist yet (created on first play)

**Expected Results:**
- ✅ New profiles have no pre-existing scores
- ✅ `scores.cfg` created after first song completion

---

### Test 4: Score History Persistence ⚠️ NEEDS TESTING

**Steps:**
1. Profile A plays 3 different songs, gets scores
2. Quit game completely
3. Relaunch game
4. Load Profile A
5. Go to song_select.gd
6. Verify all 3 scores are still there

**Expected Results:**
- ✅ Scores persist across game sessions
- ✅ Profile-specific `scores.cfg` saves correctly

---

## Migration Notes

### Existing Players
- ProfileManager already has migration logic for legacy `user://score_history.cfg`
- First time a profile loads, scores are migrated from global file to profile-specific file
- Original file is backed up to `score_history.cfg.backup`
- Migration flag: `user://profiles/migrated.flag`

### Code Reference
See `ProfileManager._check_and_migrate_legacy_data()` (line ~833)

---

## Integration Status

| Component | Status | Notes |
|-----------|--------|-------|
| ScoreHistoryManager | ✅ Complete | Profile-aware storage implemented |
| ProfileManager | ✅ Complete | Calls set_profile() on load/switch |
| song_select.gd | ✅ Auto-works | Uses ScoreHistoryManager, no changes needed |
| results_screen.gd | ✅ Auto-works | Uses ScoreHistoryManager, no changes needed |
| gameplay.gd | ✅ Auto-works | Passes data to results_screen |

---

## Known Issues / Edge Cases

### 1. Score Updates While Profile Switching
**Scenario:** User finishes song, results screen open, switches profile mid-results

**Current Behavior:** Score would save to NEW profile (wrong!)

**Solution Needed:** Lock profile switching during active gameplay/results

**Priority:** Medium (unlikely user action)

---

### 2. Concurrent Game Instances
**Scenario:** Two game windows open with different profiles

**Current Behavior:** Last-save-wins, may corrupt scores

**Solution:** File locking or instance detection

**Priority:** Low (single-player game)

---

### 3. Profile Deletion
**Scenario:** User deletes profile with scores

**Current Behavior:** `scores.cfg` is deleted with profile directory

**Status:** ✅ Working as intended (profile data is deleted)

---

## API Reference

### ScoreHistoryManager

```gdscript
# Profile Management
ScoreHistoryManager.set_profile(profile_id: String) -> void
ScoreHistoryManager.get_current_profile_id() -> String

# Score Operations (unchanged, now profile-aware)
ScoreHistoryManager.update_score(chart_path, instrument, stats) -> bool
ScoreHistoryManager.get_score_data(chart_path, instrument) -> Dictionary
ScoreHistoryManager.has_played_song(chart_path, instrument) -> bool
ScoreHistoryManager.save_score_history() -> void
ScoreHistoryManager.load_score_history() -> void

# Signals
signal score_updated(chart_key: String, is_new_high_score: bool)
signal history_loaded()
signal profile_changed(profile_id: String)  # NEW
```

### ProfileManager (Changes)

```gdscript
# Loads profile AND sets ScoreHistoryManager profile
ProfileManager.load_profile(profile_id: String) -> bool

# Switches profile AND updates ScoreHistoryManager
ProfileManager.switch_profile(profile_id: String) -> bool
```

---

## Debugging Tips

### Check Current Profile's Score File
```gdscript
print("Current profile: ", ProfileManager.current_profile_id)
print("Scores path: ", ScoreHistoryManager.history_path)
var scores_exist = FileAccess.file_exists(ScoreHistoryManager.history_path)
print("Scores file exists: ", scores_exist)
```

### Verify Profile Separation
```gdscript
# Get all scores for current profile
var all_scores = ScoreHistoryManager.get_all_scores()
print("Current profile has ", all_scores.size(), " score records")
for key in all_scores:
    print("  ", key, " -> ", all_scores[key].high_score)
```

### Monitor Profile Switches
```gdscript
# Connect to profile_changed signal
ScoreHistoryManager.profile_changed.connect(func(profile_id):
    print("Scores switched to profile: ", profile_id)
)
```

---

## Conclusion

The profile-specific score history integration is now **complete and ready for testing**. The system ensures that each profile maintains completely independent score records, fulfilling the core requirement of a multi-profile system.

**Next Steps:**
1. ✅ Code implementation complete
2. ⚠️ Manual testing required (see Testing Plan above)
3. ⏳ Achievement system verification pending
4. ⏳ Edge case testing (profile switching during gameplay)

**Estimated Testing Time:** 15-20 minutes

**Critical Test:** Verify scores don't leak between profiles (Test 1 above)
