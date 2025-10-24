extends Control

# profile_view.gd - Comprehensive profile display screen
# Shows detailed profile information, statistics, achievements, and level progress
# UI layout is defined in profile_view.tscn - this script only handles data loading and updates

# UI elements from scene
@onready var back_button: Button = %BackButton
@onready var edit_button: Button = %EditButton
@onready var profile_avatar: TextureRect = %ProfileAvatar
@onready var profile_name_label: Label = %ProfileName
@onready var profile_bio_label: Label = %ProfileBio
@onready var level_indicator_container: Control = %LevelIndicatorContainer
@onready var stats_container: GridContainer = %StatsContainer
@onready var achievements_grid: GridContainer = %AchievementsGrid
@onready var achievement_progress_label: Label = %AchievementProgress

# Level indicator component (created dynamically)
var level_indicator: LevelIndicator

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_pressed)
	edit_button.pressed.connect(_on_edit_pressed)
	
	# Create level indicator component
	level_indicator = LevelIndicator.new()
	level_indicator.show_xp_text = true
	level_indicator_container.add_child(level_indicator)
	
	# Connect to ProfileManager signals for live updates
	ProfileManager.profile_updated.connect(_on_profile_updated)
	ProfileManager.level_up.connect(_on_level_up)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# Load profile data
	_load_profile_data()

func _load_profile_data():
	"""Load and display current profile data."""
	if ProfileManager.current_profile.is_empty():
		push_warning("ProfileView: No profile loaded")
		return
	
	var profile = ProfileManager.current_profile
	
	# Load header data
	_update_header(profile)
	
	# Load statistics
	_update_stats(profile)
	
	# Load achievements
	_update_achievements()

func _update_header(profile: Dictionary):
	"""Update the header section with profile data."""
	# Avatar
	var avatar_path = profile.get("avatar", "res://Assets/Profiles/Avatars/default.svg")
	if ResourceLoader.exists(avatar_path):
		profile_avatar.texture = load(avatar_path)
	
	# Name
	var display_name = profile.get("display_name", profile.get("username", "Player"))
	profile_name_label.text = display_name
	
	# Bio
	var bio = profile.get("bio", "")
	if bio.is_empty():
		profile_bio_label.text = "No bio set. Click 'Edit Profile' to add one!"
		profile_bio_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		profile_bio_label.text = bio
		profile_bio_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# Level indicator
	var level = profile.get("level", 1)
	var xp = profile.get("xp", 0)
	var total_xp = profile.get("total_xp", 0)
	level_indicator.set_level_data(level, xp, total_xp)

func _update_stats(profile: Dictionary):
	"""Update the statistics grid."""
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()
	
	# Get stats from profile
	var stats = profile.get("stats", {})
	
	# Define stats to display (label, stat_key, color)
	var stat_definitions = [
		["Songs Completed", "songs_completed", Color(0.4, 0.8, 1.0)],
		["Total Notes Hit", "total_notes_hit", Color(0.6, 1.0, 0.6)],
		["Perfect Hits", "perfect_count", Color(1.0, 0.84, 0.0)],
		["Great Hits", "great_count", Color(0.8, 0.8, 1.0)],
		["Good Hits", "good_count", Color(0.6, 0.8, 1.0)],
		["Missed Notes", "miss_count", Color(1.0, 0.5, 0.5)],
		["Max Combo", "max_combo", Color(1.0, 0.6, 0.2)],
		["Total Playtime", "total_playtime", Color(0.7, 0.7, 1.0)],
		["Current Streak", "play_streak", Color(1.0, 0.8, 0.2)],
		["Average Accuracy", "average_accuracy", Color(0.5, 1.0, 0.8)],
		["Total Score", "total_score", Color(1.0, 0.7, 1.0)],
		["Total XP Earned", "total_xp", Color(1.0, 0.84, 0.0)]
	]
	
	for stat_def in stat_definitions:
		var stat_display = StatDisplay.new()
		var stat_value = stats.get(stat_def[1], 0)
		
		# Format special stats
		if stat_def[1] == "total_playtime":
			stat_value = _format_playtime(stat_value)
		elif stat_def[1] == "average_accuracy":
			stat_value = "%.1f%%" % stat_value
		
		stat_display.set_stat(stat_def[0], str(stat_value), stat_def[2])
		stats_container.add_child(stat_display)

func _update_achievements():
	"""Update the achievements grid."""
	# Clear existing achievements
	for child in achievements_grid.get_children():
		child.queue_free()
	
	# Get all achievements
	var all_achievements = AchievementManager.get_all_achievements()
	var unlocked_count = 0
	
	for achievement_data in all_achievements:
		# achievement_data already contains progress_data from get_all_achievements()
		var progress_data = achievement_data.get("progress_data", {})
		
		var badge = AchievementBadge.new()
		badge.set_achievement_data(achievement_data, progress_data)
		achievements_grid.add_child(badge)
		
		if progress_data.get("unlocked", false):
			unlocked_count += 1
	
	# Update progress label
	achievement_progress_label.text = "%d / %d Unlocked (%.1f%%)" % [
		unlocked_count,
		all_achievements.size(),
		AchievementManager.get_completion_percentage()
	]

func _format_playtime(seconds: int) -> String:
	"""Format playtime in seconds to readable format."""
	var hours = int(float(seconds) / 3600.0)
	var minutes = int(float(seconds % 3600) / 60.0)
	
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	else:
		return "%dm" % minutes

func _on_back_pressed():
	"""Return to previous screen."""
	SceneSwitcher.pop_scene()

func _on_edit_pressed():
	"""Open profile editor."""
	SceneSwitcher.push_scene("res://Scenes/profile_editor.tscn")

func _on_profile_updated(_stat_name: String, _new_value: Variant):
	"""Handle profile updates."""
	_load_profile_data()

func _on_level_up(_old_level: int, new_level: int):
	"""Handle level up event with visual feedback."""
	print("Level up! New level: ", new_level)
	_load_profile_data()
	
	# Could add animation here
	if level_indicator:
		level_indicator.pulse()

func _on_achievement_unlocked(achievement_id: String):
	"""Handle achievement unlock with visual feedback."""
	print("Achievement unlocked: ", achievement_id)
	_update_achievements()
