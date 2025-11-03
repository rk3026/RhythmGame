extends "res://Scripts/Commands/ICommand.gd"
class_name ModifyNoteTypeCommand

# Command that modifies a note's type
# Supports undo by storing previous type

var instrument: String
var difficulty: String
var note_id: int
var chart_data: ChartDataModel

var old_type: int
var new_type: int

func _init(p_chart_data: ChartDataModel, p_instrument: String, p_difficulty: String, p_note_id: int, p_new_type: int):
	chart_data = p_chart_data
	instrument = p_instrument
	difficulty = p_difficulty
	note_id = p_note_id
	new_type = p_new_type
	
	# Store old type for undo
	var note = chart_data.get_note(instrument, difficulty, note_id)
	if note:
		old_type = note.note_type
		scheduled_time = float(note.tick)

func execute(_ctx: Dictionary) -> void:
	# Modify note type in chart data model
	chart_data.modify_note(instrument, difficulty, note_id, -1, -1, new_type)
	# ChartDataModel emits note_modified signal which visual manager will handle

func undo(_ctx: Dictionary) -> void:
	# Restore old type
	chart_data.modify_note(instrument, difficulty, note_id, -1, -1, old_type)
	# ChartDataModel emits note_modified signal which visual manager will handle
