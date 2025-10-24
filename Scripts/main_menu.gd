
extends Control

# Profile display elements
var profile_display: PanelContainer
var profile_avatar: TextureRect
var profile_name_label: Label
var profile_level_label: Label

func _ready():
	_connect_buttons()
	_create_profile_display()
	_update_profile_display()

func _connect_buttons():
	var left_base := "MarginContainer/MainLayout/MiddleSection/LeftSidebar"
	
	var quickplay_btn = get_node_or_null(left_base + "/QuickplayButton")
	if quickplay_btn:
		quickplay_btn.pressed.connect(_on_quickplay)
	
	var online_btn = get_node_or_null(left_base + "/OnlineButton")
	if online_btn:
		online_btn.pressed.connect(_on_online)
	
	var practice_btn = get_node_or_null(left_base + "/PracticeButton")
	if practice_btn:
		practice_btn.pressed.connect(_on_practice)
	
	var news_btn = get_node_or_null(left_base + "/NewsButton")
	if news_btn:
		news_btn.pressed.connect(_on_news)
	
	var settings_btn = get_node_or_null(left_base + "/SettingsButton")
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	
	var quit_btn = get_node_or_null(left_base + "/QuitButton")
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)

func _create_profile_display():
	"""Create the profile display panel in the top-right corner."""
	var top_section = get_node_or_null("MarginContainer/MainLayout/TopSection")
	if not top_section:
		push_warning("MainMenu: TopSection not found")
		return
	
	# Create profile panel
	profile_display = PanelContainer.new()
	profile_display.name = "ProfileDisplay"
	profile_display.custom_minimum_size = Vector2(300, 100)
	
	# Style the panel
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
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	profile_display.add_theme_stylebox_override("panel", style)
	
	# Make clickable
	profile_display.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_display.gui_input.connect(_on_profile_display_clicked)
	
	# Content layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	profile_display.add_child(hbox)
	
	# Avatar
	profile_avatar = TextureRect.new()
	profile_avatar.custom_minimum_size = Vector2(70, 70)
	profile_avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	profile_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(profile_avatar)
	
	# Profile info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Name
	profile_name_label = Label.new()
	profile_name_label.add_theme_font_size_override("font_size", 20)
	profile_name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(profile_name_label)
	
	# Level
	profile_level_label = Label.new()
	profile_level_label.add_theme_font_size_override("font_size", 16)
	profile_level_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
	info_vbox.add_child(profile_level_label)
	
	# Click hint
	var hint_label = Label.new()
	hint_label.text = "Click to view profile"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(hint_label)
	
	# Add to top section (before featured song if it exists)
	var featured = top_section.get_node_or_null("FeaturedSong")
	if featured:
		top_section.add_child(profile_display)
		top_section.move_child(profile_display, featured.get_index())
	else:
		top_section.add_child(profile_display)
	
	# Add hover effect
	profile_display.mouse_entered.connect(_on_profile_hover_enter)
	profile_display.mouse_exited.connect(_on_profile_hover_exit)

func _update_profile_display():
	"""Update the profile display with current profile data."""
	if not profile_display:
		return
	
	# Check if profile is loaded
	if ProfileManager.current_profile.is_empty():
		profile_display.visible = false
		return
	
	profile_display.visible = true
	
	var profile = ProfileManager.current_profile
	
	# Update avatar
	var avatar_path = profile.get("avatar", "res://Assets/Profiles/Avatars/default.svg")
	if ResourceLoader.exists(avatar_path):
		profile_avatar.texture = load(avatar_path)
	
	# Update name
	var display_name = profile.get("display_name", profile.get("username", "Player"))
	profile_name_label.text = display_name
	
	# Update level
	var level = profile.get("level", 1)
	profile_level_label.text = "Level " + str(level)

func _on_profile_display_clicked(event: InputEvent):
	"""Handle clicks on the profile display."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_profile_view()

func _on_profile_hover_enter():
	"""Visual feedback when hovering over profile display."""
	if profile_display:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(profile_display, "scale", Vector2(1.02, 1.02), 0.15)

func _on_profile_hover_exit():
	"""Reset hover effect."""
	if profile_display:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(profile_display, "scale", Vector2(1.0, 1.0), 0.15)

# Navigation handlers
func _on_quickplay():
	SceneSwitcher.push_scene("res://Scenes/song_select.tscn")

func _on_online():
	print("Online mode not yet implemented")

func _on_practice():
	print("Practice mode not yet implemented")

func _on_news():
	print("News section not yet implemented")

func _on_settings():
	SceneSwitcher.push_scene("res://Scenes/settings.tscn")

func _on_quit():
	get_tree().quit()

func _on_profile_view():
	"""Navigate to profile view screen."""
	SceneSwitcher.push_scene("res://Scenes/profile_view.tscn")
