extends Panel

signal scrub_requested(delta_seconds)
signal toggle_direction_requested()

var time_label: Label
var direction_label: Label
var progress_label: Label
var audio_label: Label
var back_button: Button
var forward_button: Button
var toggle_dir_button: Button

func _ready():
	_assign_nodes()
	_connect_buttons()

func update_display(current_time: float, direction: int, executed: int, total: int, has_audio: bool, audio_position: float):
	if time_label:
		time_label.text = "Time: %.3f" % current_time
	if direction_label:
		direction_label.text = "Dir: %s" % ("+1" if direction == 1 else "-1")
	if progress_label:
		progress_label.text = "Exec: %d/%d" % [executed, total]
	if audio_label:
		audio_label.visible = has_audio
		if has_audio:
			audio_label.text = "Audio: %.3f" % audio_position

func _on_back_pressed():
	emit_signal("scrub_requested", -2.0)

func _on_forward_pressed():
	emit_signal("scrub_requested", 2.0)

func _on_toggle_dir_pressed():
	emit_signal("toggle_direction_requested")

func _assign_nodes():
	time_label = _get_label("VBox/TimeLabel")
	direction_label = _get_label("VBox/DirectionLabel")
	progress_label = _get_label("VBox/ProgressLabel")
	audio_label = _get_label("VBox/AudioLabel")
	back_button = _get_button("VBox/Buttons/Back2")
	forward_button = _get_button("VBox/Buttons/Fwd2")
	toggle_dir_button = _get_button("VBox/Buttons/ToggleDir")

func _connect_buttons():
	if back_button:
		back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	else:
		push_warning("TimelineDebugUI missing back scrub button")
	if forward_button:
		forward_button.connect("pressed", Callable(self, "_on_forward_pressed"))
	else:
		push_warning("TimelineDebugUI missing forward scrub button")
	if toggle_dir_button:
		toggle_dir_button.connect("pressed", Callable(self, "_on_toggle_dir_pressed"))
	else:
		push_warning("TimelineDebugUI missing toggle direction button")

func _get_label(path: String) -> Label:
	var node = get_node_or_null(path)
	if node == null:
		push_warning("TimelineDebugUI missing node: %s" % path)
	return node as Label

func _get_button(path: String) -> Button:
	var node = get_node_or_null(path)
	if node == null:
		push_warning("TimelineDebugUI missing node: %s" % path)
	return node as Button
