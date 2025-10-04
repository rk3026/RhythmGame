extends Control

var waiting_for_key_index: int = -1
var settings_manager

func _ready():
	settings_manager = get_settings_manager()
	_build_lane_key_rows()
	_load_values_into_ui()
	# Connections
	$Margin/VBox/BackButton.connect("pressed", Callable(self, "_on_back"))
	$Margin/VBox/ButtonsHBox/SaveButton.connect("pressed", Callable(self, "_on_save"))
	$Margin/VBox/ButtonsHBox/ResetButton.connect("pressed", Callable(self, "_on_reset"))
	$Margin/VBox/Scroll/Options/NoteSpeedHBox/NoteSpeedSlider.connect("value_changed", Callable(self, "_on_note_speed_changed"))
	$Margin/VBox/Scroll/Options/MasterVolHBox/MasterSlider.connect("value_changed", Callable(self, "_on_master_changed"))
	$Margin/VBox/Scroll/Options/TimingOffsetHBox/TimingOffsetSpin.connect("value_changed", Callable(self, "_on_offset_changed"))

func get_settings_manager():
	if Engine.has_singleton("SettingsManager"):
		return Engine.get_singleton("SettingsManager")
	# Fallback: instance local (not persistent across runs)
	var sm = load("res://Scripts/settings_manager.gd").new()
	add_child(sm)
	return sm

func _build_lane_key_rows():
	var lane_box = $Margin/VBox/Scroll/Options/LaneKeys
	# Remove existing children (VBoxContainer has no clear())
	for child in lane_box.get_children():
		lane_box.remove_child(child)
		child.queue_free()
	for i in range(settings_manager.lane_keys.size()):
		var h = HBoxContainer.new()
		h.name = "LaneRow" + str(i)
		h.custom_minimum_size = Vector2(0, 28)
		var lbl = Label.new()
		lbl.text = "Lane %d" % (i + 1)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(lbl)
		var btn = Button.new()
		btn.name = "KeyButton" + str(i)
		btn.text = keycode_to_string(settings_manager.lane_keys[i])
		btn.focus_mode = Control.FOCUS_NONE
		btn.connect("pressed", Callable(self, "_on_rebind_pressed").bind(i))
		h.add_child(btn)
		lane_box.add_child(h)

func keycode_to_string(code: int) -> String:
	return OS.get_keycode_string(code)

func _load_values_into_ui():
	$Margin/VBox/Scroll/Options/NoteSpeedHBox/NoteSpeedSlider.value = settings_manager.note_speed
	$Margin/VBox/Scroll/Options/NoteSpeedHBox/NoteSpeedValue.text = str(int(settings_manager.note_speed))
	$Margin/VBox/Scroll/Options/MasterVolHBox/MasterSlider.value = settings_manager.master_volume
	$Margin/VBox/Scroll/Options/MasterVolHBox/MasterValue.text = str(int(settings_manager.master_volume * 100)) + "%"
	$Margin/VBox/Scroll/Options/TimingOffsetHBox/TimingOffsetSpin.value = int(settings_manager.timing_offset * 1000.0)

func _on_note_speed_changed(value):
	settings_manager.set_note_speed(value)
	$Margin/VBox/Scroll/Options/NoteSpeedHBox/NoteSpeedValue.text = str(int(value))

func _on_master_changed(value):
	settings_manager.set_master_volume(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	$Margin/VBox/Scroll/Options/MasterVolHBox/MasterValue.text = str(int(value * 100)) + "%"

func _on_offset_changed(value):
	# store in seconds internally
	settings_manager.set_timing_offset(float(value) / 1000.0)

func _on_rebind_pressed(index: int):
	waiting_for_key_index = index
	var btn = _get_key_button(index)
	btn.text = "Press a key..."
	btn.disabled = true
	set_process_input(true)

func _input(event):
	if waiting_for_key_index >= 0 and event is InputEventKey and event.pressed and not event.echo:
		# ESC cancels rebind
		if event.keycode == KEY_ESCAPE:
			var cancel_btn = _get_key_button(waiting_for_key_index)
			if cancel_btn:
				cancel_btn.text = keycode_to_string(settings_manager.get_lane_key(waiting_for_key_index))
				cancel_btn.disabled = false
			waiting_for_key_index = -1
			set_process_input(false)
			return
		settings_manager.set_lane_key(waiting_for_key_index, event.keycode)
		var btn = _get_key_button(waiting_for_key_index)
		if btn:
			btn.text = keycode_to_string(event.keycode)
			btn.disabled = false
		waiting_for_key_index = -1
		set_process_input(false)
		# Immediately save and apply the change
		settings_manager.save_settings()

func _get_key_button(index: int) -> Button:
	for row in $Margin/VBox/Scroll/Options/LaneKeys.get_children():
		var btn = row.get_node_or_null("KeyButton" + str(index))
		if btn:
			return btn
	return null

func _on_save():
	settings_manager.save_settings()

func _on_reset():
	settings_manager.reset_defaults()
	_build_lane_key_rows()
	_load_values_into_ui()

func _on_back():
	settings_manager.save_settings()
	SceneSwitcher.pop_scene()
