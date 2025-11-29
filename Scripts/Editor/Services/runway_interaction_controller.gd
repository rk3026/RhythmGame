extends Node
class_name RunwayInteractionController

const PreviewNoteScene = preload("res://Scenes/note.tscn")

signal note_added_manually(note_data)
signal note_erased_manually(note_id: int)

var runway_viewport: Control = null
var camera_3d: Camera3D = null
var lane_positions: Array = []
var runway_board_renderer: Node = null
var note_visual_manager: EditorNoteVisualManager = null
var chart_document: ChartDocument = null
var add_note_callable: Callable = Callable()
var remove_note_callable: Callable = Callable()

var preview_note: Sprite3D = null
var current_tool: String = "Note"
var current_note_type: NoteType.Type = NoteType.Type.REGULAR
var snap_division: int = 16
var tempo_events: Array = []
var current_time: float = 0.0
var erase_threshold: float = 0.2

func configure(params: Dictionary) -> void:
	runway_viewport = params.get("runway_viewport")
	camera_3d = params.get("camera")
	lane_positions = params.get("lanes", [])
	runway_board_renderer = params.get("runway_board_renderer")
	note_visual_manager = params.get("note_visual_manager")
	chart_document = params.get("chart_document")
	add_note_callable = params.get("add_note_callable", Callable())
	remove_note_callable = params.get("remove_note_callable", Callable())
	_setup_preview_note()
	if runway_viewport:
		runway_viewport.gui_input.connect(_on_runway_input)
		runway_viewport.mouse_entered.connect(_on_runway_mouse_entered)
		runway_viewport.mouse_exited.connect(_on_runway_mouse_exited)

func set_tool(tool_name: String) -> void:
	current_tool = tool_name
	if tool_name != "Note" and preview_note:
		preview_note.visible = false

func set_note_type(note_type: NoteType.Type) -> void:
	current_note_type = note_type
	if preview_note:
		preview_note.note_type = note_type
		preview_note.update_visuals()

func set_snap_division(division: int) -> void:
	snap_division = max(division, 1)

func set_tempo_events(events: Array) -> void:
	tempo_events = events.duplicate(true)

func set_current_time(time_value: float) -> void:
	current_time = time_value

func snap_time_to_grid(time_value: float) -> float:
	var bpm: float = 120.0
	if tempo_events.size() > 0:
		bpm = tempo_events[0].bpm
	var beat_duration: float = 60.0 / bpm
	var snap_duration: float = beat_duration / (snap_division / 4.0)
	return round(time_value / snap_duration) * snap_duration

func _setup_preview_note() -> void:
	preview_note = PreviewNoteScene.instantiate()
	preview_note.movement_paused = true
	preview_note.use_timeline_positioning = true
	preview_note.modulate = Color(1, 1, 1, 0.5)
	preview_note.visible = false
	preview_note.fret = 0
	preview_note.note_type = current_note_type
	if runway_viewport:
		var viewport: SubViewport = runway_viewport.get_node("SubViewport")
		if viewport:
			viewport.add_child(preview_note)

func _on_runway_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_tool == "Note":
				_place_note_at_mouse(event.position)
			elif current_tool == "Erase":
				_erase_note_at_mouse(event.position)
	elif event is InputEventMouseMotion:
		if current_tool == "Note":
			_update_preview_note(event.position)

func _on_runway_mouse_entered() -> void:
	if preview_note and current_tool == "Note":
		preview_note.visible = true

func _on_runway_mouse_exited() -> void:
	if preview_note:
		preview_note.visible = false

func _place_note_at_mouse(mouse_pos: Vector2) -> void:
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		return
	var lane: int = _position_to_lane(world_pos.x)
	var time_value: float = snap_time_to_grid(_position_to_time(world_pos.z))
	if chart_document and not chart_document.find_note_by_lane_and_time(lane, time_value, 0.01).is_empty():
		return
	var note_data: Dictionary = {
		"lane": lane,
		"time": time_value,
		"note_type": current_note_type,
		"is_sustain": false,
		"sustain_length": 0.0
	}
	if add_note_callable.is_valid():
		add_note_callable.call(note_data)

func _erase_note_at_mouse(mouse_pos: Vector2) -> void:
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		return
	var lane: int = _position_to_lane(world_pos.x)
	var time_value: float = _position_to_time(world_pos.z)
	if not chart_document:
		return
	var note_to_remove: Dictionary = chart_document.find_note_by_lane_and_time(lane, time_value, erase_threshold)
	if note_to_remove.is_empty():
		return
	var note_id: int = note_to_remove.get("id", 0)
	if note_id == 0:
		return
	if remove_note_callable.is_valid():
		remove_note_callable.call(note_id)

func _update_preview_note(mouse_pos: Vector2) -> void:
	if not preview_note:
		return
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		preview_note.visible = false
		return
	var lane: int = _position_to_lane(world_pos.x)
	var time_value: float = snap_time_to_grid(_position_to_time(world_pos.z))
	preview_note.fret = lane
	preview_note.note_type = current_note_type
	var preview_position: Vector3 = Vector3(world_pos.x, 0.5, world_pos.z)
	if note_visual_manager:
		preview_position = note_visual_manager.to_runway_position(time_value, lane)
	preview_note.position = preview_position
	preview_note.update_visuals()
	preview_note.visible = true

func _mouse_to_runway_position(mouse_pos: Vector2) -> Vector3:
	if not camera_3d or not runway_viewport:
		return Vector3.ZERO
	var viewport: SubViewport = runway_viewport.get_node("SubViewport")
	if not viewport:
		return Vector3.ZERO
	var viewport_size: Vector2i = viewport.size
	var viewport_mouse: Vector2 = mouse_pos
	if viewport_mouse.x < 0 or viewport_mouse.y < 0 or viewport_mouse.x > viewport_size.x or viewport_mouse.y > viewport_size.y:
		return Vector3.ZERO
	var from: Vector3 = camera_3d.project_ray_origin(viewport_mouse)
	var to: Vector3 = from + camera_3d.project_ray_normal(viewport_mouse) * 1000.0
	var plane := Plane(Vector3.UP, 0)
	var intersection: Variant = plane.intersects_ray(from, to - from)
	return Vector3(intersection) if intersection else Vector3.ZERO

func _position_to_lane(x_pos: float) -> int:
	var zone_width: float = 1.0
	if runway_board_renderer:
		var maybe_zone: Variant = runway_board_renderer.get("zone_width")
		if typeof(maybe_zone) in [TYPE_FLOAT, TYPE_INT] and maybe_zone > 0:
			zone_width = float(maybe_zone)
	for i in range(lane_positions.size()):
		if abs(x_pos - lane_positions[i]) < (zone_width / 2.0):
			return i
	return 0

func _position_to_time(z_pos: float) -> float:
	var note_speed := SettingsManager.note_speed if SettingsManager else 20.0
	return current_time - (z_pos / note_speed)
