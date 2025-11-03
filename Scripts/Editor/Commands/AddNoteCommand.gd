extends "res://Scripts/Commands/ICommand.gd"
class_name AddNoteCommand

# Command that adds a note to the chart data model
# Supports undo by storing the generated note ID

var instrument: String
var difficulty: String
var lane: int
var tick: int
var note_type: int  # From NoteType enum
var length: int  # 0 for regular notes, > 0 for sustains
var note_id: int = -1  # Generated ID from ChartDataModel
var chart_data: ChartDataModel

func _init(p_chart_data: ChartDataModel, p_instrument: String, p_difficulty: String, p_lane: int, p_tick: int, p_note_type: int = 0, p_length: int = 0):
	chart_data = p_chart_data
	instrument = p_instrument
	difficulty = p_difficulty
	lane = p_lane
	tick = p_tick
	note_type = p_note_type
	length = p_length
	# scheduled_time used for command ordering (not tied to audio time in editor)
	scheduled_time = float(tick)

func execute(_ctx: Dictionary) -> void:
	# Add note to chart data model
	note_id = chart_data.add_note(instrument, difficulty, lane, tick, note_type, length)
	# ChartDataModel emits note_added signal which visual manager will handle

func undo(_ctx: Dictionary) -> void:
	# Remove note from chart data model
	if note_id != -1:
		chart_data.remove_note(instrument, difficulty, note_id)
	# ChartDataModel emits note_removed signal which visual manager will handle
