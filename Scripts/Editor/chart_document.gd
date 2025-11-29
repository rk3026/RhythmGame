extends Resource
class_name ChartDocument

## Centralized state container for the chart editor. Tracks notes, tempo markers,
## sections, and metadata while emitting signals for interested systems
## (visuals, inspectors, undo/redo, etc.).

signal note_added(note_id: int, note_data: Dictionary)
signal note_removed(note_id: int)
signal note_changed(note_id: int, note_data: Dictionary)
signal document_cleared()

@export var notes: Array = []
var _notes_by_id: Dictionary = {}
var _next_note_id: int = 1

func clear():
	notes.clear()
	_notes_by_id.clear()
	_next_note_id = 1
	emit_signal("document_cleared")

func get_note_count() -> int:
	return notes.size()

func get_notes() -> Array:
	# Return a defensive copy so callers cannot mutate internal state silently.
	return notes.duplicate(true)

func add_note(note_data: Dictionary) -> int:
	var sanitized = _sanitize_note(note_data)
	sanitized["id"] = _next_note_id
	_next_note_id += 1
	notes.append(sanitized)
	_notes_by_id[sanitized["id"]] = sanitized
	notes.sort_custom(func(a, b): return a.time < b.time)
	emit_signal("note_added", sanitized["id"], sanitized.duplicate(true))
	return sanitized["id"]

func remove_note(note_id: int) -> bool:
	if not _notes_by_id.has(note_id):
		return false
	var note_ref = _notes_by_id[note_id]
	notes.erase(note_ref)
	_notes_by_id.erase(note_id)
	emit_signal("note_removed", note_id)
	return true

func restore_note(note_id: int, note_data: Dictionary) -> int:
	if note_id <= 0:
		return 0
	var sanitized = _sanitize_note(note_data)
	sanitized["id"] = note_id
	if _notes_by_id.has(note_id):
		var existing_ref = _notes_by_id[note_id]
		notes.erase(existing_ref)
	_notes_by_id[note_id] = sanitized
	notes.append(sanitized)
	notes.sort_custom(func(a, b): return a.time < b.time)
	_next_note_id = max(_next_note_id, note_id + 1)
	emit_signal("note_added", note_id, sanitized.duplicate(true))
	return note_id

func update_note(note_id: int, changes: Dictionary) -> bool:
	if not _notes_by_id.has(note_id):
		return false
	var note_ref = _notes_by_id[note_id]
	for key in changes.keys():
		note_ref[key] = changes[key]
	notes.sort_custom(func(a, b): return a.time < b.time)
	emit_signal("note_changed", note_id, note_ref.duplicate(true))
	return true

func get_note(note_id: int) -> Dictionary:
	if not _notes_by_id.has(note_id):
		return {}
	return _notes_by_id[note_id]

func find_note_by_lane_and_time(lane: int, time: float, tolerance: float = 0.05) -> Dictionary:
	for note in notes:
		if note.lane == lane and abs(note.time - time) <= tolerance:
			return note
	return {}

func import_notes(note_array: Array):
	clear()
	for note_dict in note_array:
		add_note(note_dict)

func _sanitize_note(source: Dictionary) -> Dictionary:
	var sanitized := {
		"lane": int(source.get("lane", 0)),
		"time": float(source.get("time", 0.0)),
		"note_type": source.get("note_type", NoteType.Type.REGULAR),
		"is_sustain": bool(source.get("is_sustain", false)),
		"sustain_length": float(source.get("sustain_length", 0.0)),
		"note_flags": source.get("note_flags", {}),
		"metadata": source.get("metadata", {}),
		"id": int(source.get("id", 0))
	}
	return sanitized
