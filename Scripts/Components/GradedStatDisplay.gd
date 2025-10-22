extends VBoxContainer

# GradedStatDisplay: Displays performance statistics with animations
# Shows score, combo, accuracy with color-coded grade breakdown

@export_group("Data")
@export var score: int = 0
@export var max_combo: int = 0
@export var accuracy: float = 0.0
@export var grade_counts: Dictionary = {"perfect": 0, "great": 0, "good": 0, "bad": 0, "miss": 0}

@export_group("Animation")
@export var enable_count_up: bool = true
@export var count_up_duration: float = 1.5
@export var stagger_delay: float = 0.2

@export_group("Visual")
@export var show_progress_bars: bool = true
@export var show_rank_badge: bool = true
@export var show_comparison: bool = false

# Comparison data (optional)
var previous_score: int = 0
var previous_accuracy: float = 0.0
var previous_combo: int = 0

# Internal nodes
var _score_label: Label
var _combo_label: Label
var _accuracy_label: Label
var _rank_badge: Label
var _breakdown_container: VBoxContainer

func _ready() -> void:
	_build_ui()
	if enable_count_up:
		_animate_stats()
	else:
		_update_stats_immediate()

func _build_ui() -> void:
	# Score label
	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 32)
	add_child(_score_label)
	
	# Combo label
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 32)
	add_child(_combo_label)
	
	# Accuracy label with rank badge
	var accuracy_hbox = HBoxContainer.new()
	accuracy_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(accuracy_hbox)
	
	_accuracy_label = Label.new()
	_accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accuracy_label.add_theme_font_size_override("font_size", 32)
	accuracy_hbox.add_child(_accuracy_label)
	
	if show_rank_badge:
		_rank_badge = Label.new()
		_rank_badge.add_theme_font_size_override("font_size", 48)
		accuracy_hbox.add_child(_rank_badge)
	
	# Grade breakdown
	_breakdown_container = VBoxContainer.new()
	_breakdown_container.add_theme_constant_override("separation", 5)
	add_child(_breakdown_container)
	
	_build_grade_rows()

func _build_grade_rows() -> void:
	var grades = ["perfect", "great", "good", "bad", "miss"]
	var grade_colors = {
		"perfect": Color.GOLD,
		"great": Color(0.3, 1.0, 0.3),
		"good": Color(0.3, 0.8, 1.0),
		"bad": Color.ORANGE,
		"miss": Color.RED
	}
	var grade_icons = {
		"perfect": "✦",
		"great": "★",
		"good": "●",
		"bad": "◆",
		"miss": "✕"
	}
	
	for grade in grades:
		var hbox = HBoxContainer.new()
		hbox.name = "Grade_" + grade
		
		# Icon
		var icon = Label.new()
		icon.text = grade_icons[grade]
		icon.modulate = grade_colors[grade]
		icon.add_theme_font_size_override("font_size", 24)
		icon.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(icon)
		
		# Grade name
		var name_label = Label.new()
		name_label.text = grade.capitalize() + ":"
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)
		
		# Count
		var count_label = Label.new()
		count_label.name = "Count"
		count_label.text = "0"
		count_label.add_theme_font_size_override("font_size", 24)
		count_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(count_label)
		
		# Progress bar (optional)
		if show_progress_bars:
			var progress = ProgressBar.new()
			progress.name = "Progress"
			progress.custom_minimum_size = Vector2(200, 20)
			progress.max_value = 100.0
			progress.value = 0.0
			progress.show_percentage = false
			# Style the progress bar with grade color
			var style = StyleBoxFlat.new()
			style.bg_color = grade_colors[grade]
			progress.add_theme_stylebox_override("fill", style)
			hbox.add_child(progress)
		
		_breakdown_container.add_child(hbox)

func _update_stats_immediate() -> void:
	_score_label.text = "Score: " + _format_number(score)
	_combo_label.text = "Max Combo: " + str(max_combo)
	_accuracy_label.text = "Accuracy: " + ("%.1f" % accuracy) + "%"
	
	if show_rank_badge and _rank_badge:
		_rank_badge.text = " " + _get_rank_for_accuracy(accuracy)
		_rank_badge.modulate = _get_rank_color(accuracy)
	
	# Update grade breakdown
	var total_notes = 0
	for grade in grade_counts.keys():
		total_notes += grade_counts[grade]
	
	for grade in grade_counts.keys():
		var row = _breakdown_container.get_node_or_null("Grade_" + grade)
		if row:
			var count_label = row.get_node("Count")
			count_label.text = str(grade_counts[grade])
			
			if show_progress_bars:
				var progress = row.get_node_or_null("Progress")
				if progress and total_notes > 0:
					progress.value = (float(grade_counts[grade]) / float(total_notes)) * 100.0
	
	# Show comparison if enabled
	if show_comparison:
		_add_comparison_indicators()

func _animate_stats() -> void:
	# Animate score count-up
	var score_tween = create_tween()
	score_tween.tween_method(_update_score_label, 0, score, count_up_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Animate combo count-up
	await get_tree().create_timer(stagger_delay).timeout
	var combo_tween = create_tween()
	combo_tween.tween_method(_update_combo_label, 0, max_combo, count_up_duration * 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Animate accuracy count-up
	await get_tree().create_timer(stagger_delay).timeout
	var acc_tween = create_tween()
	acc_tween.tween_method(_update_accuracy_label, 0.0, accuracy, count_up_duration * 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Animate grade counts
	await get_tree().create_timer(stagger_delay).timeout
	_animate_grade_breakdown()

func _update_score_label(value: int) -> void:
	_score_label.text = "Score: " + _format_number(value)

func _update_combo_label(value: int) -> void:
	_combo_label.text = "Max Combo: " + str(value)

func _update_accuracy_label(value: float) -> void:
	_accuracy_label.text = "Accuracy: " + ("%.1f" % value) + "%"
	
	if show_rank_badge and _rank_badge:
		_rank_badge.text = " " + _get_rank_for_accuracy(value)
		_rank_badge.modulate = _get_rank_color(value)

func _animate_grade_breakdown() -> void:
	var total_notes = 0
	for grade in grade_counts.keys():
		total_notes += grade_counts[grade]
	
	var delay = 0.0
	for grade in ["perfect", "great", "good", "bad", "miss"]:
		var row = _breakdown_container.get_node_or_null("Grade_" + grade)
		if row:
			var count_label = row.get_node("Count")
			var target_count = grade_counts.get(grade, 0)
			
			# Animate count
			var count_tween = create_tween()
			count_tween.tween_method(
				func(val): count_label.text = str(int(val)),
				0, target_count, 0.5
			).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			
			# Animate progress bar
			if show_progress_bars:
				var progress = row.get_node_or_null("Progress")
				if progress and total_notes > 0:
					var target_value = (float(target_count) / float(total_notes)) * 100.0
					var progress_tween = create_tween()
					progress_tween.tween_property(progress, "value", target_value, 0.5).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			
			delay += 0.1

func _add_comparison_indicators() -> void:
	if previous_score > 0:
		var score_diff = score - previous_score
		if score_diff != 0:
			_score_label.bbcode_enabled = true
			var color = "green" if score_diff > 0 else "gray"
			var arrow = "↑" if score_diff > 0 else "↓"
			var prefix = "+" if score_diff > 0 else ""
			_score_label.text += " [color=" + color + "](" + prefix + _format_number(score_diff) + ") " + arrow + "[/color]"
	
	if previous_accuracy > 0.0:
		var acc_diff = accuracy - previous_accuracy
		if abs(acc_diff) > 0.05:
			_accuracy_label.bbcode_enabled = true
			var color = "green" if acc_diff > 0 else "gray"
			var arrow = "↑" if acc_diff > 0 else "↓"
			var prefix = "+" if acc_diff > 0 else ""
			_accuracy_label.text += " [color=" + color + "](" + prefix + ("%.1f" % acc_diff) + "%) " + arrow + "[/color]"
	
	if previous_combo > 0:
		var combo_diff = max_combo - previous_combo
		if combo_diff != 0:
			_combo_label.bbcode_enabled = true
			var color = "green" if combo_diff > 0 else "gray"
			var arrow = "↑" if combo_diff > 0 else "↓"
			var prefix = "+" if combo_diff > 0 else ""
			_combo_label.text += " [color=" + color + "](" + prefix + str(combo_diff) + ") " + arrow + "[/color]"

func _format_number(num: int) -> String:
	var num_str = str(abs(num))
	var formatted = ""
	var count = 0
	
	for i in range(num_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = num_str[i] + formatted
		count += 1
	
	if num < 0:
		formatted = "-" + formatted
	
	return formatted

func _get_rank_for_accuracy(acc: float) -> String:
	if acc >= 99.0:
		return "S"
	elif acc >= 95.0:
		return "A"
	elif acc >= 90.0:
		return "B"
	elif acc >= 80.0:
		return "C"
	elif acc >= 70.0:
		return "D"
	else:
		return "F"

func _get_rank_color(acc: float) -> Color:
	if acc >= 99.0:
		return Color.GOLD
	elif acc >= 95.0:
		return Color(0.75, 0.75, 0.75)  # Silver
	elif acc >= 90.0:
		return Color(0.8, 0.5, 0.2)     # Bronze
	elif acc >= 80.0:
		return Color(0.5, 0.7, 1.0)     # Light blue
	elif acc >= 70.0:
		return Color.ORANGE
	else:
		return Color.RED

# Public methods
func set_stats(p_score: int, p_combo: int, p_accuracy: float, p_grades: Dictionary) -> void:
	score = p_score
	max_combo = p_combo
	accuracy = p_accuracy
	grade_counts = p_grades
	
	if is_inside_tree():
		if enable_count_up:
			_animate_stats()
		else:
			_update_stats_immediate()

func set_comparison_data(prev_score: int, prev_acc: float, prev_combo: int) -> void:
	previous_score = prev_score
	previous_accuracy = prev_acc
	previous_combo = prev_combo
	show_comparison = true
