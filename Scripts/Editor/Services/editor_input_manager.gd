extends Node
class_name EditorInputManager

## Manages keyboard input for the chart editor, including note placement and hold notes
## Properly handles both key press and release events for sustain/hold note functionality

signal note_placement_requested(lane: int, is_hold_start: bool)
signal note_hold_released(lane: int)
signal tool_change_requested(tool_name: String)
signal note_type_change_requested(note_type: String)
signal timeline_navigation_requested(direction: String, modifier: String)
signal playback_toggle_requested()
signal snap_division_change_requested(increase: bool)
signal save_requested()
signal undo_requested()
signal redo_requested()
signal delete_requested()

# Configuration
var current_tool: String = "Note"
var is_playing: bool = false
var sustain_mode_enabled: bool = false
var num_lanes: int = 5

# Track which keys are currently held down (for hold notes)
var _keys_held: Dictionary = {}  # lane -> true/false

func _ready():
	set_process_input(true)

func configure(config: Dictionary):
	current_tool = config.get("current_tool", "Note")
	sustain_mode_enabled = config.get("sustain_mode_enabled", false)
	num_lanes = config.get("num_lanes", 5)
	is_playing = config.get("is_playing", false)

func set_playing_state(playing: bool):
	is_playing = playing
	# If playback stops, clear all held keys
	if not is_playing:
		_clear_all_held_keys()

func set_sustain_mode(enabled: bool):
	sustain_mode_enabled = enabled
	# If sustain mode is disabled, clear all held keys
	if not enabled:
		_clear_all_held_keys()

func set_tool(tool_name: String):
	current_tool = tool_name

func _clear_all_held_keys():
	# Release all currently held keys
	for lane in _keys_held.keys():
		if _keys_held[lane]:
			_keys_held[lane] = false
			note_hold_released.emit(lane)

func _input(event: InputEvent):
	# Use _input to capture ALL keyboard events, including releases
	if event is InputEventKey:
		_handle_keyboard_input(event)

func _handle_keyboard_input(event: InputEventKey):
	# Don't process if user is typing in a text field
	var focused = get_viewport().gui_get_focus_owner()
	if focused and (focused is LineEdit or focused is TextEdit):
		return
	
	var key = event.keycode
	
	# Handle tool selection shortcuts (Q/W/E/R) - on press only
	if event.pressed and not event.echo and not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
		match key:
			KEY_Q:
				tool_change_requested.emit("Cursor")
				get_viewport().set_input_as_handled()
				return
			KEY_W:
				tool_change_requested.emit("Note")
				get_viewport().set_input_as_handled()
				return
			KEY_E:
				tool_change_requested.emit("Erase")
				get_viewport().set_input_as_handled()
				return
			KEY_R:
				tool_change_requested.emit("BPM")
				get_viewport().set_input_as_handled()
				return
	
	# Handle note type shortcuts (Shift + 1-4) - on press only
	if event.pressed and not event.echo and event.shift_pressed and not event.ctrl_pressed and key >= KEY_1 and key <= KEY_4:
		var note_types = ["Regular", "HOPO", "Tap", "Open"]
		var type_index = key - KEY_1
		if type_index < note_types.size():
			note_type_change_requested.emit(note_types[type_index])
			get_viewport().set_input_as_handled()
			return
	
	# Handle note placement (1-5 for lanes)
	if key >= KEY_1 and key <= KEY_5 and current_tool == "Note" and not event.shift_pressed:
		var lane = key - KEY_1  # Convert KEY_1 to lane 0, etc.
		if lane < num_lanes:
			_handle_lane_key_input(lane, event)
			get_viewport().set_input_as_handled()
			return
	
	# Handle timeline navigation (arrow keys) - allow echo for repeating
	if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
		if key == KEY_LEFT and event.pressed:
			timeline_navigation_requested.emit("backward", "snap")
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_RIGHT and event.pressed:
			timeline_navigation_requested.emit("forward", "snap")
			get_viewport().set_input_as_handled()
			return
	
	# Timeline navigation with modifiers - on press only
	if event.pressed:
		if key == KEY_LEFT:
			if event.shift_pressed:
				timeline_navigation_requested.emit("backward", "measure")
				get_viewport().set_input_as_handled()
				return
			elif event.ctrl_pressed:
				timeline_navigation_requested.emit("backward", "beat")
				get_viewport().set_input_as_handled()
				return
		elif key == KEY_RIGHT:
			if event.shift_pressed:
				timeline_navigation_requested.emit("forward", "measure")
				get_viewport().set_input_as_handled()
				return
			elif event.ctrl_pressed:
				timeline_navigation_requested.emit("forward", "beat")
				get_viewport().set_input_as_handled()
				return
		elif key == KEY_HOME:
			timeline_navigation_requested.emit("start", "")
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_END:
			timeline_navigation_requested.emit("end", "")
			get_viewport().set_input_as_handled()
			return
	
	# Playback control - on press only
	if event.pressed and not event.echo and key == KEY_SPACE:
		playback_toggle_requested.emit()
		get_viewport().set_input_as_handled()
		return
	
	# Snap division controls - on press only
	if event.pressed and not event.echo:
		if key == KEY_BRACKETRIGHT:  # ] key - increase snap
			snap_division_change_requested.emit(true)
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_BRACKETLEFT:  # [ key - decrease snap
			snap_division_change_requested.emit(false)
			get_viewport().set_input_as_handled()
			return
	
	# Save shortcut - on press only
	if event.pressed and not event.echo and event.ctrl_pressed and key == KEY_S:
		save_requested.emit()
		get_viewport().set_input_as_handled()
		return
	
	# Undo / Redo - on press only
	if event.pressed and not event.echo:
		if event.ctrl_pressed and key == KEY_Z and not event.shift_pressed:
			undo_requested.emit()
			get_viewport().set_input_as_handled()
			return
		elif (event.ctrl_pressed and key == KEY_Y) or (event.ctrl_pressed and event.shift_pressed and key == KEY_Z):
			redo_requested.emit()
			get_viewport().set_input_as_handled()
			return
	
	# Delete - on press only
	if event.pressed and not event.echo and key == KEY_DELETE:
		delete_requested.emit()
		get_viewport().set_input_as_handled()
		return

func _handle_lane_key_input(lane: int, event: InputEventKey):
	# Special handling for lane keys during playback with sustain mode
	if is_playing and sustain_mode_enabled:
		if event.pressed and not event.echo:
			# Key pressed - start hold note
			if not _keys_held.get(lane, false):
				_keys_held[lane] = true
				note_placement_requested.emit(lane, true)
		elif not event.pressed:
			# Key released - finish hold note
			if _keys_held.get(lane, false):
				_keys_held[lane] = false
				note_hold_released.emit(lane)
	else:
		# Regular note placement (not during sustain mode)
		if event.pressed and not event.echo:
			note_placement_requested.emit(lane, false)
