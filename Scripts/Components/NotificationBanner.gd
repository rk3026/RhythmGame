extends Control

# NotificationBanner: Slide-in notification system with queue support
# Shows temporary messages with icons and color theming

enum NotificationType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	CUSTOM
}

@export_group("Behavior")
@export var auto_dismiss_duration: float = 3.0
@export var slide_duration: float = 0.3
@export var max_queue_size: int = 5

# Type colors
const TYPE_COLORS = {
	NotificationType.INFO: Color(0.3, 0.6, 1.0, 0.95),
	NotificationType.SUCCESS: Color(0.3, 0.8, 0.3, 0.95),
	NotificationType.WARNING: Color(1.0, 0.7, 0.2, 0.95),
	NotificationType.ERROR: Color(0.9, 0.2, 0.2, 0.95),
}

const TYPE_ICONS = {
	NotificationType.INFO: "ℹ",
	NotificationType.SUCCESS: "✓",
	NotificationType.WARNING: "⚠",
	NotificationType.ERROR: "✕",
}

var _notification_queue: Array = []
var _active_banner: PanelContainer = null
var _is_showing: bool = false

# Show a notification
func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = 0.0, icon: String = "") -> void:
	var notif_data = {
		"message": message,
		"type": type,
		"duration": duration if duration > 0.0 else auto_dismiss_duration,
		"icon": icon if not icon.is_empty() else TYPE_ICONS.get(type, "")
	}
	
	_notification_queue.append(notif_data)
	
	# Limit queue size
	if _notification_queue.size() > max_queue_size:
		_notification_queue.pop_front()
	
	# Show next if not currently showing
	if not _is_showing:
		_show_next()

func _show_next() -> void:
	if _notification_queue.is_empty():
		_is_showing = false
		return
	
	_is_showing = true
	var notif_data = _notification_queue.pop_front()
	
	_create_banner(notif_data)
	_animate_in()
	
	# Auto-dismiss timer
	await get_tree().create_timer(notif_data.duration).timeout
	_animate_out()

func _create_banner(notif_data: Dictionary) -> void:
	# Clean up old banner if exists
	if _active_banner:
		_active_banner.queue_free()
	
	# Create panel container
	_active_banner = PanelContainer.new()
	_active_banner.size = size  # Fill parent size
	_active_banner.position = Vector2.ZERO  # Position at top-left of parent
	_active_banner.modulate.a = 0.0  # Start invisible
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(notif_data.type, Color.GRAY)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 15
	style.content_margin_top = 15
	style.content_margin_right = 15
	style.content_margin_bottom = 15
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.shadow_color = Color(0, 0, 0, 0.3)
	_active_banner.add_theme_stylebox_override("panel", style)
	
	# Content container
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	_active_banner.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = notif_data.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(icon_label)
	
	# Message
	var message_label = Label.new()
	message_label.text = notif_data.message
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(message_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.pressed.connect(_on_close_pressed)
	hbox.add_child(close_button)
	
	add_child(_active_banner)

func _animate_in() -> void:
	if not _active_banner:
		return
	
	# Simple fade in animation
	var tween = create_tween()
	tween.tween_property(_active_banner, "modulate:a", 1.0, slide_duration).set_ease(Tween.EASE_OUT)

func _animate_out() -> void:
	if not _active_banner:
		_show_next()
		return
	
	# Simple fade out animation
	var tween = create_tween()
	tween.tween_property(_active_banner, "modulate:a", 0.0, slide_duration).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	if _active_banner:
		_active_banner.queue_free()
		_active_banner = null
	
	_show_next()

func _on_close_pressed() -> void:
	_animate_out()

# Convenience methods
func show_info(message: String, duration: float = 0.0) -> void:
	show_notification(message, NotificationType.INFO, duration)

func show_success(message: String, duration: float = 0.0) -> void:
	show_notification(message, NotificationType.SUCCESS, duration)

func show_warning(message: String, duration: float = 0.0) -> void:
	show_notification(message, NotificationType.WARNING, duration)

func show_error(message: String, duration: float = 0.0) -> void:
	show_notification(message, NotificationType.ERROR, duration)

func clear_queue() -> void:
	_notification_queue.clear()
	if _active_banner:
		_animate_out()

# Singleton access helper
static func get_instance() -> Control:
	# Look for existing NotificationBanner in scene tree
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child.get_script() == load("res://Scripts/Components/NotificationBanner.gd"):
			return child
	
	# Create new instance if not found
	var script = load("res://Scripts/Components/NotificationBanner.gd")
	var instance = script.new()
	root.add_child(instance)
	return instance
