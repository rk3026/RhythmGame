extends PanelContainer

# InfoTooltip: Hover-triggered tooltip with rich text support
# Automatically positions itself to stay on screen

@export_group("Content")
@export_multiline var tooltip_content: String = ""
@export var enable_rich_text: bool = true

@export_group("Behavior")
@export var hover_delay: float = 0.5
@export var fade_duration: float = 0.2
@export var auto_hide_delay: float = 0.0  # 0 = stay visible while hovering

@export_group("Appearance")
@export var max_width: float = 300.0
@export var bg_color: Color = Color(0.1, 0.1, 0.1, 0.95)
@export var text_color: Color = Color.WHITE
@export var border_color: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var padding: int = 10

var _label: Control  # Can be RichTextLabel or Label
var _hover_timer: Timer
var _hide_timer: Timer
var _tween: Tween
var _target_node: Control
var _is_showing: bool = false

func _ready() -> void:
	_build_ui()
	hide()
	modulate.a = 0.0
	
	# Make tooltip layer top-most
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_ui() -> void:
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	add_theme_stylebox_override("panel", style)
	
	# Create label
	if enable_rich_text:
		var rich_label = RichTextLabel.new()
		rich_label.bbcode_enabled = true
		rich_label.fit_content = true
		rich_label.scroll_active = false
		rich_label.add_theme_color_override("default_color", text_color)
		_label = rich_label
	else:
		var simple_label = Label.new()
		simple_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		simple_label.add_theme_color_override("font_color", text_color)
		_label = simple_label
	
	_label.custom_minimum_size = Vector2(0, 0)
	add_child(_label)
	
	# Create timers
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(_hover_timer)
	
	if auto_hide_delay > 0.0:
		_hide_timer = Timer.new()
		_hide_timer.one_shot = true
		_hide_timer.wait_time = auto_hide_delay
		_hide_timer.timeout.connect(_on_hide_timer_timeout)
		add_child(_hide_timer)

func _on_hover_timer_timeout() -> void:
	show_tooltip()

func _on_hide_timer_timeout() -> void:
	hide_tooltip()

func attach_to(node: Control) -> void:
	"""Attach tooltip to a control node"""
	_target_node = node
	
	if not node.is_connected("mouse_entered", _on_target_mouse_entered):
		node.mouse_entered.connect(_on_target_mouse_entered)
	if not node.is_connected("mouse_exited", _on_target_mouse_exited):
		node.mouse_exited.connect(_on_target_mouse_exited)

func _on_target_mouse_entered() -> void:
	_hover_timer.start(hover_delay)

func _on_target_mouse_exited() -> void:
	_hover_timer.stop()
	hide_tooltip()

func show_tooltip() -> void:
	if _is_showing:
		return
	
	_is_showing = true
	
	# Set content
	if _label:
		if _label is RichTextLabel:
			(_label as RichTextLabel).clear()
			(_label as RichTextLabel).append_text(tooltip_content)
		elif _label is Label:
			(_label as Label).text = tooltip_content
	
	# Position tooltip near mouse or target
	_position_tooltip()
	
	# Fade in
	show()
	_cancel_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Start auto-hide timer if configured
	if _hide_timer:
		_hide_timer.start()

func hide_tooltip() -> void:
	if not _is_showing:
		return
	
	_is_showing = false
	
	# Fade out
	_cancel_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_callback(hide)
	
	if _hide_timer:
		_hide_timer.stop()

func _position_tooltip() -> void:
	if not _target_node:
		return
	
	# Wait for size calculation
	await get_tree().process_frame
	
	var viewport_size = get_viewport_rect().size
	var tooltip_size = size
	var target_rect = _target_node.get_global_rect()
	
	# Default position: below and centered on target
	var pos = Vector2(
		target_rect.position.x + (target_rect.size.x / 2.0) - (tooltip_size.x / 2.0),
		target_rect.position.y + target_rect.size.y + 5
	)
	
	# Adjust if tooltip goes off-screen (right)
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = viewport_size.x - tooltip_size.x - 10
	
	# Adjust if tooltip goes off-screen (left)
	if pos.x < 0:
		pos.x = 10
	
	# Adjust if tooltip goes off-screen (bottom) - show above instead
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = target_rect.position.y - tooltip_size.y - 5
	
	# Adjust if tooltip goes off-screen (top)
	if pos.y < 0:
		pos.y = 10
	
	global_position = pos

func _cancel_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

# Public methods
func set_text(text: String) -> void:
	tooltip_content = text
	if _label and _is_showing:
		if _label is RichTextLabel:
			(_label as RichTextLabel).clear()
			(_label as RichTextLabel).append_text(text)
		elif _label is Label:
			(_label as Label).text = text

func set_delay(delay: float) -> void:
	hover_delay = delay

# Static helper to quickly create and attach tooltips
static func create_for(node: Control, text: String, delay: float = 0.5):
	var tooltip_script = load("res://Scripts/Components/InfoTooltip.gd")
	var tooltip = tooltip_script.new()
	tooltip.tooltip_content = text
	tooltip.hover_delay = delay
	
	# Add to scene root (top level for proper layering)
	node.get_tree().root.add_child(tooltip)
	tooltip.attach_to(node)
	
	return tooltip
