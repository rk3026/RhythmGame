extends Node
class_name EditorNoteCreationService

## Handles all note creation logic for the chart editor, including hold notes
## Separates note creation concerns from input handling and chart editor state management

const NoteScene = preload("res://Scenes/note.tscn")

signal note_created(note_data: Dictionary)

# Dependencies
var chart_document: ChartDocument
var playback_controller: EditorPlaybackController
var tempo_events: Array = []
var resolution: int = 192
var num_lanes: int = 5
var current_note_type: String = "Regular"
var runway_viewport: Node = null
var lanes: Array = []

# Hold note tracking
var _active_hold_notes: Dictionary = {}  # lane -> {start_time, start_tick, preview_visual}

# Process for updating live previews
var _process_enabled: bool = false

func _ready():
	set_process(true)

func _process(_delta: float):
	if not _process_enabled:
		return
	# Update all active hold note previews
	for lane in _active_hold_notes.keys():
		_update_hold_preview(lane)

func configure(config: Dictionary):
	chart_document = config.get("chart_document")
	playback_controller = config.get("playback_controller")
	tempo_events = config.get("tempo_events", [])
	resolution = config.get("resolution", 192)
	num_lanes = config.get("num_lanes", 5)
	current_note_type = config.get("current_note_type", "Regular")
	runway_viewport = config.get("runway_viewport")
	lanes = config.get("lanes", [])

func set_tempo_events(events: Array):
	tempo_events = events

func set_resolution(res: int):
	resolution = res

func set_note_type(note_type: String):
	current_note_type = note_type

## Place a regular note (no sustain) at the given time
func place_note_at_time(lane: int, time: float) -> bool:
	if lane < 0 or lane >= num_lanes:
		return false
	
	# Check if a note already exists at this time and lane
	var existing_note = chart_document.find_note_by_lane_and_time(lane, time, 0.01)
	if not existing_note.is_empty():
		print("Note already exists at lane ", lane, " time ", time)
		return false
	
	# Calculate tick position
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
	
	note_created.emit(note_data)
	print("Note placed at lane ", lane, " time ", time)
	return true

## Start a hold note at the current playback time
func start_hold_note(lane: int) -> bool:
	if lane < 0 or lane >= num_lanes:
		return false
	
	# Ignore if already holding a note on this lane
	if _active_hold_notes.has(lane):
		print("Already holding note on lane ", lane)
		return false
	
	if not playback_controller:
		push_error("Playback controller not configured")
		return false
	
	var press_time = playback_controller.get_current_time()
	var tick: int = TempoCalculator.time_to_tick(press_time, tempo_events, resolution)
	
	# Create visual preview
	var preview_visual = _create_hold_preview(lane, press_time)
	
	# Store the start time, tick, and preview
	_active_hold_notes[lane] = {
		"start_time": press_time,
		"start_tick": tick,
		"preview_visual": preview_visual
	}
	
	# Enable process for updating previews
	_process_enabled = true
	
	print("Hold note started on lane ", lane, " at time ", press_time)
	return true

## Finish a hold note and create it with the calculated sustain length
func finish_hold_note(lane: int) -> bool:
	if lane < 0 or lane >= num_lanes:
		return false
	
	# Check if we have an active hold note for this lane
	if not _active_hold_notes.has(lane):
		print("No active hold note on lane ", lane)
		return false
	
	if not playback_controller:
		push_error("Playback controller not configured")
		return false
	
	var hold_data = _active_hold_notes[lane]
	var start_time = hold_data["start_time"]
	var start_tick = hold_data["start_tick"]
	var preview_visual = hold_data.get("preview_visual")
	
	# Remove visual preview
	if preview_visual:
		preview_visual.queue_free()
	
	# Remove from tracking immediately
	_active_hold_notes.erase(lane)
	
	# Disable process if no more active holds
	if _active_hold_notes.is_empty():
		_process_enabled = false
	
	var release_time = playback_controller.get_current_time()
	var sustain_length = release_time - start_time
	var end_tick = TempoCalculator.time_to_tick(release_time, tempo_events, resolution)
	var sustain_ticks = end_tick - start_tick
	
	# Minimum sustain length to be considered a hold note (100ms)
	var is_sustain = sustain_length > 0.1
	
	# Create the note with the final sustain length
	var note_data = {
		"lane": lane,
		"time": start_time,
		"tick": start_tick,
		"note_type": _string_to_note_type(current_note_type),
		"is_sustain": is_sustain,
		"sustain_length": sustain_length if is_sustain else 0.0,
		"sustain_length_ticks": sustain_ticks if is_sustain else 0
	}
	
	note_created.emit(note_data)
	print("Hold note finished on lane ", lane, " with sustain ", sustain_length, "s")
	return true

## Cancel all active hold notes (called when playback stops)
func cancel_all_hold_notes():
	# Finalize any notes still being held
	var lanes_to_finish = _active_hold_notes.keys().duplicate()
	for lane in lanes_to_finish:
		finish_hold_note(lane)
	_active_hold_notes.clear()

## Check if a hold note is active on the given lane
func is_hold_note_active(lane: int) -> bool:
	return _active_hold_notes.has(lane)

## Get the number of active hold notes
func get_active_hold_count() -> int:
	return _active_hold_notes.size()

func _create_hold_preview(lane: int, start_time: float) -> Node:
	# Create a preview note visual
	var note = NoteScene.instantiate()
	note.fret = lane
	note.note_type = _string_to_note_type(current_note_type)
	note.is_sustain = true
	note.sustain_length = 0.0  # Will be updated each frame
	note.movement_paused = true
	note.use_timeline_positioning = true
	note.modulate = Color(1, 1, 1, 0.6)  # Semi-transparent to indicate preview
	
	# Position at start time
	var pos = _to_runway_position(start_time, lane)
	note.position = pos
	note.update_visuals()
	
	# Add to viewport
	var viewport = runway_viewport.get_node("SubViewport") if runway_viewport else null
	if viewport:
		viewport.add_child(note)
	
	return note

func _update_hold_preview(lane: int):
	if not _active_hold_notes.has(lane):
		return
	
	if not playback_controller:
		return
	
	var hold_data = _active_hold_notes[lane]
	var start_time = hold_data["start_time"]
	var preview_visual = hold_data.get("preview_visual")
	
	if not preview_visual or not is_instance_valid(preview_visual):
		return
	
	# Calculate current sustain length
	var current_time = playback_controller.get_current_time()
	var sustain_length = max(0.0, current_time - start_time)
	
	# Update the preview visual
	preview_visual.sustain_length = sustain_length
	preview_visual.is_sustain = sustain_length > 0.0
	preview_visual.update_visuals()
	
	# Update position (in case current_time changed)
	var pos = _to_runway_position(start_time, lane)
	preview_visual.position = pos

func _to_runway_position(time_value: float, lane: int) -> Vector3:
	if not playback_controller:
		return Vector3.ZERO
	
	var current_time = playback_controller.get_current_time()
	var x = lanes[lane] if lane < lanes.size() else 0.0
	var y = 0.5
	var time_diff = time_value - current_time
	var note_speed = SettingsManager.note_speed if SettingsManager else 20.0
	var z = time_diff * -note_speed
	return Vector3(x, y, z)

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
