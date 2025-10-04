extends Node

class_name NotePool

var note_scene: PackedScene = preload("res://Scenes/note.tscn")
var pool: Array = []
var max_pool_size: int = 200  # Allow more for long songs
var spawner_ref: Node = null  # Reference to note spawner for signal management

func _ready():
	spawner_ref = get_parent()

func get_note() -> Node:
	var note
	if pool.is_empty():
		note = note_scene.instantiate()
		# Connect signals once when creating new notes
		note.connect("note_miss", Callable(spawner_ref.get_parent(), "_on_note_miss"))
		note.connect("note_finished", Callable(spawner_ref, "_on_note_finished"))
	else:
		note = pool.pop_back()
	note.reset()
	return note

func return_note(note: Node):
	if pool.size() < max_pool_size:
		# Remove from parent without disconnecting signals (they're permanent)
		if note.get_parent():
			note.get_parent().remove_child(note)
		pool.append(note)
	else:
		# Only disconnect signals when actually freeing the note
		if note.is_connected("note_miss", Callable(spawner_ref.get_parent(), "_on_note_miss")):
			note.disconnect("note_miss", Callable(spawner_ref.get_parent(), "_on_note_miss"))
		if note.is_connected("note_finished", Callable(spawner_ref, "_on_note_finished")):
			note.disconnect("note_finished", Callable(spawner_ref, "_on_note_finished"))
		note.queue_free()