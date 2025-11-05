extends TabContainer
class_name EditorSidePanel
## Editor Side Panel Component
## Manages metadata, difficulty settings, and property editing

signal metadata_changed(metadata: Dictionary)
signal difficulty_changed(instrument: String, difficulty: String, enabled: bool)
signal property_changed(property_name: String, value: Variant)
signal audio_file_requested()

# Metadata tab controls
@onready var title_edit: LineEdit = $Metadata/MetadataGrid/TitleEdit
@onready var artist_edit: LineEdit = $Metadata/MetadataGrid/ArtistEdit
@onready var album_edit: LineEdit = $Metadata/MetadataGrid/AlbumEdit
@onready var charter_edit: LineEdit = $Metadata/MetadataGrid/CharterEdit
@onready var year_edit: SpinBox = $Metadata/MetadataGrid/YearEdit
@onready var audio_file_edit: LineEdit = $Metadata/AudioFileGroup/AudioFileEdit
@onready var audio_browse_button: Button = $Metadata/AudioFileGroup/AudioBrowseButton

# Difficulty tab controls
@onready var guitar_easy_check: CheckBox = $Difficulty/InstrumentGrid/GuitarEasyCheck
@onready var guitar_medium_check: CheckBox = $Difficulty/InstrumentGrid/GuitarMediumCheck
@onready var guitar_hard_check: CheckBox = $Difficulty/InstrumentGrid/GuitarHardCheck
@onready var guitar_expert_check: CheckBox = $Difficulty/InstrumentGrid/GuitarExpertCheck
@onready var bass_easy_check: CheckBox = $Difficulty/InstrumentGrid/BassEasyCheck
@onready var bass_medium_check: CheckBox = $Difficulty/InstrumentGrid/BassMediumCheck
@onready var bass_hard_check: CheckBox = $Difficulty/InstrumentGrid/BassHardCheck
@onready var bass_expert_check: CheckBox = $Difficulty/InstrumentGrid/BassExpertCheck

# Properties tab controls
@onready var selection_info_label: Label = $Properties/SelectionInfo
@onready var note_type_selector: OptionButton = $Properties/BulkEditGroup/NoteTypeSelector
@onready var apply_note_type_button: Button = $Properties/BulkEditGroup/ApplyNoteTypeButton

var current_metadata: Dictionary = {}

func _ready():
	_connect_signals()
	_initialize_metadata()

func _connect_signals():
	# Metadata signals
	title_edit.text_changed.connect(_on_metadata_text_changed.bind("title"))
	artist_edit.text_changed.connect(_on_metadata_text_changed.bind("artist"))
	album_edit.text_changed.connect(_on_metadata_text_changed.bind("album"))
	charter_edit.text_changed.connect(_on_metadata_text_changed.bind("charter"))
	year_edit.value_changed.connect(_on_year_changed)
	audio_browse_button.pressed.connect(_on_audio_browse_pressed)
	
	# Difficulty signals
	guitar_easy_check.toggled.connect(_on_difficulty_toggled.bind("guitar", "easy"))
	guitar_medium_check.toggled.connect(_on_difficulty_toggled.bind("guitar", "medium"))
	guitar_hard_check.toggled.connect(_on_difficulty_toggled.bind("guitar", "hard"))
	guitar_expert_check.toggled.connect(_on_difficulty_toggled.bind("guitar", "expert"))
	bass_easy_check.toggled.connect(_on_difficulty_toggled.bind("bass", "easy"))
	bass_medium_check.toggled.connect(_on_difficulty_toggled.bind("bass", "medium"))
	bass_hard_check.toggled.connect(_on_difficulty_toggled.bind("bass", "hard"))
	bass_expert_check.toggled.connect(_on_difficulty_toggled.bind("bass", "expert"))
	
	# Properties signals
	apply_note_type_button.pressed.connect(_on_apply_note_type_pressed)

func _initialize_metadata():
	current_metadata = {
		"title": "",
		"artist": "",
		"album": "",
		"charter": "",
		"year": 2024,
		"audio_file": ""
	}

func _on_metadata_text_changed(new_text: String, field: String):
	current_metadata[field] = new_text
	metadata_changed.emit(current_metadata)

func _on_year_changed(value: float):
	current_metadata["year"] = int(value)
	metadata_changed.emit(current_metadata)

func _on_audio_browse_pressed():
	audio_file_requested.emit()

func _on_difficulty_toggled(enabled: bool, instrument: String, difficulty: String):
	difficulty_changed.emit(instrument, difficulty, enabled)

func _on_apply_note_type_pressed():
	var note_type_index = note_type_selector.selected
	property_changed.emit("note_type", note_type_index)

func set_metadata(metadata: Dictionary):
	current_metadata = metadata
	if "title" in metadata:
		title_edit.text = metadata["title"]
	if "artist" in metadata:
		artist_edit.text = metadata["artist"]
	if "album" in metadata:
		album_edit.text = metadata["album"]
	if "charter" in metadata:
		charter_edit.text = metadata["charter"]
	if "year" in metadata:
		year_edit.value = metadata["year"]
	if "audio_file" in metadata:
		audio_file_edit.text = metadata["audio_file"]

func get_metadata() -> Dictionary:
	return current_metadata

func set_difficulty_enabled(instrument: String, difficulty: String, enabled: bool):
	var check_box = _get_difficulty_checkbox(instrument, difficulty)
	if check_box:
		check_box.button_pressed = enabled

func _get_difficulty_checkbox(instrument: String, difficulty: String) -> CheckBox:
	match instrument:
		"guitar":
			match difficulty:
				"easy": return guitar_easy_check
				"medium": return guitar_medium_check
				"hard": return guitar_hard_check
				"expert": return guitar_expert_check
		"bass":
			match difficulty:
				"easy": return bass_easy_check
				"medium": return bass_medium_check
				"hard": return bass_hard_check
				"expert": return bass_expert_check
	return null

func update_selection_info(count: int, _note_types: Array):
	if count == 0:
		selection_info_label.text = "No notes selected"
	elif count == 1:
		selection_info_label.text = "1 note selected"
	else:
		selection_info_label.text = "%d notes selected" % count

func set_audio_file(file_path: String):
	"""Set the audio file path in metadata and update UI"""
	audio_file_edit.text = file_path
	current_metadata["audio_file"] = file_path
	metadata_changed.emit(current_metadata)
