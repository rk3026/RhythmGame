extends Node

class_name AudioManager

signal countdown_finished

var audio_player: AudioStreamPlayer
var song_start_time: float
var settings_manager

func _ready():
	settings_manager = _get_settings_manager()

func _get_settings_manager():
	if Engine.has_singleton("SettingsManager"):
		return Engine.get_singleton("SettingsManager")
	return null

func load_audio(audio_path: String, offset: float):
	if audio_path and FileAccess.file_exists(audio_path):
		audio_player = AudioStreamPlayer.new()
		audio_player.stream = load(audio_path)
		add_child(audio_player)
		start_countdown(offset)
	else:
		print("No audio file found")
		countdown_finished.emit()

func start_countdown(offset: float):
	var label = get_parent().get_node("UI/JudgementLabel")
	for i in range(3, 0, -1):
		label.text = str(i)
		label.modulate = Color.WHITE
		label.modulate.a = 1
		await get_tree().create_timer(1.0).timeout
	label.text = "Go!"
	await get_tree().create_timer(0.5).timeout
	label.text = ""
	if audio_player:
		if offset < 0:
			audio_player.play(-offset)
		else:
			audio_player.play()
	countdown_finished.emit()

func sync_audio(desired_time: float, direction: int):
	if audio_player and direction == 1 and audio_player.playing:
		var diff = abs(audio_player.get_playback_position() - desired_time)
		if diff > 0.050:
			audio_player.seek(desired_time)

func is_audio_finished() -> bool:
	return audio_player == null or not audio_player.playing

func get_audio_position() -> float:
	return audio_player.get_playback_position() if audio_player else 0.0