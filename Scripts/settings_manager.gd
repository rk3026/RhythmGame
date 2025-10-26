extends Node

# Singleton (autoload). Manages all game settings including persistent user settings and gameplay constants
# Supports both global settings (user://settings.cfg) and per-profile settings (user://profiles/[id]/settings.cfg)
# Per-profile: lane_keys, note_speed, timing_offset
# Global: master_volume, graphics settings (future)

const GLOBAL_CONFIG_PATH := "user://settings.cfg"
const PROFILES_DIR := "user://profiles/"

# Hit grade enum (formerly in GameConfig)
enum HitGrade {
	PERFECT,
	GREAT,
	GOOD,
	MISS
}

# Setting constraints for validation
const MIN_NOTE_SPEED := 5.0
const MAX_NOTE_SPEED := 50.0  
const MIN_VOLUME := 0.0
const MAX_VOLUME := 1.0
const MIN_TIMING_OFFSET := -500.0
const MAX_TIMING_OFFSET := 500.0

# Current profile ID for per-profile settings
var current_profile_id: String = ""

# Global settings (shared across all profiles)
var master_volume: float = 1.0

# Per-profile settings (loaded based on current_profile_id)
var lane_keys: Array = [] # current runtime keycodes for lanes
var default_lane_keys: Array = [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]
var note_speed: float = 20.0
var timing_offset: float = 0.0

# Gameplay constants (formerly in GameConfig)
var lane_colors: Array[Color] = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE, Color.PURPLE]
var spawn_interval: float = 2.0
var zone_height: float = 0.5
var line_color: Color = Color.BLACK
var perfect_window: float = 0.025
var great_window: float = 0.05
var good_window: float = 0.1
var miss_window: float = 0.7

func _ready():
	load_global_settings()

# Set the current profile and load its settings
func set_profile(profile_id: String):
	current_profile_id = profile_id
	load_profile_settings(profile_id)

# Load global settings (master_volume, etc.)
func load_global_settings():
	var cfg = ConfigFile.new()
	var err = cfg.load(GLOBAL_CONFIG_PATH)
	if err == OK:
		master_volume = validate_volume(cfg.get_value("audio", "master_volume", master_volume))
		# Check if migration flag exists
		var migrated = cfg.get_value("meta", "settings_migrated", false)
		if not migrated:
			print("SettingsManager: Legacy settings detected, will migrate on first profile load")
	else:
		# No global settings file yet, use defaults
		master_volume = 1.0
		save_global_settings()

# Load per-profile settings (lane_keys, note_speed, timing_offset)
func load_profile_settings(profile_id: String):
	if profile_id.is_empty():
		push_warning("Cannot load profile settings: profile_id is empty")
		lane_keys = default_lane_keys.duplicate()
		note_speed = 20.0
		timing_offset = 0.0
		return
	
	var settings_path = PROFILES_DIR + profile_id + "/settings.cfg"
	var cfg = ConfigFile.new()
	var err = cfg.load(settings_path)
	
	if err == OK:
		# Load and validate per-profile settings
		lane_keys = validate_lane_keys(cfg.get_value("input", "lane_keys", default_lane_keys))
		note_speed = validate_note_speed(cfg.get_value("gameplay", "note_speed", 20.0))
		timing_offset = validate_timing_offset(cfg.get_value("timing", "offset", 0.0))
	else:
		# New profile or no settings file yet
		# Check if we need to migrate legacy settings
		if _should_migrate_legacy_settings():
			print("SettingsManager: Migrating legacy settings to profile " + profile_id)
			_migrate_legacy_settings_to_profile(profile_id)
		else:
			# Use defaults for new profile
			push_warning("Could not load profile settings for " + profile_id + ", using defaults. Error: " + str(err))
			lane_keys = default_lane_keys.duplicate()
			note_speed = 20.0
			timing_offset = 0.0
			save_profile_settings()

# Check if legacy settings exist that need migration
func _should_migrate_legacy_settings() -> bool:
	if not FileAccess.file_exists(GLOBAL_CONFIG_PATH):
		return false
	
	var cfg = ConfigFile.new()
	var err = cfg.load(GLOBAL_CONFIG_PATH)
	if err != OK:
		return false
	
	# Check if migration flag is not set and legacy per-profile settings exist
	var migrated = cfg.get_value("meta", "settings_migrated", false)
	if migrated:
		return false
	
	# Check if legacy settings exist (lane_keys in global config)
	return cfg.has_section_key("input", "lane_keys")

# Migrate legacy settings from global config to profile config
func _migrate_legacy_settings_to_profile(profile_id: String):
	var cfg = ConfigFile.new()
	var err = cfg.load(GLOBAL_CONFIG_PATH)
	if err != OK:
		push_error("Failed to load legacy settings for migration")
		return
	
	# Extract per-profile settings from legacy global config
	var legacy_lane_keys = cfg.get_value("input", "lane_keys", default_lane_keys)
	var legacy_note_speed = cfg.get_value("gameplay", "note_speed", 20.0)
	var legacy_timing_offset = cfg.get_value("timing", "offset", 0.0)
	
	# Validate and set
	lane_keys = validate_lane_keys(legacy_lane_keys)
	note_speed = validate_note_speed(legacy_note_speed)
	timing_offset = validate_timing_offset(legacy_timing_offset)
	
	# Save to profile
	save_profile_settings()
	
	# Remove per-profile settings from global config and set migration flag
	cfg.erase_section_key("input", "lane_keys")
	cfg.erase_section_key("gameplay", "note_speed")
	cfg.erase_section_key("timing", "offset")
	cfg.set_value("meta", "settings_migrated", true)
	cfg.save(GLOBAL_CONFIG_PATH)
	
	print("SettingsManager: Successfully migrated legacy settings to profile " + profile_id)

# Legacy method for backward compatibility (loads global settings)
func load_settings():
	load_global_settings()
	# Note: Per-profile settings must be loaded via set_profile()

func validate_lane_keys(keys) -> Array:
	if not keys is Array:
		push_warning("Invalid lane_keys type, using defaults")
		return default_lane_keys.duplicate()
	
	# Validate key count and individual keys
	if keys.size() < 5 or keys.size() > 6:
		push_warning("Invalid lane key count, using defaults")
		return default_lane_keys.duplicate()
	
	for key in keys:
		if not (key is int) or key < 0:
			push_warning("Invalid key code found, using defaults")
			return default_lane_keys.duplicate()
	
	return keys

func validate_note_speed(speed) -> float:
	var val = float(speed)
	if val < MIN_NOTE_SPEED or val > MAX_NOTE_SPEED:
		push_warning("Note speed out of range (" + str(val) + "), clamping to valid range")
		return clampf(val, MIN_NOTE_SPEED, MAX_NOTE_SPEED)
	return val

func validate_volume(volume) -> float:
	var val = float(volume)
	if val < MIN_VOLUME or val > MAX_VOLUME:
		push_warning("Volume out of range (" + str(val) + "), clamping to valid range")
		return clampf(val, MIN_VOLUME, MAX_VOLUME)
	return val

func validate_timing_offset(offset) -> float:
	var val = float(offset)
	if val < MIN_TIMING_OFFSET or val > MAX_TIMING_OFFSET:
		push_warning("Timing offset out of range (" + str(val) + "), clamping to valid range")
		return clampf(val, MIN_TIMING_OFFSET, MAX_TIMING_OFFSET)
	return val

# Save global settings to user://settings.cfg
func save_global_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(GLOBAL_CONFIG_PATH)

# Save per-profile settings to user://profiles/[id]/settings.cfg
func save_profile_settings():
	if current_profile_id.is_empty():
		push_error("Cannot save profile settings: current_profile_id is empty")
		return
	
	var settings_path = PROFILES_DIR + current_profile_id + "/settings.cfg"
	
	# Ensure profile directory exists
	var dir = DirAccess.open(PROFILES_DIR + current_profile_id)
	if dir == null:
		push_error("Profile directory does not exist: " + PROFILES_DIR + current_profile_id)
		return
	
	var cfg = ConfigFile.new()
	cfg.set_value("input", "lane_keys", lane_keys)
	cfg.set_value("gameplay", "note_speed", note_speed)
	cfg.set_value("timing", "offset", timing_offset)
	cfg.save(settings_path)

# Legacy method for backward compatibility (saves global settings)
func save_settings():
	save_global_settings()
	# Note: Per-profile settings must be saved via save_profile_settings()

func reset_defaults():
	# Reset per-profile settings
	lane_keys = default_lane_keys.duplicate()
	note_speed = 20.0
	timing_offset = 0.0
	save_profile_settings()
	
	# Reset global settings
	master_volume = 1.0
	save_global_settings()

func set_lane_key(index: int, scancode: int):
	if index < 0 or index >= lane_keys.size():
		push_error("Invalid lane index: " + str(index))
		return
	
	if scancode < 0:
		push_error("Invalid scancode: " + str(scancode))
		return
	
	# Check for duplicate keys
	for i in range(lane_keys.size()):
		if i != index and lane_keys[i] == scancode:
			push_warning("Key already assigned to lane " + str(i))
			return
	
	lane_keys[index] = scancode
	save_profile_settings()

func set_note_speed(speed: float):
	var validated_speed = validate_note_speed(speed)
	if validated_speed != speed:
		push_warning("Note speed adjusted from " + str(speed) + " to " + str(validated_speed))
	note_speed = validated_speed
	save_profile_settings()

func set_master_volume(volume: float):
	var validated_volume = validate_volume(volume)
	if validated_volume != volume:
		push_warning("Volume adjusted from " + str(volume) + " to " + str(validated_volume))
	master_volume = validated_volume
	save_global_settings()

func set_timing_offset(offset: float):
	var validated_offset = validate_timing_offset(offset)
	if validated_offset != offset:
		push_warning("Timing offset adjusted from " + str(offset) + " to " + str(validated_offset))
	timing_offset = validated_offset
	save_profile_settings()

func get_lane_key(index: int) -> int:
	if index >= 0 and index < lane_keys.size():
		return lane_keys[index]
	return KEY_NONE
