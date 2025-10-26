# Profile Switch Feature

## Overview
Added a "Switch Profile" button to the main menu that allows users to return to the profile select screen and switch profiles without restarting the game.

---

## Changes Made

### 1. Main Menu Scene (`Scenes/main_menu.tscn`) ✅

**Added Button:**
- `SwitchProfileButton` - Positioned between "SETTINGS" and "QUIT" buttons
- Uses AnimatedButton script for hover effects
- Font size: 20, left-aligned
- Text: "SWITCH PROFILE"

**Location in Hierarchy:**
```
MainMenu
└── MarginContainer
    └── MainLayout
        └── MiddleSection
            └── LeftSidebar
                ├── QuickplayButton
                ├── OnlineButton
                ├── PracticeButton
                ├── NewsButton
                ├── SettingsButton
                ├── SwitchProfileButton  ← NEW
                └── QuitButton
```

---

### 2. Main Menu Script (`Scripts/main_menu.gd`) ✅

**Added Button Connection:**
```gdscript
var switch_profile_btn = get_node_or_null(left_base + "/SwitchProfileButton")
if switch_profile_btn:
    switch_profile_btn.pressed.connect(_on_switch_profile)
```

**Added Handler Function:**
```gdscript
func _on_switch_profile():
    """Return to profile select screen to switch profiles."""
    # Clear the scene stack and go back to profile select
    SceneSwitcher.change_scene("res://Scenes/profile_select.tscn")
```

**Why `change_scene()` instead of `push_scene()`:**
- `push_scene()` adds to navigation stack → back button would return to main menu
- `change_scene()` clears entire stack → starts fresh from profile select
- Prevents navigation loop (main menu → profile select → back → main menu → repeat)

---

### 3. SceneSwitcher (`Scripts/SceneSwitcher.gd`) ✅

**Added New Method:**
```gdscript
func change_scene(scene_path: String):
    """Clear all scenes and load a new scene from scratch (resets navigation stack)."""
    # Clear entire stack
    for scene in scene_stack:
        get_tree().root.remove_child(scene)
        scene.queue_free()
    scene_stack.clear()
    
    # Load and add new scene
    var new_scene = load(scene_path).instantiate()
    get_tree().root.add_child(new_scene)
    new_scene.show()
    new_scene.process_mode = Node.PROCESS_MODE_INHERIT
    scene_stack.append(new_scene)
```

**Difference from Existing Methods:**
- `push_scene()` - Adds scene to stack, hides previous (for back navigation)
- `pop_scene()` - Removes current scene, shows previous
- `replace_scene_instance()` - Replaces top scene, keeps stack
- `change_scene()` - **NEW** - Clears entire stack, starts fresh

---

## User Flow

### Before This Feature:
1. Start game → Profile Select screen
2. Select profile → Main Menu
3. **No way to switch profiles** ❌
4. Only option: Quit game and restart

### After This Feature:
1. Start game → Profile Select screen
2. Select profile → Main Menu
3. Click "SWITCH PROFILE" button ✅
4. Returns to Profile Select screen (fresh state)
5. Select different profile
6. Back to Main Menu with new profile loaded

---

## How It Works

### Profile Switch Process:
1. User clicks "SWITCH PROFILE" button
2. `_on_switch_profile()` handler called
3. `SceneSwitcher.change_scene("profile_select.tscn")` executed
4. **SceneSwitcher clears all scenes from stack:**
   - Main menu removed and freed
   - Any pushed scenes (settings, song select, etc.) removed
5. **Profile Select screen loaded fresh:**
   - Shows all available profiles
   - User can select any profile (including current one)
6. **When profile selected:**
   - `ProfileManager.load_profile(profile_id)` called
   - `ScoreHistoryManager.set_profile(profile_id)` called automatically
   - User's profile-specific data loaded (scores, achievements, etc.)
7. **Navigate to Main Menu:**
   - New profile data displayed in ProfileDisplay component
   - All scores/achievements reflect new profile

---

## Integration with Profile System

### Automatic Data Loading:
When returning to profile select and choosing a new profile, the system automatically:

1. **ProfileManager.load_profile(profile_id)**
   - Loads profile.cfg from `user://profiles/[profile_id]/`
   - Sets current_profile and current_profile_id

2. **ScoreHistoryManager.set_profile(profile_id)**
   - Saves old profile's scores (if switching)
   - Loads new profile's scores from `user://profiles/[profile_id]/scores.cfg`
   - Updates all score displays

3. **AchievementManager (if connected)**
   - Loads new profile's achievements
   - Updates achievement progress displays

**No Manual Refresh Needed:**
- ProfileDisplay component automatically updates when profile changes
- FeaturedSong continues playing (independent of profile)
- All game systems respect new profile data

---

## Testing Checklist

### Test 1: Basic Profile Switching ✅ NEEDS TESTING
- [ ] Start game with Profile A
- [ ] Navigate to Main Menu
- [ ] Click "SWITCH PROFILE"
- [ ] Verify: Profile Select screen appears
- [ ] Select Profile B
- [ ] Verify: Main Menu shows Profile B's data
- [ ] Check: Profile B's name/avatar/level displayed

### Test 2: Score Isolation ✅ NEEDS TESTING
- [ ] Profile A: Play song, get 50,000 score
- [ ] Click "SWITCH PROFILE"
- [ ] Switch to Profile B
- [ ] Go to song select
- [ ] Verify: Song shows "Not Played" (no 50,000 score)
- [ ] Profile B: Play same song, get 60,000 score
- [ ] Click "SWITCH PROFILE"
- [ ] Switch back to Profile A
- [ ] Verify: Song shows 50,000 (NOT 60,000)

### Test 3: Navigation Stack Cleared ✅ NEEDS TESTING
- [ ] Main Menu → Settings → (back button)
- [ ] Main Menu → Click "SWITCH PROFILE"
- [ ] Profile Select screen appears
- [ ] Verify: No back button appears (stack cleared)
- [ ] Select profile → Main Menu
- [ ] Verify: Fresh navigation state

### Test 4: Same Profile Re-selection ✅ NEEDS TESTING
- [ ] Start with Profile A
- [ ] Click "SWITCH PROFILE"
- [ ] Re-select Profile A
- [ ] Verify: All data still intact
- [ ] Verify: No data loss or corruption

### Test 5: Mid-Session Switch ✅ NEEDS TESTING
- [ ] Profile A: Play 3 songs, unlock achievements
- [ ] Click "SWITCH PROFILE"
- [ ] Switch to Profile B
- [ ] Verify: Profile A's progress saved correctly
- [ ] Play as Profile B
- [ ] Switch back to Profile A
- [ ] Verify: All 3 song scores + achievements still there

---

## Edge Cases Handled

### 1. Scene Stack Clearing
**Problem:** Using `push_scene()` would leave old scenes in memory
**Solution:** `change_scene()` clears entire stack before loading profile select

### 2. Profile Data Persistence
**Problem:** Switching profiles mid-session could lose unsaved data
**Solution:** `ScoreHistoryManager.set_profile()` auto-saves old profile before switching

### 3. Navigation Loop Prevention
**Problem:** Main menu → profile select → back → main menu creates loop
**Solution:** Clearing stack prevents back navigation, forces clean profile selection

---

## Button Styling

The "SWITCH PROFILE" button uses the same styling as other main menu buttons:

- **Font Size:** 20pt
- **Alignment:** Left
- **Script:** AnimatedButton.gd (for hover effects)
- **Text Color:** Default theme (white)
- **Hover Effect:** Provided by AnimatedButton script

**Visual Consistency:**
Matches the style of QUICKPLAY, ONLINE, PRACTICE, NEWS, SETTINGS, and QUIT buttons.

---

## Future Enhancements

### Potential Improvements:
1. **Confirmation Dialog**
   - "Switch profile? Unsaved progress will be saved."
   - Prevents accidental switches

2. **Quick Profile Dropdown**
   - Instead of full profile select screen
   - Dropdown menu on main menu for faster switching

3. **Recent Profiles List**
   - Show 3 most recently used profiles
   - Quick switch without full profile select

4. **Profile Lock During Gameplay**
   - Disable "SWITCH PROFILE" button during active gameplay
   - Prevent mid-song profile switches

5. **Profile Switch Animation**
   - Fade out → Profile name display → Fade in
   - Visual feedback for profile change

---

## Known Limitations

### 1. No Confirmation Dialog
**Current Behavior:** Immediately goes to profile select
**Impact:** User might accidentally click
**Mitigation:** Button clearly labeled "SWITCH PROFILE"
**Future:** Add confirmation dialog

### 2. No Profile Lock During Gameplay
**Current Behavior:** Button accessible anytime
**Impact:** Could theoretically switch mid-song (though unlikely)
**Mitigation:** User would need to navigate to main menu first
**Future:** Disable during active gameplay

---

## API Reference

### SceneSwitcher.change_scene()
```gdscript
func change_scene(scene_path: String) -> void
```

**Parameters:**
- `scene_path` (String): Absolute resource path to scene file
  - Example: `"res://Scenes/profile_select.tscn"`

**Behavior:**
1. Removes all scenes from scene_stack
2. Frees all removed scenes from memory
3. Clears scene_stack array
4. Loads new scene from path
5. Adds new scene to root
6. Shows new scene
7. Adds new scene to stack (as only scene)

**Use Cases:**
- Switching profiles (reset navigation)
- Returning to main menu from deep navigation
- Restarting game flow
- Logout/login transitions

**Difference from push_scene():**
- `push_scene()` preserves stack for back navigation
- `change_scene()` creates clean slate

---

## Conclusion

The "Switch Profile" feature is now **complete and ready for testing**. Users can easily switch between profiles without restarting the game, and the profile-specific score system ensures complete data isolation between profiles.

**Status:** ✅ Implementation Complete  
**Testing:** ⚠️ Manual testing required  
**Priority:** High (core feature for multi-profile system)

