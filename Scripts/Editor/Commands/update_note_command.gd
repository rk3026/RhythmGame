extends RefCounted
class_name UpdateNoteCommand

var chart_document: ChartDocument
var note_id: int
var old_data: Dictionary
var new_data: Dictionary

func _init(p_document: ChartDocument, p_note_id: int, p_changes: Dictionary):
	chart_document = p_document
	note_id = p_note_id
	new_data = p_changes.duplicate(true)
	
	# Store old values for undo
	var current_note = chart_document.get_note(note_id)
	old_data = {}
	for key in p_changes.keys():
		if current_note.has(key):
			old_data[key] = current_note[key]

func execute() -> bool:
	if not chart_document:
		return false
	return chart_document.update_note(note_id, new_data)

func undo() -> bool:
	if not chart_document:
		return false
	return chart_document.update_note(note_id, old_data)
