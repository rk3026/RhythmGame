extends Node

# ScoreHistoryManager.gd - Singleton for tracking and persisting player score history
# Stores high scores, accuracy, combo records, and play statistics per song/difficulty
# NOW PROFILE-AWARE: Each profile has its own score history

const LEGACY_HISTORY_PATH := "user://score_history.cfg"  # Old global path (for migration)
const PROFILES_DIR := "user://profiles/"

# Profile-specific data
var current_profile_id: String = ""
var history_path: String = ""

# Main data structure: Dictionary of chart keys to score data
# Key format: "chart_path|difficulty+instrument"
# Example: "res://Assets/Tracks/Song1/notes.chart|ExpertSingle"
var score_data: Dictionary = {}

# Signals
signal score_updated(chart_key: String, is_new_high_score: bool)
signal history_loaded()
signal profile_changed(profile_id: String)

func _ready():
	# Don't auto-load scores - wait for ProfileManager to call set_profile()
	pass

# ============================================================================
# Profile Management
# ============================================================================

func set_profile(profile_id: String):
	"""
	Set the active profile and load its score history.
	This should be called by ProfileManager when a profile is loaded or switched.
	
	Args:
		profile_id: UUID of the profile whose scores to load
	"""
	if profile_id.is_empty():
		push_error("ScoreHistoryManager: Cannot set empty profile ID")
		return
	
	var old_profile_id = current_profile_id
	# Preserve the old history_path so we can save the old profile's scores
	var old_history_path = history_path

	# If switching from an existing profile, save its scores first (uses old_history_path)
	if not old_profile_id.is_empty() and old_profile_id != profile_id:
		print("ScoreHistoryManager: Saving scores for profile: ", old_profile_id)
		# Temporarily ensure history_path points to the old path while saving
		var tmp = history_path
		history_path = old_history_path
		save_score_history()
		history_path = tmp

	# Now switch to the new profile and load its scores
	current_profile_id = profile_id
	history_path = PROFILES_DIR + profile_id + "/scores.cfg"

	print("ScoreHistoryManager: Loading scores for profile: ", profile_id)
	load_score_history()

	emit_signal("profile_changed", profile_id)

func get_current_profile_id() -> String:
	"""Get the currently active profile ID."""
	return current_profile_id

# ============================================================================
# Core Functionality
# ============================================================================

func load_score_history():
	"""Load score history from profile-specific scores.cfg file."""
	if history_path.is_empty():
		push_warning("ScoreHistoryManager: No profile set, cannot load scores")
		emit_signal("history_loaded")
		return
	
	var cfg = ConfigFile.new()
	var err = cfg.load(history_path)
	
	if err != OK:
		push_warning("ScoreHistoryManager: No score history found for profile, starting fresh. Error: " + str(err))
		score_data.clear()
		emit_signal("history_loaded")
		return
	
	score_data.clear()
	
	for section in cfg.get_sections():
		var data = {
			"high_score": cfg.get_value(section, "high_score", 0),
			"best_accuracy": cfg.get_value(section, "best_accuracy", 0.0),
			"best_max_combo": cfg.get_value(section, "best_max_combo", 0),
			"total_notes": cfg.get_value(section, "total_notes", 0),
			"best_grade_counts": cfg.get_value(section, "best_grade_counts", {}),
			"play_count": cfg.get_value(section, "play_count", 0),
			"last_played": cfg.get_value(section, "last_played", ""),
			"first_played": cfg.get_value(section, "first_played", ""),
			"completed": cfg.get_value(section, "completed", false)
		}
		score_data[section] = data
	
	print("ScoreHistoryManager: Loaded ", score_data.size(), " score records for profile ", current_profile_id)
	emit_signal("history_loaded")

func save_score_history():
	"""Save score history to profile-specific scores.cfg file."""
	if history_path.is_empty():
		push_warning("ScoreHistoryManager: No profile set, cannot save scores")
		return
	
	var cfg = ConfigFile.new()
	
	for key in score_data.keys():
		var data = score_data[key]
		cfg.set_value(key, "high_score", data.high_score)
		cfg.set_value(key, "best_accuracy", data.best_accuracy)
		cfg.set_value(key, "best_max_combo", data.best_max_combo)
		cfg.set_value(key, "total_notes", data.total_notes)
		cfg.set_value(key, "best_grade_counts", data.best_grade_counts)
		cfg.set_value(key, "play_count", data.play_count)
		cfg.set_value(key, "last_played", data.last_played)
		cfg.set_value(key, "first_played", data.first_played)
		cfg.set_value(key, "completed", data.completed)
	
	var err = cfg.save(history_path)
	if err != OK:
		push_error("ScoreHistoryManager: Failed to save score history: " + str(err))
	else:
		print("ScoreHistoryManager: Saved ", score_data.size(), " score records for profile ", current_profile_id)

func update_score(chart_path: String, instrument: String, stats: Dictionary) -> bool:
	"""
	Update score history with new gameplay results.
	
	Args:
		chart_path: Path to chart file
		instrument: Instrument/difficulty string (e.g., "ExpertSingle")
		stats: Dictionary with keys:
			- score: int
			- max_combo: int
			- grade_counts: Dictionary {perfect, great, good, miss}
			- total_notes: int
			- completed: bool (optional, defaults to true)
	
	Returns:
		true if this was a new high score/record, false otherwise
	"""
	var key = _generate_key(chart_path, instrument)
	var is_new_high_score = false
	
	var existing = score_data.get(key, {})
	var timestamp = Time.get_datetime_string_from_system()
	
	if existing.is_empty():
		# First time playing this chart/difficulty
		score_data[key] = {
			"high_score": stats.score,
			"best_accuracy": _calculate_accuracy(stats.grade_counts, stats.total_notes),
			"best_max_combo": stats.max_combo,
			"total_notes": stats.total_notes,
			"best_grade_counts": stats.grade_counts.duplicate(),
			"play_count": 1,
			"last_played": timestamp,
			"first_played": timestamp,
			"completed": stats.get("completed", true)
		}
		is_new_high_score = true
		print("ScoreHistoryManager: New record for ", key)
	else:
		# Update existing record
		existing.play_count += 1
		existing.last_played = timestamp
		existing.completed = existing.completed or stats.get("completed", true)
		
		# Check for new records
		var new_accuracy = _calculate_accuracy(stats.grade_counts, stats.total_notes)
		
		if stats.score > existing.high_score:
			existing.high_score = stats.score
			is_new_high_score = true
			print("ScoreHistoryManager: New high score for ", key, ": ", stats.score)
		
		if new_accuracy > existing.best_accuracy:
			existing.best_accuracy = new_accuracy
			# Don't override is_new_high_score if already true
			if not is_new_high_score:
				is_new_high_score = true
			print("ScoreHistoryManager: New best accuracy for ", key, ": ", new_accuracy, "%")
		
		if stats.max_combo > existing.best_max_combo:
			existing.best_max_combo = stats.max_combo
			print("ScoreHistoryManager: New max combo for ", key, ": ", stats.max_combo)
		
		# Update best grade counts if this was the high score run
		if stats.score >= existing.high_score:
			existing.best_grade_counts = stats.grade_counts.duplicate()
	
	save_score_history()
	emit_signal("score_updated", key, is_new_high_score)
	
	return is_new_high_score

func get_score_data(chart_path: String, instrument: String) -> Dictionary:
	"""
	Retrieve score data for a specific chart/difficulty.
	
	Returns:
		Dictionary with score data, or empty Dictionary if never played
	"""
	var key = _generate_key(chart_path, instrument)
	return score_data.get(key, {})

func has_played_song(chart_path: String, instrument: String) -> bool:
	"""Check if player has ever played this chart/difficulty."""
	var key = _generate_key(chart_path, instrument)
	return score_data.has(key)

func get_all_scores() -> Dictionary:
	"""Get entire score history (for debugging/export)."""
	return score_data.duplicate()

func clear_all_scores():
	"""Clear all score history (for testing/reset). Use with caution!"""
	score_data.clear()
	save_score_history()
	print("ScoreHistoryManager: All scores cleared")

# ============================================================================
# Helper Functions
# ============================================================================

func _generate_key(chart_path: String, instrument: String) -> String:
	"""
	Generate unique key for chart/difficulty combination.
	Normalizes path separators to handle Windows/Linux differences.
	"""
	var normalized_path = chart_path.replace("\\", "/")
	return normalized_path + "|" + instrument

func _calculate_accuracy(grade_counts: Dictionary, total_notes: int) -> float:
	"""
	Calculate accuracy percentage.
	Accuracy = (notes hit / total notes) * 100
	"""
	if total_notes == 0:
		return 0.0
	
	var hit_total = grade_counts.get("perfect", 0) + \
					grade_counts.get("great", 0) + \
					grade_counts.get("good", 0)
	
	return (float(hit_total) / float(total_notes)) * 100.0
