extends Control

# profile_select.gd - Profile selection/creation screen
# First screen shown on game launch, allows users to select or create profiles

# UI elements from scene
@onready var profile_grid: GridContainer = %ProfileGrid
@onready var create_profile_button: Button = %CreateProfileButton
@onready var quit_button: Button = %QuitButton

# Dialog elements from scene
@onready var create_dialog: Window = $CreateProfileDialog
@onready var username_input: LineEdit = $CreateProfileDialog/DialogMargin/DialogContent/UsernameContainer/UsernameInput
@onready var display_name_input: LineEdit = $CreateProfileDialog/DialogMargin/DialogContent/DisplayNameContainer/DisplayNameInput
@onready var error_label: Label = $CreateProfileDialog/DialogMargin/DialogContent/UsernameContainer/ErrorLabel
@onready var create_button: Button = $CreateProfileDialog/DialogMargin/DialogContent/ButtonContainer/CreateButton
@onready var cancel_button: Button = $CreateProfileDialog/DialogMargin/DialogContent/ButtonContainer/CancelButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

# Currently displayed profile cards
var profile_cards: Array = []

func _ready():
	# Connect UI button signals
	create_profile_button.pressed.connect(_on_create_profile_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	create_button.pressed.connect(_on_create_confirm_pressed)
	cancel_button.pressed.connect(_on_create_cancel_pressed)
	
	# Connect to ProfileManager signals
	ProfileManager.profile_created.connect(_on_profile_created)
	ProfileManager.profile_deleted.connect(_on_profile_deleted)
	
	# Load profiles
	_load_profiles()

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
	card.show_delete_button = true
	card.set_profile_data(profile_data)
	
	# Connect signals
	card.card_clicked.connect(_on_profile_card_clicked)
	card.delete_requested.connect(_on_profile_delete_requested)
	
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
	
	# Load achievements for this profile
	AchievementManager.load_profile_achievements(profile_id)
	
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
	delete_confirm_dialog.dialog_text = "Are you sure you want to delete this profile?\nThis action cannot be undone!"
	
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
