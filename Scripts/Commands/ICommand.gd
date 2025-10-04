extends RefCounted
class_name ICommand

var scheduled_time: float = 0.0

func execute(_ctx: Dictionary) -> void:
	pass

func undo(_ctx: Dictionary) -> void:
	pass
