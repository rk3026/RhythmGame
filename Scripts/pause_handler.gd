extends Node

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		get_parent()._on_pause_button_pressed()
