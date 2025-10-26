# Bug Fix: AchievementManager PROFILES_DIR Access Error

## Issue
```
E 0:00:02:079   load_profile_achievements: Invalid access to property or key 'PROFILES_DIR' on a base object of type 'Nil'.
  <GDScript Source>AchievementManager.gd:69 @ load_profile_achievements()
```

## Root Cause

The `AchievementManager` was trying to access `profile_manager.PROFILES_DIR`, but the `profile_manager` variable was `Nil` (null). 

**Why it was Nil:**
- `AchievementManager._ready()` tries to get ProfileManager via `get_node("/root/ProfileManager")`
- However, autoload initialization order is not guaranteed
- When `ProfileManager.load_profile()` calls `AchievementManager.load_profile_achievements()` very early in startup, `profile_manager` might not be initialized yet

## Solution

Added `PROFILES_DIR` as a local constant in `AchievementManager.gd` instead of accessing it from `profile_manager`.

### Changes Made

**File:** `Scripts/AchievementManager.gd`

**Added constant (line 6):**
```gdscript
const PROFILES_DIR := "user://profiles/"
```

**Updated references:**
```gdscript
# Line 70 - OLD:
var achievements_path = profile_manager.PROFILES_DIR + profile_id + "/achievements.cfg"

# Line 70 - NEW:
var achievements_path = PROFILES_DIR + profile_id + "/achievements.cfg"

# Line 113 - OLD:
var achievements_path = profile_manager.PROFILES_DIR + profile_id + "/achievements.cfg"

# Line 113 - NEW:
var achievements_path = PROFILES_DIR + profile_id + "/achievements.cfg"
```

## Why This Fix Works

1. **Constants are available immediately** - No dependency on node references
2. **Same value as ProfileManager** - Both use `"user://profiles/"`
3. **No initialization order issues** - Works regardless of autoload order
4. **Maintains consistency** - Both managers use the same directory structure

## Impact

- ✅ Fixes crash on game startup
- ✅ Allows achievements to load correctly on profile load
- ✅ No behavioral changes (same paths used)
- ✅ Zero compilation errors

## Testing

After this fix, the game should:
1. Start without errors
2. Load profiles correctly
3. Load achievements for each profile
4. No "Nil" access errors in console

## Related Files

- `Scripts/AchievementManager.gd` - Fixed file
- `Scripts/ProfileManager.gd` - Also has `PROFILES_DIR` constant (same value)
- `Scripts/ScoreHistoryManager.gd` - Also has `PROFILES_DIR` constant (same value)

All three managers now independently define the same path constant, avoiding cross-dependencies.

## Alternative Considered

**Option 1 (Rejected):** Use `ProfileManager.PROFILES_DIR` directly
- **Problem:** Requires ProfileManager to be initialized first (autoload order dependency)

**Option 2 (Chosen):** Define constant in each manager
- **Benefit:** No initialization dependencies
- **Benefit:** Each manager is self-contained
- **Trade-off:** Constant duplicated (3 files), but value is simple and unlikely to change

## Future Consideration

If the profiles directory path needs to become configurable, consider:
- Creating a `GameConfig` or `PathConstants` autoload
- Define all paths in one place
- Load paths from config file

For now, duplicating the simple constant is the cleanest solution.

---

**Status:** ✅ Fixed  
**Tested:** ✅ No compilation errors  
**Ready for:** In-game testing
