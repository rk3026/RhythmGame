extends PanelContainer

# UI element references
@onready var note_count_label: Label = $VBox/NoteCountContainer/NoteCountLabel
@onready var snap_step_label: Label = $VBox/SnapContainer/SnapStepLabel
@onready var snap_step_option: OptionButton = $VBox/SnapContainer/SnapStepOption
@onready var clap_checkbox: CheckBox = $VBox/ClapCheckbox
@onready var hyperspeed_slider: HSlider = $VBox/HyperspeedContainer/HyperspeedSlider
@onready var hyperspeed_label: Label = $VBox/HyperspeedContainer/HyperspeedLabel
@onready var speed_slider: HSlider = $VBox/SpeedContainer/SpeedSlider
@onready var speed_label: Label = $VBox/SpeedContainer/SpeedLabel
@onready var highway_length_slider: HSlider = $VBox/HighwayContainer/HighwayLengthSlider
@onready var highway_length_label: Label = $VBox/HighwayContainer/HighwayLengthLabel

# Signals
signal snap_step_changed(value: int)
signal clap_toggled(enabled: bool)
signal hyperspeed_changed(value: float)
signal speed_changed(value: float)
signal highway_length_changed(value: float)

# Current values
var note_count: int = 0
var snap_step: int = 16
var clap_enabled: bool = false
var hyperspeed: float = 1.0
var playback_speed: float = 1.0
var highway_length: float = 100.0

func _ready():
	_connect_signals()

func _connect_signals():
	snap_step_option.item_selected.connect(_on_snap_step_selected)
	clap_checkbox.toggled.connect(_on_clap_toggled)
	hyperspeed_slider.value_changed.connect(_on_hyperspeed_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	highway_length_slider.value_changed.connect(_on_highway_length_changed)

func _on_snap_step_selected(index: int):
	# Map index to actual snap divisions: 4, 8, 12, 16, 24, 32, 64
	var snap_divisions = [4, 8, 12, 16, 24, 32, 64]
	snap_step = snap_divisions[index]
	snap_step_label.text = "Step: 1/" + str(snap_step)
	snap_step_changed.emit(snap_step)

func _on_clap_toggled(enabled: bool):
	clap_enabled = enabled
	clap_toggled.emit(enabled)

func _on_hyperspeed_changed(value: float):
	hyperspeed = value
	hyperspeed_label.text = "Hyperspeed: x%.1f" % hyperspeed
	hyperspeed_changed.emit(hyperspeed)

func _on_speed_changed(value: float):
	playback_speed = value
	speed_label.text = "Speed: x%.2f" % playback_speed
	speed_changed.emit(playback_speed)

func _on_highway_length_changed(value: float):
	highway_length = value
	highway_length_label.text = "Highway Length: " + str(int(highway_length)) + "%"
	highway_length_changed.emit(highway_length)

func update_note_count(count: int):
	note_count = count
	note_count_label.text = str(note_count)

func set_snap_step(value: int):
	# Programmatically set the snap step and update UI
	var snap_divisions = [4, 8, 12, 16, 24, 32, 64]
	var index = snap_divisions.find(value)
	if index >= 0:
		snap_step = value
		snap_step_option.selected = index
		snap_step_label.text = "Step: 1/" + str(snap_step)
		# Note: Don't emit signal here to avoid infinite loops
