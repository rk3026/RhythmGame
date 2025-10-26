# Profile System Quick Start Guide

## What Was Accomplished

### ✅ Complete Implementation
The multi-profile system is **fully implemented** with:
- Profile-specific scores (each profile has isolated high scores)
- Profile-specific achievements (each profile tracks its own unlocks)
- Profile switching from main menu
- FeaturedSong audio player component
- Comprehensive documentation

### 📋 What's Left
**3 Quick Tests** to validate the system works correctly (15-20 minutes total)

---

## Quick Testing (Start Here!)

### Test A: Score Separation ⭐ MOST IMPORTANT (5 minutes)

**Goal:** Verify Profile A's scores don't show up for Profile B

1. **Launch game**
2. **Create Profile A** ("Alice")
3. **Quickplay → Pick any song → Play it**
   - Get a score (e.g., 50,000 points)
   - Return to main menu
4. **Click "SWITCH PROFILE"** (left sidebar, above QUIT)
5. **Create Profile B** ("Bob")
6. **Quickplay → Same song**
7. **✅ CHECK:** Does it show "Not Played"? (Should NOT show Alice's 50,000)
8. **Play the song as Bob**
   - Get different score (e.g., 60,000)
9. **Click "SWITCH PROFILE" → Select Alice**
10. **Quickplay → Same song**
11. **✅ CHECK:** Does it show 50,000? (Should NOT show Bob's 60,000)

**Expected:** ✅ Profiles see ONLY their own scores

---

### Test B: Profile Switching (3 minutes)

**Goal:** Verify the Switch Profile button works

1. **From main menu:** Click "SWITCH PROFILE"
2. **✅ CHECK:** Does profile select screen appear?
3. **Select different profile**
4. **✅ CHECK:** Does main menu show new profile name (top-left)?
5. **Try switching 2-3 more times**
6. **✅ CHECK:** No crashes or errors?

**Expected:** ✅ Smooth profile switching

---

### Test C: Achievement Separation (5 minutes)

**Goal:** Verify achievements are per-profile

1. **Load Profile A**
2. **Click profile card (top-left) → Achievements tab**
3. **Note an unl unlocked achievement** (e.g., "First Victory")
4. **Play a song successfully** (unlock the achievement)
5. **✅ CHECK:** Achievement unlocked notification appears?
6. **Click "SWITCH PROFILE" → Profile B**
7. **Click profile card → Achievements tab**
8. **✅ CHECK:** Is the achievement NOT unlocked for Profile B?

**Expected:** ✅ Profiles have separate achievements

---

## If All Tests Pass ✅

**Congrats! Profile system is working!**

You can now:
- Use multiple profiles for different players
- Each player has their own progress
- Switch profiles anytime from main menu

**Next steps:**
- Move on to other game features
- See `ProfileSystemImplementationSummary.md` for full details

---

## If Tests Fail ❌

### Score Test Failed (Scores leaking between profiles)

**Check:**
```gdscript
# In Godot debug console:
print(ScoreHistoryManager.current_profile_id)
print(ScoreHistoryManager.history_path)
# Should show: user://profiles/[unique_id]/scores.cfg
```

**Look for:** Different score paths for different profiles

**Fix Location:** `Scripts/ProfileManager.gd` line 186  
Should have: `ScoreHistoryManager.set_profile(profile_id)`

---

### Achievement Test Failed (Achievements leaking)

**Check:**
```gdscript
# In Godot debug console:
print(AchievementManager.current_profile_id)
```

**Fix Location:** `Scripts/ProfileManager.gd` line 189  
Should have: `AchievementManager.load_profile_achievements(profile_id)`

---

### Profile Switch Failed (Button not working)

**Check:**
- Is "SWITCH PROFILE" button visible? (Left sidebar, between SETTINGS and QUIT)
- Does clicking it do anything?

**Fix Location:** `Scripts/main_menu.gd` line 41  
Should have: `switch_profile_btn.pressed.connect(_on_switch_profile)`

---

## Full Documentation

If you need more details, see:

1. **ProfileSystemTestingGuide.md** - Complete 10-test suite with detailed steps
2. **ProfileSystemImplementationSummary.md** - Architecture overview and technical details
3. **ProfileScoreIntegration.md** - How score isolation works
4. **ProfileSwitchFeature.md** - Profile switching implementation

---

## Quick Commands (Debug Console)

**Check current profile:**
```gdscript
print("Current: ", ProfileManager.current_profile_id)
```

**List all profiles:**
```gdscript
for p in ProfileManager.get_all_profiles():
    print(p.username, " - ", p.profile_id)
```

**Check if score files exist:**
```gdscript
print(FileAccess.file_exists(ScoreHistoryManager.history_path))
```

---

## Time Estimate

- **Quick Tests (A, B, C):** 15-20 minutes
- **Full Test Suite (10 tests):** 45-60 minutes
- **Reading Documentation:** 30 minutes

**Recommended:** Run quick tests first. If they pass, you're good to go!

---

## Summary

✅ **Code:** Complete and compiling  
⚠️ **Testing:** 3 quick tests needed (15-20 min)  
📚 **Docs:** 4 comprehensive documents created  

**Next:** Run the 3 quick tests above to validate the system!

**Good luck! 🎮**
