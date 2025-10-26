extends Node

# AchievementManager.gd - Singleton for managing player achievements
# Handles achievement definitions, unlocking, progress tracking, and notifications

const ACHIEVEMENTS_DEF_PATH := "res://Assets/Data/achievements.json"
const PROFILES_DIR := "user://profiles/"

# Reference to ProfileManager autoload (initialized in _ready)
var profile_manager: Node = null

# Signals
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: int, target: int)

# Achievement definitions (loaded from JSON)
var achievement_definitions: Dictionary = {}

# Current profile's achievement progress
var achievement_progress: Dictionary = {}

func _ready():
	# Get ProfileManager autoload reference
	profile_manager = get_node("/root/ProfileManager")
	_load_achievement_definitions()

# ============================================================================
# Achievement Loading
# ============================================================================

func _load_achievement_definitions():
	"""Load achievement definitions from JSON file."""
	var file = FileAccess.open(ACHIEVEMENTS_DEF_PATH, FileAccess.READ)
	
	if not file:
		push_error("AchievementManager: Failed to open achievements.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("AchievementManager: Failed to parse achievements.json: " + json.get_error_message())
		return
	
	var data = json.data
	
	if not data.has("achievements"):
		push_error("AchievementManager: Invalid achievements.json format")
		return
	
	# Convert array to dictionary keyed by achievement_id
	for achievement in data.achievements:
		achievement_definitions[achievement.achievement_id] = achievement
	
	print("AchievementManager: Loaded ", achievement_definitions.size(), " achievement definitions")

func load_profile_achievements(profile_id: String):
	"""
	Load achievement progress for a specific profile.
	
	Args:
		profile_id: UUID of the profile
	"""
	achievement_progress.clear()
	
	var achievements_path = PROFILES_DIR + profile_id + "/achievements.cfg"
	
	if not FileAccess.file_exists(achievements_path):
		# No achievements yet, initialize with defaults
		_initialize_achievement_progress()
		return
	
	var cfg = ConfigFile.new()
	var err = cfg.load(achievements_path)
	
	if err != OK:
		push_warning("AchievementManager: Failed to load achievements: " + str(err))
		_initialize_achievement_progress()
		return
	
	# Load progress for each achievement
	for achievement_id in achievement_definitions.keys():
		if cfg.has_section(achievement_id):
			achievement_progress[achievement_id] = {
				"unlocked": cfg.get_value(achievement_id, "unlocked", false),
				"progress": cfg.get_value(achievement_id, "progress", 0),
				"unlocked_at": cfg.get_value(achievement_id, "unlocked_at", "")
			}
		else:
			achievement_progress[achievement_id] = {
				"unlocked": false,
				"progress": 0,
				"unlocked_at": ""
			}
	
	print("AchievementManager: Loaded achievement progress for profile ", profile_id)

func save_achievement_progress(profile_id: String) -> bool:
	"""
	Save achievement progress for the current profile.
	
	Args:
		profile_id: UUID of the profile
	
	Returns:
		true if saved successfully
	"""
	var achievements_path = PROFILES_DIR + profile_id + "/achievements.cfg"
	var cfg = ConfigFile.new()
	
	for achievement_id in achievement_progress.keys():
		var progress_data = achievement_progress[achievement_id]
		cfg.set_value(achievement_id, "unlocked", progress_data.unlocked)
		cfg.set_value(achievement_id, "progress", progress_data.progress)
		cfg.set_value(achievement_id, "unlocked_at", progress_data.unlocked_at)
	
	var err = cfg.save(achievements_path)
	if err != OK:
		push_error("AchievementManager: Failed to save achievements: " + str(err))
		return false
	
	return true

func _initialize_achievement_progress():
	"""Initialize achievement progress with default values."""
	for achievement_id in achievement_definitions.keys():
		achievement_progress[achievement_id] = {
			"unlocked": false,
			"progress": 0,
			"unlocked_at": ""
		}

# ============================================================================
# Achievement Checking
# ============================================================================

func check_achievements_after_song(stats: Dictionary):
	"""
	Check for achievements after a song is completed.
	
	Args:
		stats: Dictionary with score, max_combo, grade_counts, etc.
	"""
	if profile_manager.current_profile.is_empty():
		return
	
	# Get current profile stats
	var profile = profile_manager.current_profile
	var profile_stats = profile.stats
	
	# Check all achievements
	for achievement_id in achievement_definitions.keys():
		var achievement = achievement_definitions[achievement_id]
		var progress_data = achievement_progress[achievement_id]
		
		# Skip if already unlocked
		if progress_data.unlocked:
			continue
		
		# Check requirement
		var requirement = achievement.requirement
		var current_value = 0
		var target_value = requirement.target
		
		match requirement.type:
			"total":
				# Check total stat (e.g., total_songs_completed)
				current_value = profile_stats.get(requirement.stat, 0)
			
			"single":
				# Check single stat (e.g., highest_combo)
				current_value = profile_stats.get(requirement.stat, 0)
			
			"difficulty":
				# Check difficulty distribution
				var difficulty = requirement.stat
				current_value = profile_stats.difficulty_distribution.get(difficulty, 0)
			
			"condition":
				# Custom condition (handled separately)
				continue
		
		# Update progress
		progress_data.progress = current_value
		emit_signal("achievement_progress_updated", achievement_id, current_value, target_value)
		
		# Check if unlocked
		if current_value >= target_value:
			_unlock_achievement(achievement_id)

func check_achievement(achievement_id: String) -> bool:
	"""
	Manually check a specific achievement.
	
	Args:
		achievement_id: ID of the achievement to check
	
	Returns:
		true if achievement is unlocked
	"""
	if not achievement_definitions.has(achievement_id):
		push_warning("AchievementManager: Unknown achievement: " + achievement_id)
		return false
	
	var progress_data = achievement_progress.get(achievement_id, {})
	return progress_data.get("unlocked", false)

func unlock_achievement_manual(achievement_id: String):
	"""
	Manually unlock an achievement (for special/hidden achievements).
	
	Args:
		achievement_id: ID of the achievement to unlock
	"""
	if not achievement_definitions.has(achievement_id):
		push_warning("AchievementManager: Unknown achievement: " + achievement_id)
		return
	
	_unlock_achievement(achievement_id)

func _unlock_achievement(achievement_id: String):
	"""
	Internal function to unlock an achievement.
	
	Args:
		achievement_id: ID of the achievement to unlock
	"""
	var progress_data = achievement_progress[achievement_id]
	
	if progress_data.unlocked:
		return  # Already unlocked
	
	var achievement = achievement_definitions[achievement_id]
	
	# Mark as unlocked
	progress_data.unlocked = true
	progress_data.unlocked_at = Time.get_datetime_string_from_system()
	
	# Grant rewards
	var reward = achievement.reward
	
	# Grant XP
	if reward.has("xp"):
		profile_manager.add_xp(reward.xp)
	
	# Unlock items (avatars, themes, titles)
	# These will be checked by customization systems
	
	# Save progress
	save_achievement_progress(profile_manager.current_profile_id)
	
	print("AchievementManager: Achievement unlocked: ", achievement.name, " (+", reward.xp, " XP)")
	emit_signal("achievement_unlocked", achievement_id, achievement)

# ============================================================================
# Achievement Queries
# ============================================================================

func get_achievement_data(achievement_id: String) -> Dictionary:
	"""
	Get the definition data for an achievement.
	
	Args:
		achievement_id: ID of the achievement
	
	Returns:
		Achievement definition dictionary, or empty if not found
	"""
	return achievement_definitions.get(achievement_id, {})

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""
	Get the progress data for an achievement.
	
	Args:
		achievement_id: ID of the achievement
	
	Returns:
		Progress dictionary with unlocked, progress, unlocked_at
	"""
	return achievement_progress.get(achievement_id, {})

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""
	Check if an achievement is unlocked.
	
	Args:
		achievement_id: ID of the achievement
	
	Returns:
		true if unlocked, false otherwise
	"""
	var progress_data = achievement_progress.get(achievement_id, {})
	return progress_data.get("unlocked", false)

func get_unlocked_achievements() -> Array:
	"""
	Get list of all unlocked achievement IDs.
	
	Returns:
		Array of achievement IDs
	"""
	var unlocked = []
	for achievement_id in achievement_progress.keys():
		if achievement_progress[achievement_id].unlocked:
			unlocked.append(achievement_id)
	return unlocked

func get_achievements_by_category(category: String) -> Array:
	"""
	Get all achievements in a specific category.
	
	Args:
		category: Category name (e.g., "score", "combo", "completion")
	
	Returns:
		Array of achievement dictionaries
	"""
	var filtered = []
	for achievement_id in achievement_definitions.keys():
		var achievement = achievement_definitions[achievement_id]
		if achievement.category == category:
			# Merge definition with progress
			var data = achievement.duplicate()
			data["progress_data"] = achievement_progress.get(achievement_id, {})
			filtered.append(data)
	return filtered

func get_all_achievements() -> Array:
	"""
	Get all achievements (definitions merged with progress).
	
	Returns:
		Array of achievement dictionaries
	"""
	var all_achievements = []
	for achievement_id in achievement_definitions.keys():
		var achievement = achievement_definitions[achievement_id]
		
		# Skip hidden achievements if not unlocked
		var progress_data = achievement_progress.get(achievement_id, {})
		if achievement.hidden and not progress_data.get("unlocked", false):
			continue
		
		var data = achievement.duplicate()
		data["progress_data"] = progress_data
		all_achievements.append(data)
	return all_achievements

func get_completion_percentage() -> float:
	"""
	Get overall achievement completion percentage.
	
	Returns:
		Percentage (0.0 - 100.0)
	"""
	if achievement_definitions.is_empty():
		return 0.0
	
	var unlocked_count = 0
	for progress_data in achievement_progress.values():
		if progress_data.unlocked:
			unlocked_count += 1
	
	return (float(unlocked_count) / float(achievement_definitions.size())) * 100.0

# ============================================================================
# Unlock Checking (for customization items)
# ============================================================================

func is_item_unlocked(item_id: String) -> bool:
	"""
	Check if a customization item (avatar, theme, title) is unlocked.
	
	Args:
		item_id: Item identifier (e.g., "avatar_guitar", "theme_gold")
	
	Returns:
		true if unlocked, false otherwise
	"""
	# Default items are always unlocked
	if item_id.ends_with("_default"):
		return true
	
	# Check if any unlocked achievement grants this item
	for achievement_id in achievement_progress.keys():
		var progress_data = achievement_progress[achievement_id]
		if not progress_data.unlocked:
			continue
		
		var achievement = achievement_definitions[achievement_id]
		var unlocks = achievement.reward.get("unlocks", [])
		
		if item_id in unlocks:
			return true
	
	# Check level-based unlocks (Level 5, 10, 15, etc.)
	# This would be expanded based on specific unlock conditions
	var level = profile_manager.current_profile.get("level", 1)
	
	# Example level unlocks
	if item_id == "theme_customization" and level >= 10:
		return true
	if item_id == "avatar_level_25" and level >= 25:
		return true
	
	return false

func get_unlock_hint(item_id: String) -> String:
	"""
	Get a hint for how to unlock an item.
	
	Args:
		item_id: Item identifier
	
	Returns:
		Hint string (e.g., "Complete 10 songs to unlock")
	"""
	# Find achievements that unlock this item
	for achievement_id in achievement_definitions.keys():
		var achievement = achievement_definitions[achievement_id]
		var unlocks = achievement.reward.get("unlocks", [])
		
		if item_id in unlocks:
			var progress_data = achievement_progress[achievement_id]
			if not progress_data.unlocked:
				return achievement.description
	
	return "Complete achievements to unlock"
