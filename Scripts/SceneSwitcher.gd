extends Node

# SceneSwitcher - Manages scene stack for navigation
var scene_stack = []

func _ready():
	# Push the initial scene
	var current = get_tree().current_scene
	if current:
		current.show()
		current.process_mode = Node.PROCESS_MODE_INHERIT
		scene_stack.append(current)

func push_scene(scene_path: String):
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	if scene_stack.size() > 0:
		var previous = scene_stack.back()
		previous.hide()
		previous.process_mode = Node.PROCESS_MODE_DISABLED
	new_scene.show()
	new_scene.process_mode = Node.PROCESS_MODE_INHERIT
	scene_stack.append(new_scene)

func push_scene_instance(scene_instance: Node):
	get_tree().root.add_child(scene_instance)
	if scene_stack.size() > 0:
		var previous = scene_stack.back()
		previous.hide()
		previous.process_mode = Node.PROCESS_MODE_DISABLED
	scene_instance.show()
	scene_instance.process_mode = Node.PROCESS_MODE_INHERIT
	scene_stack.append(scene_instance)

func replace_scene_instance(scene_instance: Node):
	if scene_stack.size() > 0:
		var current = scene_stack.pop_back()
		get_tree().root.remove_child(current)
		current.queue_free()
	get_tree().root.add_child(scene_instance)
	if scene_stack.size() > 0:
		var previous = scene_stack.back()
		previous.hide()
		previous.process_mode = Node.PROCESS_MODE_DISABLED
	scene_instance.show()
	scene_instance.process_mode = Node.PROCESS_MODE_INHERIT
	scene_stack.append(scene_instance)

func pop_scene():
	if scene_stack.size() <= 1:
		return  # Can't pop the last scene
	var current = scene_stack.pop_back()
	get_tree().root.remove_child(current)
	current.queue_free()
	if scene_stack.size() > 0:
		var previous = scene_stack.back()
		previous.show()
		previous.process_mode = Node.PROCESS_MODE_INHERIT
