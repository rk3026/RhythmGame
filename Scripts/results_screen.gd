extends Control

@export var score: int = 0
@export var max_combo: int = 0
@export var total_notes: int = 0
@export var hits_per_grade := {"perfect":0, "great":0, "good":0, "miss":0}
@export var song_title: String = ""
@export var difficulty: String = ""
@export var chart_path: String = ""  # NEW: For score history
@export var instrument: String = ""   # NEW: For score history

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
