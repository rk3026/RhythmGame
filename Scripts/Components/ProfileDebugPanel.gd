extends Control

# ProfileDebugPanel.gd - Optional debug overlay for testing profile system
# Add this to any scene to monitor profile state in real-time

@onready var info_label: Label = $Panel/VBoxContainer/InfoLabel
@onready var toggle_button: Button = $ToggleButton

var panel_visible: bool = true
var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5  # Update every 0.5 seconds

func _ready():
	toggle_button.pressed.connect(_on_toggle_pressed)
	_update_info()

func _process(delta):
	if not panel_visible:
		return
	
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		_update_info()

func _update_info():
	var info = ""
	
	# Profile Manager Info
	info += "=== PROFILE MANAGER ===\n"
	if ProfileManager.current_profile_id:
		info += "Profile ID: " + ProfileManager.current_profile_id + "\n"
		info += "Username: " + ProfileManager.current_profile.get("username", "N/A") + "\n"
		info += "Display Name: " + ProfileManager.current_profile.get("display_name", "N/A") + "\n"
		info += "Level: " + str(ProfileManager.current_profile.get("level", 0)) + "\n"
		info += "XP: " + str(ProfileManager.current_profile.get("xp", 0)) + "\n"
		info += "Songs Played: " + str(ProfileManager.current_profile.get("songs_played", 0)) + "\n"
	else:
		info += "No profile loaded\n"
	
	info += "\n"
	
	# Score History Manager Info
	info += "=== SCORE HISTORY ===\n"
	info += "Profile ID: " + ScoreHistoryManager.current_profile_id + "\n"
	info += "Score Path: " + ScoreHistoryManager.history_path + "\n"
	info += "File Exists: " + str(FileAccess.file_exists(ScoreHistoryManager.history_path)) + "\n"
	info += "Scores Loaded: " + str(ScoreHistoryManager.score_data.size()) + " songs\n"
	
	info += "\n"
	
	# Achievement Manager Info
	info += "=== ACHIEVEMENTS ===\n"
	var unlocked_count = 0
	for ach in AchievementManager.achievement_progress.values():
		if ach.unlocked:
			unlocked_count += 1
	info += "Total Achievements: " + str(AchievementManager.achievement_definitions.size()) + "\n"
	info += "Unlocked: " + str(unlocked_count) + "\n"
	info += "Progress Data: " + str(AchievementManager.achievement_progress.size()) + " tracked\n"
	
	info += "\n"
	
	# Scene Stack Info
	info += "=== SCENE STACK ===\n"
	info += "Stack Size: " + str(SceneSwitcher.scene_stack.size()) + "\n"
	if SceneSwitcher.scene_stack.size() > 0:
		var current_scene = SceneSwitcher.scene_stack.back()
		info += "Current Scene: " + current_scene.name + "\n"
	
	info += "\n"
	
	# Profile Match Check
	info += "=== VALIDATION ===\n"
	var profile_match = ProfileManager.current_profile_id == ScoreHistoryManager.current_profile_id
	info += "Profile IDs Match: " + ("✅ YES" if profile_match else "❌ NO (BUG!)") + "\n"
	
	if ProfileManager.current_profile_id:
		var profile_dir = "user://profiles/" + ProfileManager.current_profile_id + "/"
		info += "\nProfile Files:\n"
		info += "  profile.cfg: " + ("✅" if FileAccess.file_exists(profile_dir + "profile.cfg") else "❌") + "\n"
		info += "  scores.cfg: " + ("✅" if FileAccess.file_exists(profile_dir + "scores.cfg") else "⚠️ not created yet") + "\n"
		info += "  achievements.cfg: " + ("✅" if FileAccess.file_exists(profile_dir + "achievements.cfg") else "⚠️ not created yet") + "\n"
	
	info_label.text = info

func _on_toggle_pressed():
	panel_visible = !panel_visible
	$Panel.visible = panel_visible
	toggle_button.text = "Show Debug" if not panel_visible else "Hide Debug"

func _input(event):
	# Press F12 to toggle debug panel
	if event.is_action_pressed("ui_home"):  # You can change this to any key
		_on_toggle_pressed()
