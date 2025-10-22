extends HBoxContainer

# ProgressBarWithLabel: Integrated slider/progress bar with value display
# Shows visual progress with color gradients and smooth animations

@export_group("Value")
@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var current_value: float = 50.0
@export var step: float = 1.0

@export_group("Display")
@export var label_text: String = "Value"
@export var show_percentage: bool = true
@export var show_min_max_labels: bool = false
@export var value_format: String = "%.0f"  # printf format string

@export_group("Colors")
@export var enable_gradient: bool = true
@export var low_color: Color = Color.RED
@export var mid_color: Color = Color.YELLOW
@export var high_color: Color = Color.GREEN
@export var gradient_threshold_low: float = 0.33
@export var gradient_threshold_high: float = 0.66

@export_group("Icon")
@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(24, 24)

@export_group("Animation")
@export var smooth_transitions: bool = true
@export var transition_duration: float = 0.3

@export_group("Interactive")
@export var editable: bool = true

var _label: Label
var _slider: HSlider
var _value_label: Label
var _progress_bar: ProgressBar
var _icon_rect: TextureRect
var _min_label: Label
var _max_label: Label
var _tween: Tween

signal value_changed(value: float)

func _ready() -> void:
	_build_ui()
	_update_display()

func _build_ui() -> void:
	add_theme_constant_override("separation", 8)
	
	# Icon (optional)
	if icon_texture:
		_icon_rect = TextureRect.new()
		_icon_rect.texture = icon_texture
		_icon_rect.custom_minimum_size = icon_size
		_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_icon_rect)
	
	# Label
	_label = Label.new()
	_label.text = label_text
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	
	if editable:
		# Slider mode
		_slider = HSlider.new()
		_slider.min_value = min_value
		_slider.max_value = max_value
		_slider.value = current_value
		_slider.step = step
		_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_slider.custom_minimum_size = Vector2(200, 0)
		_slider.value_changed.connect(_on_slider_changed)
		add_child(_slider)
		
		# Min label (optional)
		if show_min_max_labels:
			_min_label = Label.new()
			_min_label.text = value_format % min_value
			_min_label.add_theme_font_size_override("font_size", 12)
			_min_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(_min_label)
		
		# Style slider based on value
		_update_slider_style()
	else:
		# Progress bar mode (read-only)
		_progress_bar = ProgressBar.new()
		_progress_bar.min_value = min_value
		_progress_bar.max_value = max_value
		_progress_bar.value = current_value
		_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_progress_bar.custom_minimum_size = Vector2(200, 20)
		_progress_bar.show_percentage = false
		add_child(_progress_bar)
		
		_update_progress_style()
	
	# Max label (optional)
	if show_min_max_labels:
		_max_label = Label.new()
		_max_label.text = value_format % max_value
		_max_label.add_theme_font_size_override("font_size", 12)
		_max_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_max_label)
	
	# Value label
	_value_label = Label.new()
	_value_label.custom_minimum_size = Vector2(60, 0)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_value_label)

func _on_slider_changed(value: float) -> void:
	if smooth_transitions:
		_animate_value(current_value, value)
	else:
		current_value = value
		_update_display()
	
	value_changed.emit(value)

func _animate_value(from: float, to: float) -> void:
	_cancel_tween()
	_tween = create_tween()
	_tween.tween_method(_update_value_animated, from, to, transition_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_value_animated(value: float) -> void:
	current_value = value
	_update_display()

func _update_display() -> void:
	# Update value label
	if show_percentage:
		var percent = ((current_value - min_value) / (max_value - min_value)) * 100.0
		_value_label.text = ("%.0f" % percent) + "%"
	else:
		_value_label.text = value_format % current_value
	
	# Update color based on gradient
	if enable_gradient:
		var normalized = (current_value - min_value) / (max_value - min_value)
		var color = _get_gradient_color(normalized)
		_value_label.modulate = color
		
		if editable:
			_update_slider_style()
		else:
			_update_progress_style()

func _update_slider_style() -> void:
	if not _slider or not enable_gradient:
		return
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	var color = _get_gradient_color(normalized)
	
	# Create custom grabber style
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = color
	grabber_style.corner_radius_top_left = 4
	grabber_style.corner_radius_top_right = 4
	grabber_style.corner_radius_bottom_left = 4
	grabber_style.corner_radius_bottom_right = 4
	_slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	# Also update the fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	_slider.add_theme_stylebox_override("slider", fill_style)

func _update_progress_style() -> void:
	if not _progress_bar or not enable_gradient:
		return
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	var color = _get_gradient_color(normalized)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

func _get_gradient_color(normalized: float) -> Color:
	if normalized < gradient_threshold_low:
		# Interpolate between low and mid
		var t = normalized / gradient_threshold_low
		return low_color.lerp(mid_color, t)
	elif normalized < gradient_threshold_high:
		# Interpolate between mid and high
		var t = (normalized - gradient_threshold_low) / (gradient_threshold_high - gradient_threshold_low)
		return mid_color.lerp(high_color, t)
	else:
		# Interpolate between high and max (if needed)
		var t = (normalized - gradient_threshold_high) / (1.0 - gradient_threshold_high)
		return high_color.lerp(high_color, t)  # Stay at high color

func _cancel_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

# Public methods
func set_value(value: float, animate: bool = true) -> void:
	value = clampf(value, min_value, max_value)
	
	if animate and smooth_transitions:
		_animate_value(current_value, value)
	else:
		current_value = value
		if _slider:
			_slider.value = value
		if _progress_bar:
			_progress_bar.value = value
		_update_display()

func get_value() -> float:
	return current_value

func set_label(text: String) -> void:
	label_text = text
	if _label:
		_label.text = text

func set_range(p_min: float, p_max: float) -> void:
	min_value = p_min
	max_value = p_max
	
	if _slider:
		_slider.min_value = p_min
		_slider.max_value = p_max
	if _progress_bar:
		_progress_bar.min_value = p_min
		_progress_bar.max_value = p_max
	
	if show_min_max_labels:
		if _min_label:
			_min_label.text = value_format % min_value
		if _max_label:
			_max_label.text = value_format % max_value
	
	_update_display()
