
extends Control

func _ready():
	# Use the actual container path created in the scene file.
	var left_base := "MarginContainer/MainLayout/MiddleSection/LeftSidebar"
	var mapping := {
		"QuickplayButton": "_on_quickplay",
		"OnlineButton": "_on_online",
		"PracticeButton": "_on_practice",
		"NewsButton": "_on_news",
		"SettingsButton": "_on_settings",
		"QuitButton": "_on_quit",
	}

	for btn_name in mapping.keys():
		var node_path = left_base + "/" + btn_name
		var btn = get_node_or_null(node_path)
		if btn:
			btn.connect("pressed", Callable(self, mapping[btn_name]))
		else:
			push_warning("MainMenu: button not found: %s" % node_path)

func _on_quickplay():
	# Go to song selection (same as old Play button)
	SceneSwitcher.push_scene("res://Scenes/song_select.tscn")

func _on_online():
	# Placeholder - not implemented yet
	print("Online mode not yet implemented")

func _on_practice():
	# Placeholder - could go to song select with practice mode flag
	print("Practice mode not yet implemented")

func _on_news():
	# Placeholder - could show news details
	print("News section not yet implemented")

func _on_settings():
	SceneSwitcher.push_scene("res://Scenes/settings.tscn")

func _on_quit():
	get_tree().quit()
