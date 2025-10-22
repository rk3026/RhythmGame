
extends Control

# Reference to notification banner (should be defined in .tscn)
@onready var notification_banner: Node = $NotificationBanner

func _ready():
	_connect_buttons()
	_show_welcome_notification()

func _connect_buttons():
	# Connect button signals - buttons should be defined with AnimatedButton script in .tscn
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

func _show_welcome_notification():
	if notification_banner:
		# Show welcome message after a short delay
		await get_tree().create_timer(0.5).timeout
		notification_banner.show_notification(
			"💡 Tip: Check out the Settings to customize controls and note speed!",
			notification_banner.NotificationType.INFO
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

func _on_quit():
	get_tree().quit()
