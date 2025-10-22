extends Control

@onready var _note_speed_slider: HSlider = $Margin/VBox/Scroll/Options/NoteSpeedProgress/Slider
@onready var _note_speed_label: Label = $Margin/VBox/Scroll/Options/NoteSpeedProgress/ValueLabel
@onready var _volume_slider: HSlider = $Margin/VBox/Scroll/Options/MasterVolumeProgress/Slider
@onready var _volume_label: Label = $Margin/VBox/Scroll/Options/MasterVolumeProgress/ValueLabel

var waiting_for_key_index: int = -1

func _ready():
	_load_values_into_ui()
	_connect_signals()

func _connect_signals():
	# Connect note speed slider
	_note_speed_slider.value_changed.connect(_on_note_speed_changed)
	
	# Connect volume slider
	_volume_slider.value_changed.connect(_on_volume_changed)
	
	# Connect timing offset spinbox
	$Margin/VBox/Scroll/Options/TimingOffsetHBox/TimingOffsetSpin.value_changed.connect(_on_offset_changed)
	
	# Connect lane key buttons
	var lane_keys_container = $Margin/VBox/Scroll/Options/LaneKeys
	for i in range(lane_keys_container.get_child_count()):
		var lane_row = lane_keys_container.get_child(i)
		var keybind_display = lane_row.get_node("KeybindDisplay")
		keybind_display.keybind_changed.connect(_start_rebind.bind(i))
	
	# Connect back button
	$Margin/VBox/BackButton.pressed.connect(_on_back)

func get_settings_manager():
	return SettingsManager

func _load_values_into_ui():
	# Load note speed
	_note_speed_slider.value = SettingsManager.note_speed
	_note_speed_label.text = str(int(SettingsManager.note_speed))
	
	# Load master volume
	_volume_slider.value = SettingsManager.master_volume
	_volume_label.text = str(int(SettingsManager.master_volume * 100)) + "%"
	
	# Load timing offset
	$Margin/VBox/Scroll/Options/TimingOffsetHBox/TimingOffsetSpin.value = int(SettingsManager.timing_offset * 1000.0)
	
	# Load lane keys
	var lane_keys_container = $Margin/VBox/Scroll/Options/LaneKeys
	for i in range(min(lane_keys_container.get_child_count(), SettingsManager.lane_keys.size())):
		var lane_row = lane_keys_container.get_child(i)
		var keybind_display = lane_row.get_node("KeybindDisplay")
		keybind_display.key_text = OS.get_keycode_string(SettingsManager.lane_keys[i])

func _on_note_speed_changed(value: float):
	SettingsManager.note_speed = value
	_note_speed_label.text = str(int(value))
	SettingsManager.save_settings()

func _on_volume_changed(value: float):
	SettingsManager.master_volume = value
	_volume_label.text = str(int(value * 100)) + "%"
	SettingsManager.save_settings()

func _on_offset_changed(value):
	# store in seconds internally
	SettingsManager.set_timing_offset(float(value) / 1000.0)

func _on_keybind_gui_input(event: InputEvent, lane_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_rebind(lane_index)

func _start_rebind(index: int):
	waiting_for_key_index = index
	var lane_keys_container = $Margin/VBox/Scroll/Options/LaneKeys
	var lane_row = lane_keys_container.get_child(index)
	var keybind_display = lane_row.get_node("KeybindDisplay")
	keybind_display.key_text = "Press a key..."
	keybind_display.set_state(keybind_display.KeyState.WAITING)
	set_process_input(true)

func _input(event):
	if waiting_for_key_index >= 0 and event is InputEventKey and event.pressed and not event.echo:
		# ESC cancels rebind
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			return
		
		# Update the keybind
		SettingsManager.set_lane_key(waiting_for_key_index, event.keycode)
		
		var lane_keys_container = $Margin/VBox/Scroll/Options/LaneKeys
		var lane_row = lane_keys_container.get_child(waiting_for_key_index)
		var keybind_display = lane_row.get_node("KeybindDisplay")
		keybind_display.key_text = OS.get_keycode_string(event.keycode)
		keybind_display.set_state(keybind_display.KeyState.NORMAL)
		
		waiting_for_key_index = -1
		set_process_input(false)
		
		# Immediately save and apply the change
		SettingsManager.save_settings()

func _cancel_rebind():
	if waiting_for_key_index >= 0:
		var lane_keys_container = $Margin/VBox/Scroll/Options/LaneKeys
		var lane_row = lane_keys_container.get_child(waiting_for_key_index)
		var keybind_display = lane_row.get_node("KeybindDisplay")
		keybind_display.key_text = OS.get_keycode_string(SettingsManager.get_lane_key(waiting_for_key_index))
		keybind_display.set_state(keybind_display.KeyState.NORMAL)
		waiting_for_key_index = -1
		set_process_input(false)

func _on_save():
	SettingsManager.save_settings()

func _on_reset():
	SettingsManager.reset_defaults()
	_load_values_into_ui()

func _on_back():
	SettingsManager.save_settings()
	SceneSwitcher.pop_scene()
