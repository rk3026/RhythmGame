extends HBoxContainer
class_name EditorPlaybackControls
## Editor Playback Controls Component
## Manages transport controls, timeline, and playback speed

signal play_requested()
signal pause_requested()
signal stop_requested()
signal seek_requested(position: float)
signal speed_changed(speed: float)
signal skip_to_start_requested()
signal skip_to_end_requested()

@onready var skip_start_button: Button = $SkipStartButton
@onready var play_button: Button = $PlayButton
@onready var pause_button: Button = $PauseButton
@onready var stop_button: Button = $StopButton
@onready var skip_end_button: Button = $SkipEndButton
@onready var time_label: Label = $TimeLabel
@onready var timeline_slider: HSlider = $TimelineSlider
@onready var duration_label: Label = $DurationLabel
@onready var speed_selector: OptionButton = $SpeedSelector

var is_playing: bool = false
var _updating_slider: bool = false

# Speed options matching Moonscraper
const SPEED_OPTIONS = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

func _ready():
	_setup_speed_options()
	_connect_signals()
	_update_button_states()

func _setup_speed_options():
	speed_selector.clear()
	for speed in SPEED_OPTIONS:
		speed_selector.add_item(str(speed) + "x")
	speed_selector.selected = 3  # Default to 1.0x

func _connect_signals():
	skip_start_button.pressed.connect(_on_skip_start_pressed)
	play_button.pressed.connect(_on_play_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	skip_end_button.pressed.connect(_on_skip_end_pressed)
	timeline_slider.drag_started.connect(_on_timeline_drag_started)
	timeline_slider.drag_ended.connect(_on_timeline_drag_ended)
	timeline_slider.value_changed.connect(_on_timeline_value_changed)
	speed_selector.item_selected.connect(_on_speed_selected)

func _on_skip_start_pressed():
	skip_to_start_requested.emit()

func _on_play_pressed():
	is_playing = true
	_update_button_states()
	play_requested.emit()

func _on_pause_pressed():
	is_playing = false
	_update_button_states()
	pause_requested.emit()

func _on_stop_pressed():
	is_playing = false
	_update_button_states()
	stop_requested.emit()

func _on_skip_end_pressed():
	skip_to_end_requested.emit()

func _on_timeline_drag_started():
	_updating_slider = true

func _on_timeline_drag_ended(_value_changed: bool):
	_updating_slider = false
	seek_requested.emit(timeline_slider.value)

func _on_timeline_value_changed(value: float):
	if not _updating_slider:
		seek_requested.emit(value)
	_update_time_label(value)

func _on_speed_selected(index: int):
	var speed = SPEED_OPTIONS[index]
	speed_changed.emit(speed)

func _update_button_states():
	play_button.disabled = is_playing
	pause_button.disabled = not is_playing
	stop_button.disabled = not is_playing

func set_playing(playing: bool):
	is_playing = playing
	_update_button_states()

func set_duration(duration: float):
	timeline_slider.max_value = duration
	_update_duration_label(duration)

func update_position(time_position: float):
	if not _updating_slider:
		timeline_slider.value = time_position
	_update_time_label(time_position)

func _update_time_label(time: float):
	var minutes = int(time / 60.0)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	time_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _update_duration_label(time: float):
	var minutes = int(time / 60.0)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	duration_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func get_selected_speed() -> float:
	return SPEED_OPTIONS[speed_selector.selected]

func set_speed(speed: float):
	var index = SPEED_OPTIONS.find(speed)
	if index != -1:
		speed_selector.selected = index
