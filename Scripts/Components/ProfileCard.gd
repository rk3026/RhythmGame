extends PanelContainer
class_name ProfileCard

# ProfileCard.gd - Reusable component for displaying profile summary
# Shows avatar, username, level, and last played date

signal card_clicked(profile_id: String)
signal delete_requested(profile_id: String)

@export var profile_id: String = ""
@export var show_delete_button: bool = false

# Profile data
var username: String = ""
var display_name: String = ""
var avatar_path: String = "res://Assets/Profiles/Avatars/default.svg"
var level: int = 1
var xp: int = 0
var total_xp: int = 0
var last_played: String = ""

# UI elements (created dynamically)
var avatar_texture: TextureRect
var username_label: Label
var level_label: Label
var xp_bar: ProgressBar
var last_played_label: Label
var delete_button: Button

func _ready():
	# Build UI first if not already built
	if avatar_texture == null:
		_build_ui()
	
	# Set up basic styling
	add_theme_stylebox_override("panel", _create_panel_style())
	custom_minimum_size = Vector2(300, 150)
	
	# Make clickable
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect signals
	gui_input.connect(_on_gui_input)
	
	# Update display if we have data
	if not profile_id.is_empty():
		_update_display()

func _build_ui():
	"""Build the profile card UI structure."""
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)
	
	# Top section: Avatar + Info
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(top_hbox)
	
	# Avatar
	avatar_texture = TextureRect.new()
	avatar_texture.custom_minimum_size = Vector2(80, 80)
	avatar_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_hbox.add_child(avatar_texture)
	
	# Info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(info_vbox)
	
	# Username
	username_label = Label.new()
	username_label.add_theme_font_size_override("font_size", 24)
	username_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(username_label)
	
	# Level
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	info_vbox.add_child(level_label)
	
	# XP Progress Bar
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 20)
	xp_bar.show_percentage = false
	info_vbox.add_child(xp_bar)
	
	# Last played
	last_played_label = Label.new()
	last_played_label.add_theme_font_size_override("font_size", 14)
	last_played_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	main_vbox.add_child(last_played_label)
	
	# Delete button (optional)
	if show_delete_button:
		delete_button = Button.new()
		delete_button.text = "Delete"
		delete_button.custom_minimum_size = Vector2(80, 30)
		delete_button.pressed.connect(_on_delete_pressed)
		main_vbox.add_child(delete_button)

func set_profile_data(data: Dictionary):
	"""
	Set the profile data to display.
	
	Args:
		data: Profile dictionary from ProfileManager
	"""
	profile_id = data.get("profile_id", "")
	username = data.get("username", "Unknown")
	display_name = data.get("display_name", username)
	avatar_path = data.get("avatar", "res://Assets/Profiles/Avatars/default.svg")
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	total_xp = data.get("total_xp", 0)
	last_played = data.get("last_played", "Never")
	
	# Build UI if not already built (handles case when ProfileCard created programmatically)
	if avatar_texture == null:
		_build_ui()
	
	_update_display()

func _update_display():
	"""Update the UI elements with current data."""
	# Ensure UI is built
	if avatar_texture == null:
		push_warning("ProfileCard: Cannot update display, UI not built yet")
		return
	
	# Load and set avatar
	if ResourceLoader.exists(avatar_path):
		avatar_texture.texture = load(avatar_path)
	else:
		avatar_texture.texture = load("res://Assets/Profiles/Avatars/default.svg")
	
	# Update labels
	username_label.text = display_name
	level_label.text = "Level " + str(level)
	
	# Update XP bar
	var xp_for_next_level = _calculate_xp_for_next_level()
	var xp_progress = float(xp) / float(xp_for_next_level) if xp_for_next_level > 0 else 0.0
	xp_bar.value = xp_progress * 100.0
	xp_bar.tooltip_text = str(xp) + " / " + str(xp_for_next_level) + " XP"
	
	# Update last played
	if last_played.is_empty() or last_played == "Never":
		last_played_label.text = "Never played"
	else:
		last_played_label.text = "Last played: " + _format_date(last_played)

func _calculate_xp_for_next_level() -> int:
	"""Calculate XP required for next level using ProfileManager's formula."""
	# Next level = current level + 1
	var next_level = level + 1
	# Formula: level = floor(0.1 * sqrt(total_xp))
	# Inverse: total_xp = (level / 0.1)^2 = (10 * level)^2 = 100 * level^2
	var xp_for_next = 100 * next_level * next_level
	return xp_for_next

func _format_date(date_string: String) -> String:
	"""Format ISO date string to readable format."""
	# Simple format: YYYY-MM-DD HH:MM:SS -> MM/DD/YYYY
	if date_string.length() >= 10:
		var parts = date_string.split("T")[0].split("-")
		if parts.size() >= 3:
			return parts[1] + "/" + parts[2] + "/" + parts[0]
	return date_string

func _create_panel_style() -> StyleBoxFlat:
	"""Create the panel style for the card."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 15
	style.content_margin_top = 15
	style.content_margin_right = 15
	style.content_margin_bottom = 15
	return style

func _on_gui_input(event: InputEvent):
	"""Handle mouse clicks on the card."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("card_clicked", profile_id)
			# Hover effect
			_on_hover_start()

func _on_delete_pressed():
	"""Handle delete button press."""
	emit_signal("delete_requested", profile_id)

func _on_hover_start():
	"""Visual feedback when hovering/clicking."""
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)

func _on_hover_end():
	"""Reset hover effect."""
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_mouse_entered():
	_on_hover_start()

func _on_mouse_exited():
	_on_hover_end()
