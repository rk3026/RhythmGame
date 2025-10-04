extends Sprite3D

signal note_miss(note)
signal note_finished(note)

enum NoteType {REGULAR, HOPO, TAP, OPEN}

@export var speed: float = 10.0
var spawn_time: float
var expected_hit_time: float
var was_hit: bool = false:
	set(value):
		was_hit = value
		if tail_instance:
			tail_instance.was_hit = value
var note_type: NoteType = NoteType.REGULAR
var is_sustain: bool = false
var sustain_length: float = 0.0  # in seconds
var fret: int = 0
var tail_instance: Node = null
var hit_effect_pool: Node = null
var travel_time: float = 0.0
var reverse_mode: bool = false
var spawn_command = null

func _ready():
	# Elevated priority so it draws above board; tail will use a higher one
	render_priority = 2

func reset():
	position = Vector3.ZERO
	speed = 10.0
	spawn_time = 0.0
	expected_hit_time = 0.0
	was_hit = false
	note_type = NoteType.REGULAR
	is_sustain = false
	sustain_length = 0.0
	fret = 0
	hit_effect_pool = null
	travel_time = 0.0
	reverse_mode = false
	spawn_command = null
	if tail_instance:
		tail_instance.queue_free()
		tail_instance = null
	texture = null
	scale = Vector3.ONE
	modulate = Color.WHITE
	visible = true
	render_priority = 2

func update_visuals():
	var texture_path = ""
	var base_path = "res://Assets/Textures/Notes/"
	
	if note_type == NoteType.OPEN:
		texture_path = base_path + "note_star.png"
	else:
		var color_suffix = ""
		match fret:
			0:
				color_suffix = "green"
			1:
				color_suffix = "red"
			2:
				color_suffix = "yellow"
			3:
				color_suffix = "blue"
			4:
				color_suffix = "orange"
			_:
				color_suffix = "green"  # fallback
		
		var type_suffix = ""
		if note_type == NoteType.HOPO or note_type == NoteType.TAP:
			type_suffix = "_h"
		
		texture_path = base_path + "note_" + color_suffix + type_suffix + ".png"
	
	if texture_path:
		texture = load(texture_path)
	
	if is_sustain:
		scale.y = 1.0 + sustain_length * speed / 10.0  # make taller based on sustain length
		modulate = Color(0.7, 0.7, 0.7)  # dimmer for sustain
		# Create or update tail instance
		if not tail_instance:
			var tail_scene = load("res://Scenes/note_tail.tscn")
			tail_instance = tail_scene.instantiate()
			add_child(tail_instance)
			tail_instance.connect("note_finished", Callable(self, "_on_tail_finished"))
		# Update tail properties
		tail_instance.speed = speed
		tail_instance.sustain_length = sustain_length
		tail_instance.fret = fret
		tail_instance.note_type = note_type
		tail_instance.hit_effect_pool = hit_effect_pool
		tail_instance.was_hit = was_hit
		tail_instance.update_visuals()
	else:
		scale.y = 1.0
		modulate = Color.WHITE
		if tail_instance:
			tail_instance.queue_free()
			tail_instance = null

func _process(delta: float):
	# Movement respects reverse playback flag
	var dir = -1.0 if reverse_mode else 1.0
	position.z += speed * delta * dir

	if position.z >= 5 and not was_hit and not reverse_mode:
		emit_signal("note_miss", self)
		was_hit = true
		visible = false
		if tail_instance:
			tail_instance.was_hit = true

func _on_tail_finished(_tail):
	emit_signal("note_finished", self)
	visible = false
