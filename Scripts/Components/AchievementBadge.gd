extends PanelContainer
class_name AchievementBadge

# AchievementBadge.gd - Display component for an achievement
# Shows icon, name, description, and unlock status

signal badge_clicked(achievement_id: String)

@export var achievement_id: String = ""
@export var compact_mode: bool = false  # Smaller display for lists

var achievement_name: String = ""
var achievement_description: String = ""
var icon_path: String = ""
var is_unlocked: bool = false
var is_hidden: bool = false
var progress: int = 0
var target: int = 0

# UI elements
var icon_texture: TextureRect
var name_label: Label
var description_label: Label
var progress_bar: ProgressBar
var unlock_indicator: Label

func _ready():
	# Build UI if not already built
	if name_label == null:
		_build_ui()
	
	add_theme_stylebox_override("panel", _create_panel_style())
	custom_minimum_size = Vector2(200, 100) if compact_mode else Vector2(300, 120)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	# Update display if we have data
	if not achievement_id.is_empty():
		_update_display()

func _build_ui():
	"""Build the achievement badge UI."""
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)
	
	if compact_mode:
		_build_compact_ui(main_vbox)
	else:
		_build_full_ui(main_vbox)

func _build_full_ui(container: VBoxContainer):
	"""Build full-size achievement display."""
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	container.add_child(top_hbox)
	
	# Icon
	icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(60, 60)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_hbox.add_child(icon_texture)
	
	# Info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(info_vbox)
	
	# Name + unlock indicator
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)
	
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 18)
	name_hbox.add_child(name_label)
	
	unlock_indicator = Label.new()
	unlock_indicator.add_theme_font_size_override("font_size", 16)
	unlock_indicator.text = "✓"
	unlock_indicator.add_theme_color_override("font_color", Color.GREEN)
	unlock_indicator.visible = false
	name_hbox.add_child(unlock_indicator)
	
	# Description
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(description_label)
	
	# Progress bar (only if locked)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.show_percentage = true
	container.add_child(progress_bar)

func _build_compact_ui(container: VBoxContainer):
	"""Build compact achievement display."""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	container.add_child(hbox)
	
	# Small icon
	icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(40, 40)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_texture)
	
	# Name
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Unlock indicator
	unlock_indicator = Label.new()
	unlock_indicator.text = "✓"
	unlock_indicator.add_theme_color_override("font_color", Color.GREEN)
	unlock_indicator.visible = false
	hbox.add_child(unlock_indicator)

func set_achievement_data(data: Dictionary, progress_data: Dictionary = {}):
	"""
	Set achievement data to display.
	
	Args:
		data: Achievement definition from AchievementManager
		progress_data: Progress data (unlocked, progress, unlocked_at)
	"""
	achievement_id = data.get("achievement_id", "")
	achievement_name = data.get("name", "Unknown Achievement")
	achievement_description = data.get("description", "")
	icon_path = data.get("icon_path", "")
	is_hidden = data.get("hidden", false)
	
	# Progress data
	is_unlocked = progress_data.get("unlocked", false)
	progress = progress_data.get("progress", 0)
	
	# Get target from requirement
	var requirement = data.get("requirement", {})
	target = requirement.get("target", 100)
	
	# Build UI if not already built (handles case when created programmatically)
	if name_label == null:
		_build_ui()
	
	_update_display()

func _update_display():
	"""Update UI elements with current data."""
	# Ensure UI is built
	if name_label == null:
		push_warning("AchievementBadge: Cannot update display, UI not built yet")
		return
	
	# Handle hidden achievements
	if is_hidden and not is_unlocked:
		name_label.text = "???"
		if description_label:
			description_label.text = "Hidden achievement"
		if icon_texture:
			icon_texture.modulate = Color(0.2, 0.2, 0.2)
		if progress_bar:
			progress_bar.visible = false
		return
	
	# Update name
	name_label.text = achievement_name
	
	# Update description
	if description_label:
		description_label.text = achievement_description
	
	# Update icon
	if icon_texture:
		if ResourceLoader.exists(icon_path):
			icon_texture.texture = load(icon_path)
		icon_texture.modulate = Color.WHITE if is_unlocked else Color(0.5, 0.5, 0.5)
	
	# Update unlock indicator
	if unlock_indicator:
		unlock_indicator.visible = is_unlocked
	
	# Update progress bar
	if progress_bar:
		if is_unlocked:
			progress_bar.visible = false
		else:
			progress_bar.visible = true
			progress_bar.value = (float(progress) / float(target)) * 100.0 if target > 0 else 0.0
			progress_bar.tooltip_text = str(progress) + " / " + str(target)

func _create_panel_style() -> StyleBoxFlat:
	"""Create the panel style."""
	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = Color(0.2, 0.25, 0.2, 0.95)  # Slight green tint for unlocked
		style.border_color = Color(0.3, 0.6, 0.3, 1.0)  # Green border
	else:
		style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		style.border_color = Color(0.3, 0.3, 0.4, 0.7)
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style

func _on_gui_input(event: InputEvent):
	"""Handle mouse clicks."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("badge_clicked", achievement_id)
