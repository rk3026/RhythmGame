extends RefCounted
class_name AddNoteCommand

var chart_document: ChartDocument
var note_data: Dictionary
var note_id: int = 0

func _init(p_document: ChartDocument, p_note_data: Dictionary):
	chart_document = p_document
	note_data = p_note_data.duplicate(true)

func execute() -> bool:
	if not chart_document:
		return false
	if note_id == 0:
		note_id = chart_document.add_note(note_data)
	else:
		chart_document.restore_note(note_id, note_data)
	return note_id != 0

func undo() -> bool:
	if not chart_document or note_id == 0:
		return false
	return chart_document.remove_note(note_id)
