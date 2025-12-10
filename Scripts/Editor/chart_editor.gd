extends Control

const ChartDocumentResource = preload("res://Scripts/Editor/chart_document.gd")
const EditorCommandStack = preload("res://Scripts/Editor/editor_command_stack.gd")
const AddNoteCommand = preload("res://Scripts/Editor/Commands/add_note_command.gd")
const RemoveNoteCommand = preload("res://Scripts/Editor/Commands/remove_note_command.gd")
const UpdateNoteCommand = preload("res://Scripts/Editor/Commands/update_note_command.gd")
const AddEventCommand = preload("res://Scripts/Editor/Commands/add_event_command.gd")
const RemoveEventCommand = preload("res://Scripts/Editor/Commands/remove_event_command.gd")
const UpdateEventCommand = preload("res://Scripts/Editor/Commands/update_event_command.gd")
const ChartEditorWaveformManager = preload("res://Scripts/Editor/Services/chart_editor_waveform_manager.gd")
const EditorNoteVisualManager = preload("res://Scripts/Editor/Services/editor_note_visual_manager.gd")
const ChartEditorFileService = preload("res://Scripts/Editor/Services/chart_editor_file_service.gd")
const RunwayInteractionController = preload("res://Scripts/Editor/Services/runway_interaction_controller.gd")
const EditorTransportController = preload("res://Scripts/Editor/Services/editor_transport_controller.gd")
const BeatLineRenderer = preload("res://Scripts/Editor/Services/beat_line_renderer.gd")

# References to UI components
@onready var toolbar = $MainLayout/Toolbar
@onready var settings_panel = $MainLayout/ContentArea/LeftPanel/SettingsPanel
@onready var toolbox = $MainLayout/ContentArea/LeftPanel/Toolbox
@onready var progress_bar = $MainLayout/ContentArea/ProgressBar
@onready var runway_viewport = $MainLayout/ContentArea/CenterArea/RunwayViewport
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
var loading_overlay: Control = null
var event_dialog: AcceptDialog = null

# Chart data
var current_chart_path: String = ""
var current_instrument: String = "Single"
var current_difficulty: String = "Expert"
var chart_document: ChartDocument
var tempo_events: Array = []
var time_signatures: Array = []
var resolution: int = 192
var chart_resolution: int = 192  # Ticks per beat
var offset: float = 0.0
var command_stack: EditorCommandStack
var waveform_manager: ChartEditorWaveformManager
var note_visual_manager: EditorNoteVisualManager
var file_service: ChartEditorFileService
var runway_interaction: RunwayInteractionController
var transport_controller: EditorTransportController
var beat_line_renderer: BeatLineRenderer

# Editor state
var current_time: float = 0.0
var snap_division: int = 16  # 1/16 notes by default
var playback_speed: float = 1.0
var note_placement_mode: bool = true
var num_lanes: int = 5
var show_waveform: bool = true  # Toggle for waveform display

# Audio system
var audio_stream: AudioStream
var song_duration: float = 0.0
var audio_file_path: String = ""

# Runway system
var lanes: Array = []
var runway_board_renderer: Node

@onready var playback_controller: EditorPlaybackController = $PlaybackController

func _ready():
	print("Chart Editor initialized")

	chart_document = ChartDocumentResource.new()
	command_stack = EditorCommandStack.new()
	command_stack.stack_changed.connect(_on_command_stack_changed)
	waveform_manager = ChartEditorWaveformManager.new()
	note_visual_manager = EditorNoteVisualManager.new(chart_document, runway_viewport, settings_panel)
	file_service = ChartEditorFileService.new()
	runway_interaction = RunwayInteractionController.new()
	add_child(runway_interaction)
	beat_line_renderer = BeatLineRenderer.new()
	add_child(beat_line_renderer)
	
	# Initialize with default tempo if none exists
	if tempo_events.is_empty():
		tempo_events.append({"tick": 0, "time": 0.0, "bpm": 120.0})
	
	# Initialize with default time signature if none exists
	if time_signatures.is_empty():
		time_signatures.append({"tick": 0, "numerator": 4, "denominator": 4})
	
	# Initialize song properties with default BPM
	if not song_properties.has("bpm"):
		song_properties["bpm"] = 120.0
	
	_setup_song_properties_dialog()
	_setup_runway()
	waveform_manager.configure(runway_board_renderer, num_lanes, settings_panel.hyperspeed)
	note_visual_manager.set_lane_positions(lanes)
	_configure_runway_interaction()
	_configure_beat_line_renderer()
	_setup_playback_controller()
	_setup_transport_controller()
	_connect_signals()
	
	# Enable mouse input for the runway viewport
	runway_viewport.mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_song_properties_dialog():
	# Load and instance the dialog
	var dialog_scene = load("res://Scenes/Editor/song_properties_dialog.tscn")
	song_properties_dialog = dialog_scene.instantiate()
	add_child(song_properties_dialog)
	song_properties_dialog.properties_saved.connect(_on_song_properties_saved)
	
	# Load loading overlay
	var overlay_scene = load("res://Scenes/Editor/loading_overlay.tscn")
	loading_overlay = overlay_scene.instantiate()
	add_child(loading_overlay)
	loading_overlay.visible = false
	
	# Load event dialog
	var event_dialog_scene = load("res://Scenes/Editor/event_dialog.tscn")
	event_dialog = event_dialog_scene.instantiate()
	add_child(event_dialog)
	event_dialog.event_saved.connect(_on_event_saved)

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

func _configure_runway_interaction():
	if not runway_interaction:
		return
	var params = {
		"runway_viewport": runway_viewport,
		"camera": camera_3d,
		"lanes": lanes,
		"runway_board_renderer": runway_board_renderer,
		"note_visual_manager": note_visual_manager,
		"chart_document": chart_document,
		"add_note_callable": func(note_data): _execute_add_note(note_data),
		"remove_note_callable": func(note_id): _execute_remove_note(note_id),
		"update_note_callable": func(note_id, changes): _execute_update_note(note_id, changes)
	}
	runway_interaction.configure(params)
	runway_interaction.set_tool(current_tool)
	runway_interaction.set_note_type(_string_to_note_type(current_note_type))
	runway_interaction.set_snap_division(snap_division)
	runway_interaction.set_tempo_events(tempo_events)
	runway_interaction.set_time_signatures(time_signatures)
	runway_interaction.set_resolution(resolution)
	runway_interaction.set_current_time(current_time)

func _configure_beat_line_renderer():
	if not beat_line_renderer:
		return
	var params = {
		"runway_viewport": runway_viewport,
		"camera": camera_3d,
		"note_speed": SettingsManager.note_speed if SettingsManager else 20.0,
		"viewport_height": runway_viewport.size.y if runway_viewport else 600.0
	}
	beat_line_renderer.configure(params)
	beat_line_renderer.set_tempo_events(tempo_events)
	beat_line_renderer.set_time_signatures(time_signatures)
	beat_line_renderer.set_resolution(resolution)
	beat_line_renderer.set_snap_division(snap_division)
	beat_line_renderer.set_current_time(current_time)

func _setup_playback_controller():
	if not playback_controller:
		return
	playback_controller.configure([], {})
	playback_controller.time_changed.connect(_on_playback_time_changed)

func _setup_transport_controller():
	transport_controller = EditorTransportController.new()
	var params = {
		"timeline_slider": timeline_slider,
		"time_label": time_label,
		"play_button": play_button,
		"pause_button": pause_button,
		"stop_button": stop_button,
		"playback_controller": playback_controller,
		"time_scrubbed_callable": func(value): _on_transport_time_scrubbed(value)
	}
	transport_controller.configure(params)
	transport_controller.set_current_time(current_time)
	if song_duration > 0.0:
		transport_controller.set_song_duration(song_duration)

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
	settings_panel.hyperspeed_changed.connect(_on_hyperspeed_changed)
	
	# Toolbox signals
	toolbox.tool_selected.connect(_on_tool_selected)
	toolbox.note_type_selected.connect(_on_note_type_selected)
	toolbox.sustain_toggled.connect(_on_sustain_toggled)
	
	# Progress bar / events panel signals
	progress_bar.event_add_requested.connect(_on_event_add_requested)
	progress_bar.event_edit_requested.connect(_on_event_edit_requested)
	progress_bar.event_delete_requested.connect(_on_event_delete_requested)
	progress_bar.section_selected.connect(_on_section_selected)
	
	# Configure progress bar with chart document
	progress_bar.configure(chart_document, song_duration)
	
	# Disable UI focus navigation to prevent shortcuts from interfering with UI
	_disable_ui_focus_navigation()

func _disable_ui_focus_navigation():
	# Disable focus mode on all controls to prevent arrow keys and shortcuts from navigating UI
	for child in get_tree().get_nodes_in_group("editor_ui"):
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE
	
	# Specifically disable focus on common UI elements
	if settings_panel:
		_disable_focus_recursive(settings_panel)
	if toolbar:
		_disable_focus_recursive(toolbar)
	if toolbox:
		_disable_focus_recursive(toolbox)

func _disable_focus_recursive(node: Node):
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_focus_recursive(child)

func _unhandled_key_input(event: InputEvent):
	# Use _unhandled_key_input to handle shortcuts after UI has had a chance
	# This prevents shortcuts from interfering with text input fields
	if event is InputEventKey and event.pressed:
		# Allow echo (key repeat) for navigation keys
		var allow_echo = event.keycode in [KEY_LEFT, KEY_RIGHT]
		if allow_echo or not event.echo:
			_handle_keyboard_shortcut(event)

func _handle_keyboard_shortcut(event: InputEventKey):
	# Don't process shortcuts if user is typing in a text field
	var focused = get_viewport().gui_get_focus_owner()
	if focused and (focused is LineEdit or focused is TextEdit):
		return
	
	# Handle keyboard shortcuts for chart editor
	var key = event.keycode
	
	# Tool selection shortcuts (Q/W/E/R)
	if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
		match key:
			KEY_Q:
				_on_tool_selected("Cursor")
				get_viewport().set_input_as_handled()
				return
			KEY_W:
				_on_tool_selected("Note")
				get_viewport().set_input_as_handled()
				return
			KEY_E:
				_on_tool_selected("Erase")
				get_viewport().set_input_as_handled()
				return
			KEY_R:
				_on_tool_selected("BPM")
				get_viewport().set_input_as_handled()
				return
	
	# Note type shortcuts (Shift + 1-4)
	if event.shift_pressed and not event.ctrl_pressed and key >= KEY_1 and key <= KEY_4:
		var note_types = ["Regular", "HOPO", "Tap", "Open"]
		var type_index = key - KEY_1
		if type_index < note_types.size():
			_on_note_type_selected(note_types[type_index])
			get_viewport().set_input_as_handled()
			return
	
	# Note placement shortcuts (1-5 for lanes)
	if key >= KEY_1 and key <= KEY_5 and current_tool == "Note" and not event.shift_pressed:
		var lane = key - KEY_1  # Convert KEY_1 to lane 0, KEY_2 to lane 1, etc.
		
		# During playback with sustain mode: handle hold notes
		if playback_controller and playback_controller.is_playing and sustain_mode_enabled:
			if event.pressed:
				_on_hold_key_pressed(lane)
			else:
				_on_hold_key_released(lane)
			get_viewport().set_input_as_handled()
			return
		
		# During playback WITHOUT sustain mode, or not playing: place regular note on key press only
		if event.pressed:
			if playback_controller and playback_controller.is_playing:
				# Place note at current playback time
				var current_time = playback_controller.get_current_time()
				_place_note_at_time(lane, current_time)
			else:
				# Place note at cursor time
				_place_note_at_cursor_time(lane)
			get_viewport().set_input_as_handled()
		return
	
	# Timeline navigation - Arrow keys with modifiers
	if key == KEY_LEFT:
		if event.shift_pressed:
			_move_timeline_backward_measure()
		elif event.ctrl_pressed:
			_move_timeline_backward_beat()
		else:
			_move_timeline_backward()
		get_viewport().set_input_as_handled()
		return
	
	if key == KEY_RIGHT:
		if event.shift_pressed:
			_move_timeline_forward_measure()
		elif event.ctrl_pressed:
			_move_timeline_forward_beat()
		else:
			_move_timeline_forward()
		get_viewport().set_input_as_handled()
		return
	
	# Jump to start/end
	if key == KEY_HOME:
		_jump_to_start()
		get_viewport().set_input_as_handled()
		return
	
	if key == KEY_END:
		_jump_to_end()
		get_viewport().set_input_as_handled()
		return
	
	# Playback control
	if key == KEY_SPACE:
		if transport_controller:
			transport_controller.toggle_playback()
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

	# Undo / Redo
	if event.ctrl_pressed and key == KEY_Z and not event.shift_pressed:
		_undo_editor_action()
		get_viewport().set_input_as_handled()
		return
	if (event.ctrl_pressed and key == KEY_Y) or (event.ctrl_pressed and event.shift_pressed and key == KEY_Z):
		_redo_editor_action()
		get_viewport().set_input_as_handled()
		return
	
	# Delete selected notes
	if key == KEY_DELETE:
		_delete_selected_notes()
		get_viewport().set_input_as_handled()
		return

func _undo_editor_action():
	if command_stack:
		command_stack.undo()

func _redo_editor_action():
	if command_stack:
		command_stack.redo()

func _execute_add_note(note_data: Dictionary):
	if command_stack:
		var cmd = AddNoteCommand.new(chart_document, note_data)
		command_stack.execute(cmd)
	else:
		chart_document.add_note(note_data)

func _execute_add_note_direct(note_data: Dictionary) -> int:
	# Direct add that returns note ID (for playback hold notes)
	if command_stack:
		var cmd = AddNoteCommand.new(chart_document, note_data)
		command_stack.execute(cmd)
		return cmd.note_id
	else:
		return chart_document.add_note(note_data)

func _execute_remove_note(note_id: int):
	if command_stack:
		var cmd = RemoveNoteCommand.new(chart_document, note_id)
		command_stack.execute(cmd)
	else:
		chart_document.remove_note(note_id)

func _execute_update_note(note_id: int, changes: Dictionary):
	if command_stack:
		var cmd = UpdateNoteCommand.new(chart_document, note_id, changes)
		command_stack.execute(cmd)
	else:
		chart_document.update_note(note_id, changes)
	
	# The chart_document.update_note triggers note_changed signal
	# which calls _on_note_changed in visual_manager
	# That handler now forces immediate visual update

func _execute_add_event(event_data: Dictionary):
	if command_stack:
		var cmd = AddEventCommand.new(chart_document, event_data)
		command_stack.execute(cmd)
	else:
		chart_document.add_event(event_data)

func _execute_remove_event(event_id: int):
	if command_stack:
		var cmd = RemoveEventCommand.new(chart_document, event_id)
		command_stack.execute(cmd)
	else:
		chart_document.remove_event(event_id)

func _execute_update_event(event_id: int, changes: Dictionary):
	if command_stack:
		var cmd = UpdateEventCommand.new(chart_document, event_id, changes)
		command_stack.execute(cmd)
	else:
		chart_document.update_event(event_id, changes)

func _on_command_stack_changed(_can_undo: bool, _can_redo: bool):
	# Placeholder: integrate with toolbar indicators or menu items when available.
	pass



func _update_editor_visuals():
	# Lightweight visual updates during playback
	# Only update what's necessary for smooth scrolling
	
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	if waveform_manager:
		waveform_manager.update_scroll(current_time, song_duration)
	if note_visual_manager:
		note_visual_manager.set_current_time(current_time)
		note_visual_manager.refresh_positions()
	if runway_interaction:
		runway_interaction.set_current_time(current_time)
	if beat_line_renderer:
		beat_line_renderer.set_note_speed(SettingsManager.note_speed if SettingsManager else 20.0)
		beat_line_renderer.set_current_time(current_time)
	
	# Update beat display
	_update_beat_display()

func _update_editor_state():
	# Full editor state update (called when manually seeking/scrubbing)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	if waveform_manager:
		waveform_manager.update_scroll(current_time, song_duration)
	if note_visual_manager:
		note_visual_manager.set_current_time(current_time)
		note_visual_manager.refresh_positions()
	if runway_interaction:
		runway_interaction.set_current_time(current_time)
	if beat_line_renderer:
		beat_line_renderer.set_note_speed(SettingsManager.note_speed if SettingsManager else 20.0)
		beat_line_renderer.set_current_time(current_time)

func _update_beat_display():
	# Calculate current beat and measure for display
	if tempo_events.is_empty():
		return
	
	var tick: int = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var beat_number: float = float(tick) / float(resolution)
	var current_bpm: float = TempoCalculator.get_bpm_at_time(current_time, tempo_events)
	
	# Update settings panel with beat info (if it has a beat display label)
	if settings_panel and settings_panel.has_method("set_beat_info"):
		settings_panel.set_beat_info(beat_number, current_bpm, snap_division)

# File operations
func _on_file_new():
	print("Creating new chart")
	if file_service:
		file_service.reset_document(chart_document, command_stack)
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
	if not file_service:
		push_error("File service unavailable")
		return
	var load_result = file_service.load_chart(path, current_instrument, chart_document, command_stack)
	if load_result.is_empty():
		push_error("Failed to load chart")
		return
	tempo_events = load_result.get("tempo_events", tempo_events)
	time_signatures = load_result.get("time_signatures", time_signatures)
	resolution = load_result.get("resolution", resolution)
	offset = load_result.get("offset", offset)
	if runway_interaction:
		runway_interaction.set_tempo_events(tempo_events)
		runway_interaction.set_time_signatures(time_signatures)
		runway_interaction.set_resolution(resolution)
	if beat_line_renderer:
		beat_line_renderer.set_tempo_events(tempo_events)
		beat_line_renderer.set_time_signatures(time_signatures)
		beat_line_renderer.set_resolution(resolution)
	# Update playback controller with new tempo data
	if playback_controller:
		_setup_playback_controller()
	print("Chart loaded successfully")

func save_chart():
	if current_chart_path.is_empty():
		push_error("No chart path specified")
		return
	print("Saving chart to: ", current_chart_path)
	if not file_service.save_chart(current_chart_path, chart_document, song_properties, chart_resolution, tempo_events, current_difficulty, current_instrument):
		return
	print("Chart saved successfully with ", chart_document.get_note_count(), " notes")

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
	
	# Update tempo events with BPM from song properties
	var bpm = properties.get("bpm", 120.0)
	if tempo_events.is_empty() or tempo_events[0].tick != 0:
		# Create or update the initial tempo event
		tempo_events.clear()
		tempo_events.append({"tick": 0, "time": 0.0, "bpm": bpm})
	else:
		# Update existing initial tempo event
		tempo_events[0].bpm = bpm
	
	# Propagate to all systems
	if runway_interaction:
		runway_interaction.set_tempo_events(tempo_events)
	if beat_line_renderer:
		beat_line_renderer.set_tempo_events(tempo_events)
		# Force immediate visual update
		beat_line_renderer.set_current_time(current_time)
	
	# Update beat display with new BPM
	_update_beat_display()
	
	print("✓ Tempo events updated with BPM: ", bpm, " - UI refreshed")

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
		audio_file_path = path
		if playback_controller:
			playback_controller.set_audio_stream(audio_stream)
			song_duration = playback_controller.song_length if playback_controller.song_length > 0.0 else audio_stream.get_length()
		else:
			song_duration = audio_stream.get_length()
		if transport_controller:
			transport_controller.set_song_duration(song_duration)
		else:
			timeline_slider.max_value = song_duration
		print("Audio loaded. Duration: ", song_duration, " seconds")
		
		# Update progress bar with new song duration
		if progress_bar:
			progress_bar.configure(chart_document, song_duration)
		
		if waveform_manager:
			var progress_callback = func(message: String, progress: float):
				_show_loading(message, progress)
			
			_show_loading("Processing audio...", 0.0)
			await waveform_manager.regenerate_waveform(audio_stream, audio_file_path, progress_callback)
			_hide_loading()
			
			# Enable waveform display by default
			waveform_manager.set_waveform_enabled(show_waveform)
	else:
		audio_file_path = ""
		push_error("Failed to load audio file: " + path)

func _on_playback_speed_changed(speed: float):
	playback_speed = speed
	if playback_controller:
		playback_controller.set_playback_speed(speed)

func _on_hyperspeed_changed(speed: float):
	waveform_manager.set_hyperspeed(speed)
	# Note: If waveform is currently loaded, it won't update until regenerated
	# The waveform points are baked with the hyperspeed value

# Tool and note type selection
var current_tool: String = "Note"
var current_note_type: String = "Regular"
var sustain_mode_enabled: bool = false

# Hold note tracking (for sustain mode during playback)
# Simple array: each index is a lane, value is null or {note_id, start_time, start_tick}
var _hold_notes: Array = [null, null, null, null, null]  # 5 lanes

func _on_tool_selected(tool_name: String):
	current_tool = tool_name
	if runway_interaction:
		runway_interaction.set_tool(current_tool)
	print("Tool selected: ", tool_name)

func _on_note_type_selected(note_type: String):
	current_note_type = note_type
	if runway_interaction:
		runway_interaction.set_note_type(_string_to_note_type(current_note_type))
	print("Note type selected: ", note_type)

func _on_sustain_toggled(enabled: bool):
	sustain_mode_enabled = enabled
	print("Sustain mode: ", "enabled" if enabled else "disabled")

# Settings
func set_snap_division(division: int):
	snap_division = division
	if runway_interaction:
		runway_interaction.set_snap_division(snap_division)
	print("Snap division set to 1/", division)

func set_instrument(instrument: String):
	current_instrument = instrument
	print("Instrument changed to: ", instrument)

func set_difficulty(difficulty: String):
	current_difficulty = difficulty
	print("Difficulty changed to: ", difficulty)

func _on_waveform_toggled(enabled: bool):
	show_waveform = enabled
	if waveform_manager:
		waveform_manager.set_waveform_enabled(show_waveform)
	print("Waveform display: ", "ON" if show_waveform else "OFF")

func _on_playback_time_changed(time_value: float):
	current_time = time_value
	if progress_bar:
		progress_bar.set_current_time(current_time)
	_update_editor_state()

func _on_transport_time_scrubbed(time_value: float):
	current_time = time_value
	if progress_bar:
		progress_bar.set_current_time(current_time)
	_update_editor_state()

func _on_hold_key_pressed(lane: int):
	# Ignore if already holding a note on this lane
	if _hold_notes[lane] != null:
		return
	
	var press_time = playback_controller.get_current_time()
	var tick: int = TempoCalculator.time_to_tick(press_time, tempo_events, resolution)
	
	# Store the start time and tick, but don't create the note yet
	_hold_notes[lane] = {
		"start_time": press_time,
		"start_tick": tick
	}

func _on_hold_key_released(lane: int):
	if _hold_notes[lane] == null:
		return
	
	var hold_data = _hold_notes[lane]
	var start_time = hold_data["start_time"]
	var start_tick = hold_data["start_tick"]
	
	# Clear tracking immediately
	_hold_notes[lane] = null
	
	var release_time = playback_controller.get_current_time()
	var sustain_length = release_time - start_time
	var end_tick = TempoCalculator.time_to_tick(release_time, tempo_events, resolution)
	var sustain_ticks = end_tick - start_tick
	
	# Create the note with the final sustain length
	var note_data = {
		"lane": lane,
		"time": start_time,
		"tick": start_tick,
		"note_type": _string_to_note_type(current_note_type),
		"is_sustain": sustain_length > 0.1,
		"sustain_length": sustain_length if sustain_length > 0.1 else 0.0,
		"sustain_length_ticks": sustain_ticks if sustain_length > 0.1 else 0
	}
	
	_execute_add_note(note_data)

func _finalize_all_hold_notes():
	# Called when playback stops - finalize any notes still being held
	for lane in range(5):
		if _hold_notes[lane] != null:
			_on_hold_key_released(lane)

func _place_note_at_time(lane: int, time: float):
	# Place a note at the specified time in the specified lane
	if lane < 0 or lane >= num_lanes:
		return
	
	# Check if a note already exists at this time and lane
	if not chart_document.find_note_by_lane_and_time(lane, time, 0.01).is_empty():
		print("Note already exists at this position")
		return
	
	# Calculate tick position for the note
	var tick: int = TempoCalculator.time_to_tick(time, tempo_events, resolution)
	
	# Create note data
	var note_data = {
		"lane": lane,
		"time": time,
		"tick": tick,
		"note_type": _string_to_note_type(current_note_type),
		"is_sustain": false,
		"sustain_length": 0.0,
		"sustain_length_ticks": 0
	}
	
	_execute_add_note(note_data)
	print("Note placed at lane ", lane, " time ", time, " (during playback)")

func _place_note_at_cursor_time(lane: int):
	# Place a note at the current timeline time in the specified lane
	if lane < 0 or lane >= num_lanes:
		return
	
	# Use current_time as the placement time (snapped to grid)
	var time = current_time
	if runway_interaction:
		time = runway_interaction.snap_time_to_grid(current_time)
	
	# Check if a note already exists at this time and lane
	if not chart_document.find_note_by_lane_and_time(lane, time, 0.01).is_empty():
		print("Note already exists at this position")
		return
	
	# Calculate tick position for the note
	var tick: int = TempoCalculator.time_to_tick(time, tempo_events, resolution)
	
	# Create note data
	var note_data = {
		"lane": lane,
		"time": time,
		"tick": tick,
		"note_type": _string_to_note_type(current_note_type),
		"is_sustain": false,
		"sustain_length": 0.0,
		"sustain_length_ticks": 0
	}
	
	_execute_add_note(note_data)
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
	if runway_interaction:
		runway_interaction.set_snap_division(snap_division)
	if beat_line_renderer:
		beat_line_renderer.set_snap_division(snap_division)
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
	if runway_interaction:
		runway_interaction.set_snap_division(snap_division)
	if beat_line_renderer:
		beat_line_renderer.set_snap_division(snap_division)
	print("Snap division decreased to 1/", snap_division)

# Timeline navigation functions
func _move_timeline_forward():
	# Move forward by one snap division
	var subdivisions_per_beat = snap_division / 4.0
	var ticks_per_subdivision = resolution / subdivisions_per_beat
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var next_tick = current_tick + int(ticks_per_subdivision)
	var next_time = TempoCalculator.tick_to_time(next_tick, tempo_events, resolution)
	
	current_time = clamp(next_time, 0.0, song_duration)
	
	# Sync with playback controller so play starts from correct position
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _move_timeline_backward():
	# Move backward by one snap division
	var subdivisions_per_beat = snap_division / 4.0
	var ticks_per_subdivision = resolution / subdivisions_per_beat
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var prev_tick = max(0, current_tick - int(ticks_per_subdivision))
	var prev_time = TempoCalculator.tick_to_time(prev_tick, tempo_events, resolution)
	
	current_time = max(0.0, prev_time)
	
	# Sync with playback controller so play starts from correct position
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _move_timeline_forward_beat():
	# Move forward by exactly 1 beat
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var next_tick = current_tick + resolution
	var next_time = TempoCalculator.tick_to_time(next_tick, tempo_events, resolution)
	
	current_time = clamp(next_time, 0.0, song_duration)
	
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _move_timeline_backward_beat():
	# Move backward by exactly 1 beat
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var prev_tick = max(0, current_tick - resolution)
	var prev_time = TempoCalculator.tick_to_time(prev_tick, tempo_events, resolution)
	
	current_time = max(0.0, prev_time)
	
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _move_timeline_forward_measure():
	# Move forward by 1 measure (bar)
	# Get time signature at current position (default to 4/4)
	var beats_per_measure = 4
	if not time_signatures.is_empty():
		var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
		for ts in time_signatures:
			if ts["tick"] <= current_tick:
				beats_per_measure = ts["numerator"]
	
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var ticks_per_measure = resolution * beats_per_measure
	var next_tick = current_tick + ticks_per_measure
	var next_time = TempoCalculator.tick_to_time(next_tick, tempo_events, resolution)
	
	current_time = clamp(next_time, 0.0, song_duration)
	
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _move_timeline_backward_measure():
	# Move backward by 1 measure (bar)
	# Get time signature at current position (default to 4/4)
	var beats_per_measure = 4
	if not time_signatures.is_empty():
		var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
		for ts in time_signatures:
			if ts["tick"] <= current_tick:
				beats_per_measure = ts["numerator"]
	
	var current_tick = TempoCalculator.time_to_tick(current_time, tempo_events, resolution)
	var ticks_per_measure = resolution * beats_per_measure
	var prev_tick = max(0, current_tick - ticks_per_measure)
	var prev_time = TempoCalculator.tick_to_time(prev_tick, tempo_events, resolution)
	
	current_time = max(0.0, prev_time)
	
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _jump_to_start():
	# Jump to the beginning of the song
	current_time = 0.0
	
	# Sync with playback controller
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _jump_to_end():
	# Jump to the end of the song
	current_time = song_duration
	
	# Sync with playback controller
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	
	_update_editor_state()

func _delete_selected_notes():
	# TODO: Implement note selection system first
	# For now, this is a placeholder
	print("Delete selected notes - selection system not yet implemented")

func _show_loading(message: String, progress: float = 0.0) -> void:
	if loading_overlay:
		loading_overlay.visible = true
		var status_label = loading_overlay.get_node("CenterContainer/VBox/StatusLabel")
		var progress_bar = loading_overlay.get_node("CenterContainer/VBox/ProgressBar")
		if status_label:
			status_label.text = message
		if progress_bar:
			progress_bar.value = progress

func _hide_loading() -> void:
	if loading_overlay:
		loading_overlay.visible = false

# Event management
func _on_event_add_requested(time: float):
	if event_dialog:
		event_dialog.configure(tempo_events, resolution)
		event_dialog.show_for_new_event(time)

func _on_event_edit_requested(event_id: int):
	var event_data = chart_document.get_event(event_id)
	if event_data.is_empty():
		return
	if event_dialog:
		event_dialog.configure(tempo_events, resolution)
		event_dialog.show_for_edit_event(event_data)

func _on_event_delete_requested(event_id: int):
	_execute_remove_event(event_id)

func _on_section_selected(_event_id: int, time: float):
	# Jump to the section's time
	current_time = time
	if playback_controller:
		playback_controller.seek(current_time)
	if transport_controller:
		transport_controller.set_current_time(current_time)
	_update_editor_state()

func _on_event_saved(event_data: Dictionary):
	if event_data.has("id") and event_data.id >= 0:
		# Editing existing event
		var changes = {
			"time": event_data.time,
			"tick": event_data.tick,
			"text": event_data.text,
			"type": event_data.type
		}
		_execute_update_event(event_data.id, changes)
	else:
		# Adding new event
		_execute_add_event(event_data)

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
