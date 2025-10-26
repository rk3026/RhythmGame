# Profile System Testing Checklist

## Quick Start - 3 Essential Tests (15 minutes)

Use this checklist while testing. Check off each item as you complete it.

---

## Test 1: Multi-Profile Score Separation ⭐ CRITICAL

**Goal:** Verify scores don't leak between profiles

### Setup Phase
- [ ] Launch game
- [ ] Create Profile A - Username: "Alice"
- [ ] Profile A loaded successfully
- [ ] Main menu shows "Alice" in top-left ProfileDisplay

### Profile A - Play Song
- [ ] Click "QUICKPLAY"
- [ ] Select any song (write it down): ___________________
- [ ] Note difficulty: ___________________
- [ ] Play the song
- [ ] Get score (write it down): ___________ points
- [ ] Return to main menu

### Profile B - Create & Verify Isolation
- [ ] Click "SWITCH PROFILE" button (left sidebar, above QUIT)
- [ ] Profile select screen appears
- [ ] Create Profile B - Username: "Bob"
- [ ] Profile B loaded successfully
- [ ] Main menu shows "Bob" in top-left ProfileDisplay
- [ ] Click "QUICKPLAY"
- [ ] Find the SAME song you played with Alice
- [ ] ✅ **CRITICAL CHECK:** Score shows "Not Played" or "---" (NOT Alice's score)

### Profile B - Play Song
- [ ] Play the same song with Bob
- [ ] Get DIFFERENT score (write it down): ___________ points
- [ ] Return to main menu

### Profile A - Verify Original Score Intact
- [ ] Click "SWITCH PROFILE"
- [ ] Select Profile A ("Alice")
- [ ] Click "QUICKPLAY"
- [ ] Find the same song
- [ ] ✅ **CRITICAL CHECK:** Shows Alice's original score (NOT Bob's score)

### Result
- [ ] ✅ PASS - Profiles have completely separate scores
- [ ] ❌ FAIL - Scores are leaking between profiles

**If FAIL, check console for errors and see troubleshooting below**

---

## Test 2: Profile Switching Feature ⭐ CRITICAL

**Goal:** Verify "Switch Profile" button works correctly

### Basic Switching
- [ ] From main menu, locate "SWITCH PROFILE" button
- [ ] Button is visible between "SETTINGS" and "QUIT"
- [ ] Click "SWITCH PROFILE"
- [ ] Profile select screen appears
- [ ] Select a different profile
- [ ] Main menu loads
- [ ] ProfileDisplay (top-left) shows NEW profile name

### Navigation Stack Test
- [ ] From main menu, navigate: Main Menu → Song Select → Back → Main Menu
- [ ] Click "SWITCH PROFILE"
- [ ] Profile select screen appears
- [ ] ✅ **CRITICAL CHECK:** No back button available (stack cleared)
- [ ] Select any profile
- [ ] Main menu loads cleanly

### Rapid Switching Test
- [ ] Click "SWITCH PROFILE"
- [ ] Select Profile A
- [ ] Immediately click "SWITCH PROFILE" again
- [ ] Select Profile B
- [ ] Repeat 2-3 more times
- [ ] ✅ **CRITICAL CHECK:** No crashes or errors

### Result
- [ ] ✅ PASS - Profile switching works smoothly
- [ ] ❌ FAIL - Crashes, errors, or navigation issues

---

## Test 3: Achievement System Separation ⭐ CRITICAL

**Goal:** Verify achievements don't leak between profiles

### Profile A - Unlock Achievement
- [ ] Load Profile A ("Alice")
- [ ] Click profile card (top-left) to open Profile View
- [ ] Click "Achievements" tab
- [ ] Note an achievement that is NOT unlocked yet: ___________________
- [ ] Close Profile View
- [ ] Perform action to unlock that achievement:
  - For "First Victory": Complete a song successfully
  - For "Combo Master": Get 100+ combo
  - For "Perfect Score": Get 100% accuracy
- [ ] Achievement unlocked notification appears
- [ ] Open Profile View → Achievements tab
- [ ] Achievement is now unlocked
- [ ] Note completion %: ________%

### Profile B - Verify Isolation
- [ ] Click "SWITCH PROFILE"
- [ ] Select Profile B ("Bob")
- [ ] Click profile card → Profile View → Achievements tab
- [ ] ✅ **CRITICAL CHECK:** Achievement unlocked by Alice is NOT unlocked for Bob
- [ ] ✅ **CRITICAL CHECK:** Bob's completion % is different (lower or 0%)

### Profile B - Unlock Different Achievement
- [ ] Close Profile View
- [ ] Unlock a DIFFERENT achievement with Bob (not the same as Alice)
- [ ] Achievement unlocked for Bob: ___________________
- [ ] Open Profile View → Achievements tab
- [ ] Bob's new achievement is unlocked
- [ ] Alice's achievement is NOT shown as unlocked for Bob

### Profile A - Verify Separation
- [ ] Click "SWITCH PROFILE"
- [ ] Select Profile A ("Alice")
- [ ] Open Profile View → Achievements tab
- [ ] ✅ **CRITICAL CHECK:** Alice's achievement still unlocked
- [ ] ✅ **CRITICAL CHECK:** Bob's achievement is NOT unlocked for Alice

### Result
- [ ] ✅ PASS - Achievements are completely separate per profile
- [ ] ❌ FAIL - Achievements are leaking between profiles

---

## Troubleshooting

### Scores Are Leaking Between Profiles

**Check in Godot debugger:**
Press F6 to open debugger, go to "Debugger" tab → "Monitors" → Add these watches:

```gdscript
ProfileManager.current_profile_id
ScoreHistoryManager.current_profile_id
ScoreHistoryManager.history_path
```

**Expected values:**
- Both profile IDs should match
- history_path should be: `user://profiles/[unique_id]/scores.cfg`
- Each profile should have DIFFERENT unique_id

**If they're the same, check:**
- Line 186 in ProfileManager.gd has: `ScoreHistoryManager.set_profile(profile_id)`

---

### Achievements Are Leaking

**Check console output:**
Look for these messages when loading profiles:
```
ProfileManager: Loaded profile: Alice ([profile_id])
AchievementManager: Loaded achievement progress for profile [profile_id]
```

**Each profile should show different [profile_id]**

**If missing, check:**
- Line 189 in ProfileManager.gd has: `AchievementManager.load_profile_achievements(profile_id)`

---

### Switch Profile Button Missing

**Check:**
1. Main menu left sidebar
2. Between "SETTINGS" and "QUIT"
3. Button text: "SWITCH PROFILE"

**If missing:**
- Open `Scenes/main_menu.tscn` in Godot editor
- Check scene tree for "SwitchProfileButton" node
- Verify button is not hidden

---

### Crashes on Profile Load

**Check console for errors:**
- "Invalid access" errors → Script issue
- "File not found" errors → Profile directory issue

**Verify file structure:**
Open file explorer to `%APPDATA%\Godot\app_userdata\[project_name]\profiles\`

Should see:
```
profiles/
├── profiles_list.cfg
├── [profile_a_id]/
│   ├── profile.cfg
│   ├── scores.cfg
│   └── achievements.cfg
└── [profile_b_id]/
    ├── profile.cfg
    ├── scores.cfg
    └── achievements.cfg
```

---

## Debug Commands

If you need to debug, open the Godot script console and run:

### Check Current Profile
```gdscript
print("Current profile: ", ProfileManager.current_profile_id)
print("Current username: ", ProfileManager.current_profile.username)
```

### Check Score System
```gdscript
print("Score profile: ", ScoreHistoryManager.current_profile_id)
print("Score path: ", ScoreHistoryManager.history_path)
print("File exists: ", FileAccess.file_exists(ScoreHistoryManager.history_path))
```

### List All Profiles
```gdscript
for p in ProfileManager.get_all_profiles():
    print("Profile: ", p.username, " | ID: ", p.profile_id)
```

### Check Achievement Count
```gdscript
var unlocked = 0
for ach in AchievementManager.achievement_progress.values():
    if ach.unlocked:
        unlocked += 1
print("Unlocked achievements: ", unlocked)
```

---

## Test Summary

Fill this out after completing all tests:

**Test 1 - Score Separation:**
- [ ] PASS  [ ] FAIL
- Notes: _________________________________________________

**Test 2 - Profile Switching:**
- [ ] PASS  [ ] FAIL
- Notes: _________________________________________________

**Test 3 - Achievement Separation:**
- [ ] PASS  [ ] FAIL
- Notes: _________________________________________________

---

## Overall Result

- [ ] ✅ ALL TESTS PASSED - Profile system is production ready!
- [ ] ⚠️ SOME TESTS FAILED - See notes above for issues
- [ ] ❌ CRITICAL FAILURES - System needs fixes before use

---

## Next Steps After Testing

### If All Tests Pass:
1. Mark profile system as complete ✅
2. Update todo list
3. Move on to next game features
4. Consider optional enhancements:
   - Profile export/import
   - Profile statistics graphs
   - Activity feed

### If Any Tests Fail:
1. Document the exact failure
2. Check the troubleshooting section
3. Review the bug fix documentation
4. Re-run tests after fixes
5. Update this checklist with lessons learned

---

## Time Estimate

- **Test 1:** 5-7 minutes
- **Test 2:** 3-4 minutes
- **Test 3:** 5-7 minutes
- **Total:** ~15-20 minutes

**Good luck! 🎮**
