extends GdUnitTestSuite
class_name TestScoreManager

const ScoreManagerScript = preload("res://Scripts/ScoreManager.gd")

func test_add_hit_perfect():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	assert_int(score_manager.score).is_equal(10)
	assert_int(score_manager.combo).is_equal(1)

func test_add_miss():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_miss()
	assert_int(score_manager.combo).is_equal(0)
	assert_int(score_manager.grade_counts.miss).is_equal(1)

func test_add_hit_great():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.GREAT)
	assert_int(score_manager.score).is_equal(8)
	assert_int(score_manager.combo).is_equal(1)

func test_add_hit_good():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.GOOD)
	assert_int(score_manager.score).is_equal(5)
	assert_int(score_manager.combo).is_equal(1)

func test_combo_multiplier():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	assert_int(score_manager.score).is_equal(20)  # 10 + 10*2
	assert_int(score_manager.combo).is_equal(2)

func test_max_combo():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_miss()
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	assert_int(score_manager.max_combo).is_equal(3)
	assert_int(score_manager.combo).is_equal(1)

func test_note_type_multiplier_hopo():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT, NoteType.Type.HOPO)
	assert_int(score_manager.score).is_equal(20)  # 10 * 2

func test_note_type_multiplier_tap():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT, NoteType.Type.TAP)
	assert_int(score_manager.score).is_equal(20)  # 10 * 2

func test_add_sustain_score():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_sustain_score(0.5)
	assert_float(score_manager.score).is_greater(10.0)

func test_remove_hit():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	var prev_combo = score_manager.combo
	var score_delta = 10
	score_manager.remove_hit(SettingsManager.HitGrade.PERFECT, NoteType.Type.REGULAR, prev_combo, score_delta)
	assert_int(score_manager.score).is_equal(0)
	assert_int(score_manager.combo).is_equal(0)

func test_remove_miss():
	var score_manager = auto_free(ScoreManagerScript.new())
	score_manager.add_hit(SettingsManager.HitGrade.PERFECT)
	score_manager.add_miss()
	score_manager.remove_miss(1)
	assert_int(score_manager.combo).is_equal(1)
	assert_int(score_manager.grade_counts.miss).is_equal(0)