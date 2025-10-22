extends VBoxContainer

# FancyHeader: Styled header with animations and optional decorations
# Provides consistent header styling across all screens

@export_group("Content")
@export var header_text: String = "Header"
@export var subtitle_text: String = ""
@export var header_font_size: int = 48
@export var subtitle_font_size: int = 24

@export_group("Icon")
@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(48, 48)
@export var icon_position: String = "left"  # "left", "right", "center"

@export_group("Style")
@export var enable_gradient: bool = false
@export var gradient_start: Color = Color.BLUE
@export var gradient_end: Color = Color.PURPLE
@export var text_color: Color = Color.WHITE

@export_group("Decoration")
@export var show_underline: bool = true
@export var underline_color: Color = Color.WHITE
@export var underline_thickness: int = 2
@export var show_overline: bool = false
@export var overline_color: Color = Color.WHITE

@export_group("Animation")
@export var animate_on_ready: bool = true
@export var slide_in_direction: String = "none"  # "none", "left", "right", "top", "bottom"
@export var slide_duration: float = 0.5

var _header_label: Label
var _subtitle_label: Label
var _icon_rect: TextureRect
var _underline: ColorRect
var _overline: ColorRect
var _content_hbox: HBoxContainer

func _ready() -> void:
	_build_ui()
	
	if animate_on_ready and slide_in_direction != "none":
		_animate_slide_in()

func _build_ui() -> void:
	add_theme_constant_override("separation", 10)
	
	# Overline (optional)
	if show_overline:
		_overline = ColorRect.new()
		_overline.color = overline_color
		_overline.custom_minimum_size = Vector2(0, underline_thickness)
		add_child(_overline)
	
	# Main content container
	_content_hbox = HBoxContainer.new()
	_content_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_hbox.add_theme_constant_override("separation", 15)
	add_child(_content_hbox)
	
	# Icon (left position)
	if icon_texture and icon_position == "left":
		_add_icon()
	
	# Text container
	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 5)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_hbox.add_child(text_vbox)
	
	# Header label
	_header_label = Label.new()
	_header_label.text = header_text
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", header_font_size)
	
	if enable_gradient:
		_header_label.add_theme_color_override("font_color", gradient_start)
		# Note: True gradient text requires shader or custom rendering
	else:
		_header_label.add_theme_color_override("font_color", text_color)
	
	text_vbox.add_child(_header_label)
	
	# Subtitle label (optional)
	if not subtitle_text.is_empty():
		_subtitle_label = Label.new()
		_subtitle_label.text = subtitle_text
		_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_subtitle_label.add_theme_font_size_override("font_size", subtitle_font_size)
		_subtitle_label.add_theme_color_override("font_color", text_color * Color(0.8, 0.8, 0.8, 1.0))
		text_vbox.add_child(_subtitle_label)
	
	# Icon (right or center position)
	if icon_texture and icon_position == "right":
		_add_icon()
	
	# Underline (optional)
	if show_underline:
		_underline = ColorRect.new()
		_underline.color = underline_color
		_underline.custom_minimum_size = Vector2(0, underline_thickness)
		add_child(_underline)
		
		# Animate underline width
		if animate_on_ready:
			_underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_underline.custom_minimum_size.x = 0
			var tween = create_tween()
			tween.tween_property(_underline, "custom_minimum_size:x", 300.0, 0.5).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _add_icon() -> void:
	_icon_rect = TextureRect.new()
	_icon_rect.texture = icon_texture
	_icon_rect.custom_minimum_size = icon_size
	_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_content_hbox.add_child(_icon_rect)

func _animate_slide_in() -> void:
	var viewport_size = get_viewport_rect().size
	var original_pos = position
	var start_offset = Vector2.ZERO
	
	match slide_in_direction:
		"left":
			start_offset = Vector2(-viewport_size.x, 0)
		"right":
			start_offset = Vector2(viewport_size.x, 0)
		"top":
			start_offset = Vector2(0, -200)
		"bottom":
			start_offset = Vector2(0, 200)
	
	position = original_pos + start_offset
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", original_pos, slide_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, slide_duration * 0.5)

# Public methods
func set_header_text(text: String) -> void:
	header_text = text
	if _header_label:
		_header_label.text = text

func set_subtitle_text(text: String) -> void:
	subtitle_text = text
	if _subtitle_label:
		_subtitle_label.text = text
	elif not text.is_empty() and is_inside_tree():
		# Need to rebuild to add subtitle
		_clear_children()
		_build_ui()

func set_icon(texture: Texture2D) -> void:
	icon_texture = texture
	if _icon_rect:
		_icon_rect.texture = texture
	elif is_inside_tree():
		_clear_children()
		_build_ui()

func pulse() -> void:
	"""Play a pulse animation to draw attention"""
	var tween = create_tween()
	tween.tween_property(_header_label, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(_header_label, "scale", Vector2.ONE, 0.2)

func flash_colors(color1: Color, color2: Color, duration: float = 1.0) -> void:
	"""Alternate between two colors"""
	var tween = create_tween().set_loops()
	tween.tween_method(_set_header_color, color1, color2, duration / 2.0)
	tween.tween_method(_set_header_color, color2, color1, duration / 2.0)

func stop_flash() -> void:
	"""Stop color flashing and return to normal"""
	var tweens = get_tree().get_nodes_in_group("tween")
	for t in tweens:
		if t is Tween:
			t.kill()
	_header_label.add_theme_color_override("font_color", text_color)

func _set_header_color(color: Color) -> void:
	if _header_label:
		_header_label.add_theme_color_override("font_color", color)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
