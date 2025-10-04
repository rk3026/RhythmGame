extends Control

func _ready():
	$CenterContainer/VBox/PlayButton.connect("pressed", Callable(self, "_on_play"))
	$CenterContainer/VBox/SettingsButton.connect("pressed", Callable(self, "_on_settings"))
	$CenterContainer/VBox/QuitButton.connect("pressed", Callable(self, "_on_quit"))

func _on_play():
	SceneSwitcher.push_scene("res://Scenes/song_select.tscn")

func _on_settings():
	SceneSwitcher.push_scene("res://Scenes/settings.tscn")

func _on_quit():
	get_tree().quit()
