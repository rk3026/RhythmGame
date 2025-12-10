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
var update_note_callable: Callable = Callable()

var preview_note: Sprite3D = null
var current_tool: String = "Note"
var current_note_type: NoteType.Type = NoteType.Type.REGULAR
var snap_division: int = 16
var tempo_events: Array = []
var time_signatures: Array = []
var resolution: int = 192
var current_time: float = 0.0
var erase_threshold: float = 0.2

# Selection state
var selected_note_ids: Array = []
var _selection_dragging: bool = false
var _selection_start: Vector2 = Vector2.ZERO
var _selection_rect: ColorRect = null

# Sustain dragging state
var is_dragging_sustain: bool = false
var sustain_drag_note_id: int = 0
var sustain_drag_start_time: float = 0.0
var sustain_original_length: float = 0.0

func configure(params: Dictionary) -> void:
	runway_viewport = params.get("runway_viewport")
	camera_3d = params.get("camera")
	lane_positions = params.get("lanes", [])
	runway_board_renderer = params.get("runway_board_renderer")
	note_visual_manager = params.get("note_visual_manager")
	chart_document = params.get("chart_document")
	add_note_callable = params.get("add_note_callable", Callable())
	remove_note_callable = params.get("remove_note_callable", Callable())
	update_note_callable = params.get("update_note_callable", Callable())
	_setup_preview_note()
	_setup_selection_rect()
	if runway_viewport:
		runway_viewport.gui_input.connect(_on_runway_input)
		runway_viewport.mouse_entered.connect(_on_runway_mouse_entered)
		runway_viewport.mouse_exited.connect(_on_runway_mouse_exited)

func set_tool(tool_name: String) -> void:
	current_tool = _normalize_tool_name(tool_name)
	if current_tool != "Note" and preview_note:
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

func set_time_signatures(signatures: Array) -> void:
	time_signatures = signatures.duplicate(true)

func set_resolution(res: int) -> void:
	resolution = max(res, 1)

func set_current_time(time_value: float) -> void:
	current_time = time_value

func _normalize_tool_name(tool_name: String) -> String:
	if tool_name == "Cursor":
		return "Select"
	return tool_name

func _is_selection_tool() -> bool:
	return current_tool == "Select"

func snap_time_to_grid(time_value: float) -> float:
	# Convert time to tick using tempo events
	var tick: int = TempoCalculator.time_to_tick(time_value, tempo_events, resolution)
	# Snap tick to grid based on resolution, snap division, and time signatures
	var snapped_tick: int = TempoCalculator.snap_tick_to_grid(tick, snap_division, resolution, time_signatures)
	# Convert snapped tick back to time
	var snapped_time: float = TempoCalculator.tick_to_time(snapped_tick, tempo_events, resolution)
	return snapped_time

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

func _setup_selection_rect() -> void:
	if not runway_viewport:
		return
	_selection_rect = ColorRect.new()
	_selection_rect.color = Color(0.2, 0.8, 1.0, 0.2)
	_selection_rect.visible = false
	_selection_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_rect.size = Vector2.ZERO
	_selection_rect.z_index = 10
	runway_viewport.add_child(_selection_rect)

func _on_runway_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_tool == "Note":
					_place_note_at_mouse(event.position)
				elif current_tool == "Erase":
					_erase_note_at_mouse(event.position)
				elif _is_selection_tool():
					_start_selection(event.position, event.shift_pressed)
			else:
				# Released - end any sustain drag
				if is_dragging_sustain:
					_end_sustain_drag()
				if _selection_dragging:
					_end_selection(event.position, event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_start_sustain_drag(event.position)
			else:
				if is_dragging_sustain:
					_end_sustain_drag()
	elif event is InputEventMouseMotion:
		if is_dragging_sustain:
			_update_sustain_drag(event.position)
		elif current_tool == "Note":
			_update_preview_note(event.position)
		elif _is_selection_tool():
			_update_selection_drag(event.position)

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
	var raw_time: float = _position_to_time(world_pos.z)
	var time_value: float = snap_time_to_grid(raw_time)
	
	if chart_document and not chart_document.find_note_by_lane_and_time(lane, time_value, 0.01).is_empty():
		return
	# Calculate tick position for the note
	var tick: int = TempoCalculator.time_to_tick(time_value, tempo_events, resolution)
	var note_data: Dictionary = {
		"lane": lane,
		"time": time_value,
		"tick": tick,
		"note_type": current_note_type,
		"is_sustain": false,
		"sustain_length": 0.0,
		"sustain_length_ticks": 0
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
		_selected_after_removal(note_id)

func _clear_selection() -> void:
	selected_note_ids.clear()
	_sync_selection_visuals()

func _selected_after_removal(note_id: int) -> void:
	if selected_note_ids.has(note_id):
		selected_note_ids.erase(note_id)
		_sync_selection_visuals()

func _sync_selection_visuals() -> void:
	if note_visual_manager:
		note_visual_manager.set_selection(selected_note_ids)

func _start_selection(mouse_pos: Vector2, additive: bool) -> void:
	_selection_dragging = true
	_selection_start = mouse_pos
	if not additive:
		selected_note_ids.clear()
	_sync_selection_visuals()
	if _selection_rect:
		_selection_rect.visible = true
		_selection_rect.position = mouse_pos
		_selection_rect.size = Vector2.ZERO

func _update_selection_drag(mouse_pos: Vector2) -> void:
	if not _selection_dragging or not _selection_rect:
		return
	var rect_pos = Vector2(min(_selection_start.x, mouse_pos.x), min(_selection_start.y, mouse_pos.y))
	var rect_size = (mouse_pos - _selection_start).abs()
	_selection_rect.position = rect_pos
	_selection_rect.size = rect_size

func _end_selection(mouse_pos: Vector2, additive: bool) -> void:
	if not _selection_dragging:
		return
	_selection_dragging = false
	if _selection_rect:
		_selection_rect.visible = false
		_selection_rect.size = Vector2.ZERO

	var drag_distance = (_selection_start - mouse_pos).length()
	var did_drag = drag_distance > 6.0
	if did_drag:
		_select_in_rect(_selection_start, mouse_pos, additive)
	else:
		_select_single(mouse_pos, additive)

func _select_single(mouse_pos: Vector2, additive: bool) -> void:
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		if not additive:
			_clear_selection()
		return
	var lane: int = _position_to_lane(world_pos.x)
	var time_value: float = _position_to_time(world_pos.z)
	if not chart_document:
		return
	var note: Dictionary = chart_document.find_note_by_lane_and_time(lane, time_value, 0.2)
	if note.is_empty():
		if not additive:
			_clear_selection()
		return
	var note_id: int = note.get("id", 0)
	if note_id == 0:
		return
	if not additive:
		selected_note_ids.clear()
	elif selected_note_ids.has(note_id):
		selected_note_ids.erase(note_id)
		_sync_selection_visuals()
		return
	selected_note_ids.append(note_id)
	_sync_selection_visuals()

func _select_in_rect(start: Vector2, end: Vector2, additive: bool) -> void:
	if not chart_document or not note_visual_manager or not camera_3d:
		return
	var viewport: SubViewport = runway_viewport.get_node("SubViewport") if runway_viewport else null
	if not viewport:
		return
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_y = min(start.y, end.y)
	var max_y = max(start.y, end.y)
	if not additive:
		selected_note_ids.clear()
	for note_id in note_visual_manager.note_visuals.keys():
		var visual = note_visual_manager.note_visuals[note_id]
		if not visual:
			continue
		var world_pos: Vector3 = visual.global_transform.origin
		if not camera_3d.has_method("unproject_position"):
			continue
		var screen_pos: Vector2 = camera_3d.unproject_position(world_pos)
		if screen_pos.x >= min_x and screen_pos.x <= max_x and screen_pos.y >= min_y and screen_pos.y <= max_y:
			if not selected_note_ids.has(note_id):
				selected_note_ids.append(note_id)
	_sync_selection_visuals()

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

# Sustain editing functions
func _start_sustain_drag(mouse_pos: Vector2) -> void:
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		return
	
	var lane: int = _position_to_lane(world_pos.x)
	var time_value: float = _position_to_time(world_pos.z)
	
	# Find note at this position
	if not chart_document:
		return
	var note: Dictionary = chart_document.find_note_by_lane_and_time(lane, time_value, 0.2)
	if note.is_empty():
		return
	
	# Start dragging this note's sustain
	is_dragging_sustain = true
	sustain_drag_note_id = note.get("id", 0)
	sustain_drag_start_time = note.get("time", 0.0)
	sustain_original_length = note.get("sustain_length", 0.0)

func _update_sustain_drag(mouse_pos: Vector2) -> void:
	if not is_dragging_sustain or sustain_drag_note_id == 0:
		return
	
	var world_pos: Vector3 = _mouse_to_runway_position(mouse_pos)
	if world_pos == Vector3.ZERO:
		return
	
	var end_time: float = snap_time_to_grid(_position_to_time(world_pos.z))
	
	# Calculate new sustain length
	var new_length: float = max(0.0, end_time - sustain_drag_start_time)
	
	# Update the note's sustain length directly (visual feedback during drag)
	if chart_document:
		var changes: Dictionary = {
			"sustain_length": new_length,
			"is_sustain": new_length > 0.0
		}
		chart_document.update_note(sustain_drag_note_id, changes)

func _end_sustain_drag() -> void:
	if not is_dragging_sustain:
		return
	
	# Get the final sustain length
	var note: Dictionary = chart_document.get_note(sustain_drag_note_id) if chart_document else {}
	if not note.is_empty():
		var final_length: float = note.get("sustain_length", 0.0)
		
		# Only create command if length actually changed
		if abs(final_length - sustain_original_length) > 0.001:
			# Calculate sustain length in ticks
			var start_tick: int = TempoCalculator.time_to_tick(sustain_drag_start_time, tempo_events, resolution)
			var end_tick: int = TempoCalculator.time_to_tick(sustain_drag_start_time + final_length, tempo_events, resolution)
			var sustain_ticks: int = end_tick - start_tick
			
			# Execute through command for undo/redo support
			if update_note_callable.is_valid():
				var changes: Dictionary = {
					"sustain_length": final_length,
					"is_sustain": final_length > 0.0,
					"sustain_length_ticks": sustain_ticks
				}
				update_note_callable.call(sustain_drag_note_id, changes)
	
	is_dragging_sustain = false
	sustain_drag_note_id = 0
	sustain_drag_start_time = 0.0
	sustain_original_length = 0.0
