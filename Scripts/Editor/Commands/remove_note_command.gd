extends RefCounted
class_name RemoveNoteCommand

var chart_document: ChartDocument
var note_id: int
var cached_note: Dictionary = {}

func _init(p_document: ChartDocument, p_note_id: int):
	chart_document = p_document
	note_id = p_note_id

func execute() -> bool:
	if not chart_document or note_id == 0:
		return false
	var note_ref = chart_document.get_note(note_id)
	if note_ref.is_empty():
		return false
	cached_note = note_ref.duplicate(true)
	return chart_document.remove_note(note_id)

func undo() -> bool:
	if not chart_document or cached_note.is_empty() or note_id == 0:
		return false
	chart_document.restore_note(note_id, cached_note)
	return true
