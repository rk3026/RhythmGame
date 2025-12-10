extends RefCounted
class_name AddEventCommand

var chart_document: ChartDocument
var event_data: Dictionary
var event_id: int = -1

func _init(doc: ChartDocument, data: Dictionary):
	chart_document = doc
	event_data = data.duplicate(true)

func execute():
	event_id = chart_document.add_event(event_data)

func undo():
	if event_id > 0:
		chart_document.remove_event(event_id)

func redo():
	if event_id > 0:
		chart_document.restore_event(event_id, event_data)
