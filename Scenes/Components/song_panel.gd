extends Button

class_name SongPanel

var song_info: Dictionary = {}

@onready var album_art: TextureRect = $Panel/MarginContainer/HBoxContainer/TextureRect
@onready var song_name_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SongName
@onready var artist_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Artist
@onready var difficulty_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Difficulty
@onready var stars_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Stars
@onready var clear_icon: TextureRect = $Panel/ClearIcon

func _ready() -> void:
	# Set pivot for carousel scaling
	pivot_offset = size / 2.0

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

func get_song_info() -> Dictionary:
	return song_info
