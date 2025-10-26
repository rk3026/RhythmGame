
extends Control

# Node references
@onready var profile_display = %ProfileDisplay

func _ready():
	_connect_buttons()
	_connect_profile_display()

func _connect_profile_display():
	"""Connect to ProfileDisplay signals."""
	if profile_display:
		profile_display.profile_clicked.connect(_on_profile_view)

func _connect_buttons():
	var left_base := "MarginContainer/MainLayout/MiddleSection/LeftSidebar"
	
	var quickplay_btn = get_node_or_null(left_base + "/QuickplayButton")
	if quickplay_btn:
		quickplay_btn.pressed.connect(_on_quickplay)
		_connect_ui_sounds(quickplay_btn)
	
	var online_btn = get_node_or_null(left_base + "/OnlineButton")
	if online_btn:
		online_btn.pressed.connect(_on_online)
		_connect_ui_sounds(online_btn)
	
	var practice_btn = get_node_or_null(left_base + "/PracticeButton")
	if practice_btn:
		practice_btn.pressed.connect(_on_practice)
		_connect_ui_sounds(practice_btn)
	
	var news_btn = get_node_or_null(left_base + "/NewsButton")
	if news_btn:
		news_btn.pressed.connect(_on_news)
		_connect_ui_sounds(news_btn)
	
	var settings_btn = get_node_or_null(left_base + "/SettingsButton")
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
		_connect_ui_sounds(settings_btn)
	
	var switch_profile_btn = get_node_or_null(left_base + "/SwitchProfileButton")
	if switch_profile_btn:
		switch_profile_btn.pressed.connect(_on_switch_profile)
		_connect_ui_sounds(switch_profile_btn)
	
	var quit_btn = get_node_or_null(left_base + "/QuitButton")
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
		_connect_ui_sounds(quit_btn)

func _connect_ui_sounds(button: Button):
	"""Connect UI sound effects to button interactions."""
	if SoundEffectManager:
		button.mouse_entered.connect(func(): 
			SoundEffectManager.play_sfx("ui_hover", SoundEffectManager.SoundCategory.UI_HOVER)
		)
		button.pressed.connect(func(): 
			SoundEffectManager.play_sfx("ui_click", SoundEffectManager.SoundCategory.UI_CLICK)
		)

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

func _on_switch_profile():
	"""Return to profile select screen to switch profiles."""
	# Clear the scene stack and go back to profile select
	SceneSwitcher.change_scene("res://Scenes/profile_select.tscn")

func _on_quit():
	get_tree().quit()

func _on_profile_view():
	"""Navigate to profile view screen."""
	SceneSwitcher.push_scene("res://Scenes/profile_view.tscn")
