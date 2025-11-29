extends RefCounted
class_name EditorNoteVisualManager

const NoteScene = preload("res://Scenes/note.tscn")

var chart_document: ChartDocument = null
var runway_viewport: Node = null
var settings_panel: Node = null
var lanes: Array = []
var note_visuals: Dictionary = {}
var current_time: float = 0.0

func _init(doc: ChartDocument, viewport: Node, panel: Node) -> void:
	chart_document = doc
	runway_viewport = viewport
	settings_panel = panel
	_connect_document()

func set_lane_positions(lane_positions: Array) -> void:
	lanes = lane_positions.duplicate()

func set_current_time(time_value: float) -> void:
	current_time = time_value

func refresh_positions() -> void:
	for note_id in note_visuals.keys():
		var note_data = chart_document.get_note(note_id)
		if note_data.is_empty():
			continue
		var visual = note_visuals[note_id]
		if not visual:
			continue
		visual.position = _to_runway_position(note_data.time, note_data.lane)
		var time_diff = note_data.time - current_time
		visual.visible = time_diff > -1.0 and time_diff < 10.0

func to_runway_position(time_value: float, lane: int) -> Vector3:
	return _to_runway_position(time_value, lane)

func clear_all() -> void:
	for visual in note_visuals.values():
		if visual:
			visual.queue_free()
	note_visuals.clear()

func _connect_document() -> void:
	if not chart_document:
		return
	chart_document.note_added.connect(_on_note_added)
	chart_document.note_removed.connect(_on_note_removed)
	chart_document.note_changed.connect(_on_note_changed)
	chart_document.document_cleared.connect(_on_document_cleared)

func _on_note_added(note_id: int, note_data: Dictionary) -> void:
	_create_note_visual(note_id, note_data)
	_update_note_count()

func _on_note_removed(note_id: int) -> void:
	if not note_visuals.has(note_id):
		return
	var visual = note_visuals[note_id]
	if visual:
		visual.queue_free()
	note_visuals.erase(note_id)
	_update_note_count()

func _on_note_changed(note_id: int, note_data: Dictionary) -> void:
	if not note_visuals.has(note_id):
		return
	var visual = note_visuals[note_id]
	if not visual:
		return
	visual.fret = note_data.lane
	visual.note_type = note_data.note_type
	visual.is_sustain = note_data.is_sustain
	visual.sustain_length = note_data.sustain_length
	visual.position = _to_runway_position(note_data.time, note_data.lane)
	visual.update_visuals()

func _on_document_cleared() -> void:
	clear_all()
	_update_note_count(0)

func _create_note_visual(note_id: int, note_data: Dictionary) -> void:
	var note = NoteScene.instantiate()
	note.fret = note_data.lane
	note.note_type = note_data.note_type
	note.is_sustain = note_data.sustain_length > 0
	note.sustain_length = note_data.sustain_length
	note.movement_paused = true
	note.use_timeline_positioning = true
	note.position = _to_runway_position(note_data.time, note_data.lane)
	note.update_visuals()
	var viewport := runway_viewport.get_node("SubViewport") if runway_viewport else null
	if viewport:
		viewport.add_child(note)
	note_visuals[note_id] = note

func _update_note_count(forced_value: int = -1) -> void:
	if not settings_panel:
		return
	var count = forced_value if forced_value >= 0 else chart_document.get_note_count()
	if settings_panel.has_method("update_note_count"):
		settings_panel.update_note_count(count)

func _to_runway_position(time_value: float, lane: int) -> Vector3:
	var x = lanes[lane] if lane < lanes.size() else 0.0
	var y = 0.5
	var time_diff = time_value - current_time
	var note_speed = SettingsManager.note_speed if SettingsManager else 20.0
	var z = time_diff * -note_speed
	return Vector3(x, y, z)
