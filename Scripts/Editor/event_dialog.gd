extends AcceptDialog

signal event_saved(event_data: Dictionary)

@onready var type_option: OptionButton = $VBoxContainer/TypeOption
@onready var name_edit: LineEdit = $VBoxContainer/NameEdit
@onready var time_edit: SpinBox = $VBoxContainer/TimeEdit

var editing_event_id: int = -1
var tempo_events: Array = []
var resolution: int = 192

func _ready():
	# Add event type options
	type_option.add_item("Section", 0)
	type_option.add_item("Event", 1)

func configure(events: Array, res: int):
	tempo_events = events
	resolution = res

func show_for_new_event(time: float):
	editing_event_id = -1
	title = "Add Event"
	time_edit.value = time
	name_edit.text = ""
	type_option.selected = 0  # Default to Section
	popup_centered()
	name_edit.grab_focus()

func show_for_edit_event(event_data: Dictionary):
	editing_event_id = event_data.get("id", -1)
	title = "Edit Event"
	time_edit.value = event_data.get("time", 0.0)
	name_edit.text = event_data.get("text", "")
	
	# Set type
	var event_type = event_data.get("type", "section")
	type_option.selected = 0 if event_type == "section" else 1
	
	popup_centered()
	name_edit.grab_focus()

func _on_confirmed():
	var event_type = "section" if type_option.selected == 0 else "event"
	var time_value = time_edit.value
	var tick_value = TempoCalculator.time_to_tick(time_value, tempo_events, resolution)
	
	var event_data = {
		"time": time_value,
		"tick": tick_value,
		"text": name_edit.text,
		"type": event_type
	}
	
	if editing_event_id >= 0:
		event_data["id"] = editing_event_id
	
	event_saved.emit(event_data)
