extends Control

# References to UI components
@onready var toolbar = $MainLayout/Toolbar
@onready var settings_panel = $MainLayout/ContentArea/LeftPanel/SettingsPanel
@onready var toolbox = $MainLayout/ContentArea/LeftPanel/Toolbox
@onready var progress_bar = $MainLayout/ContentArea/ProgressBar
@onready var runway_viewport = $MainLayout/ContentArea/CenterArea/RunwayViewport
@onready var sub_viewport = $MainLayout/ContentArea/CenterArea/RunwayViewport/SubViewport
@onready var camera_3d = $MainLayout/ContentArea/CenterArea/RunwayViewport/SubViewport/Camera3D
@onready var runway_mesh = $MainLayout/ContentArea/CenterArea/RunwayViewport/SubViewport/Runway
@onready var timeline_slider = $MainLayout/TimelineArea/Timeline
@onready var time_label = $MainLayout/TimelineArea/TimelineControls/TimeLabel
@onready var play_button = $MainLayout/TimelineArea/TimelineControls/PlayButton
@onready var pause_button = $MainLayout/TimelineArea/TimelineControls/PauseButton
@onready var stop_button = $MainLayout/TimelineArea/TimelineControls/StopButton

# Song properties dialog
var song_properties_dialog: AcceptDialog
var song_properties: Dictionary = {}

# Chart data
var current_chart_path: String = ""
var current_instrument: String = "Single"
var current_difficulty: String = "Expert"
var chart_notes: Array = []
var tempo_events: Array = []
var resolution: int = 192
var chart_resolution: int = 192  # Ticks per beat
var offset: float = 0.0

# Editor state
var is_playing: bool = false
var current_time: float = 0.0
var snap_division: int = 16  # 1/16 notes by default
var playback_speed: float = 1.0
var note_placement_mode: bool = true
var num_lanes: int = 5
var sync_timer: float = 0.0  # Timer for periodic audio sync checks
var show_waveform: bool = false  # Toggle for waveform display
var waveform_texture: Texture2D = null  # Cached waveform texture

# Audio system
var audio_player: AudioStreamPlayer
var audio_stream: AudioStream
var song_duration: float = 0.0

# Runway system
var lanes: Array = []
var runway_board_renderer: Node
var placed_notes: Array = []  # Notes placed in editor
var note_visuals: Dictionary = {}  # Map note data to visual nodes
var preview_note: Sprite3D = null  # Preview note that follows mouse
var current_preview_lane: int = -1
var current_preview_time: float = 0.0

func _ready():
	print("Chart Editor initialized")
	
	# Initialize with default tempo if none exists
	if tempo_events.is_empty():
		tempo_events.append({"time": 0.0, "bpm": 120.0})
	
	_setup_song_properties_dialog()
	_setup_runway()
	_setup_audio_player()
	_setup_preview_note()
	_connect_signals()
	
	# Enable mouse input for the runway viewport
	runway_viewport.mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_song_properties_dialog():
	# Load and instance the dialog
	var dialog_scene = load("res://Scenes/Editor/song_properties_dialog.tscn")
	song_properties_dialog = dialog_scene.instantiate()
	add_child(song_properties_dialog)
	song_properties_dialog.properties_saved.connect(_on_song_properties_saved)

func _setup_runway():
	# Set up the 3D runway using the board_renderer system
	# Remove the default mesh and replace with board_renderer
	var board_renderer = load("res://Scripts/board_renderer.gd").new()
	board_renderer.mesh = QuadMesh.new()
	# Runway length should show ~3 seconds of notes at default speed (20 units/sec = 60 units)
	# Using 60 units gives a comfortable preview window in the editor
	board_renderer.mesh.size = Vector2(10, 60)
	board_renderer.mesh.orientation = PlaneMesh.FACE_Y
	board_renderer.num_lanes = num_lanes
	
	# Create a material for the runway
	var runway_material = StandardMaterial3D.new()
	runway_material.albedo_color = Color(0.2, 0.2, 0.25)  # Dark gray-blue color
	runway_material.uv1_scale = Vector3(num_lanes, 1, 1)
	board_renderer.set_surface_override_material(0, runway_material)
	
	# Replace runway_mesh with board_renderer
	var parent = runway_mesh.get_parent()
	var mesh_index = runway_mesh.get_index()
	parent.remove_child(runway_mesh)
	parent.add_child(board_renderer)
	parent.move_child(board_renderer, mesh_index)
	runway_mesh.queue_free()
	
	# Store reference and get lanes
	runway_board_renderer = board_renderer
	lanes = runway_board_renderer.lanes
	
	print("Runway set up with ", num_lanes, " lanes")

func _setup_audio_player():
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioPlayer"
	add_child(audio_player)
	audio_player.finished.connect(_on_audio_finished)

func _setup_preview_note():
	# Create a preview note that shows where notes will be placed
	var note_scene = preload("res://Scenes/note.tscn")
	preview_note = note_scene.instantiate()
	preview_note.movement_paused = true
	preview_note.use_timeline_positioning = true
	preview_note.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	preview_note.visible = false
	preview_note.fret = 0
	preview_note.note_type = NoteType.Type.REGULAR
	
	# Add to SubViewport
	if runway_viewport:
		var viewport = runway_viewport.get_node("SubViewport")
		viewport.add_child(preview_note)
	
	print("Preview note set up")

func _connect_signals():
	# Toolbar signals
	toolbar.file_new_requested.connect(_on_file_new)
	toolbar.file_open_requested.connect(_on_file_open)
	toolbar.file_save_requested.connect(_on_file_save)
	toolbar.file_save_as_requested.connect(_on_file_save_as)
	toolbar.instrument_changed.connect(set_instrument)
	toolbar.difficulty_changed.connect(set_difficulty)
	toolbar.song_properties_requested.connect(_on_song_properties_requested)
	toolbar.tool_selected.connect(_on_tool_selected)
	toolbar.waveform_toggled.connect(_on_waveform_toggled)
	
	# Settings panel signals
	settings_panel.snap_step_changed.connect(set_snap_division)
	settings_panel.speed_changed.connect(_on_playback_speed_changed)
	
	# Timeline signals
	timeline_slider.value_changed.connect(_on_timeline_changed)
	
	# Toolbox signals
	toolbox.tool_selected.connect(_on_tool_selected)
	toolbox.note_type_selected.connect(_on_note_type_selected)
	
	# Viewport input
	runway_viewport.gui_input.connect(_on_runway_input)
	runway_viewport.mouse_entered.connect(_on_runway_mouse_entered)
	runway_viewport.mouse_exited.connect(_on_runway_mouse_exited)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_shortcut(event)

func _handle_keyboard_shortcut(event: InputEventKey):
	# Handle keyboard shortcuts for chart editor
	var key = event.keycode
	
	# Note placement shortcuts (1-5 for lanes)
	if key >= KEY_1 and key <= KEY_5 and current_tool == "Note":
		var lane = key - KEY_1  # Convert KEY_1 to lane 0, KEY_2 to lane 1, etc.
		_place_note_at_cursor_time(lane)
		return
	
	# Playback control
	if key == KEY_SPACE:
		toggle_playback()
		get_viewport().set_input_as_handled()
		return
	
	# Snap division controls
	if key == KEY_BRACKETRIGHT:  # ] key - increase snap
		_increase_snap_division()
		get_viewport().set_input_as_handled()
		return
	
	if key == KEY_BRACKETLEFT:  # [ key - decrease snap
		_decrease_snap_division()
		get_viewport().set_input_as_handled()
		return
	
	# Save shortcut
	if event.ctrl_pressed and key == KEY_S:
		_on_file_save()
		get_viewport().set_input_as_handled()
		return
	
	# Delete selected notes
	if key == KEY_DELETE:
		_delete_selected_notes()
		get_viewport().set_input_as_handled()
		return

func _process(delta):
	if is_playing and audio_player and audio_player.playing:
		# Smoothly increment current_time instead of constantly querying audio position
		current_time += delta * playback_speed
		
		# Periodically sync with audio player (every 0.5 seconds) to prevent drift
		sync_timer += delta
		if sync_timer >= 0.5:
			sync_timer = 0.0
			var audio_time = audio_player.get_playback_position()
			var time_diff = abs(current_time - audio_time)
			# Only sync if drift is significant (more than 0.1 seconds)
			if time_diff > 0.1:
				current_time = audio_time
		
		# Clamp to audio duration
		if current_time >= song_duration:
			current_time = song_duration
			_stop_playback()
		
		# Update visuals
		_update_editor_visuals()

func _update_editor_visuals():
	# Lightweight visual updates during playback
	# Only update what's necessary for smooth scrolling
	
	# Update timeline position (disable signals temporarily to avoid feedback)
	timeline_slider.set_value_no_signal(current_time)
	time_label.text = _format_time(current_time)
	
	# Update waveform texture offset to scroll with time
	_update_waveform_scroll()
	
	# Update note positions based on current time
	_update_note_positions()

func _update_editor_state():
	# Full editor state update (called when manually seeking/scrubbing)
	timeline_slider.value = current_time
	time_label.text = _format_time(current_time)
	_update_waveform_scroll()
	_update_note_positions()

func _update_waveform_scroll():
	# Update waveform texture UV offset to scroll with current time
	if runway_board_renderer and song_duration > 0:
		var runway_material = runway_board_renderer.get_surface_override_material(0)
		if runway_material and runway_material.albedo_texture:
			# Calculate UV offset based on current time
			# The texture represents the full song (UV scale = 1.0)
			# We want to scroll through it as time progresses
			# At time 0, show the beginning of the waveform
			# At time = song_duration, show the end of the waveform
			var time_progress = current_time / song_duration
			
			# Offset in Y direction (along the runway)
			# Negative offset moves the texture "up" in UV space, showing later parts
			runway_material.uv1_offset = Vector3(0, -time_progress, 0)

func _update_note_positions():
	# Update visual position of all notes based on current_time
	for note_data in note_visuals.keys():
		var note_visual = note_visuals[note_data]
		if note_visual:
			# Recalculate position based on current time
			var new_pos = _time_to_runway_position(note_data.time, note_data.lane)
			note_visual.position = new_pos
			
			# Hide notes that are too far away or already passed
			var time_diff = note_data.time - current_time
			note_visual.visible = time_diff > -1.0 and time_diff < 10.0  # Show notes within 10 second window

func _format_time(time: float) -> String:
	var minutes = int(time) / 60.0
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [int(minutes), seconds, milliseconds]

# File operations
func _on_file_new():
	print("Creating new chart")
	chart_notes.clear()
	placed_notes.clear()
	_clear_note_visuals()
	current_chart_path = ""
	_on_song_properties_requested()

func _on_file_open():
	print("Opening chart")
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.chart ; Chart Files"])
	file_dialog.file_selected.connect(_on_chart_file_selected)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_chart_file_selected(path: String):
	load_chart(path)

func _on_file_save():
	if current_chart_path.is_empty():
		_on_file_save_as()
	else:
		save_chart()

func _on_file_save_as():
	print("Save chart as")
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.chart ; Chart Files"])
	file_dialog.file_selected.connect(_on_save_path_selected)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_save_path_selected(path: String):
	current_chart_path = path
	save_chart()

func load_chart(path: String):
	print("Loading chart: ", path)
	current_chart_path = path
	# Use ChartLoadingService
	var chart_loading_service = ChartLoadingService.new()
	var chart_data = chart_loading_service.load_chart_data_sync(path, current_instrument)
	
	if chart_data:
		chart_notes = chart_data.notes
		tempo_events = chart_data.tempo_events
		resolution = chart_data.resolution
		offset = chart_data.offset
		
		# Update UI
		settings_panel.update_note_count(chart_notes.size())
		
		# TODO: Create visual representations of loaded notes
		_create_note_visuals_from_chart()
		print("Chart loaded successfully")
	else:
		push_error("Failed to load chart")

func save_chart():
	if current_chart_path.is_empty():
		push_error("No chart path specified")
		return
	
	print("Saving chart to: ", current_chart_path)
	
	# Open file for writing
	var file = FileAccess.open(current_chart_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: ", current_chart_path)
		return
	
	# Write [Song] section
	file.store_line("[Song]")
	file.store_line("{")
	file.store_line("  Name = \"" + song_properties.get("name", "Untitled") + "\"")
	file.store_line("  Artist = \"" + song_properties.get("artist", "Unknown") + "\"")
	file.store_line("  Charter = \"" + song_properties.get("charter", "Unknown") + "\"")
	file.store_line("  Album = \"" + song_properties.get("album", "") + "\"")
	file.store_line("  Year = \"" + song_properties.get("year", "") + "\"")
	file.store_line("  Offset = " + str(song_properties.get("offset", 0)))
	file.store_line("  Resolution = " + str(chart_resolution))
	file.store_line("  Genre = \"" + song_properties.get("genre", "") + "\"")
	if song_properties.has("audio_file"):
		file.store_line("  MusicStream = \"" + song_properties.get("audio_file", "") + "\"")
	file.store_line("}")
	
	# Write [SyncTrack] section with tempo events
	file.store_line("[SyncTrack]")
	file.store_line("{")
	file.store_line("  0 = TS 4")  # Default time signature
	for tempo_event in tempo_events:
		var tick = _time_to_tick(tempo_event.time)
		file.store_line("  " + str(tick) + " = B " + str(int(tempo_event.bpm * 1000)))
	file.store_line("}")
	
	# Write [Events] section (empty for now)
	file.store_line("[Events]")
	file.store_line("{")
	file.store_line("}")
	
	# Write note data for current difficulty
	var difficulty_name = "[" + current_difficulty + current_instrument.capitalize() + "]"
	file.store_line(difficulty_name)
	file.store_line("{")
	
	# Sort notes by time
	var sorted_notes = placed_notes.duplicate()
	sorted_notes.sort_custom(func(a, b): return a.time < b.time)
	
	# Write each note
	for note_data in sorted_notes:
		var tick = _time_to_tick(note_data.time)
		var lane = note_data.lane
		var sustain_ticks = _time_to_tick(note_data.sustain_length) if note_data.sustain_length > 0 else 0
		
		file.store_line("  " + str(tick) + " = N " + str(lane) + " " + str(sustain_ticks))
	
	file.store_line("}")
	
	file.close()
	print("Chart saved successfully with ", placed_notes.size(), " notes")

func _time_to_tick(time: float) -> int:
	# Convert time in seconds to tick position
	# Tick = (time * BPM * resolution) / 60
	var bpm = tempo_events[0].bpm if tempo_events.size() > 0 else 120.0
	return int((time * bpm * chart_resolution) / 60.0)

# Song properties
func _on_song_properties_requested():
	song_properties_dialog.set_properties(song_properties)
	song_properties_dialog.popup_centered()

func _on_song_properties_saved(properties: Dictionary):
	song_properties = properties
	print("Song properties saved: ", properties)
	
	# Load audio file if specified
	if properties.has("audio_path") and not properties["audio_path"].is_empty():
		_load_audio_file(properties["audio_path"])
	
	offset = properties.get("offset", 0.0)

func _load_audio_file(path: String):
	print("Loading audio file: ", path)
	
	# Determine audio format and load
	var file_ext = path.get_extension().to_lower()
	match file_ext:
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var audio_stream_mp3 = AudioStreamMP3.new()
				audio_stream_mp3.data = file.get_buffer(file.get_length())
				audio_stream = audio_stream_mp3
				file.close()
		"wav":
			audio_stream = load(path)
	
	if audio_stream:
		audio_player.stream = audio_stream
		song_duration = audio_stream.get_length()
		timeline_slider.max_value = song_duration
		print("Audio loaded. Duration: ", song_duration, " seconds")
		
		# Generate waveform texture (cached for toggling)
		_generate_waveform_texture()
		
		# Apply waveform if enabled
		if show_waveform:
			_toggle_waveform_display()
	else:
		push_error("Failed to load audio file: " + path)

# Playback controls
func toggle_playback():
	if is_playing:
		_pause_playback()
	else:
		_start_playback()

func _start_playback():
	if audio_player and audio_player.stream:
		audio_player.play(current_time)
		is_playing = true
		play_button.disabled = true
		pause_button.disabled = false
		print("Playback started")

func _pause_playback():
	if audio_player and audio_player.playing:
		audio_player.stop()
	is_playing = false
	play_button.disabled = false
	pause_button.disabled = true
	print("Playback paused")

func _stop_playback():
	if audio_player:
		audio_player.stop()
	is_playing = false
	current_time = 0.0
	timeline_slider.value = 0.0
	play_button.disabled = false
	pause_button.disabled = true
	print("Playback stopped")

func _on_audio_finished():
	_stop_playback()

func _on_timeline_changed(value: float):
	current_time = value
	
	# Only seek audio if user is manually scrubbing (not during playback updates)
	# We use set_value_no_signal during playback to avoid this callback
	if audio_player and audio_player.stream and is_playing:
		# Seek the audio to new position
		audio_player.seek(current_time)
	
	_update_editor_state()

func _on_playback_speed_changed(speed: float):
	playback_speed = speed
	if audio_player:
		audio_player.pitch_scale = speed

# Tool and note type selection
var current_tool: String = "Note"
var current_note_type: String = "Regular"

func _on_tool_selected(tool_name: String):
	current_tool = tool_name
	print("Tool selected: ", tool_name)

func _on_note_type_selected(note_type: String):
	current_note_type = note_type
	print("Note type selected: ", note_type)

# Settings
func set_snap_division(division: int):
	snap_division = division
	print("Snap division set to 1/", division)

func set_instrument(instrument: String):
	current_instrument = instrument
	print("Instrument changed to: ", instrument)

func set_difficulty(difficulty: String):
	current_difficulty = difficulty
	print("Difficulty changed to: ", difficulty)

func _on_waveform_toggled(enabled: bool):
	show_waveform = enabled
	_toggle_waveform_display()
	print("Waveform display: ", "ON" if show_waveform else "OFF")

func _toggle_waveform_display():
	if not runway_board_renderer:
		print("ERROR: No runway_board_renderer found!")
		return
	
	var runway_material = runway_board_renderer.get_surface_override_material(0)
	if not runway_material:
		print("ERROR: No runway material found!")
		return
	
	if show_waveform:
		# Show waveform - apply the texture
		if waveform_texture:
			print("Applying waveform texture to runway...")
			runway_material.albedo_texture = waveform_texture
			# Enable texture mixing with base color
			runway_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # White to show texture
			
			# The waveform texture is now oriented correctly:
			# - X-axis (width=512) = amplitude across the runway
			# - Y-axis (height=2048) = time along the runway
			# The texture represents the FULL song duration
			# We want it to display once and scroll through as time progresses
			# UV scale of 1.0 means the texture displays once across the surface
			runway_material.uv1_scale = Vector3(1.0, 1.0, 1.0)
			
			# Ensure texture is visible
			runway_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			print("✓ Waveform texture applied successfully!")
			print("  - Texture size: ", waveform_texture.get_size())
			print("  - UV scale: ", runway_material.uv1_scale)
			print("  - Song duration: ", song_duration, "s")
		else:
			print("ERROR: No waveform texture available - load audio first")
	else:
		# Hide waveform - remove the texture and restore runway color
		print("Removing waveform texture from runway...")
		runway_material.albedo_texture = null
		runway_material.albedo_color = Color(0.2, 0.2, 0.25)  # Restore dark gray-blue
		runway_material.uv1_scale = Vector3(num_lanes, 1, 1)  # Restore original scale
		print("✓ Waveform texture removed")

# Mouse input and note placement
func _on_runway_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if current_tool == "Note":
				_place_note_at_mouse(event.position)
			elif current_tool == "Erase":
				_erase_note_at_mouse(event.position)
	elif event is InputEventMouseMotion:
		if current_tool == "Note":
			_update_preview_note(event.position)

func _on_runway_mouse_entered():
	if preview_note and current_tool == "Note":
		preview_note.visible = true

func _on_runway_mouse_exited():
	if preview_note:
		preview_note.visible = false

func _update_preview_note(mouse_pos: Vector2):
	if not preview_note:
		return
	
	# Convert mouse to runway position
	var world_pos = _mouse_to_runway_position(mouse_pos)
	if world_pos != Vector3.ZERO:
		var lane = _position_to_lane(world_pos.x)
		var time = _position_to_time(world_pos.z)
		time = _snap_time_to_grid(time)
		
		# Update preview note properties
		preview_note.fret = lane
		preview_note.note_type = _string_to_note_type(current_note_type)
		preview_note.position = _time_to_runway_position(time, lane)
		preview_note.update_visuals()
		preview_note.visible = true
		
		# Store for potential placement
		current_preview_lane = lane
		current_preview_time = time
	else:
		preview_note.visible = false

func _place_note_at_mouse(mouse_pos: Vector2):
	# Convert 2D mouse position to 3D runway position
	var world_pos = _mouse_to_runway_position(mouse_pos)
	if world_pos:
		var lane = _position_to_lane(world_pos.x)
		var time = _position_to_time(world_pos.z)
		
		# Snap time to grid
		time = _snap_time_to_grid(time)
		
		# Create note data
		var note_data = {
			"lane": lane,
			"time": time,
			"note_type": _string_to_note_type(current_note_type),
			"is_sustain": false,
			"sustain_length": 0.0
		}
		
		placed_notes.append(note_data)
		_create_note_visual(note_data)
		settings_panel.update_note_count(placed_notes.size())
		print("Note placed at lane ", lane, " time ", time)

func _erase_note_at_mouse(mouse_pos: Vector2):
	# Convert mouse position to runway position
	var runway_pos = _mouse_to_runway_position(mouse_pos)
	if runway_pos == Vector3.ZERO:
		return
	
	# Find the lane and time at this position
	var lane = _position_to_lane(runway_pos.x)
	var time = _position_to_time(runway_pos.z)
	
	# Find nearest note within a threshold
	var threshold = 0.2  # 200ms threshold for note selection
	var nearest_note = null
	var nearest_distance = threshold
	
	for note_data in placed_notes:
		if note_data.lane == lane:
			var time_diff = abs(note_data.time - time)
			if time_diff < nearest_distance:
				nearest_distance = time_diff
				nearest_note = note_data
	
	# Remove the note if found
	if nearest_note:
		# Remove visual
		if note_visuals.has(nearest_note):
			var visual = note_visuals[nearest_note]
			if visual:
				visual.queue_free()
			note_visuals.erase(nearest_note)
		
		# Remove from placed notes
		placed_notes.erase(nearest_note)
		
		# Update UI
		settings_panel.update_note_count(placed_notes.size())
		print("Note erased at lane ", lane, " time ", nearest_note.time)

func _place_note_at_cursor_time(lane: int):
	# Place a note at the current timeline time in the specified lane
	if lane < 0 or lane >= num_lanes:
		return
	
	# Use current_time as the placement time (snapped to grid)
	var time = _snap_time_to_grid(current_time)
	
	# Check if a note already exists at this time and lane
	for note_data in placed_notes:
		if note_data.lane == lane and abs(note_data.time - time) < 0.01:
			print("Note already exists at this position")
			return
	
	# Create note data
	var note_data = {
		"lane": lane,
		"time": time,
		"note_type": _string_to_note_type(current_note_type),
		"is_sustain": false,
		"sustain_length": 0.0
	}
	
	placed_notes.append(note_data)
	_create_note_visual(note_data)
	settings_panel.update_note_count(placed_notes.size())
	print("Note placed at lane ", lane, " time ", time, " (keyboard shortcut)")

func _increase_snap_division():
	# Increase snap division: 4 -> 8 -> 12 -> 16 -> 24 -> 32 -> 64 -> (cycle back to 4)
	var divisions = [4, 8, 12, 16, 24, 32, 64]
	var current_index = divisions.find(snap_division)
	if current_index >= 0:
		var next_index = (current_index + 1) % divisions.size()
		snap_division = divisions[next_index]
	else:
		snap_division = 16  # Default
	
	# Update UI
	settings_panel.set_snap_step(snap_division)
	print("Snap division increased to 1/", snap_division)

func _decrease_snap_division():
	# Decrease snap division: 4 <- 8 <- 12 <- 16 <- 24 <- 32 <- 64 <- (cycle back to 64)
	var divisions = [4, 8, 12, 16, 24, 32, 64]
	var current_index = divisions.find(snap_division)
	if current_index >= 0:
		var prev_index = (current_index - 1 + divisions.size()) % divisions.size()
		snap_division = divisions[prev_index]
	else:
		snap_division = 16  # Default
	
	# Update UI
	settings_panel.set_snap_step(snap_division)
	print("Snap division decreased to 1/", snap_division)

func _delete_selected_notes():
	# TODO: Implement note selection system first
	# For now, this is a placeholder
	print("Delete selected notes - selection system not yet implemented")

func _mouse_to_runway_position(mouse_pos: Vector2) -> Vector3:
	if not camera_3d:
		return Vector3.ZERO
	
	# Get the SubViewport size and convert mouse position to viewport coordinates
	var viewport = runway_viewport.get_node("SubViewport")
	if not viewport:
		return Vector3.ZERO
	
	# mouse_pos is relative to runway_viewport control, need to map to SubViewport
	# SubViewport fills the entire runway_viewport control, so coordinates map 1:1
	var viewport_size = viewport.size
	var viewport_mouse = mouse_pos
	
	# Ensure mouse is within viewport bounds
	if viewport_mouse.x < 0 or viewport_mouse.y < 0 or viewport_mouse.x > viewport_size.x or viewport_mouse.y > viewport_size.y:
		return Vector3.ZERO
	
	# Project ray from camera through mouse position
	var from = camera_3d.project_ray_origin(viewport_mouse)
	var to = from + camera_3d.project_ray_normal(viewport_mouse) * 1000
	
	# Intersect with runway plane (y = 0)
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(from, to - from)
	
	return intersection if intersection else Vector3.ZERO

func _position_to_lane(x_pos: float) -> int:
	# Find which lane the x position corresponds to
	for i in range(lanes.size()):
		if abs(x_pos - lanes[i]) < (runway_board_renderer.zone_width / 2.0):
			return i
	return 0

func _position_to_time(z_pos: float) -> float:
	# Convert z position on runway to time in song
	# Z coordinate system: negative Z = far away = future time, Z = 0 = hit line = current_time
	# Earlier notes (negative Z) should map to later time (current_time + offset)
	# Using the inverse of _time_to_runway_position: z = (time - current_time) * -note_speed
	# So: time = current_time - (z / note_speed)
	var note_speed = SettingsManager.note_speed if SettingsManager else 20.0
	return current_time - (z_pos / note_speed)

func _snap_time_to_grid(time: float) -> float:
	# Snap time to the nearest grid division
	# Use default BPM of 120 if no tempo events exist
	var bpm = 120.0
	if tempo_events.size() > 0:
		bpm = tempo_events[0].bpm
	
	# Calculate snap duration based on BPM and snap division
	# snap_division is the denominator (e.g., 16 for 1/16 notes)
	var beat_duration = 60.0 / bpm  # Duration of one quarter note in seconds
	var snap_duration = beat_duration / (snap_division / 4.0)  # Duration of one snap unit
	
	var snapped_time = round(time / snap_duration) * snap_duration
	return snapped_time

# Note visual management
func _create_note_visual(note_data: Dictionary):
	# Load and instantiate note scene
	var note_scene = preload("res://Scenes/note.tscn")
	var note = note_scene.instantiate()
	
	# Set note properties
	note.fret = note_data.lane
	note.note_type = note_data.note_type
	note.is_sustain = note_data.sustain_length > 0
	note.sustain_length = note_data.sustain_length
	
	# CRITICAL: Disable automatic movement - editor controls positioning
	note.movement_paused = true
	note.use_timeline_positioning = true
	
	# Calculate 3D position
	note.position = _time_to_runway_position(note_data.time, note_data.lane)
	
	# Update visuals to show correct texture/color
	note.update_visuals()
	
	# Add to SubViewport (add as child of runway or camera's parent)
	if runway_viewport:
		var viewport = runway_viewport.get_node("SubViewport")
		viewport.add_child(note)
	
	# Store reference
	note_visuals[note_data] = note
	
	return note

func _time_to_runway_position(time: float, lane: int) -> Vector3:
	# Convert time and lane to 3D position on runway
	var x = lanes[lane] if lane < lanes.size() else 0.0
	var y = 0.5  # Slightly above runway surface
	
	# Z position based on time relative to current_time
	# Notes at current_time should be at z=0 (hit line)
	# Earlier notes should be negative (further away)
	var time_diff = time - current_time
	# Use the same note speed as gameplay for consistent visual speed
	var note_speed = SettingsManager.note_speed if SettingsManager else 20.0
	var z = time_diff * -note_speed
	
	return Vector3(x, y, z)

func _create_note_visuals_from_chart():
	# Create visuals for all loaded chart notes
	_clear_note_visuals()
	
	for note_data in placed_notes:
		_create_note_visual(note_data)

func _clear_note_visuals():
	for visual in note_visuals.values():
		if visual:
			visual.queue_free()
	note_visuals.clear()

# Helper functions
func _string_to_note_type(note_type_string: String) -> NoteType.Type:
	match note_type_string:
		"Regular":
			return NoteType.Type.REGULAR
		"HOPO":
			return NoteType.Type.HOPO
		"Tap":
			return NoteType.Type.TAP
		"Open":
			return NoteType.Type.OPEN
		_:
			return NoteType.Type.REGULAR

# Waveform visualization
func _generate_waveform_texture():
	if not audio_stream:
		return
	
	print("Generating waveform texture...")
	
	# Get audio data
	var audio_data = _get_audio_data(audio_stream)
	if audio_data.is_empty():
		print("No audio data available for waveform")
		return
	
	# Create waveform image
	# NOTE: We draw it rotated 90° so time goes vertically (along runway Y-axis in UVs)
	var waveform_width = 512   # Width in pixels (amplitude direction, across runway)
	var waveform_height = 2048  # Height in pixels (time direction, along runway)
	var image = Image.create(waveform_width, waveform_height, false, Image.FORMAT_RGBA8)
	
	# Fill with semi-transparent dark background
	image.fill(Color(0.1, 0.1, 0.15, 0.7))
	
	# Calculate samples per pixel along the HEIGHT (time axis)
	var samples_per_pixel = float(audio_data.size()) / float(waveform_height)
	
	# Draw waveform - iterate along Y (time), draw amplitude on X
	for y in range(waveform_height):
		var sample_start = int(y * samples_per_pixel)
		var sample_end = int((y + 1) * samples_per_pixel)
		
		# Get min and max amplitude in this pixel range
		var min_amp = 0.0
		var max_amp = 0.0
		
		for i in range(sample_start, min(sample_end, audio_data.size())):
			var amp = audio_data[i]
			min_amp = min(min_amp, amp)
			max_amp = max(max_amp, amp)
		
		# Convert amplitude to pixel width (center line is at width/2)
		var center_x = waveform_width / 2.0
		var x_min = int(center_x + min_amp * center_x)
		var x_max = int(center_x + max_amp * center_x)
		
		# Draw horizontal line for this pixel (amplitude across the width)
		for x in range(max(0, x_min), min(waveform_width, x_max + 1)):
			# Gradient color from blue to cyan based on amplitude
			var amp_intensity = abs((x - center_x) / float(center_x))
			var color = Color(0.2, 0.5 + amp_intensity * 0.5, 1.0, 0.9)
			image.set_pixel(x, y, color)
	
	# Create texture from image and cache it
	waveform_texture = ImageTexture.create_from_image(image)
	print("✓ Waveform texture generated and cached successfully!")
	print("  - Texture dimensions: ", waveform_width, "x", waveform_height)
	print("  - Audio data samples: ", audio_data.size())
	print("  - Song duration: ", song_duration, " seconds")

func _get_audio_data(stream: AudioStream) -> PackedFloat32Array:
	# Extract raw audio data for waveform visualization
	var data = PackedFloat32Array()
	
	if stream is AudioStreamOggVorbis:
		# For OGG, we need to get the raw packet data
		var ogg_data = stream.get_packet_sequence()
		if ogg_data and ogg_data.get_length() > 0:
			# This is a simplified approach - actual OGG decoding would require more complex processing
			# For now, we'll create a placeholder that shows the general structure
			var duration = stream.get_length()
			var num_samples = int(duration * 100)  # 100 samples per second
			
			for i in range(num_samples):
				# Generate a simple visualization based on packet data
				var amp = randf_range(-0.5, 0.5)  # Placeholder waveform
				data.append(amp)
	
	elif stream is AudioStreamMP3:
		# Similar approach for MP3
		var duration = stream.get_length()
		var num_samples = int(duration * 100)
		
		for i in range(num_samples):
			var amp = randf_range(-0.5, 0.5)  # Placeholder waveform
			data.append(amp)
	
	elif stream is AudioStreamWAV:
		# WAV files have direct access to PCM data
		var wav_data = stream.data
		if wav_data and wav_data.size() > 0:
			var downsample_factor = max(1, wav_data.size() / 10000)  # Target ~10k samples
			
			for i in range(0, wav_data.size(), downsample_factor):
				# WAV data is typically stored as bytes, need to convert to float
				var sample = (wav_data[i] - 128) / 128.0  # Normalize to -1.0 to 1.0
				data.append(sample)
	
	return data
