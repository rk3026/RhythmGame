extends ICommand
class_name HitNoteCommand

var grade: int
var note_type: int
var prev_combo: int
var score_delta: int = 0

func _init(p_time: float, p_grade: int, p_note_type: int, p_prev_combo: int):
	scheduled_time = p_time
	grade = p_grade
	note_type = p_note_type
	prev_combo = p_prev_combo

func execute(ctx: Dictionary) -> void:
	var score_manager = ctx.get("score_manager")
	if score_manager == null:
		return
	# Recompute delta the same way add_hit does to store for undo.
	var before_score = score_manager.score
	# Temporarily call original add_hit (cannot override internal formula easily)
	score_manager.add_hit(grade, note_type)
	score_delta = score_manager.score - before_score

func undo(ctx: Dictionary) -> void:
	var score_manager = ctx.get("score_manager")
	if score_manager == null:
		return
	score_manager.remove_hit(grade, note_type, prev_combo, score_delta)
