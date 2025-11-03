extends RefCounted
class_name EditorHistoryManager

# Manages undo/redo history for chart editor commands
# Uses a command stack approach instead of TimelineController

signal history_changed(can_undo: bool, can_redo: bool)

var command_history: Array = []  # Array of ICommand
var current_index: int = -1  # Points to the last executed command
var chart_data: ChartDataModel

func _init(p_chart_data: ChartDataModel):
	chart_data = p_chart_data

func execute_command(command: ICommand) -> void:
	"""Execute a new command and add it to history"""
	# If we're not at the end of history, remove all commands after current_index
	if current_index < command_history.size() - 1:
		command_history.resize(current_index + 1)
	
	# Execute the command
	var ctx = {"chart_data": chart_data}
	command.execute(ctx)
	
	# Add to history
	command_history.append(command)
	current_index += 1
	
	_emit_history_state()

func undo() -> bool:
	"""Undo the last executed command"""
	if not can_undo():
		return false
	
	var command = command_history[current_index]
	var ctx = {"chart_data": chart_data}
	command.undo(ctx)
	
	current_index -= 1
	_emit_history_state()
	return true

func redo() -> bool:
	"""Redo the next command in history"""
	if not can_redo():
		return false
	
	current_index += 1
	var command = command_history[current_index]
	var ctx = {"chart_data": chart_data}
	command.execute(ctx)
	
	_emit_history_state()
	return true

func can_undo() -> bool:
	return current_index >= 0

func can_redo() -> bool:
	return current_index < command_history.size() - 1

func clear_history() -> void:
	"""Clear all command history"""
	command_history.clear()
	current_index = -1
	_emit_history_state()

func get_undo_description() -> String:
	"""Get description of what will be undone"""
	if can_undo():
		var command = command_history[current_index]
		return command.get_class()
	return ""

func get_redo_description() -> String:
	"""Get description of what will be redone"""
	if can_redo():
		var command = command_history[current_index + 1]
		return command.get_class()
	return ""

func _emit_history_state() -> void:
	history_changed.emit(can_undo(), can_redo())
