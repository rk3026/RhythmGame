extends Control

@export var score: int = 0
@export var max_combo: int = 0
@export var total_notes: int = 0
@export var hits_per_grade := {"perfect":0, "great":0, "good":0, "miss":0}
@export var song_title: String = ""
@export var difficulty: String = ""
@export var chart_path: String = ""  # NEW: For score history
@export var instrument: String = ""   # NEW: For score history

# Profile system integration
var xp_earned: int = 0
var leveled_up: bool = false
var new_level: int = 0
var old_level: int = 0
var unlocked_achievements: Array = []

func _ready():
	var readable_difficulty = difficulty.replace("Single", " Single").replace("Double", " Double")
	$VBox/TitleLabel.text = song_title + " (" + readable_difficulty + ")"
	$VBox/StatsContainer/StatsVBox/ScoreLabel.text = "Score: " + str(int(score))
	$VBox/StatsContainer/StatsVBox/ComboLabel.text = "Max Combo: " + str(max_combo)
	var acc = calculate_accuracy()
	$VBox/StatsContainer/StatsVBox/AccuracyLabel.text = "Accuracy: " + str(acc) + "%"
	$VBox/StatsContainer/StatsVBox/BreakdownLabel.text = breakdown_text()
	
	# NEW: Update score history and show indicators
	_update_score_history()
	
	# NEW: Update profile statistics and progression
	_update_profile_stats()
	
	$VBox/Buttons/ButtonsHBox/RetryButton.connect("pressed", Callable(self, "_on_retry"))
	$VBox/Buttons/ButtonsHBox/MenuButton.connect("pressed", Callable(self, "_on_menu"))
	
	# Add hover effects to buttons
	_add_hover_effects($VBox/Buttons/ButtonsHBox/RetryButton)
	_add_hover_effects($VBox/Buttons/ButtonsHBox/MenuButton)

func calculate_accuracy() -> float:
	var hit_total = hits_per_grade.perfect + hits_per_grade.great + hits_per_grade.good
	if total_notes == 0:
		return 0.0
	return round((float(hit_total) / float(total_notes)) * 1000.0) / 10.0

func breakdown_text() -> String:
	return "Perfect: %d\nGreat: %d\nGood: %d\nMiss: %d" % [
		hits_per_grade.perfect,
		hits_per_grade.great,
		hits_per_grade.good,
		hits_per_grade.miss
	]

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
		# First time playing this chart/difficulty
		_show_first_clear_indicator()
	elif is_new_record:
		# New personal record!
		_show_new_record_indicator()
		_show_comparison(previous, stats)
	else:
		# No new record, but still show comparison
		_show_comparison(previous, stats)

func _show_new_record_indicator():
	"""Display 'NEW RECORD!' banner with animation."""
	var label = Label.new()
	label.text = "🏆 NEW RECORD!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = Color.GOLD
	
	# Insert after title
	$VBox.add_child(label)
	$VBox.move_child(label, 1)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)

func _show_first_clear_indicator():
	"""Display 'FIRST CLEAR!' badge."""
	var label = Label.new()
	label.text = "⭐ FIRST CLEAR!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.modulate = Color.CYAN
	
	# Insert after title
	$VBox.add_child(label)
	$VBox.move_child(label, 1)
	
	# Fade in animation
	label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)

func _show_comparison(previous: Dictionary, current: Dictionary):
	"""Show improvement indicators comparing to previous best."""
	var current_acc = calculate_accuracy()
	var score_diff = current.score - previous.high_score
	var acc_diff = current_acc - previous.best_accuracy
	var combo_diff = current.max_combo - previous.best_max_combo
	
	# Update score label with difference (plain text, no BBCode for Label nodes)
	if score_diff > 0:
		$VBox/StatsContainer/StatsVBox/ScoreLabel.text += " (+" + StringFormatter.format_score(score_diff) + ") ↑"
	elif score_diff < 0:
		$VBox/StatsContainer/StatsVBox/ScoreLabel.text += " (" + StringFormatter.format_score(score_diff) + ") ↓"
	
	# Update accuracy label with difference
	if acc_diff > 0.05:  # Only show if meaningful difference (>0.05%)
		$VBox/StatsContainer/StatsVBox/AccuracyLabel.text += " (+" + ("%.1f" % acc_diff) + "%) ↑"
	elif acc_diff < -0.05:
		$VBox/StatsContainer/StatsVBox/AccuracyLabel.text += " (" + ("%.1f" % acc_diff) + "%) ↓"
	
	# Update combo label with difference
	if combo_diff > 0:
		$VBox/StatsContainer/StatsVBox/ComboLabel.text += " (+" + str(combo_diff) + ") ↑"
	elif combo_diff < 0:
		$VBox/StatsContainer/StatsVBox/ComboLabel.text += " (" + str(combo_diff) + ") ↓"

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
	if xp_earned <= 0:
		return
	
	var xp_label = Label.new()
	xp_label.text = "+ " + str(xp_earned) + " XP"
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.modulate = Color(0.5, 1.0, 0.5)  # Light green
	
	# Add to UI (after breakdown)
	$VBox/StatsContainer/StatsVBox.add_child(xp_label)
	
	# Fade in animation
	xp_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(xp_label, "modulate:a", 1.0, 0.5)

func _display_level_up():
	"""Display LEVEL UP notification with celebration animation."""
	var level_up_label = Label.new()
	level_up_label.text = "🎉 LEVEL UP! " + str(old_level) + " → " + str(new_level) + " 🎉"
	level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_label.add_theme_font_size_override("font_size", 36)
	level_up_label.modulate = Color(1.0, 0.84, 0.0)  # Gold
	
	# Insert near top (after title and any record indicators)
	$VBox.add_child(level_up_label)
	$VBox.move_child(level_up_label, 1)
	
	# Pulsing + color shifting animation
	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(level_up_label, "scale", Vector2(1.1, 1.1), 0.4)
	tween.tween_property(level_up_label, "modulate", Color(1.0, 1.0, 0.5), 0.4)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(level_up_label, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_property(level_up_label, "modulate", Color(1.0, 0.84, 0.0), 0.4)

func _display_achievements_unlocked():
	"""Display notifications for any achievements unlocked during this song."""
	if unlocked_achievements.is_empty():
		return
	
	# Create container for achievement notifications
	var achievements_container = VBoxContainer.new()
	achievements_container.name = "AchievementsContainer"
	
	# Add header
	var header = Label.new()
	header.text = "🏆 ACHIEVEMENTS UNLOCKED 🏆"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.modulate = Color.GOLD
	achievements_container.add_child(header)
	
	# Add each achievement
	for achievement in unlocked_achievements:
		var ach_label = Label.new()
		ach_label.text = "  ★ " + achievement.name
		ach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ach_label.add_theme_font_size_override("font_size", 20)
		ach_label.modulate = Color(0.8, 0.8, 1.0)  # Light blue
		achievements_container.add_child(ach_label)
	
	# Add to main UI (before buttons)
	$VBox.add_child(achievements_container)
	$VBox.move_child(achievements_container, $VBox.get_child_count() - 2)  # Before buttons
	
	# Fade in animation
	achievements_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(achievements_container, "modulate:a", 1.0, 0.6)

