extends PanelContainer

# MenuCardPanel: A unified card-style panel with hover effects
# Provides consistent visual design for menu items, song lists, and info panels

@export_group("Appearance")
@export var card_color: Color = Color(0.76, 0.76, 0.76, 0.25)
@export var hover_color: Color = Color(0.9, 0.9, 0.9, 0.4)
@export var border_width: int = 0
@export var border_color: Color = Color.WHITE
@export var corner_radius: int = 8
@export var shadow_enabled: bool = true
@export var shadow_offset: Vector2 = Vector2(2, 2)
@export var shadow_color: Color = Color(0, 0, 0, 0.3)

@export_group("Animation")
@export var enable_hover_lift: bool = true
@export var lift_distance: float = -5.0
@export var animation_duration: float = 0.2

@export_group("Badge")
@export var badge_text: String = ""
@export var badge_color: Color = Color.RED
@export var badge_position: Vector2 = Vector2(10, 10)

@export_group("Icon")
@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(48, 48)
@export var icon_position: String = "left"  # "left", "right", "top", "bottom"

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _tween: Tween
var _badge_label: Label
var _icon_rect: TextureRect

func _ready() -> void:
	_setup_styles()
	_setup_badge()
	_setup_icon()
	
	# Connect mouse events
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_styles() -> void:
	# Normal style
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = card_color
	_style_normal.corner_radius_top_left = corner_radius
	_style_normal.corner_radius_top_right = corner_radius
	_style_normal.corner_radius_bottom_left = corner_radius
	_style_normal.corner_radius_bottom_right = corner_radius
	
	if border_width > 0:
		_style_normal.border_width_left = border_width
		_style_normal.border_width_top = border_width
		_style_normal.border_width_right = border_width
		_style_normal.border_width_bottom = border_width
		_style_normal.border_color = border_color
	
	if shadow_enabled:
		_style_normal.shadow_size = 4
		_style_normal.shadow_offset = shadow_offset
		_style_normal.shadow_color = shadow_color
	
	# Hover style
	_style_hover = _style_normal.duplicate()
	_style_hover.bg_color = hover_color
	
	if shadow_enabled:
		_style_hover.shadow_size = 8
		_style_hover.shadow_offset = shadow_offset * 1.5
	
	# Apply normal style
	add_theme_stylebox_override("panel", _style_normal)

func _setup_badge() -> void:
	if badge_text.is_empty():
		return
	
	_badge_label = Label.new()
	_badge_label.text = badge_text
	_badge_label.add_theme_font_size_override("font_size", 14)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Create badge background
	var badge_bg = PanelContainer.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = badge_color
	badge_style.corner_radius_top_left = 4
	badge_style.corner_radius_top_right = 4
	badge_style.corner_radius_bottom_left = 4
	badge_style.corner_radius_bottom_right = 4
	badge_style.content_margin_left = 8
	badge_style.content_margin_right = 8
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 4
	badge_bg.add_theme_stylebox_override("panel", badge_style)
	badge_bg.add_child(_badge_label)
	
	# Position badge
	badge_bg.position = badge_position
	badge_bg.z_index = 10
	add_child(badge_bg)

func _setup_icon() -> void:
	if not icon_texture:
		return
	
	_icon_rect = TextureRect.new()
	_icon_rect.texture = icon_texture
	_icon_rect.custom_minimum_size = icon_size
	_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Icon positioning would require modifying the content structure
	# For now, we'll add it as an overlay
	_icon_rect.position = Vector2(10, 10)
	_icon_rect.z_index = 5
	add_child(_icon_rect)

func _on_mouse_entered() -> void:
	_cancel_tween()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Change style to hover
	add_theme_stylebox_override("panel", _style_hover)
	
	# Simple scale effect instead of position change (more reliable with layouts)
	if enable_hover_lift:
		_tween.tween_property(self, "scale", Vector2(1.02, 1.02), animation_duration)
	
	# Brightness increase
	_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), animation_duration)

func _on_mouse_exited() -> void:
	_cancel_tween()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Change style to normal
	add_theme_stylebox_override("panel", _style_normal)
	
	# Return to normal scale
	if enable_hover_lift:
		_tween.tween_property(self, "scale", Vector2.ONE, animation_duration)
	
	# Return to normal modulate
	_tween.tween_property(self, "modulate", Color.WHITE, animation_duration)

func _cancel_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

# Public methods
func set_badge(text: String, color: Color = Color.RED) -> void:
	badge_text = text
	badge_color = color
	
	if is_inside_tree():
		# Remove old badge if exists
		for child in get_children():
			if child.get_child_count() > 0 and child.get_child(0) is Label:
				child.queue_free()
		_setup_badge()

func clear_badge() -> void:
	badge_text = ""
	if _badge_label and _badge_label.get_parent():
		_badge_label.get_parent().queue_free()
		_badge_label = null

func set_icon(texture: Texture2D) -> void:
	icon_texture = texture
	if _icon_rect:
		_icon_rect.texture = texture
	elif is_inside_tree():
		_setup_icon()

func clear_icon() -> void:
	if _icon_rect:
		_icon_rect.queue_free()
		_icon_rect = null
	icon_texture = null

func pulse_attention() -> void:
	"""Briefly pulse the card to draw attention"""
	var pulse_tween = create_tween()
	pulse_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
