extends Node

class_name UIManager

var debug_labels = {}

func _ready():
	pass

func connect_pause_buttons(gameplay_node: Node):
	var pause_button = gameplay_node.get_node("UI/PauseButton")
	pause_button.connect("pressed", Callable(gameplay_node, "_on_pause_button_pressed"))
	
	var pause_menu = gameplay_node.get_node("UI/PauseMenu/Panel/VBoxContainer")
	pause_menu.get_node("ResumeButton").connect("pressed", Callable(gameplay_node, "_on_resume"))
	pause_menu.get_node("EndSongButton").connect("pressed", Callable(gameplay_node, "_on_end_song"))
	pause_menu.get_node("SongSelectButton").connect("pressed", Callable(gameplay_node, "_on_song_select"))
	pause_menu.get_node("MainMenuButton").connect("pressed", Callable(gameplay_node, "_on_main_menu"))

func update_debug_ui(timeline_controller: Node):
	if not timeline_controller:
		return
	var ui = get_parent().get_node("UI")
	if ui.has_node("DebugTimeline"):
		var dbg = ui.get_node("DebugTimeline")
		if dbg.has_node("VBox/TimeLabel"):
			dbg.get_node("VBox/TimeLabel").text = "Time: %.3f" % timeline_controller.current_time
		if dbg.has_node("VBox/DirectionLabel"):
			dbg.get_node("VBox/DirectionLabel").text = "Dir: %s" % ("+1" if timeline_controller.direction == 1 else "-1")
		if dbg.has_node("VBox/ProgressLabel"):
			dbg.get_node("VBox/ProgressLabel").text = "Exec: %d/%d" % [timeline_controller.executed_count, timeline_controller.command_log.size()]
		# Audio time
		if not debug_labels.has("AudioLabel") and ui.has_node("DebugTimeline/VBox/AudioLabel"):
			debug_labels["AudioLabel"] = ui.get_node("DebugTimeline/VBox/AudioLabel")
		if debug_labels.has("AudioLabel"):
			var audio_mgr = get_parent().get_node("AudioManager")
			debug_labels["AudioLabel"].text = "Audio: %.3f" % audio_mgr.get_audio_position()

func show_pause_menu():
	get_parent().get_node("UI/PauseMenu").visible = true
	get_parent().get_node("UI/PauseButton").visible = false

func hide_pause_menu():
	get_parent().get_node("UI/PauseMenu").visible = false
	get_parent().get_node("UI/PauseButton").visible = true