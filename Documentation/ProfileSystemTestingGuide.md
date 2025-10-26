# Profile System Testing Guide

## Overview
This guide provides comprehensive test cases to verify the multi-profile system works correctly. All code implementation is complete - manual testing is required to validate the system.

---

## System Integration Status

### ✅ Completed Implementation
- [x] ProfileManager - Core CRUD operations
- [x] ScoreHistoryManager - Profile-specific score storage
- [x] AchievementManager - Profile-specific achievement tracking
- [x] ProfileDisplay component - Main menu profile card
- [x] ProfileView screen - Detailed profile statistics
- [x] ProfileEditor screen - Profile customization
- [x] FeaturedSong component - Audio player on main menu
- [x] Switch Profile button - Main menu navigation
- [x] Automatic data loading - Scores & achievements load on profile switch

### ⚠️ Requires Testing
- [ ] Multi-profile score separation
- [ ] Multi-profile achievement separation
- [ ] Profile switching functionality
- [ ] Score persistence across sessions
- [ ] Achievement persistence across sessions

---

## Test Suite

### Test 1: Profile Creation & Basic Navigation ⭐ START HERE

**Objective:** Verify profile creation and navigation works

**Steps:**
1. Launch game
2. Verify: Profile select screen appears
3. Click "Create New Profile"
4. Enter username: "TestPlayer1"
5. Enter display name: "Test Player One"
6. Click "Create"
7. Verify: Profile card appears in profile list
8. Click profile card
9. Verify: Main menu loads
10. Verify: ProfileDisplay shows "TestPlayer1" with correct display name

**Expected Results:**
✅ Profile created successfully  
✅ Profile appears in list  
✅ Main menu loads with profile data  
✅ ProfileDisplay shows correct info  

**If Test Fails:**
- Check console for errors
- Verify `user://profiles/` directory exists
- Check `profiles_list.cfg` contains new profile

---

### Test 2: Multi-Profile Score Separation ⚠️ CRITICAL

**Objective:** Verify scores don't leak between profiles

**Setup:**
1. Create Profile A ("Alice")
2. Create Profile B ("Bob")

**Test Steps:**

#### Phase 1: Profile A - Play Song
1. Load Profile A ("Alice")
2. Go to Song Select (Quickplay)
3. Select a song (e.g., "Re:Re:")
4. Note difficulty level (e.g., "Expert")
5. Play the song
6. Get a specific score (e.g., **50,000 points**)
7. Note the accuracy % and max combo
8. Return to main menu

#### Phase 2: Profile B - Verify Isolation
9. Click "SWITCH PROFILE"
10. Verify: Profile select screen appears
11. Select Profile B ("Bob")
12. Verify: Main menu loads with "Bob" displayed
13. Go to Song Select (Quickplay)
14. Find the SAME song ("Re:Re:")
15. Check difficulty selector
16. **CRITICAL CHECK:** Verify score display shows:
    - "Not Played" OR "--- pts"
    - No high score from Profile A
    - No accuracy from Profile A

#### Phase 3: Profile B - Play Song
17. Play the same song with Profile B
18. Get a DIFFERENT score (e.g., **60,000 points**)
19. Return to main menu

#### Phase 4: Profile A - Verify Original Score Intact
20. Click "SWITCH PROFILE"
21. Select Profile A ("Alice")
22. Go to Song Select
23. Find the same song ("Re:Re:")
24. **CRITICAL CHECK:** Verify score display shows:
    - Alice's original 50,000 points (NOT Bob's 60,000)
    - Alice's original accuracy
    - Alice's original max combo

#### Phase 5: Profile B - Verify Separate Score
25. Click "SWITCH PROFILE"
26. Select Profile B ("Bob")
27. Go to Song Select
28. Find the same song
29. **CRITICAL CHECK:** Verify score display shows:
    - Bob's 60,000 points (NOT Alice's 50,000)

**Expected Results:**
✅ Profile A: 50,000 score isolated  
✅ Profile B: Initially "Not Played"  
✅ Profile B: 60,000 score after playing  
✅ Profile A: Still shows 50,000 (not 60,000)  
✅ Scores NEVER leak between profiles  

**If Test Fails:**
- Check console for "Loading scores for profile: [id]"
- Verify `user://profiles/[alice_id]/scores.cfg` exists
- Verify `user://profiles/[bob_id]/scores.cfg` exists
- Check if scores.cfg files have different content
- Verify ScoreHistoryManager.set_profile() is being called

**Debug Commands (GDScript console):**
```gdscript
# Check current profile
print(ProfileManager.current_profile_id)
print(ScoreHistoryManager.current_profile_id)

# Check score file path
print(ScoreHistoryManager.history_path)

# List score files
var dir = DirAccess.open("user://profiles/")
print(dir.get_directories())
```

---

### Test 3: Achievement System Separation ⚠️ CRITICAL

**Objective:** Verify achievements don't leak between profiles

**Setup:**
1. Use Profile A ("Alice") and Profile B ("Bob") from Test 2

**Test Steps:**

#### Phase 1: Profile A - Unlock Achievement
1. Load Profile A ("Alice")
2. Click profile card (top-left) to open Profile View
3. Go to Achievements tab
4. Note which achievements are unlocked (if any)
5. Note an achievement that is NOT unlocked (e.g., "First Victory")
6. Close Profile View
7. **Perform action to unlock achievement:**
   - For "First Victory": Play and complete a song successfully
   - For "Perfect Score": Get 100% accuracy on a song
   - For "Combo Master": Get a 100+ note combo
8. Verify achievement unlocked notification appears
9. Open Profile View → Achievements tab
10. Verify achievement is now unlocked
11. Note achievement completion percentage

#### Phase 2: Profile B - Verify Isolation
12. Click "SWITCH PROFILE"
13. Select Profile B ("Bob")
14. Click profile card to open Profile View
15. Go to Achievements tab
16. **CRITICAL CHECK:** Verify:
    - Achievement unlocked by Alice is NOT unlocked for Bob
    - Bob's completion % is lower than Alice's (or 0% if no achievements)
    - Bob has separate achievement progress

#### Phase 3: Profile B - Unlock Different Achievement
17. Close Profile View
18. Unlock a DIFFERENT achievement with Profile B
    - E.g., If Alice unlocked "First Victory", have Bob unlock "Combo Master"
19. Open Profile View → Achievements tab
20. Verify Bob's achievement is unlocked
21. Verify Alice's achievement is NOT shown as unlocked

#### Phase 4: Profile A - Verify Separation
22. Click "SWITCH PROFILE"
23. Select Profile A ("Alice")
24. Open Profile View → Achievements tab
25. **CRITICAL CHECK:** Verify:
    - Alice's original achievement still unlocked
    - Bob's different achievement is NOT unlocked for Alice
    - Achievement progress is profile-specific

**Expected Results:**
✅ Profile A: "First Victory" unlocked  
✅ Profile B: "First Victory" NOT unlocked (separate tracking)  
✅ Profile B: "Combo Master" unlocked  
✅ Profile A: "Combo Master" NOT unlocked (separate tracking)  
✅ Completion % different between profiles  
✅ Achievements NEVER leak between profiles  

**If Test Fails:**
- Check console for "Loaded achievement progress for profile [id]"
- Verify `user://profiles/[alice_id]/achievements.cfg` exists
- Verify `user://profiles/[bob_id]/achievements.cfg` exists
- Check if achievements.cfg files have different content
- Verify AchievementManager.load_profile_achievements() is being called
- Check ProfileManager.load_profile() has achievement loading integration

---

### Test 4: Score Persistence Across Sessions

**Objective:** Verify scores save and reload correctly

**Steps:**
1. Load Profile A ("Alice")
2. Play 3 different songs, get scores
3. Note exact scores for each song:
   - Song 1: _________ points
   - Song 2: _________ points
   - Song 3: _________ points
4. Return to main menu
5. **QUIT GAME COMPLETELY** (don't just switch profiles)
6. Relaunch game
7. Load Profile A ("Alice")
8. Go to Song Select
9. **CRITICAL CHECK:** Verify all 3 songs show original scores:
   - Song 1: Original score intact
   - Song 2: Original score intact
   - Song 3: Original score intact

**Expected Results:**
✅ All scores persist after game restart  
✅ No score data lost  
✅ Scores match original values exactly  

**If Test Fails:**
- Check if `user://profiles/[alice_id]/scores.cfg` file exists
- Open scores.cfg and verify data is written
- Check console for save errors during gameplay
- Verify ScoreHistoryManager.save_score_history() is being called

---

### Test 5: Profile Switching During Session

**Objective:** Verify switching profiles mid-session doesn't corrupt data

**Steps:**
1. Load Profile A ("Alice")
2. Play Song 1, get 50,000 score
3. Return to main menu
4. Click "SWITCH PROFILE"
5. Select Profile B ("Bob")
6. Play Song 2, get 70,000 score
7. Return to main menu
8. Click "SWITCH PROFILE"
9. Select Profile A ("Alice")
10. Go to Song Select
11. Verify Song 1 still shows 50,000 (not lost)
12. Verify Song 2 shows "Not Played" (Bob's score not visible)
13. Click "SWITCH PROFILE"
14. Select Profile B ("Bob")
15. Go to Song Select
16. Verify Song 2 still shows 70,000 (not lost)
17. Verify Song 1 shows "Not Played" (Alice's score not visible)

**Expected Results:**
✅ Profile A: Song 1 score intact (50,000)  
✅ Profile B: Song 2 score intact (70,000)  
✅ Scores don't corrupt during switches  
✅ Each profile sees only its own scores  

---

### Test 6: Switch Profile Button Navigation

**Objective:** Verify "SWITCH PROFILE" button works correctly

**Steps:**
1. Load any profile
2. Navigate: Main Menu → Song Select
3. Press Back button → Main Menu
4. Navigate: Main Menu → Settings
5. Press Back button → Main Menu
6. Click "SWITCH PROFILE"
7. Verify: Profile select screen appears
8. Verify: No back button available (navigation stack cleared)
9. Select any profile
10. Verify: Main menu loads cleanly
11. Click "SWITCH PROFILE" immediately
12. Verify: Can switch again without issues

**Expected Results:**
✅ "SWITCH PROFILE" button visible on main menu  
✅ Clicking button loads profile select screen  
✅ Navigation stack cleared (no back button)  
✅ Can switch profiles multiple times  
✅ No navigation loops or crashes  

---

### Test 7: Profile Editor Integration

**Objective:** Verify profile edits save correctly

**Steps:**
1. Load Profile A ("Alice")
2. Click profile card (top-left) to open Profile View
3. Click "Edit Profile" button
4. Change display name to: "Alice Updated"
5. Change favorite color to: Green
6. Click "Save Changes"
7. Verify: Profile View shows updated name
8. Close Profile View
9. Verify: ProfileDisplay (top-left) shows "Alice Updated"
10. Click "SWITCH PROFILE"
11. Select Profile B ("Bob")
12. Click "SWITCH PROFILE"
13. Select Profile A ("Alice") again
14. **CRITICAL CHECK:** Verify:
    - Display name still "Alice Updated" (not reverted)
    - Favorite color still Green

**Expected Results:**
✅ Profile edits save immediately  
✅ Changes persist after profile switch  
✅ Changes visible in all UI components  

---

### Test 8: Profile Deletion

**Objective:** Verify profile deletion works and cleans up data

**Steps:**
1. Create a test profile ("DeleteMe")
2. Load "DeleteMe" profile
3. Play 2 songs, unlock achievement
4. Return to main menu
5. Click profile card → Profile View
6. Click "Edit Profile"
7. Scroll to bottom → Click "Delete Profile"
8. Confirm deletion
9. Verify: Returns to profile select screen
10. Verify: "DeleteMe" profile no longer in list
11. **CRITICAL CHECK:** Manual file verification:
    - Open `user://profiles/` directory
    - Verify no folder for "DeleteMe" profile
    - Verify scores.cfg for this profile is deleted
    - Verify achievements.cfg for this profile is deleted

**Expected Results:**
✅ Profile deleted successfully  
✅ Profile removed from list  
✅ All profile data cleaned up (directory removed)  
✅ Other profiles unaffected  

**Warning:** This is destructive testing - use a throwaway profile!

---

### Test 9: Rapid Profile Switching

**Objective:** Verify system handles rapid switches without crashes

**Steps:**
1. Create 3 profiles (A, B, C)
2. Load Profile A
3. Click "SWITCH PROFILE" → Select Profile B
4. Immediately click "SWITCH PROFILE" → Select Profile C
5. Immediately click "SWITCH PROFILE" → Select Profile A
6. Repeat 5 times rapidly
7. Verify: No crashes, errors, or data corruption
8. Go to Song Select with each profile
9. Verify: Each profile has correct (separate) scores

**Expected Results:**
✅ No crashes during rapid switching  
✅ No console errors  
✅ Data remains consistent  
✅ Each profile isolated  

---

### Test 10: New Profile Starts Fresh

**Objective:** Verify new profiles have clean slate

**Steps:**
1. Create Profile A, play 5 songs, unlock 3 achievements
2. Create NEW Profile B ("FreshStart")
3. Load Profile B
4. Open Profile View
5. Verify: Level 1, 0 XP
6. Go to Achievements tab
7. Verify: 0% completion, no achievements unlocked
8. Go to Song Select
9. Verify: All songs show "Not Played"
10. Check stats
11. Verify: 0 total score, 0 songs played

**Expected Results:**
✅ New profile has no carryover data  
✅ Level 1, 0 XP  
✅ No achievements  
✅ No song scores  
✅ Clean slate for new player  

---

## Debug Tools

### Console Commands (GDScript Debug Console)

**Check Current Profile:**
```gdscript
print("ProfileManager: ", ProfileManager.current_profile_id)
print("ScoreHistoryManager: ", ScoreHistoryManager.current_profile_id)
print("Match: ", ProfileManager.current_profile_id == ScoreHistoryManager.current_profile_id)
```

**List All Profiles:**
```gdscript
var profiles = ProfileManager.get_all_profiles()
for p in profiles:
    print("Profile: ", p.username, " (", p.profile_id, ")")
```

**Check Score File:**
```gdscript
print("Score path: ", ScoreHistoryManager.history_path)
print("File exists: ", FileAccess.file_exists(ScoreHistoryManager.history_path))
```

**List Profile Directories:**
```gdscript
var dir = DirAccess.open("user://profiles/")
if dir:
    var folders = dir.get_directories()
    print("Profile folders: ", folders)
```

**Check Scores for Song:**
```gdscript
var song_path = "res://Assets/Tracks/SomeArtist - SomeSong/notes.chart"
var score_data = ScoreHistoryManager.get_score_data(song_path, "guitar_expert")
print("High score: ", score_data.high_score)
print("Accuracy: ", score_data.accuracy)
```

**Check Achievement Status:**
```gdscript
var achievement = AchievementManager.get_achievement("first_victory")
print("Unlocked: ", achievement.unlocked)
print("Progress: ", achievement.progress, "/", achievement.get("max_progress", 1))
```

---

## Common Issues & Solutions

### Issue 1: Scores Leaking Between Profiles

**Symptoms:**
- Profile B sees Profile A's scores
- Both profiles share the same high scores

**Diagnosis:**
```gdscript
# Check if profiles have different score file paths
print(ScoreHistoryManager.history_path)
# Should print: user://profiles/[unique_id]/scores.cfg
```

**Solution:**
- Verify ScoreHistoryManager.set_profile() is called in ProfileManager.load_profile()
- Check line 186 in ProfileManager.gd: `ScoreHistoryManager.set_profile(profile_id)`

---

### Issue 2: Achievements Not Loading

**Symptoms:**
- Achievements reset when switching profiles
- All profiles show same achievements

**Diagnosis:**
```gdscript
# Check if achievements are loading per profile
var achievements = AchievementManager.get_all_achievements()
print("Unlocked count: ", achievements.filter(func(a): return a.unlocked).size())
```

**Solution:**
- Verify AchievementManager.load_profile_achievements() is called in ProfileManager.load_profile()
- Check line 189 in ProfileManager.gd: `AchievementManager.load_profile_achievements(profile_id)`

---

### Issue 3: Profile Switch Button Not Appearing

**Symptoms:**
- Can't find "SWITCH PROFILE" button on main menu

**Location:**
- Main menu → Left sidebar
- Between "SETTINGS" and "QUIT" buttons

**Solution:**
- Verify main_menu.tscn has SwitchProfileButton node
- Check main_menu.gd has _on_switch_profile() handler

---

### Issue 4: Data Not Persisting After Restart

**Symptoms:**
- Scores/achievements lost after closing game

**Diagnosis:**
```gdscript
# Check if data files exist
print("Scores exist: ", FileAccess.file_exists("user://profiles/[id]/scores.cfg"))
print("Achievements exist: ", FileAccess.file_exists("user://profiles/[id]/achievements.cfg"))
```

**Solution:**
- Verify save functions are called after gameplay
- Check results_screen.gd calls ProfileManager.save_profile()
- Check ScoreHistoryManager auto-saves in update_score()

---

## Test Results Template

Copy this template to track your testing:

```
# Profile System Test Results

Date: __________
Tester: __________
Game Version: __________

## Test Results

### Test 1: Profile Creation & Basic Navigation
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 2: Multi-Profile Score Separation ⚠️ CRITICAL
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________
Alice Score: ________ | Bob Score: ________
Alice sees Bob's score: [ ] Yes [ ] No (should be No)

### Test 3: Achievement System Separation ⚠️ CRITICAL
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________
Achievement leakage: [ ] Yes [ ] No (should be No)

### Test 4: Score Persistence Across Sessions
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 5: Profile Switching During Session
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 6: Switch Profile Button Navigation
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 7: Profile Editor Integration
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 8: Profile Deletion
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 9: Rapid Profile Switching
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

### Test 10: New Profile Starts Fresh
Status: [ ] Pass  [ ] Fail
Notes: ________________________________________________

## Summary

Total Tests: 10
Passed: ____
Failed: ____
Critical Failures: ____ (Tests 2 & 3)

## Overall Status
[ ] All tests passed - System ready for production
[ ] Minor issues found - See notes
[ ] Critical failures - Requires fixes

## Additional Notes
____________________________________________________________
____________________________________________________________
____________________________________________________________
```

---

## Test Completion Checklist

Before marking profile system as "complete":

- [ ] Test 1 completed (Profile Creation)
- [ ] Test 2 completed (Score Separation) ⚠️ CRITICAL
- [ ] Test 3 completed (Achievement Separation) ⚠️ CRITICAL
- [ ] Test 4 completed (Score Persistence)
- [ ] Test 5 completed (Mid-Session Switching)
- [ ] Test 6 completed (Switch Button)
- [ ] Test 7 completed (Profile Editor)
- [ ] Test 8 completed (Profile Deletion)
- [ ] Test 9 completed (Rapid Switching)
- [ ] Test 10 completed (Fresh Profile)
- [ ] All critical tests passed
- [ ] No console errors during testing
- [ ] Documentation updated with any issues found

---

## Next Steps After Testing

### If All Tests Pass:
1. Mark profile system as production-ready
2. Update main README with profile system features
3. Create user documentation for profile management
4. Consider adding profile import/export feature
5. Move on to next game features

### If Tests Fail:
1. Document exact failure scenario
2. Check relevant code sections (see Common Issues)
3. Add debug logging to identify root cause
4. Fix issue and re-test
5. Update documentation with lessons learned

---

## Contact & Support

If you encounter issues not covered in this guide:
1. Check console output for error messages
2. Review ProfileScoreIntegration.md for implementation details
3. Check ProfileSwitchFeature.md for navigation details
4. Use Debug Tools section to diagnose issues

**Good luck with testing! 🎮**
