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
@onready var bpm_spin: SpinBox = $VBox/BPMContainer/BPMSpin
@onready var detect_bpm_button: Button = $VBox/BPMContainer/DetectBPMButton
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
	detect_bpm_button.pressed.connect(_on_detect_bpm)
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
	bpm_spin.value = properties.get("bpm", 120.0)
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
		"bpm": bpm_spin.value,
		"audio_path": audio_path_edit.text
	}

func _on_browse_audio():
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_audio_file_selected(path: String):
	audio_path_edit.text = path
	# Automatically detect BPM when audio is selected
	await get_tree().process_frame
	_auto_detect_bpm()

func _auto_detect_bpm():
	"""Automatically detect BPM when audio file is selected."""
	var audio_path = audio_path_edit.text
	if audio_path.is_empty():
		return
	
	if not FileAccess.file_exists(audio_path):
		push_error("Audio file not found: " + audio_path)
		return
	
	print("Auto-detecting BPM from audio file...")
	
	# Show detection status in BPM field
	var original_bpm = bpm_spin.value
	bpm_spin.editable = false
	
	# Emit signal to show loading in parent
	if get_parent() and get_parent().has_method("_show_loading"):
		get_parent()._show_loading("Detecting BPM...", 0.3)
	
	# Run detection
	await get_tree().process_frame
	var BPMDetector = load("res://Scripts/Editor/Services/bpm_detector.gd")
	var detected_bpm = BPMDetector.detect_bpm_quick(audio_path)
	
	# Hide loading
	if get_parent() and get_parent().has_method("_hide_loading"):
		get_parent()._hide_loading()
	
	if detected_bpm > 0:
		bpm_spin.value = detected_bpm
		print("✓ BPM auto-detected: ", detected_bpm)
	else:
		push_warning("BPM detection failed, keeping current value: ", original_bpm)
	
	# Re-enable editing
	bpm_spin.editable = true

func _on_detect_bpm():
	"""Manual BPM detection (kept for backwards compatibility but hidden)."""
	_auto_detect_bpm()

func _on_confirmed():
	properties_saved.emit(get_properties())
