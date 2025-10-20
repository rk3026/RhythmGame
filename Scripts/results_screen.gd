extends Control

@export var score: int = 0
@export var max_combo: int = 0
@export var total_notes: int = 0
@export var hits_per_grade := {"perfect":0, "great":0, "good":0, "bad":0, "miss":0}
@export var song_title: String = ""
@export var difficulty: String = ""

func _ready():
	var readable_difficulty = difficulty.replace("Single", " Single").replace("Double", " Double")
	$VBox/TitleLabel.text = song_title + " (" + readable_difficulty + ")"
	$VBox/StatsContainer/StatsVBox/ScoreLabel.text = "Score: " + str(int(score))
	$VBox/StatsContainer/StatsVBox/ComboLabel.text = "Max Combo: " + str(max_combo)
	var acc = calculate_accuracy()
	$VBox/StatsContainer/StatsVBox/AccuracyLabel.text = "Accuracy: " + str(acc) + "%"
	$VBox/StatsContainer/StatsVBox/BreakdownLabel.text = breakdown_text()
	$VBox/Buttons/ButtonsHBox/RetryButton.connect("pressed", Callable(self, "_on_retry"))
	$VBox/Buttons/ButtonsHBox/MenuButton.connect("pressed", Callable(self, "_on_menu"))

func calculate_accuracy() -> float:
	var hit_total = hits_per_grade.perfect + hits_per_grade.great + hits_per_grade.good + hits_per_grade.bad
	if total_notes == 0:
		return 0.0
	return round((float(hit_total) / float(total_notes)) * 1000.0) / 10.0

func breakdown_text() -> String:
	return "Perfect: %d\nGreat: %d\nGood: %d\nBad: %d\nMiss: %d" % [
		hits_per_grade.perfect,
		hits_per_grade.great,
		hits_per_grade.good,
		hits_per_grade.bad,
		hits_per_grade.miss
	]

func _on_retry():
	# Reload gameplay with same chart/difficulty
	var gameplay = load("res://Scenes/gameplay.tscn").instantiate()
	gameplay.chart_path = ProjectSettings.get_setting("application/run/last_chart_path", "")
	gameplay.instrument = ProjectSettings.get_setting("application/run/last_instrument", "")
	SceneSwitcher.pop_scene()  # Remove results
	SceneSwitcher.replace_scene_instance(gameplay)  # Replace old gameplay

func _on_menu():
	SceneSwitcher.pop_scene()  # Remove results
	SceneSwitcher.pop_scene()  # Remove gameplay
	# Now song_select is shown
