extends RefCounted
class_name EditorCommandStack

## Lightweight undo/redo stack for editor actions. Commands must implement
## execute() and undo() methods that return true on success.

signal stack_changed(can_undo: bool, can_redo: bool)

var _undo_stack: Array = []
var _redo_stack: Array = []

func execute(command) -> void:
	if not command:
		return
	if not command.execute():
		return
	_undo_stack.append(command)
	_redo_stack.clear()
	_emit_stack_changed()

func undo() -> void:
	if _undo_stack.is_empty():
		return
	var command = _undo_stack.pop_back()
	if command.undo():
		_redo_stack.append(command)
	else:
		# If undo failed, push it back so the user can retry or inspect state.
		_undo_stack.append(command)
	_emit_stack_changed()

func redo() -> void:
	if _redo_stack.is_empty():
		return
	var command = _redo_stack.pop_back()
	if command.execute():
		_undo_stack.append(command)
	else:
		# Execution failed; drop the command to avoid infinite loops.
		command = null
	_emit_stack_changed()

func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_emit_stack_changed()

func can_undo() -> bool:
	return not _undo_stack.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()

func _emit_stack_changed():
	emit_signal("stack_changed", can_undo(), can_redo())
