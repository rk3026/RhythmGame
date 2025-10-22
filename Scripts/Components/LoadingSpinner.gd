extends VBoxContainer
class_name LoadingSpinner

## Reusable loading/waiting indicator with multiple animation styles
## Shows animated spinner with optional progress bar, percentage, and rotating tips
## Usage: LoadingSpinner.create(LoadingSpinner.SpinnerStyle.DOTS, "Loading chart...")

enum SpinnerStyle {
	DOTS,       # Three dots bouncing
	BARS,       # Vertical bars oscillating
	CIRCLE,     # Rotating circle segments
	PULSE       # Pulsing single element
}

@export_group("Display Settings")
@export var spinner_style: SpinnerStyle = SpinnerStyle.CIRCLE
@export var show_message: bool = true
@export var show_progress: bool = false
@export var show_tips: bool = false

@export_group("Animation")
@export var animation_speed: float = 1.0
@export var spinner_color: Color = Color(0.2, 0.8, 1.0)
@export var tip_rotation_interval: float = 3.0

@export_group("Sizing")
@export var spinner_size: int = 64
@export var message_font_size: int = 18
@export var tip_font_size: int = 14

var _spinner_container: Control = null
var _message_label: Label = null
var _progress_bar: ProgressBar = null
var _tip_label: Label = null
var _animation_tween: Tween = null
var _tip_timer: Timer = null
var _current_progress: float = 0.0
var _loading_tips: Array[String] = []
var _current_tip_index: int = 0

func _ready() -> void:
	add_theme_constant_override("separation", 15)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_build_spinner()
	_start_animation()
	
	if show_tips and _loading_tips.size() > 0:
		_start_tip_rotation()

func _build_spinner() -> void:
	# Spinner container
	_spinner_container = Control.new()
	_spinner_container.custom_minimum_size = Vector2(spinner_size, spinner_size)
	add_child(_spinner_container)
	
	# Build specific spinner style
	match spinner_style:
		SpinnerStyle.DOTS:
			_build_dots_spinner()
		SpinnerStyle.BARS:
			_build_bars_spinner()
		SpinnerStyle.CIRCLE:
			_build_circle_spinner()
		SpinnerStyle.PULSE:
			_build_pulse_spinner()
	
	# Message label
	if show_message:
		_message_label = Label.new()
		_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_message_label.add_theme_font_size_override("font_size", message_font_size)
		add_child(_message_label)
	
	# Progress bar
	if show_progress:
		_progress_bar = ProgressBar.new()
		_progress_bar.custom_minimum_size = Vector2(300, 10)
		_progress_bar.max_value = 100
		_progress_bar.value = 0
		_progress_bar.show_percentage = true
		add_child(_progress_bar)
	
	# Tips label
	if show_tips:
		_tip_label = Label.new()
		_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tip_label.add_theme_font_size_override("font_size", tip_font_size)
		_tip_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tip_label.custom_minimum_size.x = 400
		add_child(_tip_label)

func _build_dots_spinner() -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.position = Vector2(spinner_size / 2.0 - 30, spinner_size / 2.0 - 8)
	_spinner_container.add_child(hbox)
	
	for i in range(3):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = spinner_color
		dot.set_meta("dot_index", i)
		hbox.add_child(dot)

func _build_bars_spinner() -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.position = Vector2(spinner_size / 2.0 - 30, spinner_size / 2.0 - 20)
	_spinner_container.add_child(hbox)
	
	var heights = [20, 30, 40, 30, 20]
	for i in range(5):
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(8, heights[i])
		bar.color = spinner_color
		bar.set_meta("bar_index", i)
		hbox.add_child(bar)

func _build_circle_spinner() -> void:
	# Create rotating circle using labels with circle segments
	var segments = "◐◓◑◒"
	var label = Label.new()
	label.text = segments[0]
	label.add_theme_font_size_override("font_size", spinner_size)
	label.add_theme_color_override("font_color", spinner_color)
	label.position = Vector2(0, 0)
	label.set_meta("circle_label", true)
	_spinner_container.add_child(label)

func _build_pulse_spinner() -> void:
	var circle = ColorRect.new()
	circle.custom_minimum_size = Vector2(spinner_size / 2.0, spinner_size / 2.0)
	circle.color = spinner_color
	circle.position = Vector2(spinner_size / 4.0, spinner_size / 4.0)
	circle.set_meta("pulse_circle", true)
	_spinner_container.add_child(circle)

func _start_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()
	
	match spinner_style:
		SpinnerStyle.DOTS:
			_animate_dots()
		SpinnerStyle.BARS:
			_animate_bars()
		SpinnerStyle.CIRCLE:
			_animate_circle()
		SpinnerStyle.PULSE:
			_animate_pulse()

func _animate_dots() -> void:
	var dots = []
	for child in _spinner_container.get_children():
		for dot_child in child.get_children():
			if dot_child.has_meta("dot_index"):
				dots.append(dot_child)
	
	_animation_tween = create_tween().set_loops()
	for i in range(dots.size()):
		var dot = dots[i]
		var delay = i * 0.2 / animation_speed
		_animation_tween.tween_property(dot, "position:y", -15, 0.3 / animation_speed).set_delay(delay)
		_animation_tween.parallel().tween_property(dot, "position:y", 0, 0.3 / animation_speed).set_delay(delay + 0.3 / animation_speed)

func _animate_bars() -> void:
	var bars = []
	for child in _spinner_container.get_children():
		for bar_child in child.get_children():
			if bar_child.has_meta("bar_index"):
				bars.append(bar_child)
	
	_animation_tween = create_tween().set_loops()
	for i in range(bars.size()):
		var bar = bars[i]
		var original_height = bar.custom_minimum_size.y
		var delay = i * 0.15 / animation_speed
		_animation_tween.tween_property(bar, "custom_minimum_size:y", original_height * 1.5, 0.4 / animation_speed).set_delay(delay)
		_animation_tween.parallel().tween_property(bar, "custom_minimum_size:y", original_height, 0.4 / animation_speed).set_delay(delay + 0.4 / animation_speed)

func _animate_circle() -> void:
	for child in _spinner_container.get_children():
		if child.has_meta("circle_label"):
			_animation_tween = create_tween().set_loops()
			_animation_tween.tween_property(child, "rotation", TAU, 1.0 / animation_speed)

func _animate_pulse() -> void:
	for child in _spinner_container.get_children():
		if child.has_meta("pulse_circle"):
			_animation_tween = create_tween().set_loops()
			_animation_tween.tween_property(child, "scale", Vector2(1.5, 1.5), 0.6 / animation_speed)
			_animation_tween.parallel().tween_property(child, "modulate:a", 0.3, 0.6 / animation_speed)
			_animation_tween.tween_property(child, "scale", Vector2(1.0, 1.0), 0.6 / animation_speed)
			_animation_tween.parallel().tween_property(child, "modulate:a", 1.0, 0.6 / animation_speed)

func set_message(msg: String) -> void:
	if _message_label:
		_message_label.text = msg

func set_progress(value: float) -> void:
	_current_progress = clampf(value, 0.0, 100.0)
	if _progress_bar:
		var tween = create_tween()
		tween.tween_property(_progress_bar, "value", _current_progress, 0.2)

func set_tips(tips: Array[String]) -> void:
	_loading_tips = tips
	if show_tips and _loading_tips.size() > 0:
		_show_next_tip()
		if not _tip_timer:
			_start_tip_rotation()

func _start_tip_rotation() -> void:
	_tip_timer = Timer.new()
	_tip_timer.wait_time = tip_rotation_interval
	_tip_timer.autostart = true
	_tip_timer.timeout.connect(_show_next_tip)
	add_child(_tip_timer)

func _show_next_tip() -> void:
	if _loading_tips.size() == 0 or not _tip_label:
		return
	
	_current_tip_index = (_current_tip_index + 1) % _loading_tips.size()
	var new_tip = _loading_tips[_current_tip_index]
	
	# Fade out, change text, fade in
	var tween = create_tween()
	tween.tween_property(_tip_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): _tip_label.text = "💡 " + new_tip)
	tween.tween_property(_tip_label, "modulate:a", 1.0, 0.3)

func stop_spinner() -> void:
	if _animation_tween:
		_animation_tween.kill()
	if _tip_timer:
		_tip_timer.stop()

static func create(style: SpinnerStyle = SpinnerStyle.CIRCLE, message: String = "Loading..."):
	"""Static factory method to create and configure a LoadingSpinner"""
	var script_path = "res://Scripts/Components/LoadingSpinner.gd"
	var spinner_script = load(script_path)
	var spinner = spinner_script.new()
	spinner.spinner_style = style
	spinner.set_message(message)
	return spinner
