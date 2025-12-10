extends RefCounted
class_name RemoveEventCommand

var chart_document: ChartDocument
var event_id: int
var event_data: Dictionary

func _init(doc: ChartDocument, id: int):
	chart_document = doc
	event_id = id
	# Capture event data before removal for undo
	event_data = chart_document.get_event(event_id).duplicate(true)

func execute():
	chart_document.remove_event(event_id)

func undo():
	chart_document.restore_event(event_id, event_data)

func redo():
	chart_document.remove_event(event_id)
