extends RefCounted
class_name UpdateEventCommand

var chart_document: ChartDocument
var event_id: int
var changes: Dictionary
var old_values: Dictionary

func _init(doc: ChartDocument, id: int, change_dict: Dictionary):
	chart_document = doc
	event_id = id
	changes = change_dict.duplicate(true)
	
	# Capture old values for undo
	var event = chart_document.get_event(event_id)
	old_values = {}
	for key in changes.keys():
		if event.has(key):
			old_values[key] = event[key]

func execute():
	chart_document.update_event(event_id, changes)

func undo():
	chart_document.update_event(event_id, old_values)

func redo():
	chart_document.update_event(event_id, changes)
