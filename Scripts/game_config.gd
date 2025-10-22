extends Node

enum HitGrade {
	PERFECT,
	GREAT,
	GOOD,
	MISS
}

var lane_colors: Array[Color] = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE, Color.PURPLE]
var spawn_interval: float = 2.0
var lane_keys: Array = [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]
var zone_height: float = 0.5
var line_color: Color = Color.BLACK
var note_speed: float = 20
var perfect_window: float = 0.025
var great_window: float = 0.05
var good_window: float = 0.1
