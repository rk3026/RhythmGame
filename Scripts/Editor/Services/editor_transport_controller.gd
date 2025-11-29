extends RefCounted
class_name EditorTransportController

var timeline_slider: Range
var time_label: Label
var play_button: BaseButton
var pause_button: BaseButton
var stop_button: BaseButton
var playback_controller: EditorPlaybackController
var on_time_scrubbed: Callable
var song_duration: float = 0.0

func configure(params: Dictionary) -> void:
	timeline_slider = params.get("timeline_slider")
	time_label = params.get("time_label")
	play_button = params.get("play_button")
	pause_button = params.get("pause_button")
	stop_button = params.get("stop_button")
	playback_controller = params.get("playback_controller")
	on_time_scrubbed = params.get("time_scrubbed_callable", Callable())
	_connect_controls()
	if playback_controller:
		playback_controller.playback_state_changed.connect(_on_playback_state_changed)
	_update_button_states(playback_controller and playback_controller.is_playing)
	_set_slider_max()

func set_song_duration(duration: float) -> void:
	song_duration = max(duration, 0.0)
	_set_slider_max()

func set_current_time(time_value: float) -> void:
	if timeline_slider:
		timeline_slider.set_value_no_signal(clamp(time_value, 0.0, song_duration if song_duration > 0.0 else time_value))
	if time_label:
		time_label.text = _format_time(time_value)

func toggle_playback() -> void:
	if not playback_controller:
		if on_time_scrubbed.is_valid():
			on_time_scrubbed.call(get_current_time())
		return
	if playback_controller.is_playing:
		playback_controller.pause()
	else:
		playback_controller.play()

func get_current_time() -> float:
	if playback_controller:
		return playback_controller.get_current_time()
	return timeline_slider.value if timeline_slider else 0.0

func _connect_controls() -> void:
	if timeline_slider and not timeline_slider.value_changed.is_connected(_on_timeline_changed):
		timeline_slider.value_changed.connect(_on_timeline_changed)
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if pause_button and not pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.connect(_on_pause_pressed)
	if stop_button and not stop_button.pressed.is_connected(_on_stop_pressed):
		stop_button.pressed.connect(_on_stop_pressed)

func _on_play_pressed() -> void:
	if playback_controller:
		playback_controller.play()

func _on_pause_pressed() -> void:
	if playback_controller:
		playback_controller.pause()

func _on_stop_pressed() -> void:
	if playback_controller:
		playback_controller.stop()

func _on_timeline_changed(value: float) -> void:
	if playback_controller:
		playback_controller.seek(value)
	elif on_time_scrubbed.is_valid():
		on_time_scrubbed.call(value)

func _on_playback_state_changed(is_now_playing: bool) -> void:
	_update_button_states(is_now_playing)

func _update_button_states(is_playing: bool) -> void:
	if play_button:
		play_button.disabled = is_playing
	if pause_button:
		pause_button.disabled = not is_playing

func _set_slider_max() -> void:
	if timeline_slider:
		var max_value = song_duration if song_duration > 0.0 else timeline_slider.max_value
		timeline_slider.max_value = max_value

func _format_time(time_value: float) -> String:
	var minutes = int(time_value) / 60
	var seconds = int(time_value) % 60
	var milliseconds = int((time_value - int(time_value)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
