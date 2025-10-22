extends HBoxContainer
class_name DifficultyIndicator

## Reusable difficulty display component with star/tier rating
## Shows difficulty level with visual indicators (stars, colors) and optional metadata
## Usage: DifficultyIndicator.create(3, "Medium", 450) for 3 stars, "Medium" label, 450 notes

signal difficulty_selected(level: int)

@export_group("Display Settings")
@export var max_stars: int = 5
@export var star_size: int = 24
@export var show_label: bool = true
@export var show_note_count: bool = false

@export_group("Colors")
@export var filled_star_color: Color = Color(1.0, 0.85, 0.0)  # Gold
@export var empty_star_color: Color = Color(0.3, 0.3, 0.3)
@export var selected_outline_color: Color = Color(0.2, 0.8, 1.0)

@export_group("Animation")
@export var enable_hover: bool = true
@export var enable_selection: bool = false
@export var animation_speed: float = 0.3

# Difficulty tier colors
const TIER_COLORS = {
	1: Color(0.4, 0.8, 0.4),   # Green - Easy
	2: Color(0.5, 0.9, 1.0),   # Light Blue - Medium
	3: Color(1.0, 0.7, 0.0),   # Orange - Hard
	4: Color(1.0, 0.3, 0.3),   # Red - Expert
	5: Color(0.8, 0.2, 1.0)    # Purple - Master
}

var _current_level: int = 0
var _difficulty_name: String = ""
var _note_count: int = 0
var _is_selected: bool = false
var _star_labels: Array = []
var _label_node: Label = null
var _note_label: Label = null

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_build_display()
	
	if enable_hover or enable_selection:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	
	if enable_selection:
		gui_input.connect(_on_gui_input)

func _build_display() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	_star_labels.clear()
	
	# Stars container
	var stars_container = HBoxContainer.new()
	stars_container.add_theme_constant_override("separation", 2)
	add_child(stars_container)
	
	for i in range(max_stars):
		var star_label = Label.new()
		star_label.text = "★"
		star_label.add_theme_font_size_override("font_size", star_size)
		star_label.add_theme_color_override("font_color", empty_star_color)
		star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stars_container.add_child(star_label)
		_star_labels.append(star_label)
	
	# Difficulty label
	if show_label:
		_label_node = Label.new()
		_label_node.add_theme_font_size_override("font_size", 16)
		_label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label_node)
	
	# Note count label
	if show_note_count:
		_note_label = Label.new()
		_note_label.add_theme_font_size_override("font_size", 14)
		_note_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_note_label)
	
	_update_display()

func set_difficulty(level: int, diff_name: String = "", notes: int = 0) -> void:
	_current_level = clampi(level, 0, max_stars)
	_difficulty_name = diff_name
	_note_count = notes
	_update_display()

func _update_display() -> void:
	# Update stars
	var tier_color = TIER_COLORS.get(_current_level, filled_star_color)
	for i in range(_star_labels.size()):
		var star: Label = _star_labels[i]
		if i < _current_level:
			star.add_theme_color_override("font_color", tier_color)
		else:
			star.add_theme_color_override("font_color", empty_star_color)
	
	# Update label
	if _label_node:
		_label_node.text = _difficulty_name if _difficulty_name != "" else ""
		_label_node.add_theme_color_override("font_color", tier_color)
	
	# Update note count
	if _note_label:
		_note_label.text = "(%d notes)" % _note_count if _note_count > 0 else ""
	
	# Update selection outline
	_update_selection_style()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_selection_style()

func _update_selection_style() -> void:
	if not enable_selection:
		return
	
	if _is_selected:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = selected_outline_color
		style.set_border_width_all(2)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 8
		style.content_margin_top = 4
		style.content_margin_right = 8
		style.content_margin_bottom = 4
		add_theme_stylebox_override("panel", style)
	else:
		remove_theme_stylebox_override("panel")

func _on_mouse_entered() -> void:
	if enable_hover:
		_animate_hover(true)

func _on_mouse_exited() -> void:
	if enable_hover:
		_animate_hover(false)

func _animate_hover(is_hovering: bool) -> void:
	var tween = create_tween().set_parallel(true)
	var target_scale = 1.05 if is_hovering else 1.0
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), animation_speed)

func _on_gui_input(event: InputEvent) -> void:
	if enable_selection and event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			set_selected(true)
			difficulty_selected.emit(_current_level)

func animate_fill() -> void:
	"""Animate stars filling in sequence"""
	for i in range(_current_level):
		var star: Label = _star_labels[i]
		var delay = i * 0.1
		
		# Reset scale
		star.scale = Vector2.ZERO
		
		# Animate pop-in
		var tween = create_tween()
		tween.tween_property(star, "scale", Vector2(1.2, 1.2), 0.15).set_delay(delay)
		tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.1)

static func create(level: int, diff_name: String = "", notes: int = 0):
	"""Static factory method to create and configure a DifficultyIndicator"""
	var script_path = "res://Scripts/Components/DifficultyIndicator.gd"
	var indicator_script = load(script_path)
	var indicator = indicator_script.new()
	indicator.set_difficulty(level, diff_name, notes)
	return indicator
