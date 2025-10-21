extends Node

# ScoreHistoryManager.gd - Singleton for tracking and persisting player score history
# Stores high scores, accuracy, combo records, and play statistics per song/difficulty

const HISTORY_PATH := "user://score_history.cfg"

# Main data structure: Dictionary of chart keys to score data
# Key format: "chart_path|difficulty+instrument"
# Example: "res://Assets/Tracks/Song1/notes.chart|ExpertSingle"
var score_data: Dictionary = {}

# Signals
signal score_updated(chart_key: String, is_new_high_score: bool)
signal history_loaded()

func _ready():
	load_score_history()

# ============================================================================
# Core Functionality
# ============================================================================

func load_score_history():
	var cfg = ConfigFile.new()
	var err = cfg.load(HISTORY_PATH)
	
	if err != OK:
		push_warning("No score history found, starting fresh. Error: " + str(err))
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
	
	print("ScoreHistoryManager: Loaded ", score_data.size(), " score records")
	emit_signal("history_loaded")

func save_score_history():
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
	
	var err = cfg.save(HISTORY_PATH)
	if err != OK:
		push_error("Failed to save score history: " + str(err))
	else:
		print("ScoreHistoryManager: Saved ", score_data.size(), " score records")

func update_score(chart_path: String, instrument: String, stats: Dictionary) -> bool:
	"""
	Update score history with new gameplay results.
	
	Args:
		chart_path: Path to chart file
		instrument: Instrument/difficulty string (e.g., "ExpertSingle")
		stats: Dictionary with keys:
			- score: int
			- max_combo: int
			- grade_counts: Dictionary {perfect, great, good, bad, miss}
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
					grade_counts.get("good", 0) + \
					grade_counts.get("bad", 0)
	
	return (float(hit_total) / float(total_notes)) * 100.0
