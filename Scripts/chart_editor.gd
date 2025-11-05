extends Node3D
## Chart Editor Main Controller
## Coordinates between data model, UI components, and editor systems

# Classes are available via class_name declarations

@onready var menu_bar = $UI/VBox/EditorMenuBar
@onready var playback_controls = $UI/VBox/PlaybackArea/EditorPlaybackControls
@onready var toolbar = $UI/VBox/MainContent/EditorToolbar
@onready var side_panel = $UI/VBox/MainContent/EditorSidePanel
@onready var note_canvas_container = $UI/VBox/MainContent/ViewportPanel
@onready var status_bar = $UI/VBox/EditorStatusBar
@onready var audio_player = $AudioStreamPlayer
@onready var runway = $Runway
@onready var note_spawner = $NoteSpawner
@onready var note_pool = $NoteSpawner/NotePool

var chart_data: ChartDataModel
var history_manager: EditorHistoryManager
var note_canvas: EditorNoteCanvas
var timeline_controller: TimelineController = null

var file_path: String = ""
var current_instrument: String = "Single"
var current_difficulty: String = "Expert"
var is_playing: bool = false
var current_time: float = 0.0
var playback_speed: float = 1.0
var current_tool: int = 0  # From EditorToolbar.Tool enum

# Playback-related variables
var song_start_time: float = 0.0
var lanes: Array = []

# File dialogs
var audio_file_dialog: FileDialog = null

func _ready():
	_initialize_chart_data()
	_initialize_history_manager()
	_create_note_canvas()
	_connect_component_signals()
	_setup_runway()
	_setup_file_dialogs()

func _initialize_chart_data():
	chart_data = ChartDataModel.new()
	chart_data.data_changed.connect(_on_chart_data_changed)
	chart_data.create_chart(current_instrument, current_difficulty)

func _initialize_history_manager():
	history_manager = EditorHistoryManager.new(chart_data)
	history_manager.history_changed.connect(_on_history_changed)

func _create_note_canvas():
	"""Create and set up the 2D note canvas for charting"""
	note_canvas = EditorNoteCanvas.new()
	note_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note_canvas_container.add_child(note_canvas)
	
	note_canvas.set_chart_data(chart_data)
	note_canvas.set_instrument_difficulty(current_instrument, current_difficulty)
	note_canvas.note_clicked.connect(_on_note_clicked)
	note_canvas.canvas_clicked.connect(_on_canvas_clicked)
	note_canvas.notes_moved.connect(_on_notes_moved)

func _connect_component_signals():
	# Menu bar signals
	menu_bar.new_chart_requested.connect(_on_new_chart_requested)
	menu_bar.open_chart_requested.connect(_on_open_chart_requested)
	menu_bar.save_requested.connect(_on_save_requested)
	menu_bar.save_as_requested.connect(_on_save_as_requested)
	menu_bar.undo_requested.connect(_on_undo_requested)
	menu_bar.redo_requested.connect(_on_redo_requested)
	
	# Playback control signals
	playback_controls.play_requested.connect(_on_play_requested)
	playback_controls.pause_requested.connect(_on_pause_requested)
	playback_controls.stop_requested.connect(_on_stop_requested)
	playback_controls.seek_requested.connect(_on_seek_requested)
	playback_controls.speed_changed.connect(_on_speed_changed)
	
	# Toolbar signals
	toolbar.tool_selected.connect(_on_tool_selected)
	toolbar.snap_changed.connect(_on_snap_changed)
	toolbar.grid_toggled.connect(_on_grid_toggled)
	
	# Side panel signals
	side_panel.metadata_changed.connect(_on_metadata_changed)
	side_panel.difficulty_changed.connect(_on_difficulty_changed)
	side_panel.audio_file_requested.connect(_on_audio_file_requested)

func _setup_runway():
	# Reuse existing board_renderer logic from gameplay
	runway.set_script(load("res://Scripts/board_renderer.gd"))
	runway.num_lanes = 5
	runway.board_width = runway.mesh.size.x
	runway.setup_lanes()
	runway.create_hit_zones()
	runway.create_lane_lines()
	runway.set_board_texture()
	
	# Store lanes for note spawner
	lanes = runway.lanes
	
	# Create hit effect pool (required by note spawner)
	var hit_effect_pool = load("res://Scripts/HitEffectPool.gd").new()
	hit_effect_pool.name = "HitEffectPool"
	add_child(hit_effect_pool)

func _setup_file_dialogs():
	"""Create and configure file dialogs for audio loading"""
	# Audio file dialog
	audio_file_dialog = FileDialog.new()
	audio_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	audio_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_file_dialog.filters = PackedStringArray(["*.ogg ; OGG Audio Files", "*.mp3 ; MP3 Audio Files", "*.wav ; WAV Audio Files"])
	audio_file_dialog.title = "Select Audio File"
	audio_file_dialog.size = Vector2i(800, 600)
	audio_file_dialog.file_selected.connect(_on_audio_file_selected)
	add_child(audio_file_dialog)

func _process(_delta):
	if is_playing:
		# Update timeline if it exists
		if timeline_controller and timeline_controller.active:
			current_time = timeline_controller.get_time()
			
			# Sync audio to timeline (keep them aligned)
			if audio_player and audio_player.playing and not audio_player.stream_paused:
				_sync_audio_to_timeline(false)
		elif audio_player and audio_player.playing:
			# Fallback: use audio time if no timeline
			current_time = audio_player.get_playback_position()
		
		# Update UI
		playback_controls.update_position(current_time)
		status_bar.update_time(current_time)
		
		# Update note canvas with playback position
		var current_tick = chart_data.time_to_tick(current_time)
		var current_bpm = chart_data.get_bpm_at_tick(current_tick)
		status_bar.update_bpm(current_bpm)
		note_canvas.update_playback_position(current_tick, true)
		
		# Auto-scroll note canvas to follow playback
		note_canvas.scroll_to_tick(current_tick)
	elif note_canvas:
		# When not playing, update without playback line
		var current_tick = chart_data.time_to_tick(current_time)
		note_canvas.update_playback_position(current_tick, false)

func _on_new_chart_requested():
	# TODO: Show confirmation if modified
	chart_data.clear()
	history_manager.clear_history()
	file_path = ""
	status_bar.set_modified(false)

func _on_open_chart_requested():
	# TODO: Show file dialog
	# For now, this would load a chart file and populate chart_data
	# After loading, call _load_audio_for_chart()
	print("Open chart requested")

func _on_save_requested():
	if file_path.is_empty():
		_on_save_as_requested()
	else:
		_save_chart(file_path)

func _on_save_as_requested():
	# TODO: Show file dialog
	print("Save as requested")

func _save_chart(path: String):
	# TODO: Implement chart serialization
	file_path = path
	status_bar.set_modified(false)

func _on_undo_requested():
	if history_manager.undo():
		print("Undo successful")

func _on_redo_requested():
	if history_manager.redo():
		print("Redo successful")

func _on_history_changed(can_undo: bool, can_redo: bool):
	menu_bar.set_undo_enabled(can_undo)
	menu_bar.set_redo_enabled(can_redo)

func _on_play_requested():
	if not audio_player.stream:
		print("No audio loaded for playback")
		return
	
	# Initialize timeline controller if needed
	if not timeline_controller:
		_initialize_playback_system()
	
	# Start or resume playback
	audio_player.play(current_time)
	is_playing = true
	playback_controls.set_playing(true)
	
	# Activate timeline
	if timeline_controller:
		timeline_controller.active = true
		timeline_controller.scrub_to(current_time)

func _on_pause_requested():
	audio_player.stop()
	is_playing = false
	playback_controls.set_playing(false)

func _on_stop_requested():
	audio_player.stop()
	current_time = 0.0
	is_playing = false
	playback_controls.set_playing(false)
	playback_controls.update_position(0.0)

func _on_seek_requested(seek_position: float):
	current_time = seek_position
	
	# Scrub timeline controller if it exists
	if timeline_controller:
		timeline_controller.scrub_to(seek_position)
	
	# Seek audio if playing
	if is_playing and audio_player and audio_player.stream:
		audio_player.play(seek_position)
	
	# Scroll note canvas to show the current position
	var current_tick = chart_data.time_to_tick(current_time)
	note_canvas.scroll_to_tick(current_tick)

func _on_speed_changed(speed: float):
	playback_speed = speed
	# Note: Godot AudioStreamPlayer doesn't support pitch_scale for speed
	# You may need to use AudioEffectPitchShift for this

func _on_tool_selected(tool_type):
	current_tool = tool_type
	print("Tool selected: ", tool_type)

func _on_snap_changed(snap_division: int):
	status_bar.update_snap(snap_division)
	note_canvas.set_snap_division(snap_division)

func _on_grid_toggled(enabled: bool):
	print("Grid toggled: ", enabled)

func _on_metadata_changed(metadata: Dictionary):
	for key in metadata:
		chart_data.set_metadata(key, metadata[key])
	status_bar.set_modified(true)

func _on_difficulty_changed(instrument: String, difficulty: String, enabled: bool):
	if enabled:
		chart_data.create_chart(instrument, difficulty)
	print("Difficulty changed: ", instrument, "/", difficulty, " = ", enabled)

func _on_audio_file_requested():
	"""Show file dialog to select audio file"""
	if audio_file_dialog:
		audio_file_dialog.popup_centered()

func _on_audio_file_selected(path: String):
	"""Handle audio file selection"""
	if not FileAccess.file_exists(path):
		push_error("Audio file not found: " + path)
		return
	
	# Load the audio stream
	var audio_stream = null
	var extension = path.get_extension().to_lower()
	
	match extension:
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		"mp3", "wav":
			audio_stream = load(path)
		_:
			push_error("Unsupported audio format: " + extension)
			return
	
	if not audio_stream:
		push_error("Failed to load audio file: " + path)
		return
	
	# Set the audio stream
	audio_player.stream = audio_stream
	
	# Update metadata with the audio file path
	chart_data.set_metadata("audio_file", path)
	
	# Update side panel UI
	side_panel.set_audio_file(path)
	
	# Update playback controls with duration
	playback_controls.set_duration(audio_stream.get_length())
	
	print("Loaded audio: ", path, " (Duration: ", audio_stream.get_length(), "s)")

func _on_chart_data_changed():
	status_bar.set_modified(true)
	var note_count = chart_data.get_note_count(current_instrument, current_difficulty)
	status_bar.update_note_count(note_count)

func _on_note_clicked(note_id: int, button_index: int):
	"""Handle clicking on an existing note"""
	if button_index == MOUSE_BUTTON_RIGHT:
		# Delete note with right click (selection handled in canvas)
		var command = RemoveNoteCommand.new(
			chart_data,
			current_instrument,
			current_difficulty,
			note_id
		)
		history_manager.execute_command(command)

func _on_notes_moved(note_ids: Array, offset_lane: int, offset_tick: int, original_positions: Dictionary):
	"""Handle notes being dragged to new positions"""
	# Create MoveNoteCommand for each moved note
	for note_id in note_ids:
		if note_id in original_positions:
			var original = original_positions[note_id]
			var new_lane = clamp(original.lane + offset_lane, 0, 4)
			var new_tick = max(0, original.tick + offset_tick)
			
			var command = MoveNoteCommand.new(
				chart_data,
				current_instrument,
				current_difficulty,
				note_id,
				new_lane,
				new_tick
			)
			history_manager.execute_command(command)
	
	print("Moved ", note_ids.size(), " notes by lane:", offset_lane, " tick:", offset_tick)

func _on_canvas_clicked(lane: int, tick: int, button_index: int):
	"""Handle clicking on empty canvas space"""
	if button_index == MOUSE_BUTTON_LEFT:
		# Place note based on current tool
		match current_tool:
			0:  # NOTE tool (from EditorToolbar.Tool enum)
				var command = AddNoteCommand.new(
					chart_data,
					current_instrument,
					current_difficulty,
					lane,
					tick,
					0,  # Regular note type
					0   # No sustain
				)
				history_manager.execute_command(command)
				print("Placed note at lane ", lane, " tick ", tick)

func _input(event):
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		# Check for Ctrl+Z (undo) and Ctrl+Y (redo)
		if event.ctrl_pressed and not event.shift_pressed and event.keycode == KEY_Z:
			_on_undo_requested()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			_on_redo_requested()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_Z:
			_on_redo_requested()
			get_viewport().set_input_as_handled()
		else:
			match event.keycode:
				KEY_SPACE:
					if is_playing:
						_on_pause_requested()
					else:
						_on_play_requested()
					get_viewport().set_input_as_handled()
				KEY_BRACKETLEFT:  # [
					toolbar.decrease_snap()
					get_viewport().set_input_as_handled()
				KEY_BRACKETRIGHT:  # ]
					toolbar.increase_snap()
					get_viewport().set_input_as_handled()
				KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
					# Quick note placement with number keys
					_handle_lane_key_press(event.keycode - KEY_1)
					get_viewport().set_input_as_handled()
				KEY_DELETE:
					# Delete selected notes
					_delete_selected_notes()
					get_viewport().set_input_as_handled()
				KEY_A:
					if event.ctrl_pressed:
						# Ctrl+A: Select all notes
						note_canvas.select_all()
						get_viewport().set_input_as_handled()
				KEY_ESCAPE:
					# Clear selection
					note_canvas.clear_selection()
					get_viewport().set_input_as_handled()

func _handle_lane_key_press(lane: int):
	"""Handle number key press for quick note placement"""
	if current_tool == 0:  # NOTE tool
		# Place note at current playback position
		var current_tick = chart_data.time_to_tick(current_time)
		var snapped_tick = note_canvas.snap_tick_to_grid(current_tick)
		
		var command = AddNoteCommand.new(
			chart_data,
			current_instrument,
			current_difficulty,
			lane,
			snapped_tick,
			0,  # Regular note type
			0   # No sustain
		)
		history_manager.execute_command(command)
		print("Placed note with key at lane ", lane, " tick ", snapped_tick)

func _delete_selected_notes():
	"""Delete all currently selected notes"""
	var selected = note_canvas.get_selected_notes()
	if selected.size() == 0:
		return
	
	# Delete each selected note
	for note_id in selected:
		var command = RemoveNoteCommand.new(
			chart_data,
			current_instrument,
			current_difficulty,
			note_id
		)
		history_manager.execute_command(command)
	
	print("Deleted ", selected.size(), " notes")
	note_canvas.clear_selection()

# ============================================================================
# Playback System Methods (adapted from gameplay.gd)
# ============================================================================

func _initialize_playback_system():
	"""Initialize the timeline controller and note spawner for playback"""
	if timeline_controller:
		return  # Already initialized
	
	# Get chart data for current instrument/difficulty
	var chart = chart_data.get_chart(current_instrument, current_difficulty)
	if not chart:
		print("No chart data available for playback")
		return
	
	# Convert ChartDataModel notes to format expected by note_spawner
	var notes_array = _convert_chart_notes_to_spawner_format(chart.notes)
	
	# Convert ChartDataModel BPM changes to tempo events
	var tempo_events = _convert_bpm_changes_to_tempo_events()
	
	# Configure note spawner
	note_spawner.notes = notes_array
	note_spawner.tempo_events = tempo_events
	note_spawner.resolution = chart_data.resolution
	note_spawner.offset = chart_data.metadata.get("offset", 0.0)
	note_spawner.lanes = lanes
	note_spawner.note_scene = preload("res://Scenes/note.tscn")
	note_spawner.note_pool = note_pool
	
	# Start spawning (builds spawn_data)
	note_spawner.song_start_time = Time.get_ticks_msec() / 1000.0
	note_spawner.start_spawning()
	
	# Create timeline controller
	timeline_controller = TimelineController.new()
	timeline_controller.name = "TimelineController"
	add_child(timeline_controller)
	
	# Setup timeline context
	var ctx = {
		"note_spawner": note_spawner,
		"get_time": func(): return timeline_controller.current_time if timeline_controller else 0.0
	}
	
	# Build spawn commands
	var spawn_cmds = note_spawner.build_spawn_commands()
	
	# Use audio duration as song end time (not note duration)
	var song_end_time = 0.0
	if audio_player.stream:
		song_end_time = audio_player.stream.get_length()
	else:
		# Fallback: calculate from last note
		var last_time = 0.0
		for d in note_spawner.spawn_data:
			last_time = max(last_time, d.hit_time)
		song_end_time = last_time + 5.0  # Add margin
	
	# Setup timeline
	timeline_controller.setup(ctx, spawn_cmds, song_end_time)
	note_spawner.attach_timeline(timeline_controller)
	timeline_controller.active = false  # Will be activated on play
	
	print("Playback system initialized with ", spawn_cmds.size(), " note commands, duration: ", song_end_time, "s")

func _convert_chart_notes_to_spawner_format(chart_notes: Array) -> Array:
	"""Convert ChartDataModel notes to the format expected by note_spawner"""
	var converted = []
	
	for note in chart_notes:
		var spawner_note = {
			"fret": note.get("lane", 0),  # lane -> fret mapping
			"pos": note.get("tick", 0),   # note_spawner expects "pos" not "tick"
			"length": note.get("length", 0),  # sustain length in ticks
			"is_hopo": note.get("type", 0) == 1,  # type 1 = HOPO
			"is_tap": note.get("type", 0) == 2    # type 2 = TAP
		}
		converted.append(spawner_note)
	
	return converted

func _convert_bpm_changes_to_tempo_events() -> Array:
	"""Convert ChartDataModel BPM changes to tempo events format"""
	var tempo_events = []
	
	for bpm_change in chart_data.bpm_changes:
		tempo_events.append({
			"tick": bpm_change.get("tick", 0),
			"bpm": bpm_change.get("bpm", 120.0)
		})
	
	return tempo_events

func _sync_audio_to_timeline(force_seek: bool):
	"""Sync audio playback position to timeline (adapted from gameplay.gd)"""
	if not audio_player or not audio_player.stream or not timeline_controller:
		return
	
	var timeline_time = timeline_controller.current_time
	var audio_time = _timeline_to_audio_time(timeline_time)
	var audio_pos = audio_player.get_playback_position()
	var delta = abs(audio_time - audio_pos)
	
	# Seek if out of sync
	if force_seek or delta > 0.1:  # 100ms tolerance
		if audio_time >= 0.0 and audio_time < audio_player.stream.get_length():
			audio_player.seek(audio_time)

func _timeline_to_audio_time(timeline_time: float) -> float:
	"""Convert timeline time to audio time (accounting for offset)"""
	var offset = chart_data.metadata.get("offset", 0.0)
	return timeline_time - offset

func _load_audio_for_chart():
	"""Load audio file specified in chart metadata"""
	var audio_file = chart_data.metadata.get("audio_file", "")
	if audio_file.is_empty():
		print("No audio file specified in chart metadata")
		return
	
	# Construct full path relative to chart file
	var folder = file_path.get_base_dir() if not file_path.is_empty() else ""
	var audio_path = folder + "/" + audio_file if not folder.is_empty() else audio_file
	
	if FileAccess.file_exists(audio_path):
		var audio_stream = AudioStreamOggVorbis.load_from_file(audio_path)
		if not audio_stream:
			# Try MP3
			audio_stream = load(audio_path)
		
		if audio_stream:
			audio_player.stream = audio_stream
			print("Loaded audio: ", audio_path)
			
			# Update playback controls with audio duration
			playback_controls.set_duration(audio_stream.get_length())
		else:
			print("Failed to load audio: ", audio_path)
	else:
		print("Audio file not found: ", audio_path)
