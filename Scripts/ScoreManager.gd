extends Node

signal combo_changed(combo)
signal score_changed(score)

var combo = 0
var score = 0
var max_combo = 0
var grade_counts := {"perfect":0, "great":0, "good":0, "bad":0, "miss":0}

func add_hit(grade: int, note_type: int = 0):
	combo += 1
	if combo > max_combo:
		max_combo = combo
	var base_score = 0
	if grade == GameConfig.HitGrade.PERFECT:
		base_score = 10
		grade_counts.perfect += 1
	elif grade == GameConfig.HitGrade.GREAT:
		base_score = 8
		grade_counts.great += 1
	elif grade == GameConfig.HitGrade.GOOD:
		base_score = 5
		grade_counts.good += 1
	elif grade == GameConfig.HitGrade.BAD:
		base_score = 3
		grade_counts.bad += 1
	var type_multiplier = get_type_multiplier(note_type)
	score += base_score * combo * type_multiplier
	emit_signal("combo_changed", combo)
	emit_signal("score_changed", score)

func get_type_multiplier(note_type: int) -> int:
	match note_type:
		0: return 1  # REGULAR
		1: return 2  # HOPO
		2: return 2  # TAP
		3: return 1  # OPEN
		_: return 1

func add_sustain_score(delta: float):
	var sustain_points = delta * combo
	score += sustain_points
	emit_signal("score_changed", score)

func add_miss():
	combo = 0
	grade_counts.miss += 1
	emit_signal("combo_changed", combo)

# ---------------- Reversible API for command pattern ----------------
func remove_hit(grade: int, _note_type: int, prev_combo: int, score_delta: int):
	# Roll back combo & score and decrement grade bucket
	combo = prev_combo
	score -= score_delta
	match grade:
		GameConfig.HitGrade.PERFECT:
			grade_counts.perfect = max(0, grade_counts.perfect - 1)
		GameConfig.HitGrade.GREAT:
			grade_counts.great = max(0, grade_counts.great - 1)
		GameConfig.HitGrade.GOOD:
			grade_counts.good = max(0, grade_counts.good - 1)
		GameConfig.HitGrade.BAD:
			grade_counts.bad = max(0, grade_counts.bad - 1)
	emit_signal("combo_changed", combo)
	emit_signal("score_changed", score)

func remove_miss(prev_combo: int):
	# Remove one miss and restore previous combo (does not grant score)
	grade_counts.miss = max(0, grade_counts.miss - 1)
	combo = prev_combo
	emit_signal("combo_changed", combo)
	emit_signal("score_changed", score)