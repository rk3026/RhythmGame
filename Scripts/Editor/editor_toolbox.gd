extends PanelContainer

# Signals for tool selection
signal tool_selected(tool_name: String)
signal note_type_selected(note_type: String)

# Tool buttons
@onready var cursor_button: Button = $VBox/CursorButton
@onready var note_button: Button = $VBox/NoteButton
@onready var erase_button: Button = $VBox/EraseButton
@onready var bpm_button: Button = $VBox/BPMButton
@onready var section_button: Button = $VBox/SectionButton
@onready var event_button: Button = $VBox/EventButton

# Note type buttons
@onready var regular_button: Button = $VBox/RegularButton
@onready var hopo_button: Button = $VBox/HOPOButton
@onready var tap_button: Button = $VBox/TapButton
@onready var open_button: Button = $VBox/OpenButton
@onready var starpower_button: Button = $VBox/StarPowerButton

# Current selections
var current_tool: String = "Note"
var current_note_type: String = "Regular"

func _ready():
	_connect_signals()

func _connect_signals():
	cursor_button.pressed.connect(_on_tool_selected.bind("Cursor"))
	note_button.pressed.connect(_on_tool_selected.bind("Note"))
	erase_button.pressed.connect(_on_tool_selected.bind("Erase"))
	bpm_button.pressed.connect(_on_tool_selected.bind("BPM"))
	section_button.pressed.connect(_on_tool_selected.bind("Section"))
	event_button.pressed.connect(_on_tool_selected.bind("Event"))
	
	regular_button.pressed.connect(_on_note_type_selected.bind("Regular"))
	hopo_button.pressed.connect(_on_note_type_selected.bind("HOPO"))
	tap_button.pressed.connect(_on_note_type_selected.bind("Tap"))
	open_button.pressed.connect(_on_note_type_selected.bind("Open"))
	starpower_button.pressed.connect(_on_note_type_selected.bind("StarPower"))

func _on_tool_selected(tool_name: String):
	current_tool = tool_name
	tool_selected.emit(tool_name)
	print("Tool selected: ", tool_name)

func _on_note_type_selected(note_type: String):
	current_note_type = note_type
	note_type_selected.emit(note_type)
	print("Note type selected: ", note_type)

func get_current_tool() -> String:
	return current_tool

func get_current_note_type() -> String:
	return current_note_type
