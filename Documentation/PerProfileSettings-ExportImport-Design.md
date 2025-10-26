# Per-Profile Settings & Profile Export/Import Design

## Overview
This document outlines the design for per-profile settings support and profile export/import functionality, with Steam integration in mind for future deployment.

---

## Part 1: Per-Profile Settings Architecture

### Current State Analysis

**Global Settings (user://settings.cfg):**
```gdscript
[input]
lane_keys = [68, 70, 74, 75, 76, 59]  # D, F, J, K, L, ;

[gameplay]
note_speed = 20.0

[audio]
master_volume = 1.0

[timing]
offset = 0.0
```

**Problem:** All profiles share the same settings. If Player A uses QWERTY and Player B uses a controller, switching profiles requires reconfiguring controls each time.

---

### Settings Categories

#### Per-Profile Settings ✅ (User-Specific)
These should be isolated per profile as they reflect individual player preferences and skill:

1. **Input Settings:**
   - `lane_keys` - Keyboard bindings for lanes
   - Custom controller mappings (future)
   - Input sensitivity (future)

2. **Gameplay Settings:**
   - `note_speed` - Highway speed (player skill/preference)
   - `timing_offset` - Calibration for player's display/audio latency
   - Visual preferences (highway theme, note skins - future)

3. **Accessibility:**
   - Colorblind mode settings (future)
   - Left-handed mode (future)
   - UI scale preferences (future)

#### Global Settings 🌍 (System-Level)
These affect the entire game and should remain shared:

1. **System Audio:**
   - `master_volume` - Overall game volume
   - Music volume, SFX volume (future)
   - Audio device selection (future)

2. **Graphics Settings:**
   - Resolution (future)
   - V-Sync, FPS limit (future)
   - Anti-aliasing (future)
   - Graphics quality presets (future)

3. **System Preferences:**
   - Language/locale (future)
   - Update preferences (future)

---

### Proposed Architecture

#### File Structure
```
user://
├── settings.cfg                    # Global system settings
└── profiles/
    ├── [profile_a_id]/
    │   ├── profile.cfg            # Profile data (username, level, XP)
    │   ├── scores.cfg             # High scores
    │   ├── achievements.cfg       # Unlocked achievements
    │   └── settings.cfg           # Per-profile settings (NEW)
    │
    └── [profile_b_id]/
        └── ... (same structure)
```

#### SettingsManager Refactoring

**New Structure:**
```gdscript
# Global settings (shared)
var master_volume: float = 1.0
var graphics_quality: String = "high"
var language: String = "en"

# Per-profile settings (loaded per profile)
var current_profile_id: String = ""
var profile_lane_keys: Array = []
var profile_note_speed: float = 20.0
var profile_timing_offset: float = 0.0

# Public API
func set_profile(profile_id: String)  # Load profile-specific settings
func save_global_settings()           # Save system settings
func save_profile_settings()          # Save current profile's settings
```

**Backward Compatibility:**
- On first run with new system, migrate existing `user://settings.cfg` to default profile
- Keep global settings in `user://settings.cfg`
- Create `user://profiles/[id]/settings.cfg` for each profile

---

### Migration Strategy

**Step 1: Detect Legacy Settings**
```gdscript
func _migrate_legacy_settings():
    # Check if user://settings.cfg exists with old structure
    if FileAccess.file_exists("user://settings.cfg"):
        var cfg = ConfigFile.new()
        cfg.load("user://settings.cfg")
        
        # Extract per-profile settings
        var legacy_lane_keys = cfg.get_value("input", "lane_keys", default_lane_keys)
        var legacy_note_speed = cfg.get_value("gameplay", "note_speed", 20.0)
        var legacy_timing_offset = cfg.get_value("timing", "offset", 0.0)
        
        # Save to current profile's settings
        if not current_profile_id.is_empty():
            _save_profile_settings_to_file(current_profile_id, {
                "lane_keys": legacy_lane_keys,
                "note_speed": legacy_note_speed,
                "timing_offset": legacy_timing_offset
            })
        
        # Keep global settings, remove per-profile ones
        cfg.erase_section_key("input", "lane_keys")
        cfg.erase_section_key("gameplay", "note_speed")
        cfg.erase_section_key("timing", "offset")
        cfg.save("user://settings.cfg")
        
        # Create migration flag
        cfg.set_value("meta", "settings_migrated", true)
        cfg.save("user://settings.cfg")
```

**Step 2: Profile-Specific Settings on Load**
```gdscript
# Called by ProfileManager after loading a profile
func set_profile(profile_id: String):
    current_profile_id = profile_id
    _load_profile_settings(profile_id)

func _load_profile_settings(profile_id: String):
    var settings_path = "user://profiles/" + profile_id + "/settings.cfg"
    
    if not FileAccess.file_exists(settings_path):
        # New profile, use defaults
        profile_lane_keys = default_lane_keys.duplicate()
        profile_note_speed = 20.0
        profile_timing_offset = 0.0
        save_profile_settings()
        return
    
    var cfg = ConfigFile.new()
    cfg.load(settings_path)
    
    profile_lane_keys = cfg.get_value("input", "lane_keys", default_lane_keys)
    profile_note_speed = cfg.get_value("gameplay", "note_speed", 20.0)
    profile_timing_offset = cfg.get_value("timing", "offset", 0.0)
```

---

## Part 2: Profile Export/Import System

### Use Cases

#### Use Case 1: Backup & Restore
- Player wants to backup their profile before reinstalling
- Player wants to transfer profile to new PC
- Player wants to restore profile after data loss

#### Use Case 2: Profile Sharing
- Player wants to share profile with friend
- Speedrunner wants to share optimized settings
- Content creator shares profile with community

#### Use Case 3: Steam Cloud Sync (Future)
- Profile automatically syncs between devices
- Conflict resolution when playing on multiple PCs
- Cross-platform profile transfer (Windows → Linux → Steam Deck)

---

### Profile Package Format

#### File Format: `.rgprofile` (Rhythm Game Profile)
**Why custom extension:**
- Easy file association
- Clear purpose (not just .zip)
- Future-proof for format changes
- Steam Workshop compatibility

#### Package Structure
```
profile_export.rgprofile  (ZIP archive)
├── metadata.json         # Package metadata
├── profile.cfg           # Profile data (username, level, XP, stats)
├── scores.cfg            # High scores per song
├── achievements.cfg      # Achievement progress
└── settings.cfg          # Per-profile settings
```

#### Metadata Format (metadata.json)
```json
{
  "format_version": "1.0",
  "game_version": "0.4.0",
  "export_date": "2025-10-26T14:30:00Z",
  "profile_username": "ExileLord",
  "profile_id": "original-uuid-here",
  "export_type": "full",
  "includes": {
    "profile_data": true,
    "scores": true,
    "achievements": true,
    "settings": true
  },
  "statistics": {
    "total_songs_played": 150,
    "total_score": 12500000,
    "level": 25,
    "achievements_unlocked": 15
  },
  "checksums": {
    "profile.cfg": "sha256_hash_here",
    "scores.cfg": "sha256_hash_here",
    "achievements.cfg": "sha256_hash_here",
    "settings.cfg": "sha256_hash_here"
  }
}
```

**Why include checksums:**
- Detect file corruption during transfer
- Validate package integrity
- Security for Steam Workshop uploads

---

### Export Workflow

```
User Action: Click "Export Profile" in profile_select.gd
    ↓
Show Export Dialog:
    - Profile summary (username, level, songs played)
    - Checkboxes: [ ] Include scores [ ] Include achievements [✓] Include settings
    - Export location selection
    - [Cancel] [Export]
    ↓
ProfileManager.export_profile(profile_id, options, destination)
    ↓
    1. Create temporary directory: user://temp/export_[timestamp]/
    2. Copy profile.cfg → temp/
    3. Copy scores.cfg → temp/ (if selected)
    4. Copy achievements.cfg → temp/ (if selected)
    5. Copy settings.cfg → temp/ (if selected)
    6. Generate metadata.json with checksums
    7. Create ZIP archive → [profile_username].rgprofile
    8. Move to destination (user's Downloads or selected folder)
    9. Clean up temp directory
    ↓
Show Success Dialog:
    "Profile exported successfully!"
    Path: C:/Users/Player/Downloads/ExileLord.rgprofile
    [Open Folder] [OK]
```

---

### Import Workflow

```
User Action: Click "Import Profile" in profile_select.gd
    ↓
Show File Dialog: Select .rgprofile file
    ↓
ProfileManager.import_profile(file_path)
    ↓
    1. Validate file exists and is .rgprofile
    2. Extract to temp directory: user://temp/import_[timestamp]/
    3. Validate metadata.json exists
    4. Parse metadata, check format_version
    5. Verify checksums (detect corruption)
    6. Check for username conflicts
    ↓
If username conflicts:
    Show Conflict Dialog:
        "Profile 'ExileLord' already exists!"
        Options:
        ( ) Rename imported profile to: [ExileLord_2]
        ( ) Replace existing profile (⚠️ destructive)
        ( ) Skip import
        [Cancel] [Import]
    ↓
    7. Generate new profile_id (UUID)
    8. Copy files to user://profiles/[new_id]/
    9. Add profile to profiles_list.cfg
    10. Clean up temp directory
    ↓
Show Success Dialog:
    "Profile imported successfully!"
    Profile: ExileLord
    Level: 25 | Songs Played: 150
    [View Profile] [OK]
```

---

### Import Validation

**Critical Checks:**
1. **File Format:**
   - Is it a valid ZIP archive?
   - Does metadata.json exist?
   - Does format_version match or is compatible?

2. **Data Integrity:**
   - Do checksums match file contents?
   - Are required files present?
   - Are file sizes reasonable (<100MB for safety)?

3. **Content Validation:**
   - Is profile.cfg valid ConfigFile format?
   - Are scores.cfg entries valid?
   - Are achievement IDs recognized?

4. **Version Compatibility:**
   ```gdscript
   func is_compatible_version(export_game_version: String) -> bool:
       # Parse versions: "0.4.0" → [0, 4, 0]
       var export_parts = export_game_version.split(".")
       var current_parts = ProjectSettings.get_setting("application/config/version").split(".")
       
       # Major version must match (breaking changes)
       if export_parts[0] != current_parts[0]:
           return false
       
       # Minor version can be different (feature additions)
       # Patch version doesn't matter (bug fixes)
       return true
   ```

**Security Considerations:**
- Validate all file paths (prevent directory traversal)
- Limit file sizes (prevent ZIP bombs)
- Sanitize usernames (prevent code injection in UI)
- Don't execute any code from imported files

---

## Part 3: Steam Integration Preparation

### Steam Cloud Requirements

**Steam Cloud Quota:**
- Free quota: ~200MB per user per game
- For rhythm game: Profiles should be <1MB each
- Can support 100-200 profiles per user comfortably

**File Locations for Steam Cloud:**
```
steam_cloud://
└── profiles/
    ├── cloud_sync_manifest.json    # Tracks sync state
    ├── [profile_a_id]/
    │   ├── profile.cfg
    │   ├── scores.cfg
    │   ├── achievements.cfg
    │   └── settings.cfg
    └── [profile_b_id]/
        └── ... (same structure)
```

---

### Cloud Sync Strategy

#### Option 1: Automatic Sync (Recommended)
**When:**
- On profile load
- On profile switch
- On game exit
- Every 5 minutes during gameplay (scores)

**How:**
```gdscript
func sync_profile_to_cloud(profile_id: String):
    if not Steam.isCloudEnabledForAccount():
        return
    
    # Read local profile
    var local_profile = _read_profile_from_disk(profile_id)
    var local_timestamp = local_profile.last_modified
    
    # Read cloud profile
    var cloud_profile = Steam.fileRead("profiles/" + profile_id + "/profile.cfg")
    var cloud_timestamp = cloud_profile.last_modified if cloud_profile else 0
    
    # Sync strategy
    if local_timestamp > cloud_timestamp:
        # Local is newer, upload to cloud
        Steam.fileWrite("profiles/" + profile_id + "/profile.cfg", local_profile.data)
    elif cloud_timestamp > local_timestamp:
        # Cloud is newer, download from cloud
        _write_profile_to_disk(profile_id, cloud_profile.data)
    else:
        # Timestamps match, no sync needed
        pass
```

#### Option 2: Manual Sync with Conflict Resolution
**For edge cases:**
- Player edits profile on PC A
- Player edits profile on PC B (without syncing A first)
- Conflict detected on next sync

**Resolution UI:**
```
Sync Conflict Detected!

Profile: ExileLord
PC A (Local):   Level 25 | Last Played: Oct 26, 2:30 PM
Steam Cloud:    Level 26 | Last Played: Oct 26, 3:00 PM

Which version should we keep?
( ) Keep Local (lose cloud progress)
( ) Keep Cloud (lose local progress)
( ) Merge (keep highest level, combine scores)

[Cancel] [Resolve]
```

---

### Steam API Integration Points

```gdscript
# In ProfileManager.gd

func _ready():
    if OS.has_feature("steam"):
        _init_steam_cloud()

func _init_steam_cloud():
    if not Steam.restartAppIfNecessary(YOUR_STEAM_APP_ID):
        Steam.steamInit()
        
        if Steam.isCloudEnabledForAccount():
            print("Steam Cloud enabled, auto-sync active")
            # Load cloud profile list
            _sync_profile_list_from_cloud()

func save_profile():
    # Existing local save
    _save_profile_to_disk()
    
    # Also save to Steam Cloud if enabled
    if Steam.isCloudEnabledForAccount():
        _save_profile_to_cloud(current_profile_id)

func load_profile(profile_id: String):
    # Check if cloud version is newer
    if Steam.isCloudEnabledForAccount():
        var cloud_profile = _get_cloud_profile(profile_id)
        if cloud_profile and cloud_profile.is_newer_than_local():
            # Download from cloud
            _load_profile_from_cloud(profile_id)
            return true
    
    # Load from local disk
    return _load_profile_from_disk(profile_id)
```

---

### Steam Workshop Integration (Future)

**Use Case:** Share profiles as Workshop items

**Profile as Workshop Item:**
- Upload .rgprofile as Workshop content
- Include profile screenshot (achievements, stats)
- Tags: "High Scores", "Expert Settings", "Speedrun"
- Description: Player bio, notable achievements
- Ratings & comments from community

**Implementation:**
```gdscript
func upload_profile_to_workshop(profile_id: String, description: String, tags: Array):
    var profile_path = export_profile(profile_id, "user://temp/workshop_upload/")
    
    Steam.createItem(YOUR_STEAM_APP_ID, Steam.WORKSHOP_FILE_TYPE_COMMUNITY)
    Steam.setItemTitle(item_handle, ProfileManager.current_profile.username + "'s Profile")
    Steam.setItemDescription(item_handle, description)
    Steam.setItemTags(item_handle, tags)
    Steam.setItemContent(item_handle, profile_path)
    Steam.submitItemUpdate(item_handle)
```

---

## Part 4: Implementation Plan

### Phase 1: Per-Profile Settings ⚠️ HIGH PRIORITY
1. Add `current_profile_id` to SettingsManager
2. Split settings into global vs per-profile
3. Create `set_profile()` method
4. Implement `save_profile_settings()` and `load_profile_settings()`
5. Add migration logic for legacy settings.cfg
6. Update ProfileManager to call `SettingsManager.set_profile()`

**Testing:**
- Create 2 profiles with different keybindings
- Switch between profiles
- Verify each profile loads its own settings
- Verify global settings (volume) remain shared

---

### Phase 2: Profile Export/Import 🔧 CORE FEATURE
1. Create `.rgprofile` package format with metadata
2. Implement `export_profile()` in ProfileManager
3. Implement `import_profile()` with validation
4. Add checksum generation/verification
5. Handle username conflicts
6. Create Export/Import UI dialogs
7. Add buttons to profile_select screen

**Testing:**
- Export profile A
- Import on fresh install
- Verify all data intact (scores, achievements, settings)
- Test username conflict resolution
- Test corrupted file handling

---

### Phase 3: Steam Cloud Preparation 🎮 FUTURE-PROOFING
1. Add Steam Cloud detection
2. Implement cloud sync manifest
3. Create conflict resolution system
4. Add Steam API hooks (conditional compilation)
5. Test with Steamworks SDK (in development branch)

**Testing:**
- Test with Steam Cloud disabled (fallback to local)
- Test with Steam Cloud enabled (sync behavior)
- Test conflict resolution with different timestamps
- Test large profile datasets (<100MB)

---

### Phase 4: Polish & Documentation 📚
1. Create user documentation for export/import
2. Add in-game tooltips for Steam Cloud status
3. Create video tutorial for profile transfer
4. Document Steam Cloud behavior in README
5. Add FAQ for common profile issues

---

## API Design

### SettingsManager New API
```gdscript
# Profile Management
func set_profile(profile_id: String) -> void
func get_current_profile_id() -> String

# Per-Profile Settings
func get_profile_lane_keys() -> Array
func set_profile_lane_key(index: int, scancode: int) -> void
func get_profile_note_speed() -> float
func set_profile_note_speed(speed: float) -> void
func get_profile_timing_offset() -> float
func set_profile_timing_offset(offset: float) -> void

# Global Settings (unchanged API, but separate storage)
func get_master_volume() -> float
func set_master_volume(volume: float) -> void

# Save/Load
func save_profile_settings() -> bool
func save_global_settings() -> bool
func load_profile_settings(profile_id: String) -> bool
```

---

### ProfileManager Export/Import API
```gdscript
# Export
func export_profile(profile_id: String, options: Dictionary = {}) -> Dictionary
# options: {
#   "include_scores": bool,
#   "include_achievements": bool,
#   "include_settings": bool,
#   "destination": String  # File path
# }
# Returns: { "success": bool, "path": String, "error": String }

# Import
func import_profile(file_path: String, options: Dictionary = {}) -> Dictionary
# options: {
#   "on_conflict": String,  # "rename", "replace", "skip"
#   "new_username": String  # If renaming
# }
# Returns: { 
#   "success": bool, 
#   "profile_id": String,
#   "error": String,
#   "conflict": bool,
#   "conflict_with": String  # Existing username
# }

# Validation
func validate_profile_package(file_path: String) -> Dictionary
# Returns: {
#   "valid": bool,
#   "format_version": String,
#   "game_version": String,
#   "username": String,
#   "errors": Array[String]
# }

# Steam Cloud (conditional compilation)
func sync_profile_to_cloud(profile_id: String) -> bool
func sync_profile_from_cloud(profile_id: String) -> bool
func resolve_cloud_conflict(profile_id: String, keep: String) -> bool
```

---

## Backward Compatibility

### Migration Checklist
- [x] Existing profiles continue to work
- [x] Legacy settings.cfg migrated automatically
- [x] New profiles created with new structure
- [x] No data loss during migration
- [x] Clear migration messaging to user

### Version Support
- **v0.3.x and earlier:** No profile system
- **v0.4.x:** Profile system introduced (current)
- **v0.5.x:** Per-profile settings + export/import (planned)
- **v1.0.x:** Steam release with Cloud sync

**Import Compatibility:**
- v1.0 can import v0.5 profiles ✅
- v1.0 can import v0.4 profiles ✅ (settings use defaults)
- v0.5 can import v0.4 profiles ✅ (settings use defaults)
- v0.4 cannot import v0.5 profiles ❌ (missing features)

---

## Security & Privacy

### Data Privacy
- Profiles stored locally by default
- Steam Cloud is opt-in (user consent)
- No telemetry in profile exports
- No personally identifiable information required

### Security Measures
- Validate all imported data
- Sanitize usernames (SQL injection, XSS prevention)
- Limit file sizes (ZIP bomb prevention)
- Checksum verification (corruption detection)
- No executable code in profiles (code injection prevention)

---

## Performance Considerations

### Profile Size Estimates
```
profile.cfg:       ~2-5 KB    (metadata, stats)
scores.cfg:        ~50-200 KB (100-500 songs)
achievements.cfg:  ~5-20 KB   (50-100 achievements)
settings.cfg:      ~1-2 KB    (keybindings, preferences)
---
Total per profile: ~60-230 KB
```

**Steam Cloud Impact:**
- 100 profiles = ~6-23 MB (well within 200MB quota)
- Sync time: <1 second per profile on broadband
- Minimal impact on game startup

---

## Future Enhancements

### v0.6.x - Advanced Features
- Profile themes/customization
- Profile badges and titles
- Friend profile comparison
- Local leaderboards

### v1.1.x - Steam Workshop
- Upload profiles to Workshop
- Download community profiles
- Rate and comment on profiles
- Profile collections

### v1.2.x - Cross-Platform
- Sync between PC and Steam Deck
- Mobile companion app (view stats)
- Web profile viewer

---

## Summary

This design provides:
1. ✅ **Per-Profile Settings** - Individual player preferences
2. ✅ **Export/Import** - Profile backup and sharing
3. ✅ **Steam Cloud Ready** - Future cloud sync support
4. ✅ **Backward Compatible** - Existing profiles migrate smoothly
5. ✅ **Secure & Private** - Validated imports, opt-in cloud
6. ✅ **Scalable** - Supports 100+ profiles per user

**Implementation Priority:**
1. Per-Profile Settings (Phase 1) - Immediate user benefit
2. Export/Import (Phase 2) - Backup safety net
3. Steam Cloud (Phase 3) - Pre-release preparation

**Ready to implement Phase 1!**
