# Per-Profile Settings Implementation

**Date:** October 26, 2025  
**Version:** 0.5.0  
**Status:** Implemented ✅

---

## Overview

The SettingsManager has been refactored to support per-profile settings, allowing each player profile to have independent keybindings, note speed, and timing calibration while maintaining shared global settings like master volume.

---

## Changes Summary

### SettingsManager.gd

#### New Architecture
- **Global Settings:** Stored in `user://settings.cfg`
  - `master_volume` - Shared across all profiles
  
- **Per-Profile Settings:** Stored in `user://profiles/[id]/settings.cfg`
  - `lane_keys` - Keybindings for each lane
  - `note_speed` - Highway scroll speed
  - `timing_offset` - Player-specific audio/display calibration

#### New Variables
```gdscript
const GLOBAL_CONFIG_PATH := "user://settings.cfg"
const PROFILES_DIR := "user://profiles/"
var current_profile_id: String = ""
```

#### New Methods

**`set_profile(profile_id: String)`**
- Called by ProfileManager when loading a profile
- Sets the current profile and loads its settings
- Usage: `SettingsManager.set_profile("profile-uuid-here")`

**`load_global_settings()`**
- Loads system-wide settings (master_volume)
- Called automatically in `_ready()`
- Checks for legacy settings migration flag

**`load_profile_settings(profile_id: String)`**
- Loads per-profile settings from `user://profiles/[id]/settings.cfg`
- If no settings file exists, checks for legacy settings to migrate
- Falls back to defaults if neither exist
- Automatically saves defaults for new profiles

**`save_global_settings()`**
- Saves global settings to `user://settings.cfg`
- Called by `set_master_volume()`

**`save_profile_settings()`**
- Saves per-profile settings to current profile's settings.cfg
- Called by `set_lane_key()`, `set_note_speed()`, `set_timing_offset()`
- Validates that `current_profile_id` is set

**`_should_migrate_legacy_settings() -> bool`**
- Checks if legacy global settings.cfg contains per-profile settings
- Returns true if migration is needed

**`_migrate_legacy_settings_to_profile(profile_id: String)`**
- Migrates legacy per-profile settings from global config to profile config
- Removes migrated settings from global config
- Sets migration flag to prevent re-migration
- Preserves user's existing configuration

#### Updated Methods

**`reset_defaults()`**
- Now resets both per-profile and global settings
- Saves to separate files

**`set_lane_key()`, `set_note_speed()`, `set_timing_offset()`**
- Now call `save_profile_settings()` instead of `save_settings()`

**`set_master_volume()`**
- Now calls `save_global_settings()` instead of `save_settings()`

#### Legacy Compatibility

**`load_settings()`**
- Still exists for backward compatibility
- Now only loads global settings
- Per-profile settings must be loaded via `set_profile()`

**`save_settings()`**
- Still exists for backward compatibility
- Now only saves global settings
- Per-profile settings must be saved via `save_profile_settings()`

---

### ProfileManager.gd

#### Integration Point

Added SettingsManager integration to `load_profile()`:

```gdscript
# Load profile-specific settings (NEW: per-profile settings support)
SettingsManager.set_profile(profile_id)
```

**Location:** After `AchievementManager.load_profile_achievements()`, before profile_loaded signal

**Effect:** When a profile is loaded or switched, its settings are automatically loaded

---

## Migration Strategy

### Scenario 1: Fresh Install (No Legacy Settings)
1. User creates first profile
2. `load_profile_settings()` finds no settings file
3. `_should_migrate_legacy_settings()` returns false (no global settings)
4. Uses default settings (DFJKL;, speed 20.0, offset 0.0)
5. Saves defaults to `user://profiles/[id]/settings.cfg`

### Scenario 2: Existing User (Legacy Global Settings)
1. User has existing `user://settings.cfg` with per-profile settings:
   ```
   [input]
   lane_keys = [68, 70, 74, 75, 76, 59]
   [gameplay]
   note_speed = 25.0
   [timing]
   offset = 15.0
   ```
2. User loads first profile (or existing profile without settings.cfg)
3. `_should_migrate_legacy_settings()` returns true:
   - Global config exists
   - Migration flag not set
   - Contains `lane_keys` in `[input]` section
4. `_migrate_legacy_settings_to_profile()` executes:
   - Extracts: lane_keys, note_speed, timing_offset
   - Validates all values
   - Saves to `user://profiles/[id]/settings.cfg`
   - Removes per-profile settings from global config
   - Sets migration flag: `[meta] settings_migrated = true`
5. Global config now only contains:
   ```
   [audio]
   master_volume = 1.0
   [meta]
   settings_migrated = true
   ```
6. User's settings preserved perfectly!

### Scenario 3: Multiple Profiles After Migration
1. First profile has migrated settings
2. User creates second profile
3. `_should_migrate_legacy_settings()` returns false (migration flag set)
4. Second profile uses defaults
5. Each profile now has independent settings

---

## File Structure

### Before Refactoring
```
user://
└── settings.cfg (all settings global)
    ├── [input] lane_keys
    ├── [gameplay] note_speed
    ├── [audio] master_volume
    └── [timing] offset
```

### After Refactoring
```
user://
├── settings.cfg (global only)
│   ├── [audio] master_volume
│   └── [meta] settings_migrated = true
│
└── profiles/
    ├── [profile_a_id]/
    │   ├── profile.cfg
    │   ├── scores.cfg
    │   ├── achievements.cfg
    │   └── settings.cfg (per-profile) ← NEW
    │       ├── [input] lane_keys
    │       ├── [gameplay] note_speed
    │       └── [timing] offset
    │
    └── [profile_b_id]/
        └── ... (same structure)
```

---

## API Changes

### New Public Methods

```gdscript
# SettingsManager
func set_profile(profile_id: String)
func load_global_settings()
func load_profile_settings(profile_id: String)
func save_global_settings()
func save_profile_settings()
```

### Behavior Changes

| Method | Old Behavior | New Behavior |
|--------|-------------|--------------|
| `set_lane_key()` | Saved to global settings.cfg | Saves to profile's settings.cfg |
| `set_note_speed()` | Saved to global settings.cfg | Saves to profile's settings.cfg |
| `set_timing_offset()` | Saved to global settings.cfg | Saves to profile's settings.cfg |
| `set_master_volume()` | Saved to global settings.cfg | Still saves to global settings.cfg |
| `reset_defaults()` | Reset all to global | Resets both global and profile settings |

### Integration Requirements

**Any code that switches profiles must call:**
```gdscript
SettingsManager.set_profile(new_profile_id)
```

**Current Integration Points:**
- ✅ `ProfileManager.load_profile()` - Automatically loads profile settings
- ✅ `ProfileManager.switch_profile()` - Calls `load_profile()` internally

---

## Testing Checklist

### ✅ Basic Functionality
- [x] New profile uses defaults
- [x] Settings save per-profile
- [x] Settings load per-profile
- [x] Global volume remains shared

### ✅ Migration
- [x] Legacy settings detected
- [x] Legacy settings migrated to first profile
- [x] Migration flag prevents re-migration
- [x] Global settings preserved
- [x] User configuration preserved

### ✅ Profile Switching
- [x] Switch between 2 profiles with different keybindings
- [x] Profile A settings don't affect Profile B
- [x] Master volume shared between profiles
- [x] Settings persist after game restart

### 🟡 Edge Cases (Not Yet Tested)
- [ ] Profile directory missing during save
- [ ] Corrupted settings.cfg
- [ ] Settings.cfg with invalid data types
- [ ] Very long profile_id strings
- [ ] Concurrent profile switches

---

## Known Limitations

1. **No Settings Inheritance:** 
   - Profiles don't inherit from global defaults
   - Each profile has completely independent settings
   - Future: Could add "Use Global Defaults" option

2. **No Validation on Load:**
   - If user manually edits settings.cfg with invalid data, validation occurs but no repair
   - Future: Add repair mechanism to fix corrupted settings

3. **No Settings Presets:**
   - Can't copy settings from one profile to another
   - Future: Add "Copy Settings From..." option

4. **No Per-Setting Global Override:**
   - Can't make specific settings global (e.g., always use global timing_offset)
   - Future: Add settings category flags

---

## Future Enhancements

### v0.6.x - Settings UI
- Settings screen shows "Profile Settings" vs "Global Settings" tabs
- Visual indicator of which profile's settings are active
- "Copy Settings From Profile..." button
- "Reset to Defaults" per-category

### v0.7.x - Advanced Settings
- Graphics settings (resolution, quality, V-Sync) - global
- Controller support - per-profile
- Accessibility options - per-profile
- Language/locale - global

### v1.0.x - Steam Integration
- Per-profile settings sync via Steam Cloud
- Conflict resolution UI when settings differ between devices
- Settings versioning for compatibility

---

## Impact on Other Systems

### ✅ No Changes Required
- **GameplayScene:** Still uses `SettingsManager.lane_keys` directly
- **SettingsUI:** Still uses `SettingsManager.set_note_speed()` etc.
- **InputHandler:** Still uses `SettingsManager.lane_keys`

### ✅ Already Integrated
- **ProfileManager:** Now calls `SettingsManager.set_profile()` on load

### 🔄 Future Integration (Not Required Now)
- **SettingsScreen:** Could display "Profile Settings" vs "Global Settings"
- **ProfileEditor:** Could show current settings summary
- **MainMenu:** Could display active profile's keybindings hint

---

## Rollback Plan

If issues arise, rollback is straightforward:

1. **Revert SettingsManager.gd** to previous version
2. **Revert ProfileManager.gd** `load_profile()` method
3. **Data Safety:** Profile settings files remain (future re-migration possible)
4. **User Impact:** Settings revert to global, but no data loss

**Migration is idempotent:** Re-running migration won't duplicate or corrupt data

---

## Summary

✅ **Per-profile settings implemented**  
✅ **Migration system preserves existing user settings**  
✅ **Backward compatible with legacy code**  
✅ **Zero compilation errors**  
✅ **Ready for profile export/import (next phase)**

**Next Steps:**
- Implement profile export/import (.rgprofile format)
- Add export/import UI
- Prepare for Steam Cloud integration

---

## Related Documentation

- [PerProfileSettings-ExportImport-Design.md](./PerProfileSettings-ExportImport-Design.md) - Full design document
- [ProfileSystemArchitecture.md](./ProfileSystemArchitecture.md) - Overall profile system
- [ScoreTrackingSystem.md](./ScoreTrackingSystem.md) - Profile-aware score history
