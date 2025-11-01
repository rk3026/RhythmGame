extends Button

class_name SongPanel

var song_info: Dictionary = {}
var hover_tween: Tween = null

@onready var panel: Panel = $Panel
@onready var album_art: TextureRect = $Panel/MarginContainer/HBoxContainer/AspectRatioContainer/TextureRect
@onready var song_name_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SongName
@onready var artist_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Artist
@onready var difficulty_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Difficulty
@onready var stars_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Stars
@onready var clear_icon: TextureRect = $Panel/ClearIcon
@onready var clear_text: Label = $Panel/ClearText
@onready var score_label: Label = $Panel/MarginContainer/HBoxContainer/ScoreLabel
@onready var percent_label: Label = $Panel/MarginContainer/HBoxContainer/PercentLabel

func _ready() -> void:
	# Set pivot for scaling animations
	pivot_offset = size / 2.0
	
	# Connect hover signals for animations
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_animate_hover(true)

func _on_mouse_exited() -> void:
	_animate_hover(false)

func _animate_hover(hover: bool) -> void:
	# Cancel any existing tween
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if hover:
		# Scale up and brighten when hovering
		hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)
		hover_tween.tween_method(_update_panel_brightness, 0.0, 1.0, 0.2)
	else:
		# Scale back and dim when not hovering
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		hover_tween.tween_method(_update_panel_brightness, 1.0, 0.0, 0.2)

func _update_panel_brightness(value: float) -> void:
	if not panel:
		return
	
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var new_style = style.duplicate()
		var base_color = Color(0.043039158, 0.04303915, 0.04303915, 0.8)
		var bright_color = Color(0.1, 0.1, 0.1, 0.9)
		new_style.bg_color = base_color.lerp(bright_color, value)
		panel.add_theme_stylebox_override("panel", new_style)

func set_song_data(data: Dictionary) -> void:
	song_info = data
	
	# Set song name
	if song_name_label and data.has("title"):
		song_name_label.clear()
		song_name_label.append_text(data.title)
	
	# Set artist
	if artist_label and data.has("artist"):
		artist_label.clear()
		artist_label.append_text(data.artist)
	
	# Set album art
	if album_art and data.has("image_path") and data.image_path:
		if FileAccess.file_exists(data.image_path):
			var image = Image.load_from_file(data.image_path)
			if image:
				var texture = ImageTexture.create_from_image(image)
				album_art.texture = texture
	
	# Set difficulty and stars (you can customize this based on your needs)
	if difficulty_label:
		difficulty_label.text = data.get("difficulty", "")
	
	if stars_label:
		var star_rating = data.get("star_rating", 0)
		if star_rating > 0:
			stars_label.text = "★".repeat(star_rating)
		else:
			stars_label.text = ""
	
	# Set clear icon visibility (customize based on completion status)
	if clear_icon:
		clear_icon.visible = data.get("completed", false)

	# Set clear text (e.g., Full Combo, Clear, Failed)
	if clear_text:
		var clear_str = data.get("clear_text", "")
		clear_text.text = clear_str

	# Set score / percent if provided (populated by song_select)
	if score_label:
		score_label.text = data.get("best_score_text", "")

	if percent_label:
		percent_label.text = data.get("best_accuracy_text", "")

func get_song_info() -> Dictionary:
	return song_info
