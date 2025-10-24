extends VBoxContainer
class_name LevelIndicator

# LevelIndicator.gd - Display component for player level and XP progress
# Shows current level, XP bar, and XP text

@export var show_xp_text: bool = true
@export var show_level_icon: bool = true

var current_level: int = 1
var current_xp: int = 0
var total_xp: int = 0

# UI elements
var level_hbox: HBoxContainer
var level_icon: TextureRect
var level_label: Label
var xp_bar: ProgressBar
var xp_label: Label

func _ready():
	_build_ui()
	_update_display()

func _build_ui():
	"""Build the level indicator UI."""
	# Level display (icon + label)
	level_hbox = HBoxContainer.new()
	level_hbox.add_theme_constant_override("separation", 5)
	add_child(level_hbox)
	
	if show_level_icon:
		level_icon = TextureRect.new()
		level_icon.custom_minimum_size = Vector2(32, 32)
		level_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		level_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Use star icon as level indicator
		if ResourceLoader.exists("res://Assets/Profiles/Avatars/star_gold.svg"):
			level_icon.texture = load("res://Assets/Profiles/Avatars/star_gold.svg")
		level_hbox.add_child(level_icon)
	
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
	level_hbox.add_child(level_label)
	
	# XP Progress bar
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(200, 24)
	xp_bar.show_percentage = false
	add_child(xp_bar)
	
	# XP text (optional)
	if show_xp_text:
		xp_label = Label.new()
		xp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(xp_label)

func set_level_data(level: int, xp: int, total: int):
	"""
	Update the level indicator with current data.
	
	Args:
		level: Current player level
		xp: XP towards next level
		total: Total XP accumulated
	"""
	current_level = level
	current_xp = xp
	total_xp = total
	_update_display()

func _update_display():
	"""Update UI elements with current data."""
	# Update level label
	if level_label:
		level_label.text = "Level " + str(current_level)
	
	# Calculate XP for next level
	var xp_for_next = _calculate_xp_for_next_level()
	
	# Update progress bar
	if xp_bar:
		var progress = float(current_xp) / float(xp_for_next) if xp_for_next > 0 else 0.0
		xp_bar.value = progress * 100.0
		xp_bar.tooltip_text = str(current_xp) + " / " + str(xp_for_next) + " XP to Level " + str(current_level + 1)
	
	# Update XP label
	if xp_label and show_xp_text:
		xp_label.text = str(current_xp) + " / " + str(xp_for_next) + " XP"

func _calculate_xp_for_next_level() -> int:
	"""Calculate XP required for next level using ProfileManager's formula."""
	var next_level = current_level + 1
	# Formula: level = floor(0.1 * sqrt(total_xp))
	# Inverse: total_xp = (10 * level)^2 = 100 * level^2
	var xp_for_next_level = 100 * next_level * next_level
	return xp_for_next_level

func animate_xp_gain(xp_amount: int):
	"""Animate XP bar filling up when XP is gained."""
	if not xp_bar:
		return
	
	var old_xp = current_xp
	current_xp += xp_amount
	
	var xp_for_next = _calculate_xp_for_next_level()
	var old_progress = float(old_xp) / float(xp_for_next)
	var new_progress = float(current_xp) / float(xp_for_next)
	
	var tween = create_tween()
	tween.tween_method(_update_progress_value, old_progress * 100.0, new_progress * 100.0, 1.0)
	tween.finished.connect(_update_display)

func _update_progress_value(value: float):
	"""Helper for animating progress bar."""
	xp_bar.value = value

func pulse():
	"""Play a pulse animation to draw attention."""
	if level_label:
		var tween = create_tween()
		tween.tween_property(level_label, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(level_label, "scale", Vector2.ONE, 0.2)
