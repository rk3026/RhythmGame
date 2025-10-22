extends Node

# Singleton (autoload). Manages all game settings including persistent user settings and gameplay constants
# Stores user settings in user://settings.cfg with validation

const CONFIG_PATH := "user://settings.cfg"

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

# User settings (persistent)
var lane_keys: Array = [] # current runtime keycodes for lanes
var default_lane_keys: Array = [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]
var note_speed: float = 20.0
var master_volume: float = 1.0
var timing_offset: float = 0.0

# Gameplay constants (formerly in GameConfig)
var lane_colors: Array[Color] = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE, Color.PURPLE]
var spawn_interval: float = 2.0
var zone_height: float = 0.5
var line_color: Color = Color.BLACK
var perfect_window: float = 0.025
var great_window: float = 0.05
var good_window: float = 0.1

func _ready():
	load_settings()

func load_settings():
	var cfg = ConfigFile.new()
	var err = cfg.load(CONFIG_PATH)
	if err == OK:
		# Load and validate settings
		lane_keys = validate_lane_keys(cfg.get_value("input", "lane_keys", default_lane_keys))
		note_speed = validate_note_speed(cfg.get_value("gameplay", "note_speed", note_speed))
		master_volume = validate_volume(cfg.get_value("audio", "master_volume", master_volume))
		timing_offset = validate_timing_offset(cfg.get_value("timing", "offset", timing_offset))
	else:
		push_warning("Could not load settings file, using defaults. Error: " + str(err))
		lane_keys = default_lane_keys.duplicate()
		save_settings()

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

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("input", "lane_keys", lane_keys)
	cfg.set_value("gameplay", "note_speed", note_speed)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("timing", "offset", timing_offset)
	cfg.save(CONFIG_PATH)

func reset_defaults():
	lane_keys = default_lane_keys.duplicate()
	note_speed = 20.0
	master_volume = 1.0
	timing_offset = 0.0
	save_settings()

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
	save_settings()

func set_note_speed(speed: float):
	var validated_speed = validate_note_speed(speed)
	if validated_speed != speed:
		push_warning("Note speed adjusted from " + str(speed) + " to " + str(validated_speed))
	note_speed = validated_speed
	save_settings()

func set_master_volume(volume: float):
	var validated_volume = validate_volume(volume)
	if validated_volume != volume:
		push_warning("Volume adjusted from " + str(volume) + " to " + str(validated_volume))
	master_volume = validated_volume
	save_settings()

func set_timing_offset(offset: float):
	var validated_offset = validate_timing_offset(offset)
	if validated_offset != offset:
		push_warning("Timing offset adjusted from " + str(offset) + " to " + str(validated_offset))
	timing_offset = validated_offset
	save_settings()

func get_lane_key(index: int) -> int:
	if index >= 0 and index < lane_keys.size():
		return lane_keys[index]
	return KEY_NONE
