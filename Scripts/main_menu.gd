
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
			# Add hover effects
			btn.connect("mouse_entered", Callable(self, "_on_button_hover_enter").bind(btn))
			btn.connect("mouse_exited", Callable(self, "_on_button_hover_exit").bind(btn))
			# Set pivot for center scaling
			if btn is Button:
				btn.pivot_offset = btn.size / 2.0
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

func _on_button_hover_enter(button: Button):
	# Animate scale up and brighten
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2)
	
	# Brighten button (modulate makes it lighter)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_button_hover_exit(button: Button):
	# Animate back to normal
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Reset brightness
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
