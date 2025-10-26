extends Control

# profile_editor.gd - Profile editing screen
# Handles profile data editing: avatar, display name, bio, colors

# Node references
@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton
@onready var current_avatar: TextureRect = %CurrentAvatar
@onready var avatar_grid: GridContainer = %AvatarGridContainer
@onready var display_name_input: LineEdit = %DisplayNameInput
@onready var bio_input: TextEdit = %BioInput
@onready var bio_char_count: Label = %BioCharCount
@onready var primary_color_button: ColorPickerButton = %PrimaryColorButton
@onready var accent_color_button: ColorPickerButton = %AccentColorButton
@onready var error_label: Label = %ErrorLabel

# State
var profile_id: String = ""
var original_data: Dictionary = {}
var selected_avatar: String = ""
var available_avatars: Array[String] = []

# Constants
const AVATAR_SIZE := 64
const AVATARS_DIR := "res://Assets/Profiles/Avatars/"
const MAX_BIO_LENGTH := 200

func _ready() -> void:
	# Hide error initially
	error_label.visible = false
	
	# Load available avatars
	_load_available_avatars()
	_populate_avatar_grid()
	
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	display_name_input.text_changed.connect(_on_display_name_changed)
	bio_input.text_changed.connect(_on_bio_changed)
	primary_color_button.color_changed.connect(_on_primary_color_changed)
	accent_color_button.color_changed.connect(_on_accent_color_changed)
	
	# Load profile data
	_load_profile_data()

func _load_available_avatars() -> void:
	"""Load all available avatar files from the Avatars directory."""
	available_avatars.clear()
	
	var dir = DirAccess.open(AVATARS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only include .svg files
			if file_name.ends_with(".svg") and not file_name.ends_with(".import"):
				available_avatars.append(AVATARS_DIR + file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		# Sort alphabetically
		available_avatars.sort()

func _populate_avatar_grid() -> void:
	"""Create buttons for each available avatar."""
	# Clear existing children
	for child in avatar_grid.get_children():
		child.queue_free()
	
	# Create button for each avatar
	for avatar_path in available_avatars:
		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
		button.texture_normal = load(avatar_path)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_avatar_selected.bind(avatar_path))
		
		# Add hover effect
		button.mouse_entered.connect(func(): button.modulate = Color(1.2, 1.2, 1.2))
		button.mouse_exited.connect(func(): button.modulate = Color(1, 1, 1))
		
		avatar_grid.add_child(button)

func _load_profile_data() -> void:
	"""Load the current profile data into the editor."""
	if ProfileManager.current_profile.is_empty():
		push_error("ProfileEditor: No current profile loaded")
		_show_error("No profile loaded. Returning to profile view.")
		await get_tree().create_timer(2.0).timeout
		_navigate_back()
		return
	
	# Store original data for comparison
	original_data = ProfileManager.current_profile.duplicate(true)
	profile_id = ProfileManager.current_profile_id
	
	# Set avatar
	selected_avatar = ProfileManager.current_profile.get("avatar", AVATARS_DIR + "default.svg")
	if ResourceLoader.exists(selected_avatar):
		current_avatar.texture = load(selected_avatar)
	
	# Set display name
	display_name_input.text = ProfileManager.current_profile.get("display_name", ProfileManager.current_profile.username)
	
	# Set bio
	var bio = ProfileManager.current_profile.get("bio", "")
	bio_input.text = bio
	_update_bio_char_count()
	
	# Set colors
	var primary_color_str = ProfileManager.current_profile.get("profile_color_primary", "#4CAF50")
	var accent_color_str = ProfileManager.current_profile.get("profile_color_accent", "#F44336")
	primary_color_button.color = Color(primary_color_str)
	accent_color_button.color = Color(accent_color_str)

func _on_avatar_selected(avatar_path: String) -> void:
	"""Handle avatar selection."""
	selected_avatar = avatar_path
	if ResourceLoader.exists(selected_avatar):
		current_avatar.texture = load(selected_avatar)
	_hide_error()

func _on_display_name_changed(_new_text: String) -> void:
	"""Handle display name input changes."""
	_hide_error()

func _on_bio_changed() -> void:
	"""Handle bio text changes."""
	var text = bio_input.text
	
	# Enforce character limit
	if text.length() > MAX_BIO_LENGTH:
		bio_input.text = text.substr(0, MAX_BIO_LENGTH)
		bio_input.set_caret_column(MAX_BIO_LENGTH)
	
	_update_bio_char_count()
	_hide_error()

func _update_bio_char_count() -> void:
	"""Update the character count label."""
	var char_count = bio_input.text.length()
	bio_char_count.text = "%d / %d characters" % [char_count, MAX_BIO_LENGTH]
	
	# Color code based on usage
	if char_count >= MAX_BIO_LENGTH:
		bio_char_count.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif char_count >= MAX_BIO_LENGTH * 0.8:
		bio_char_count.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	else:
		bio_char_count.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func _on_primary_color_changed(_color: Color) -> void:
	"""Handle primary color changes."""
	_hide_error()

func _on_accent_color_changed(_color: Color) -> void:
	"""Handle accent color changes."""
	_hide_error()

func _on_back_pressed() -> void:
	"""Handle cancel button press."""
	# Check if there are unsaved changes
	if _has_unsaved_changes():
		# TODO: Show confirmation dialog
		# For now, just navigate back
		pass
	
	_navigate_back()

func _on_save_pressed() -> void:
	"""Handle save button press."""
	if not _validate_inputs():
		return
	
	# Save all changes via ProfileManager
	var new_display_name = display_name_input.text.strip_edges()
	if not new_display_name.is_empty():
		ProfileManager.update_profile_field("display_name", new_display_name)
	
	ProfileManager.update_profile_field("bio", bio_input.text.strip_edges())
	
	# Convert avatar path to avatar_id before saving
	var avatar_id = ProfileManager.get_avatar_id_from_path(selected_avatar)
	ProfileManager.update_profile_field("avatar_id", avatar_id)
	ProfileManager.update_profile_field("avatar", selected_avatar)  # Also update the computed field
	
	ProfileManager.update_profile_field("profile_color_primary", primary_color_button.color.to_html())
	ProfileManager.update_profile_field("profile_color_accent", accent_color_button.color.to_html())
	
	# Save to disk
	ProfileManager.save_profile()
	
	# Navigate back to profile view
	_show_success("Profile updated successfully!")
	await get_tree().create_timer(1.0).timeout
	_navigate_back()

func _validate_inputs() -> bool:
	"""Validate all input fields."""
	var display_name = display_name_input.text.strip_edges()
	
	# Validate display name
	if display_name.is_empty():
		_show_error("Display name cannot be empty")
		return false
	
	if display_name.length() < ProfileManager.MIN_USERNAME_LENGTH:
		_show_error("Display name must be at least %d characters" % ProfileManager.MIN_USERNAME_LENGTH)
		return false
	
	if display_name.length() > ProfileManager.MAX_USERNAME_LENGTH:
		_show_error("Display name cannot exceed %d characters" % ProfileManager.MAX_USERNAME_LENGTH)
		return false
	
	# Check for invalid characters (alphanumeric, spaces, underscores, hyphens only)
	var valid_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-"
	for c in display_name:
		if not c in valid_chars:
			_show_error("Display name contains invalid characters. Use only letters, numbers, spaces, underscores, and hyphens.")
			return false
	
	# Validate bio length (already enforced during typing, but double check)
	if bio_input.text.length() > MAX_BIO_LENGTH:
		_show_error("Bio exceeds maximum length of %d characters" % MAX_BIO_LENGTH)
		return false
	
	return true

func _has_unsaved_changes() -> bool:
	"""Check if there are unsaved changes."""
	if original_data.is_empty():
		return false
	
	var current_display_name = display_name_input.text.strip_edges()
	var current_bio = bio_input.text.strip_edges()
	var current_primary_color = primary_color_button.color.to_html()
	var current_accent_color = accent_color_button.color.to_html()
	
	return (
		selected_avatar != original_data.get("avatar", "") or
		current_display_name != original_data.get("display_name", "") or
		current_bio != original_data.get("bio", "") or
		current_primary_color != original_data.get("profile_color_primary", "") or
		current_accent_color != original_data.get("profile_color_accent", "")
	)

func _show_error(message: String) -> void:
	"""Display an error message."""
	error_label.text = message
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.visible = true

func _show_success(message: String) -> void:
	"""Display a success message."""
	error_label.text = message
	error_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	error_label.visible = true

func _hide_error() -> void:
	"""Hide the error label."""
	error_label.visible = false

func _navigate_back() -> void:
	"""Navigate back to the profile view screen."""
	SceneSwitcher.pop_scene()
