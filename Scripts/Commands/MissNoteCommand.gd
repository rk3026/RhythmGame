extends ICommand
class_name MissNoteCommand

var prev_combo: int

func _init(p_time: float, p_prev_combo: int):
	scheduled_time = p_time
	prev_combo = p_prev_combo

func execute(ctx: Dictionary) -> void:
	var score_manager = ctx.get("score_manager")
	if score_manager == null:
		return
	score_manager.add_miss()

func undo(ctx: Dictionary) -> void:
	var score_manager = ctx.get("score_manager")
	if score_manager == null:
		return
	score_manager.remove_miss(prev_combo)
