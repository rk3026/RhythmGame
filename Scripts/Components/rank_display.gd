extends PanelContainer
## Displays the rank/grade (S, A, B, C, D) with styling and optional animations

@onready var rank_label: Label = $VBox/RankLabel
@onready var new_record_badge: Label = $VBox/NewRecordBadge

enum Rank { S, A, B, C, D, F }

var rank_colors = {
	Rank.S: Color.GOLD,
	Rank.A: Color(0.5, 1.0, 0.5),  # Light green
	Rank.B: Color(0.3, 0.8, 1.0),  # Light blue
	Rank.C: Color(1.0, 0.7, 0.3),  # Orange
	Rank.D: Color(1.0, 0.5, 0.5),  # Light red
	Rank.F: Color(0.7, 0.3, 0.3)   # Dark red
}

func _ready():
	new_record_badge.visible = false

func set_rank(rank: Rank, animate: bool = true):
	"""Set the rank and update styling."""
	var rank_text = Rank.keys()[rank]
	rank_label.text = "★★★ " + rank_text + " RANK ★★★"
	rank_label.modulate = rank_colors[rank]
	
	if animate:
		_play_rank_animation()

func show_new_record_badge():
	"""Display the NEW RECORD badge."""
	new_record_badge.visible = true
	new_record_badge.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(new_record_badge, "modulate:a", 1.0, 0.5)

func _play_rank_animation():
	"""Animate the rank reveal."""
	rank_label.scale = Vector2.ZERO
	rank_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(rank_label, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(rank_label, "modulate:a", 1.0, 0.4)

func calculate_rank_from_accuracy(accuracy: float) -> Rank:
	"""Calculate rank based on accuracy percentage."""
	if accuracy >= 95.0:
		return Rank.S
	elif accuracy >= 90.0:
		return Rank.A
	elif accuracy >= 80.0:
		return Rank.B
	elif accuracy >= 70.0:
		return Rank.C
	elif accuracy >= 60.0:
		return Rank.D
	else:
		return Rank.F
