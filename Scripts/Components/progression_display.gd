extends PanelContainer
## Displays XP earned, level ups, and achievements unlocked

@onready var xp_label: Label = $MarginContainer/VBox/XPLabel
@onready var level_up_container: VBoxContainer = $MarginContainer/VBox/LevelUpContainer
@onready var level_up_label: Label = $MarginContainer/VBox/LevelUpContainer/LevelUpLabel
@onready var achievements_container: VBoxContainer = $MarginContainer/VBox/AchievementsContainer
@onready var achievements_header: Label = $MarginContainer/VBox/AchievementsContainer/HeaderLabel
@onready var achievements_list: VBoxContainer = $MarginContainer/VBox/AchievementsContainer/AchievementsList

func _ready():
	# Hide sections by default
	xp_label.visible = false
	level_up_container.visible = false
	achievements_container.visible = false

func set_xp_earned(xp: int, animate: bool = true):
	"""Display XP earned."""
	if xp <= 0:
		xp_label.visible = false
		return
	
	xp_label.visible = true
	xp_label.text = "+ %d XP" % xp
	
	if animate:
		xp_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(xp_label, "modulate:a", 1.0, 0.5)

func set_level_up(old_level: int, new_level: int, animate: bool = true):
	"""Display level up notification."""
	if old_level >= new_level:
		level_up_container.visible = false
		return
	
	level_up_container.visible = true
	level_up_label.text = "🎉 LEVEL UP! %d → %d 🎉" % [old_level, new_level]
	
	if animate:
		_animate_level_up()

func set_achievements(achievements: Array):
	"""Display unlocked achievements."""
	if achievements.is_empty():
		achievements_container.visible = false
		return
	
	achievements_container.visible = true
	
	# Clear previous achievement labels
	for child in achievements_list.get_children():
		child.queue_free()
	
	# Add each achievement
	for achievement in achievements:
		var ach_label = Label.new()
		ach_label.text = "  ★ " + achievement.name
		ach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ach_label.add_theme_font_size_override("font_size", 18)
		ach_label.modulate = Color(0.8, 0.8, 1.0)  # Light blue
		achievements_list.add_child(ach_label)
	
	# Animate fade in
	achievements_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(achievements_container, "modulate:a", 1.0, 0.6).set_delay(0.5)

func _animate_level_up():
	"""Pulsing animation for level up notification."""
	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(level_up_label, "scale", Vector2(1.1, 1.1), 0.4)
	tween.tween_property(level_up_label, "modulate", Color(1.0, 1.0, 0.5), 0.4)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(level_up_label, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_property(level_up_label, "modulate", Color(1.0, 0.84, 0.0), 0.4)

func hide_all():
	"""Hide all progression elements (for when no progression data available)."""
	xp_label.visible = false
	level_up_container.visible = false
	achievements_container.visible = false
