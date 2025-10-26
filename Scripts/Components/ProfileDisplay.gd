extends PanelContainer

# ProfileDisplay.gd - Reusable profile display component
# Shows avatar, name, and level with click interaction
# UI layout is defined in ProfileDisplay.tscn - this script only handles data and interactions

# Signals
signal profile_clicked()

# Node references
@onready var profile_avatar: TextureRect = %ProfileAvatar
@onready var profile_name: Label = %ProfileName
@onready var profile_level: Label = %ProfileLevel

func _ready() -> void:
	# Make clickable
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	# Add hover effects
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	
	# Connect to ProfileManager signals for live updates
	ProfileManager.profile_updated.connect(_on_profile_updated)
	ProfileManager.profile_loaded.connect(_on_profile_loaded)
	ProfileManager.level_up.connect(_on_level_up)
	
	# Load initial data
	update_display()

func update_display() -> void:
	"""Update the display with current profile data."""
	# Check if profile is loaded
	if ProfileManager.current_profile.is_empty():
		visible = false
		return
	
	visible = true
	
	var profile = ProfileManager.current_profile
	
	# Update avatar
	var avatar_path = profile.get("avatar", "res://Assets/Profiles/Avatars/default.svg")
	if ResourceLoader.exists(avatar_path):
		profile_avatar.texture = load(avatar_path)
	
	# Update name
	var display_name = profile.get("display_name", profile.get("username", "Player"))
	profile_name.text = display_name
	
	# Update level
	var level = profile.get("level", 1)
	profile_level.text = "Level " + str(level)

func _on_gui_input(event: InputEvent) -> void:
	"""Handle input events."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("profile_clicked")

func _on_hover_enter() -> void:
	"""Visual feedback when hovering."""
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.15)

func _on_hover_exit() -> void:
	"""Reset hover effect."""
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _on_profile_updated(_field: String, _value: Variant) -> void:
	"""Handle profile updates."""
	update_display()

func _on_profile_loaded(_profile_id: String) -> void:
	"""Handle profile loaded."""
	update_display()

func _on_level_up(_new_level: int, _old_level: int) -> void:
	"""Handle level up."""
	update_display()
