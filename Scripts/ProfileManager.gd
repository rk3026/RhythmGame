extends Node

# ProfileManager.gd - Singleton for managing player profiles
# Handles profile creation, loading, saving, switching, and statistics tracking

const PROFILES_DIR := "user://profiles/"
const PROFILES_LIST_PATH := "user://profiles/profiles_list.cfg"
const MIGRATION_FLAG := "user://profiles/migrated.flag"

# Signals
signal profile_created(profile_id: String)
signal profile_loaded(profile_id: String)
signal profile_updated(field: String, value: Variant)
signal profile_switched(old_id: String, new_id: String)
signal profile_deleted(profile_id: String)
signal stat_updated(stat_name: String, new_value: Variant)
signal level_up(new_level: int, old_level: int)

# Current active profile
var current_profile: Dictionary = {}
var current_profile_id: String = ""

# List of all profiles (loaded from profiles_list.cfg)
var profiles: Array[Dictionary] = []

# Validation constants
const MIN_USERNAME_LENGTH := 3
const MAX_USERNAME_LENGTH := 20
const MAX_BIO_LENGTH := 200
const MAX_DISPLAY_NAME_LENGTH := 30

func _ready():
	_ensure_directories_exist()
	_check_and_migrate_legacy_data()
	_load_profile_list()
	
	# Auto-load last active profile or create default
	if profiles.is_empty():
		print("ProfileManager: No profiles found, creating default profile")
		var default_profile = create_profile("Player")
		load_profile(default_profile.profile_id)
	else:
		var last_active = _get_last_active_profile_id()
		if last_active.is_empty():
			last_active = profiles[0].profile_id
		load_profile(last_active)

# ============================================================================
# Profile Creation & Management
# ============================================================================

func create_profile(username: String, display_name: String = "") -> Dictionary:
	"""
	Create a new player profile with default values.
	
	Args:
		username: Player username (3-20 characters)
		display_name: Optional display name (max 30 characters)
	
	Returns:
		Dictionary with profile data, or empty Dictionary on failure
	"""
	# Validate username
	if not _validate_username(username):
		push_error("ProfileManager: Invalid username: " + username)
		return {}
	
	# Check for duplicate username
	for profile in profiles:
		if profile.username.to_lower() == username.to_lower():
			push_error("ProfileManager: Username already exists: " + username)
			return {}
	
	# Generate unique profile ID (UUID v4 format)
	var profile_id = _generate_uuid()
	var timestamp = Time.get_datetime_string_from_system()
	
	# Create profile data structure
	var profile = {
		"profile_id": profile_id,
		"username": username,
		"display_name": display_name if display_name else username,
		"bio": "",
		"created_at": timestamp,
		"last_played": timestamp,
		
		"level": 1,
		"xp": 0,
		"total_xp": 0,
		
		"avatar_id": "avatar_default",
		"theme_id": "theme_default",
		"title_id": "",
		"profile_color_primary": "#FF6B6B",
		"profile_color_accent": "#4ECDC4",
		
		"privacy_stats": "public",
		"privacy_activity": "public",
		
		"stats": {
			"total_playtime_seconds": 0,
			"total_songs_played": 0,
			"total_songs_completed": 0,
			"total_notes_hit": 0,
			"total_notes_missed": 0,
			"highest_combo": 0,
			"total_perfect": 0,
			"total_great": 0,
			"total_good": 0,
			"total_miss": 0,
			"play_streak_current": 0,
			"play_streak_best": 0,
			"favorite_song": "",
			"favorite_instrument": "",
			"sessions_played": 0,
			"last_session_date": "",
			"difficulty_distribution": {
				"Easy": 0,
				"Medium": 0,
				"Hard": 0,
				"Expert": 0
			}
		}
	}
	
	# Create profile directory
	var profile_dir = PROFILES_DIR + profile_id + "/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(profile_dir):
		dir.make_dir_recursive(profile_dir)
	
	# Save profile data
	_save_profile_to_disk(profile)
	
	# Add to profiles list
	profiles.append({"profile_id": profile_id, "username": username, "last_played": timestamp})
	_save_profile_list()
	
	print("ProfileManager: Created profile: ", username, " (", profile_id, ")")
	emit_signal("profile_created", profile_id)
	
	return profile

func load_profile(profile_id: String) -> bool:
	"""
	Load a profile and set it as the active profile.
	
	Args:
		profile_id: UUID of the profile to load
	
	Returns:
		true if loaded successfully, false otherwise
	"""
	var profile_path = PROFILES_DIR + profile_id + "/profile.cfg"
	
	if not FileAccess.file_exists(profile_path):
		push_error("ProfileManager: Profile not found: " + profile_id)
		return false
	
	var cfg = ConfigFile.new()
	var err = cfg.load(profile_path)
	
	if err != OK:
		push_error("ProfileManager: Failed to load profile: " + profile_id + ", error: " + str(err))
		return false
	
	# Parse profile data from config file
	var profile = _parse_profile_from_config(cfg)
	
	if profile.is_empty():
		push_error("ProfileManager: Failed to parse profile data: " + profile_id)
		return false
	
	var old_profile_id = current_profile_id
	current_profile = profile
	current_profile_id = profile_id
	
	# Update last played timestamp
	current_profile.last_played = Time.get_datetime_string_from_system()
	_update_profile_in_list(profile_id, current_profile.last_played)
	
	# Load profile-specific score history
	_load_profile_scores(profile_id)
	
	print("ProfileManager: Loaded profile: ", profile.username, " (", profile_id, ")")
	emit_signal("profile_loaded", profile_id)
	
	if old_profile_id != "" and old_profile_id != profile_id:
		emit_signal("profile_switched", old_profile_id, profile_id)
	
	return true

func save_profile() -> bool:
	"""
	Save the current active profile to disk.
	
	Returns:
		true if saved successfully, false otherwise
	"""
	if current_profile.is_empty():
		push_warning("ProfileManager: No active profile to save")
		return false
	
	return _save_profile_to_disk(current_profile)

func delete_profile(profile_id: String) -> bool:
	"""
	Delete a profile and all associated data.
	
	Args:
		profile_id: UUID of the profile to delete
	
	Returns:
		true if deleted successfully, false otherwise
	"""
	# Cannot delete currently active profile
	if profile_id == current_profile_id:
		push_error("ProfileManager: Cannot delete active profile. Switch to another profile first.")
		return false
	
	var profile_dir = PROFILES_DIR + profile_id + "/"
	
	if not DirAccess.dir_exists_absolute(profile_dir):
		push_warning("ProfileManager: Profile directory not found: " + profile_id)
		return false
	
	# Delete all files in profile directory
	var dir = DirAccess.open(profile_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		# Remove directory
		dir = DirAccess.open(PROFILES_DIR)
		dir.remove(profile_id)
	
	# Remove from profiles list
	for i in range(profiles.size() - 1, -1, -1):
		if profiles[i].profile_id == profile_id:
			profiles.remove_at(i)
			break
	
	_save_profile_list()
	
	print("ProfileManager: Deleted profile: ", profile_id)
	emit_signal("profile_deleted", profile_id)
	
	return true

func switch_profile(profile_id: String) -> bool:
	"""
	Switch to a different profile.
	
	Args:
		profile_id: UUID of the profile to switch to
	
	Returns:
		true if switched successfully, false otherwise
	"""
	if profile_id == current_profile_id:
		push_warning("ProfileManager: Already on profile: " + profile_id)
		return true
	
	# Save current profile before switching
	save_profile()
	
	return load_profile(profile_id)

func get_all_profiles() -> Array[Dictionary]:
	"""
	Get list of all profiles (summary info only).
	
	Returns:
		Array of dictionaries with profile_id, username, last_played
	"""
	return profiles.duplicate()

# ============================================================================
# Profile Data Access
# ============================================================================

func get_current_profile() -> Dictionary:
	"""Get the current active profile data."""
	return current_profile.duplicate()

func get_current_profile_id() -> String:
	"""Get the current active profile ID."""
	return current_profile_id

func update_profile_field(field: String, value: Variant) -> void:
	"""
	Update a field in the current profile.
	
	Args:
		field: Field name (supports nested fields with dot notation, e.g., "stats.total_songs_played")
		value: New value for the field
	"""
	if current_profile.is_empty():
		push_warning("ProfileManager: No active profile to update")
		return
	
	# Handle nested fields (e.g., "stats.total_songs_played")
	var parts = field.split(".")
	var target = current_profile
	
	for i in range(parts.size() - 1):
		if not target.has(parts[i]):
			target[parts[i]] = {}
		target = target[parts[i]]
	
	target[parts[-1]] = value
	
	emit_signal("profile_updated", field, value)

func get_profile_stat(stat_name: String) -> Variant:
	"""
	Get a statistic value from the current profile.
	
	Args:
		stat_name: Stat name (e.g., "total_songs_played")
	
	Returns:
		Stat value, or null if not found
	"""
	if current_profile.is_empty():
		return null
	
	if current_profile.stats.has(stat_name):
		return current_profile.stats[stat_name]
	
	return null

# ============================================================================
# Statistics Updates
# ============================================================================

func record_song_completion(chart_path: String, difficulty: String, stats: Dictionary) -> void:
	"""
	Record a song completion and update profile statistics.
	
	Args:
		chart_path: Path to the chart file
		difficulty: Difficulty string (e.g., "ExpertSingle")
		stats: Dictionary with score, max_combo, grade_counts, total_notes, completed
	"""
	if current_profile.is_empty():
		return
	
	var profile_stats = current_profile.stats
	
	# Update play counts
	profile_stats.total_songs_played += 1
	if stats.get("completed", false):
		profile_stats.total_songs_completed += 1
	
	# Update note counts
	var grade_counts = stats.get("grade_counts", {})
	profile_stats.total_perfect += grade_counts.get("perfect", 0)
	profile_stats.total_great += grade_counts.get("great", 0)
	profile_stats.total_good += grade_counts.get("good", 0)
	profile_stats.total_miss += grade_counts.get("miss", 0)
	
	var notes_hit = grade_counts.get("perfect", 0) + grade_counts.get("great", 0) + grade_counts.get("good", 0)
	profile_stats.total_notes_hit += notes_hit
	profile_stats.total_notes_missed += grade_counts.get("miss", 0)
	
	# Update highest combo
	var combo = stats.get("max_combo", 0)
	if combo > profile_stats.highest_combo:
		profile_stats.highest_combo = combo
		emit_signal("stat_updated", "highest_combo", combo)
	
	# Update difficulty distribution
	var diff = _parse_difficulty_from_string(difficulty)
	if profile_stats.difficulty_distribution.has(diff):
		profile_stats.difficulty_distribution[diff] += 1
	
	# Update favorite song (most played)
	# This would require additional tracking, simplified for now
	if profile_stats.favorite_song == "":
		profile_stats.favorite_song = chart_path
	
	# Update favorite instrument
	if profile_stats.favorite_instrument == "":
		profile_stats.favorite_instrument = difficulty
	
	# Update play streak
	update_play_streak()
	
	emit_signal("stat_updated", "song_completion", stats)
	
	# Auto-save after song completion
	save_profile()

func add_playtime(seconds: float) -> void:
	"""
	Add playtime to the current profile.
	
	Args:
		seconds: Playtime in seconds
	"""
	if current_profile.is_empty():
		return
	
	current_profile.stats.total_playtime_seconds += int(seconds)
	emit_signal("stat_updated", "total_playtime_seconds", current_profile.stats.total_playtime_seconds)

func update_play_streak() -> void:
	"""Update the play streak based on the last session date."""
	if current_profile.is_empty():
		return
	
	var today = Time.get_date_string_from_system()
	var last_session = current_profile.stats.last_session_date
	
	if last_session == "":
		# First session
		current_profile.stats.play_streak_current = 1
		current_profile.stats.play_streak_best = 1
		current_profile.stats.last_session_date = today
	elif last_session == today:
		# Already played today, no change
		return
	else:
		# Check if consecutive day
		# Simplified: just check if different day (proper date math would be more complex)
		var yesterday = _get_yesterday_date()
		
		if last_session == yesterday:
			# Consecutive day
			current_profile.stats.play_streak_current += 1
			if current_profile.stats.play_streak_current > current_profile.stats.play_streak_best:
				current_profile.stats.play_streak_best = current_profile.stats.play_streak_current
		else:
			# Streak broken
			current_profile.stats.play_streak_current = 1
		
		current_profile.stats.last_session_date = today
	
	current_profile.stats.sessions_played += 1

func record_note_hit(grade: int) -> void:
	"""
	Record a single note hit (for real-time stat updates during gameplay).
	
	Args:
		grade: HitGrade enum value
	"""
	if current_profile.is_empty():
		return
	
	match grade:
		SettingsManager.HitGrade.PERFECT:
			current_profile.stats.total_perfect += 1
			current_profile.stats.total_notes_hit += 1
		SettingsManager.HitGrade.GREAT:
			current_profile.stats.total_great += 1
			current_profile.stats.total_notes_hit += 1
		SettingsManager.HitGrade.GOOD:
			current_profile.stats.total_good += 1
			current_profile.stats.total_notes_hit += 1
		_:
			current_profile.stats.total_miss += 1
			current_profile.stats.total_notes_missed += 1

func add_xp(xp_amount: int) -> bool:
	"""
	Add XP to the current profile and check for level up.
	
	Args:
		xp_amount: Amount of XP to add
	
	Returns:
		true if leveled up, false otherwise
	"""
	if current_profile.is_empty():
		return false
	
	var old_level = current_profile.level
	current_profile.xp += xp_amount
	current_profile.total_xp += xp_amount
	
	# Calculate new level (exponential curve: level = floor(0.1 * sqrt(total_xp)))
	var new_level = _calculate_level(current_profile.total_xp)
	
	if new_level > old_level:
		current_profile.level = new_level
		emit_signal("level_up", new_level, old_level)
		print("ProfileManager: Level up! ", old_level, " -> ", new_level)
		return true
	
	return false

# ============================================================================
# Customization
# ============================================================================

func get_avatar_path_from_id(avatar_id: String) -> String:
	"""
	Convert avatar ID to full path.
	
	Args:
		avatar_id: Avatar identifier (e.g., "avatar_default", "guitar", "default")
	
	Returns:
		Full path to avatar file
	"""
	# Handle legacy format where avatar_id might just be the base name
	var base_name = avatar_id.replace("avatar_", "")
	return "res://Assets/Profiles/Avatars/" + base_name + ".svg"

func get_avatar_id_from_path(avatar_path: String) -> String:
	"""
	Convert avatar path to ID.
	
	Args:
		avatar_path: Full path to avatar (e.g., "res://Assets/Profiles/Avatars/default.svg")
	
	Returns:
		Avatar identifier
	"""
	var file_name = avatar_path.get_file().get_basename()
	return file_name

func set_avatar(avatar_id: String) -> bool:
	"""
	Set the profile avatar.
	
	Args:
		avatar_id: Avatar identifier
	
	Returns:
		true if set successfully, false if avatar locked/invalid
	"""
	if current_profile.is_empty():
		return false
	
	# TODO: Check if avatar is unlocked
	current_profile.avatar_id = avatar_id
	emit_signal("profile_updated", "avatar_id", avatar_id)
	save_profile()
	return true

func set_theme(theme_id: String) -> bool:
	"""
	Set the profile theme.
	
	Args:
		theme_id: Theme identifier
	
	Returns:
		true if set successfully, false if theme locked/invalid
	"""
	if current_profile.is_empty():
		return false
	
	# TODO: Check if theme is unlocked
	current_profile.theme_id = theme_id
	emit_signal("profile_updated", "theme_id", theme_id)
	save_profile()
	return true

func set_title(title_id: String) -> bool:
	"""
	Set the profile title (equipped title shown in profile).
	
	Args:
		title_id: Title identifier
	
	Returns:
		true if set successfully, false if title locked/invalid
	"""
	if current_profile.is_empty():
		return false
	
	# TODO: Check if title is unlocked
	current_profile.title_id = title_id
	emit_signal("profile_updated", "title_id", title_id)
	save_profile()
	return true

func set_profile_colors(primary: Color, accent: Color) -> void:
	"""
	Set the profile color theme.
	
	Args:
		primary: Primary color
		accent: Accent color
	"""
	if current_profile.is_empty():
		return
	
	current_profile.profile_color_primary = primary.to_html()
	current_profile.profile_color_accent = accent.to_html()
	emit_signal("profile_updated", "profile_colors", {"primary": primary, "accent": accent})
	save_profile()

# ============================================================================
# Helper Functions
# ============================================================================

func _ensure_directories_exist():
	"""Ensure the profiles directory structure exists."""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("profiles"):
		dir.make_dir("profiles")

func _generate_uuid() -> String:
	"""Generate a UUID v4 string."""
	randomize()
	var uuid = ""
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid += "-"
		var n = randi() % 16
		uuid += "0123456789abcdef"[n]
	return uuid

func _validate_username(username: String) -> bool:
	"""Validate username meets requirements."""
	if username.length() < MIN_USERNAME_LENGTH or username.length() > MAX_USERNAME_LENGTH:
		return false
	
	# Only allow alphanumeric and underscore
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_]+$")
	return regex.search(username) != null

func _save_profile_to_disk(profile: Dictionary) -> bool:
	"""Save a profile to disk."""
	var profile_path = PROFILES_DIR + profile.profile_id + "/profile.cfg"
	var cfg = ConfigFile.new()
	
	# Identity section
	cfg.set_value("identity", "profile_id", profile.profile_id)
	cfg.set_value("identity", "username", profile.username)
	cfg.set_value("identity", "display_name", profile.display_name)
	cfg.set_value("identity", "bio", profile.bio)
	cfg.set_value("identity", "created_at", profile.created_at)
	cfg.set_value("identity", "last_played", profile.last_played)
	
	# Progression section
	cfg.set_value("progression", "level", profile.level)
	cfg.set_value("progression", "xp", profile.xp)
	cfg.set_value("progression", "total_xp", profile.total_xp)
	
	# Customization section
	cfg.set_value("customization", "avatar_id", profile.avatar_id)
	cfg.set_value("customization", "theme_id", profile.theme_id)
	cfg.set_value("customization", "title_id", profile.title_id)
	cfg.set_value("customization", "profile_color_primary", profile.profile_color_primary)
	cfg.set_value("customization", "profile_color_accent", profile.profile_color_accent)
	
	# Privacy section
	cfg.set_value("privacy", "privacy_stats", profile.privacy_stats)
	cfg.set_value("privacy", "privacy_activity", profile.privacy_activity)
	
	# Stats section
	for key in profile.stats.keys():
		if key == "difficulty_distribution":
			cfg.set_value("stats", key, profile.stats[key])
		else:
			cfg.set_value("stats", key, profile.stats[key])
	
	var err = cfg.save(profile_path)
	if err != OK:
		push_error("ProfileManager: Failed to save profile: " + str(err))
		return false
	
	return true

func _parse_profile_from_config(cfg: ConfigFile) -> Dictionary:
	"""Parse profile data from a ConfigFile."""
	var profile = {}
	
	# Identity
	profile.profile_id = cfg.get_value("identity", "profile_id", "")
	profile.username = cfg.get_value("identity", "username", "")
	profile.display_name = cfg.get_value("identity", "display_name", "")
	profile.bio = cfg.get_value("identity", "bio", "")
	profile.created_at = cfg.get_value("identity", "created_at", "")
	profile.last_played = cfg.get_value("identity", "last_played", "")
	
	# Progression
	profile.level = cfg.get_value("progression", "level", 1)
	profile.xp = cfg.get_value("progression", "xp", 0)
	profile.total_xp = cfg.get_value("progression", "total_xp", 0)
	
	# Customization
	profile.avatar_id = cfg.get_value("customization", "avatar_id", "avatar_default")
	profile.theme_id = cfg.get_value("customization", "theme_id", "theme_default")
	profile.title_id = cfg.get_value("customization", "title_id", "")
	profile.profile_color_primary = cfg.get_value("customization", "profile_color_primary", "#FF6B6B")
	profile.profile_color_accent = cfg.get_value("customization", "profile_color_accent", "#4ECDC4")
	
	# Compute avatar path from avatar_id for display purposes
	profile.avatar = get_avatar_path_from_id(profile.avatar_id)
	
	# Privacy
	profile.privacy_stats = cfg.get_value("privacy", "privacy_stats", "public")
	profile.privacy_activity = cfg.get_value("privacy", "privacy_activity", "public")
	
	# Stats
	profile.stats = {
		"total_playtime_seconds": cfg.get_value("stats", "total_playtime_seconds", 0),
		"total_songs_played": cfg.get_value("stats", "total_songs_played", 0),
		"total_songs_completed": cfg.get_value("stats", "total_songs_completed", 0),
		"total_notes_hit": cfg.get_value("stats", "total_notes_hit", 0),
		"total_notes_missed": cfg.get_value("stats", "total_notes_missed", 0),
		"highest_combo": cfg.get_value("stats", "highest_combo", 0),
		"total_perfect": cfg.get_value("stats", "total_perfect", 0),
		"total_great": cfg.get_value("stats", "total_great", 0),
		"total_good": cfg.get_value("stats", "total_good", 0),
		"total_miss": cfg.get_value("stats", "total_miss", 0),
		"play_streak_current": cfg.get_value("stats", "play_streak_current", 0),
		"play_streak_best": cfg.get_value("stats", "play_streak_best", 0),
		"favorite_song": cfg.get_value("stats", "favorite_song", ""),
		"favorite_instrument": cfg.get_value("stats", "favorite_instrument", ""),
		"sessions_played": cfg.get_value("stats", "sessions_played", 0),
		"last_session_date": cfg.get_value("stats", "last_session_date", ""),
		"difficulty_distribution": cfg.get_value("stats", "difficulty_distribution", {"Easy": 0, "Medium": 0, "Hard": 0, "Expert": 0})
	}
	
	return profile

func _load_profile_list():
	"""Load the list of all profiles with full summary data."""
	profiles.clear()
	
	if not FileAccess.file_exists(PROFILES_LIST_PATH):
		return
	
	var cfg = ConfigFile.new()
	var err = cfg.load(PROFILES_LIST_PATH)
	
	if err != OK:
		push_warning("ProfileManager: Failed to load profiles list: " + str(err))
		return
	
	for section in cfg.get_sections():
		# Load basic info from profiles list
		var profile_id = section
		var username = cfg.get_value(section, "username", "Unknown")
		var last_played = cfg.get_value(section, "last_played", "")
		
		# Load additional data from the actual profile file for display
		var profile_path = PROFILES_DIR + profile_id + "/profile.cfg"
		var profile_info = {
			"profile_id": profile_id,
			"username": username,
			"last_played": last_played,
			"display_name": username,
			"avatar": "res://Assets/Profiles/Avatars/default.svg",
			"level": 1,
			"xp": 0,
			"total_xp": 0
		}
		
		# Try to load full profile data for more accurate display
		if FileAccess.file_exists(profile_path):
			var profile_cfg = ConfigFile.new()
			if profile_cfg.load(profile_path) == OK:
				profile_info.display_name = profile_cfg.get_value("identity", "display_name", username)
				var avatar_id = profile_cfg.get_value("customization", "avatar_id", "default")
				profile_info.avatar = get_avatar_path_from_id(avatar_id)
				profile_info.level = profile_cfg.get_value("progression", "level", 1)
				profile_info.xp = profile_cfg.get_value("progression", "xp", 0)
				profile_info.total_xp = profile_cfg.get_value("progression", "total_xp", 0)
		
		profiles.append(profile_info)

func _save_profile_list():
	"""Save the list of all profiles."""
	var cfg = ConfigFile.new()
	
	for profile_info in profiles:
		cfg.set_value(profile_info.profile_id, "username", profile_info.username)
		cfg.set_value(profile_info.profile_id, "last_played", profile_info.last_played)
	
	var err = cfg.save(PROFILES_LIST_PATH)
	if err != OK:
		push_error("ProfileManager: Failed to save profiles list: " + str(err))

func _update_profile_in_list(profile_id: String, last_played: String):
	"""Update a profile's last played timestamp in the list."""
	for profile_info in profiles:
		if profile_info.profile_id == profile_id:
			profile_info.last_played = last_played
			break
	_save_profile_list()

func _get_last_active_profile_id() -> String:
	"""Get the most recently played profile ID."""
	if profiles.is_empty():
		return ""
	
	var latest = profiles[0]
	for profile_info in profiles:
		if profile_info.last_played > latest.last_played:
			latest = profile_info
	
	return latest.profile_id

func _calculate_level(total_xp: int) -> int:
	"""Calculate level from total XP (exponential curve)."""
	return int(floor(0.1 * sqrt(total_xp)))

func _parse_difficulty_from_string(difficulty: String) -> String:
	"""Parse difficulty from instrument string (e.g., 'ExpertSingle' -> 'Expert')."""
	if difficulty.begins_with("Easy"):
		return "Easy"
	elif difficulty.begins_with("Medium"):
		return "Medium"
	elif difficulty.begins_with("Hard"):
		return "Hard"
	elif difficulty.begins_with("Expert"):
		return "Expert"
	return "Medium"  # Default

func _get_yesterday_date() -> String:
	"""Get yesterday's date string (simplified)."""
	# Simplified date math - proper implementation would use Time.get_unix_time_from_system()
	var date_dict = Time.get_date_dict_from_system()
	date_dict.day -= 1
	if date_dict.day < 1:
		date_dict.month -= 1
		date_dict.day = 28  # Simplified
	return "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

# ============================================================================
# Migration Functions
# ============================================================================

func _check_and_migrate_legacy_data():
	"""Check for legacy score data and migrate to profile system."""
	if FileAccess.file_exists(MIGRATION_FLAG):
		# Already migrated
		return
	
	var legacy_scores = "user://score_history.cfg"
	
	if not FileAccess.file_exists(legacy_scores):
		# No legacy data to migrate
		return
	
	print("ProfileManager: Detected legacy score data, starting migration...")
	
	# Create default profile
	var profile = create_profile("Player")
	
	if profile.is_empty():
		push_error("ProfileManager: Failed to create profile for migration")
		return
	
	# Copy scores to profile directory
	var src = legacy_scores
	var dst = PROFILES_DIR + profile.profile_id + "/scores.cfg"
	DirAccess.copy_absolute(src, dst)
	
	# Backfill statistics from scores
	_backfill_stats_from_scores(profile.profile_id)
	
	# Rename original file as backup
	DirAccess.rename_absolute(legacy_scores, "user://score_history.cfg.backup")
	
	# Mark migration complete
	var flag = FileAccess.open(MIGRATION_FLAG, FileAccess.WRITE)
	if flag:
		flag.store_string(Time.get_datetime_string_from_system())
		flag.close()
	
	print("ProfileManager: Migration complete! Original data backed up to score_history.cfg.backup")

func _backfill_stats_from_scores(profile_id: String):
	"""Calculate lifetime stats from existing score history."""
	var scores_path = PROFILES_DIR + profile_id + "/scores.cfg"
	
	if not FileAccess.file_exists(scores_path):
		return
	
	var cfg = ConfigFile.new()
	var err = cfg.load(scores_path)
	
	if err != OK:
		return
	
	# Load the profile we just created
	if not load_profile(profile_id):
		return
	
	var total_plays = 0
	var total_completions = 0
	var max_combo = 0
	var total_perfect = 0
	var total_great = 0
	var total_good = 0
	var total_miss = 0
	
	# Iterate through all score entries
	for section in cfg.get_sections():
		var grade_counts = cfg.get_value(section, "best_grade_counts", {})
		var completed = cfg.get_value(section, "completed", false)
		var play_count = cfg.get_value(section, "play_count", 0)
		var best_max_combo = cfg.get_value(section, "best_max_combo", 0)
		
		total_plays += play_count
		if completed:
			total_completions += play_count
		
		if best_max_combo > max_combo:
			max_combo = best_max_combo
		
		# Accumulate grade counts (best run only to avoid overestimation)
		total_perfect += grade_counts.get("perfect", 0)
		total_great += grade_counts.get("great", 0)
		total_good += grade_counts.get("good", 0)
		total_miss += grade_counts.get("miss", 0)
	
	# Update profile stats
	current_profile.stats.total_songs_played = total_plays
	current_profile.stats.total_songs_completed = total_completions
	current_profile.stats.highest_combo = max_combo
	current_profile.stats.total_perfect = total_perfect
	current_profile.stats.total_great = total_great
	current_profile.stats.total_good = total_good
	current_profile.stats.total_miss = total_miss
	current_profile.stats.total_notes_hit = total_perfect + total_great + total_good
	current_profile.stats.total_notes_missed = total_miss
	
	# Calculate starting XP based on backfilled stats
	var backfill_xp = (total_perfect * 10) + (total_great * 7) + (total_good * 4)
	current_profile.total_xp = backfill_xp
	current_profile.level = _calculate_level(backfill_xp)
	current_profile.xp = backfill_xp
	
	save_profile()
	
	print("ProfileManager: Backfilled stats - Plays: ", total_plays, ", XP: ", backfill_xp, ", Level: ", current_profile.level)

func _load_profile_scores(profile_id: String):
	"""Load profile-specific score history into ScoreHistoryManager."""
	var scores_path = PROFILES_DIR + profile_id + "/scores.cfg"
	
	# Tell ScoreHistoryManager to use profile-specific scores
	# This will be implemented when we integrate the systems
	# For now, just check if the file exists
	if FileAccess.file_exists(scores_path):
		print("ProfileManager: Profile-specific scores found for ", profile_id)
