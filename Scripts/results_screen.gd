extends Control

@export var score: int = 0
@export var max_combo: int = 0
@export var total_notes: int = 0
@export var hits_per_grade := {"perfect":0, "great":0, "good":0, "miss":0}
@export var song_title: String = ""
@export var difficulty: String = ""
@export var chart_path: String = ""
@export var instrument: String = ""

# Profile system integration
var xp_earned: int = 0
var leveled_up: bool = false
var new_level: int = 0
var old_level: int = 0
var unlocked_achievements: Array = []

# Component references
@onready var title_label: Label = $ScrollContainer/MainVBox/TitleLabel
@onready var rank_display = $ScrollContainer/MainVBox/RankDisplay
@onready var score_card = $ScrollContainer/MainVBox/StatsHBox/ScoreCard
@onready var accuracy_card = $ScrollContainer/MainVBox/StatsHBox/AccuracyCard
@onready var combo_card = $ScrollContainer/MainVBox/StatsHBox/ComboCard
@onready var judgment_breakdown = $ScrollContainer/MainVBox/JudgmentBreakdown
@onready var progression_display = $ScrollContainer/MainVBox/ProgressionDisplay
@onready var retry_button: Button = $ScrollContainer/MainVBox/ButtonsContainer/ButtonsHBox/RetryButton
@onready var menu_button: Button = $ScrollContainer/MainVBox/ButtonsContainer/ButtonsHBox/MenuButton

func _ready():
	# Set title
	var readable_difficulty = difficulty.replace("Single", " Single").replace("Double", " Double")
	title_label.text = song_title + " (" + readable_difficulty + ")"
	
	# Calculate accuracy
	var accuracy = calculate_accuracy()
	
	# Update rank display
	var rank = rank_display.calculate_rank_from_accuracy(accuracy)
	rank_display.set_rank(rank, true)
	
	# Update stat cards (without comparison initially)
	score_card.set_stat("SCORE", _format_score(score))
	accuracy_card.set_stat("ACCURACY", "%.1f%%" % accuracy)
	combo_card.set_stat("MAX COMBO", "x%d" % max_combo)
	
	# Update judgment breakdown
	judgment_breakdown.set_judgments(
		hits_per_grade.perfect,
		hits_per_grade.great,
		hits_per_grade.good,
		hits_per_grade.miss,
		total_notes
	)
	
	# Update score history and show comparisons
	_update_score_history()
	
	# Update profile statistics and progression
	_update_profile_stats()
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	
	# Add hover effects to buttons
	_add_hover_effects(retry_button)
	_add_hover_effects(menu_button)

func calculate_accuracy() -> float:
	var hit_total = hits_per_grade.perfect + hits_per_grade.great + hits_per_grade.good
	if total_notes == 0:
		return 0.0
	return round((float(hit_total) / float(total_notes)) * 1000.0) / 10.0

func _format_score(value: int) -> String:
	"""Format score with comma separators."""
	var score_str = str(value)
	var result = ""
	var count = 0
	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = score_str[i] + result
		count += 1
	return result

func _on_retry():
	# Reload gameplay with same chart/difficulty
	var gameplay = load("res://Scenes/gameplay.tscn").instantiate()
	gameplay.chart_path = ProjectSettings.get_setting("application/run/last_chart_path", "")
	gameplay.instrument = ProjectSettings.get_setting("application/run/last_instrument", "")
	SceneSwitcher.pop_scene()  # Remove results
	SceneSwitcher.replace_scene_instance(gameplay)  # Replace old gameplay

func _on_menu():
	SceneSwitcher.pop_scene()  # Remove results
	SceneSwitcher.pop_scene()  # Remove gameplay
	# Now song_select is shown

func _add_hover_effects(button: Button):
	if button:
		button.connect("mouse_entered", Callable(self, "_on_button_hover_enter").bind(button))
		button.connect("mouse_exited", Callable(self, "_on_button_hover_exit").bind(button))
		button.pivot_offset = button.size / 2.0

func _on_button_hover_enter(button: Button):
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_button_hover_exit(button: Button):
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

# ============================================================================
# Score History Integration
# ============================================================================

func _update_score_history():
	"""Update score history and display new record indicators."""
	# Skip if chart path not provided (shouldn't happen in normal gameplay)
	if chart_path.is_empty() or instrument.is_empty():
		push_warning("Results screen missing chart_path or instrument, skipping score history update")
		return
	
	# Prepare stats dictionary
	var stats = {
		"score": score,
		"max_combo": max_combo,
		"grade_counts": hits_per_grade,
		"total_notes": total_notes,
		"completed": true  # Reached results screen = completed song
	}
	
	# Get previous best for comparison (before updating)
	var previous = ScoreHistoryManager.get_score_data(chart_path, instrument)
	
	# Update history
	var is_new_record = ScoreHistoryManager.update_score(chart_path, instrument, stats)
	
	# Display indicators
	if previous.is_empty():
		# First time playing this chart/difficulty - no comparison
		score_card.hide_comparison()
		accuracy_card.hide_comparison()
		combo_card.hide_comparison()
	elif is_new_record:
		# New personal record!
		rank_display.show_new_record_badge()
		_show_comparison(previous, stats)
	else:
		# No new record, but still show comparison
		_show_comparison(previous, stats)

func _show_comparison(previous: Dictionary, current: Dictionary):
	"""Show improvement indicators comparing to previous best."""
	var current_acc = calculate_accuracy()
	var score_diff = current.score - previous.high_score
	var acc_diff = current_acc - previous.best_accuracy
	var combo_diff = current.max_combo - previous.best_max_combo
	
	# Update stat cards with comparisons
	score_card.set_comparison(score_diff, false)
	accuracy_card.set_comparison(acc_diff, true)
	combo_card.set_comparison(combo_diff, false)

# ============================================================================
# Profile System Integration
# ============================================================================

func _update_profile_stats():
	"""Update profile statistics, XP, and check achievements."""
	# Skip if no active profile
	if ProfileManager.current_profile.is_empty():
		push_warning("Results screen: No active profile, skipping profile update")
		return
	
	# Skip if chart path not provided
	if chart_path.is_empty() or instrument.is_empty():
		push_warning("Results screen missing chart_path or instrument, skipping profile update")
		return
	
	# Prepare stats dictionary
	var stats = {
		"score": score,
		"max_combo": max_combo,
		"grade_counts": hits_per_grade,
		"total_notes": total_notes,
		"accuracy": calculate_accuracy(),
		"completed": true,
		"difficulty": difficulty,
		"instrument": instrument
	}
	
	# Store old level for comparison
	old_level = ProfileManager.current_profile.level
	
	# Update profile statistics (song completion, notes hit, etc.)
	ProfileManager.record_song_completion(chart_path, difficulty, stats)
	
	# Calculate and award XP
	xp_earned = _calculate_xp_earned(stats)
	if xp_earned > 0:
		leveled_up = ProfileManager.add_xp(xp_earned)
		if leveled_up:
			new_level = ProfileManager.current_profile.level
	
	# Check achievements
	_check_achievements_unlocked(stats)
	
	# Display profile feedback
	_display_xp_earned()
	if leveled_up:
		_display_level_up()
	_display_achievements_unlocked()
	
	# Save profile
	ProfileManager.save_profile()

func _calculate_xp_earned(stats: Dictionary) -> int:
	"""
	Calculate XP earned based on performance.
	
	Formula:
	- Base XP: 50
	- Score bonus: score / 1000 (1 XP per 1000 points)
	- Accuracy bonus: accuracy * 2 (max 200 XP for 100% accuracy)
	- Combo bonus: max_combo / 10 (1 XP per 10 combo)
	- Completion bonus: 100 XP for completing the song
	- Difficulty multiplier: Easy 1.0x, Medium 1.25x, Hard 1.5x, Expert 2.0x
	"""
	var base_xp = 50
	var score_bonus = stats.score / 1000
	var accuracy_bonus = int(stats.accuracy * 2.0)
	var combo_bonus = stats.max_combo / 10
	var completion_bonus = 100 if stats.completed else 0
	
	# Difficulty multiplier
	var difficulty_mult = 1.0
	if "Expert" in difficulty:
		difficulty_mult = 2.0
	elif "Hard" in difficulty:
		difficulty_mult = 1.5
	elif "Medium" in difficulty:
		difficulty_mult = 1.25
	# Easy = 1.0
	
	var total_xp = int((base_xp + score_bonus + accuracy_bonus + combo_bonus + completion_bonus) * difficulty_mult)
	return total_xp

func _check_achievements_unlocked(stats: Dictionary):
	"""Check for newly unlocked achievements after this song."""
	# Connect to achievement_unlocked signal if not already connected
	if not AchievementManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# Load current profile's achievements
	AchievementManager.load_profile_achievements(ProfileManager.current_profile_id)
	
	# Check achievements based on song stats
	AchievementManager.check_achievements_after_song(stats)

func _on_achievement_unlocked(_achievement_id: String, achievement_data: Dictionary):
	"""Called when an achievement is unlocked during results screen."""
	unlocked_achievements.append(achievement_data)

func _display_xp_earned():
	"""Display XP earned with animation."""
	progression_display.set_xp_earned(xp_earned, true)

func _display_level_up():
	"""Display LEVEL UP notification with celebration animation."""
	if leveled_up:
		progression_display.set_level_up(old_level, new_level, true)

func _display_achievements_unlocked():
	"""Display notifications for any achievements unlocked during this song."""
	progression_display.set_achievements(unlocked_achievements)

