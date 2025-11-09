extends AcceptDialog

# Signals
signal properties_saved(properties: Dictionary)

# UI References
@onready var song_name_edit: LineEdit = $VBox/SongNameContainer/SongNameEdit
@onready var artist_edit: LineEdit = $VBox/ArtistContainer/ArtistEdit
@onready var charter_edit: LineEdit = $VBox/CharterContainer/CharterEdit
@onready var album_edit: LineEdit = $VBox/AlbumContainer/AlbumEdit
@onready var year_edit: LineEdit = $VBox/YearContainer/YearEdit
@onready var genre_edit: LineEdit = $VBox/GenreContainer/GenreEdit
@onready var offset_spin: SpinBox = $VBox/OffsetContainer/OffsetSpin
@onready var audio_path_edit: LineEdit = $VBox/AudioContainer/AudioPathEdit
@onready var browse_button: Button = $VBox/AudioContainer/BrowseButton
@onready var file_dialog: FileDialog = $FileDialog

# Current properties
var current_properties: Dictionary = {}

func _ready():
	_connect_signals()
	confirmed.connect(_on_confirmed)
	
func _connect_signals():
	browse_button.pressed.connect(_on_browse_audio)
	file_dialog.file_selected.connect(_on_audio_file_selected)

func set_properties(properties: Dictionary):
	current_properties = properties
	song_name_edit.text = properties.get("name", "")
	artist_edit.text = properties.get("artist", "")
	charter_edit.text = properties.get("charter", "")
	album_edit.text = properties.get("album", "")
	year_edit.text = properties.get("year", "")
	genre_edit.text = properties.get("genre", "")
	offset_spin.value = properties.get("offset", 0.0)
	audio_path_edit.text = properties.get("audio_path", "")

func get_properties() -> Dictionary:
	return {
		"name": song_name_edit.text,
		"artist": artist_edit.text,
		"charter": charter_edit.text,
		"album": album_edit.text,
		"year": year_edit.text,
		"genre": genre_edit.text,
		"offset": offset_spin.value,
		"audio_path": audio_path_edit.text
	}

func _on_browse_audio():
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_audio_file_selected(path: String):
	audio_path_edit.text = path

func _on_confirmed():
	properties_saved.emit(get_properties())
