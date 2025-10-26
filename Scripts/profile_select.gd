extends Control

# profile_select.gd - Profile selection/creation screen
# First screen shown on game launch, allows users to select or create profiles

# UI elements from scene
@onready var profile_grid: GridContainer = %ProfileGrid
@onready var create_profile_button: Button = %CreateProfileButton
@onready var import_profile_button: Button = %ImportProfileButton
@onready var quit_button: Button = %QuitButton

# Dialog elements from scene
@onready var create_dialog: Window = $CreateProfileDialog
@onready var username_input: LineEdit = $CreateProfileDialog/DialogMargin/DialogContent/UsernameContainer/UsernameInput
@onready var display_name_input: LineEdit = $CreateProfileDialog/DialogMargin/DialogContent/DisplayNameContainer/DisplayNameInput
@onready var error_label: Label = $CreateProfileDialog/DialogMargin/DialogContent/UsernameContainer/ErrorLabel
@onready var create_button: Button = $CreateProfileDialog/DialogMargin/DialogContent/ButtonContainer/CreateButton
@onready var cancel_button: Button = $CreateProfileDialog/DialogMargin/DialogContent/ButtonContainer/CancelButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

# File dialog for import/export
var import_file_dialog: FileDialog
var export_file_dialog: FileDialog

# Profile being exported (for export dialog)
var profile_to_export: String = ""

# Currently displayed profile cards
var profile_cards: Array = []

# Track if we're switching profiles (vs initial selection)
var is_switching_profiles: bool = false
var active_profile_id: String = ""

func _ready():
	# Check if we're coming from main menu (switching) or initial launch
	is_switching_profiles = not ProfileManager.current_profile_id.is_empty()
	active_profile_id = ProfileManager.current_profile_id
	
	# Connect UI button signals
	create_profile_button.pressed.connect(_on_create_profile_pressed)
	import_profile_button.pressed.connect(_on_import_profile_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	create_button.pressed.connect(_on_create_confirm_pressed)
	cancel_button.pressed.connect(_on_create_cancel_pressed)
	
	# Create file dialogs
	_setup_file_dialogs()
	
	# Connect to ProfileManager signals
	ProfileManager.profile_created.connect(_on_profile_created)
	ProfileManager.profile_deleted.connect(_on_profile_deleted)
	
	# Load profiles
	_load_profiles()

func _setup_file_dialogs():
	"""Setup file dialogs for import/export."""
	# Import dialog
	import_file_dialog = FileDialog.new()
	import_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_file_dialog.add_filter("*.rgprofile", "Rhythm Game Profile")
	import_file_dialog.title = "Import Profile"
	import_file_dialog.size = Vector2i(800, 600)
	import_file_dialog.file_selected.connect(_on_import_file_selected)
	add_child(import_file_dialog)
	
	# Export dialog
	export_file_dialog = FileDialog.new()
	export_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_file_dialog.add_filter("*.rgprofile", "Rhythm Game Profile")
	export_file_dialog.title = "Export Profile"
	export_file_dialog.size = Vector2i(800, 600)
	export_file_dialog.file_selected.connect(_on_export_file_selected)
	add_child(export_file_dialog)

func _load_profiles():
	"""Load and display all existing profiles."""
	# Clear existing cards
	for card in profile_cards:
		card.queue_free()
	profile_cards.clear()
	
	# Get all profiles
	var profiles = ProfileManager.get_all_profiles()
	
	if profiles.is_empty():
		_show_no_profiles_message()
		return
	
	# Create card for each profile
	for profile_data in profiles:
		_create_profile_card(profile_data)

func _create_profile_card(profile_data: Dictionary):
	"""Create and add a profile card to the grid."""
	var card = ProfileCard.new()
	var profile_id = profile_data.profile_id
	var is_active = profile_id == active_profile_id
	
	# Configure card based on whether it's the active profile
	if is_active:
		# Active profile: can't delete, show indicator
		card.show_delete_button = false
		card.show_export_button = true
		card.show_active_indicator = true  # Will add this property
	else:
		# Inactive profiles: can delete and export
		card.show_delete_button = true
		card.show_export_button = true
		card.show_active_indicator = false
	
	card.set_profile_data(profile_data)
	
	# Connect signals
	card.card_clicked.connect(_on_profile_card_clicked)
	if not is_active:
		# Only connect delete for non-active profiles
		card.delete_requested.connect(_on_profile_delete_requested)
	card.export_requested.connect(_on_profile_export_requested)
	
	profile_grid.add_child(card)
	profile_cards.append(card)

func _show_no_profiles_message():
	"""Show message when no profiles exist."""
	var message = Label.new()
	message.text = "No profiles found.\nCreate a new profile to get started!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	profile_grid.add_child(message)

func _on_profile_card_clicked(profile_id: String):
	"""Handle profile card click - load profile and go to main menu."""
	var success = ProfileManager.load_profile(profile_id)
	
	if not success:
		push_error("Failed to load profile: " + profile_id)
		_show_error_message("Failed to load profile. Please try again.")
		return
	
	# NOTE: Achievements are now loaded automatically by ProfileManager.load_profile()
	
	print("Profile loaded: ", ProfileManager.current_profile.username)
	
	# Transition to main menu
	SceneSwitcher.push_scene("res://Scenes/main_menu.tscn")

func _on_create_profile_pressed():
	"""Show create profile dialog."""
	# Clear previous input
	username_input.text = ""
	display_name_input.text = ""
	error_label.text = " "
	error_label.visible = false
	
	# Focus username input and show dialog
	username_input.grab_focus()
	create_dialog.popup_centered()

func _on_create_confirm_pressed():
	"""Handle create profile confirmation."""
	var username = username_input.text.strip_edges()
	var display_name = display_name_input.text.strip_edges()
	
	# Validate username
	if username.is_empty():
		_show_dialog_error("Username is required")
		return
	
	if username.length() < 3:
		_show_dialog_error("Username must be at least 3 characters")
		return
	
	if username.length() > 20:
		_show_dialog_error("Username must be 20 characters or less")
		return
	
	# Check if username already exists
	var existing_profiles = ProfileManager.get_all_profiles()
	for profile in existing_profiles:
		if profile.username.to_lower() == username.to_lower():
			_show_dialog_error("Username already exists")
			return
	
	# Use username as display name if not provided
	if display_name.is_empty():
		display_name = username
	
	# Create profile
	var profile_id = ProfileManager.create_profile(username, display_name)
	
	if profile_id.is_empty():
		_show_dialog_error("Failed to create profile")
		return
	
	# Close dialog
	create_dialog.hide()
	
	print("Profile created: ", username)

func _on_create_cancel_pressed():
	"""Handle create profile cancellation."""
	create_dialog.hide()

func _show_dialog_error(message: String):
	"""Show error message in the dialog."""
	error_label.text = message
	error_label.visible = true

func _on_profile_created(_profile_id: String):
	"""Called when a new profile is created."""
	# Reload profiles display
	_load_profiles()

func _on_profile_deleted(_profile_id: String):
	"""Called when a profile is deleted."""
	# Reload profiles display
	_load_profiles()

func _on_profile_delete_requested(profile_id: String):
	"""Handle profile deletion request with confirmation."""
	# Get profile info for better messaging
	var profiles = ProfileManager.get_all_profiles()
	var username = "Unknown"
	for profile in profiles:
		if profile.profile_id == profile_id:
			username = profile.username
			break
	
	delete_confirm_dialog.dialog_text = "Are you sure you want to delete the profile '" + username + "'?\n\nAll associated data will be permanently lost:\n• Scores and rankings\n• Achievements and progress\n• Settings and keybindings\n\nThis action cannot be undone!"
	
	# Disconnect any previous connections
	if delete_confirm_dialog.confirmed.is_connected(_delete_profile):
		delete_confirm_dialog.confirmed.disconnect(_delete_profile)
	
	# Connect with profile_id as parameter
	delete_confirm_dialog.confirmed.connect(_delete_profile.bind(profile_id), CONNECT_ONE_SHOT)
	delete_confirm_dialog.popup_centered()

func _delete_profile(profile_id: String):
	"""Actually delete the profile."""
	var success = ProfileManager.delete_profile(profile_id)
	if not success:
		_show_error_message("Failed to delete profile")

func _show_error_message(message: String):
	"""Show error message to user."""
	var error_popup = AcceptDialog.new()
	error_popup.dialog_text = message
	error_popup.title = "Error"
	add_child(error_popup)
	error_popup.popup_centered()

func _on_quit_pressed():
	"""Handle quit button press."""
	get_tree().quit()

# ============================================================================
# Import/Export Functionality
# ============================================================================

func _on_import_profile_pressed():
	"""Handle import profile button press."""
	# Show file picker
	import_file_dialog.popup_centered()

func _on_import_file_selected(path: String):
	"""Handle file selected for import."""
	# Defer validation to allow FileDialog to close first
	call_deferred("_validate_and_import", path)

func _validate_and_import(path: String):
	"""Validate and import the profile (called deferred)."""
	# Validate the profile package first
	var validation = ProfileManager.validate_profile_package(path)
	
	if not validation.valid:
		var error_msg = "Failed to validate profile package:\n\n"
		for error in validation.errors:
			error_msg += "• " + error + "\n"
		_show_error_message(error_msg)
		return
	
	# Check for username conflict
	var existing_profiles = ProfileManager.get_all_profiles()
	var username_exists = false
	
	for profile in existing_profiles:
		if profile.username.to_lower() == validation.username.to_lower():
			username_exists = true
			break
	
	# If conflict, show rename dialog
	if username_exists:
		_show_import_conflict_dialog(path, validation.username)
	else:
		# No conflict, import directly
		_perform_import(path, "rename")

func _show_import_conflict_dialog(file_path: String, username: String):
	"""Show dialog to resolve username conflict during import."""
	var conflict_dialog = AcceptDialog.new()
	conflict_dialog.title = "Username Conflict"
	conflict_dialog.dialog_text = "A profile with username '" + username + "' already exists.\n\nThe imported profile will be renamed to '" + username + "_imported'."
	conflict_dialog.ok_button_text = "Import with New Name"
	
	# Add cancel button
	conflict_dialog.add_cancel_button("Cancel")
	
	conflict_dialog.confirmed.connect(func():
		_perform_import(file_path, "rename", username + "_imported")
		conflict_dialog.queue_free()
	)
	
	conflict_dialog.canceled.connect(func():
		conflict_dialog.queue_free()
	)
	
	add_child(conflict_dialog)
	conflict_dialog.popup_centered()

func _perform_import(file_path: String, on_conflict: String, new_username: String = ""):
	"""Actually perform the profile import."""
	var options = {
		"on_conflict": on_conflict
	}
	
	if not new_username.is_empty():
		options["new_username"] = new_username
	
	var result = ProfileManager.import_profile(file_path, options)
	
	if not result.success:
		_show_error_message("Import failed: " + result.error)
		return
	
	# Show success message
	var success_dialog = AcceptDialog.new()
	success_dialog.title = "Import Successful"
	success_dialog.dialog_text = "Profile imported successfully!"
	success_dialog.confirmed.connect(func():
		success_dialog.queue_free()
	)
	add_child(success_dialog)
	success_dialog.popup_centered()
	
	print("Profile imported successfully: " + result.profile_id)

func _on_profile_export_requested(profile_id: String):
	"""Handle export request from profile card."""
	profile_to_export = profile_id
	
	# Get profile username for default filename
	var profiles = ProfileManager.get_all_profiles()
	var username = "profile"
	for profile in profiles:
		if profile.profile_id == profile_id:
			username = profile.username
			break
	
	# Set default filename
	export_file_dialog.current_file = username + ".rgprofile"
	export_file_dialog.popup_centered()

func _on_export_file_selected(path: String):
	"""Handle file selected for export."""
	if profile_to_export.is_empty():
		_show_error_message("No profile selected for export")
		return
	
	# Ensure .rgprofile extension
	if not path.ends_with(".rgprofile"):
		path += ".rgprofile"
	
	# Defer showing the export options dialog to allow FileDialog to close first
	call_deferred("_show_export_options_dialog", path)

func _show_export_options_dialog(destination_path: String):
	"""Show dialog with export options."""
	var options_dialog = AcceptDialog.new()
	options_dialog.title = "Export Options"
	options_dialog.dialog_text = "Choose what to include in the export:"
	options_dialog.ok_button_text = "Export"
	
	# Create container for checkboxes
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var scores_check = CheckBox.new()
	scores_check.text = "Include Scores"
	scores_check.button_pressed = true
	scores_check.name = "ScoresCheck"
	vbox.add_child(scores_check)
	
	var achievements_check = CheckBox.new()
	achievements_check.text = "Include Achievements"
	achievements_check.button_pressed = true
	achievements_check.name = "AchievementsCheck"
	vbox.add_child(achievements_check)
	
	var settings_check = CheckBox.new()
	settings_check.text = "Include Settings (keybindings, note speed)"
	settings_check.button_pressed = true
	settings_check.name = "SettingsCheck"
	vbox.add_child(settings_check)
	
	# Add to dialog
	options_dialog.add_child(vbox)
	
	options_dialog.confirmed.connect(func():
		var options = {
			"include_scores": scores_check.button_pressed,
			"include_achievements": achievements_check.button_pressed,
			"include_settings": settings_check.button_pressed,
			"full_path": destination_path  # Pass full path including user's chosen filename
		}
		_perform_export(destination_path, options)
		options_dialog.queue_free()
	)
	
	options_dialog.canceled.connect(func():
		options_dialog.queue_free()
	)
	
	add_child(options_dialog)
	options_dialog.popup_centered()

func _perform_export(_destination_path: String, options: Dictionary):
	"""Actually perform the profile export."""
	var result = ProfileManager.export_profile(profile_to_export, options)
	
	if not result.success:
		_show_error_message("Export failed: " + result.error)
		return
	
	# Show success message with path
	var success_dialog = AcceptDialog.new()
	success_dialog.title = "Export Successful"
	success_dialog.dialog_text = "Profile exported successfully!\n\nSaved to:\n" + result.path
	
	# Add button to open folder
	var _open_folder_button = success_dialog.add_button("Open Folder", false, "open_folder")
	
	success_dialog.custom_action.connect(func(action):
		if action == "open_folder":
			OS.shell_open(result.path.get_base_dir())
	)
	
	success_dialog.confirmed.connect(func():
		success_dialog.queue_free()
	)
	
	add_child(success_dialog)
	success_dialog.popup_centered()
	
	print("Profile exported successfully: " + result.path)
