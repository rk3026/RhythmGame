extends Node
# HitEffectPool.gd - pools particle effects for note hit / sustain / miss events

class_name HitEffectPool

@export var max_pool_size: int = 64
var effect_scene: PackedScene = preload("res://Scenes/hit_effect.tscn")
var pool: Array = []
var active: Array = []

func _process(_delta):
	for i in range(active.size() - 1, -1, -1):
		var e = active[i]
		if not is_instance_valid(e):
			active.remove_at(i)
			continue
		if e.lifetime_elapsed >= e.lifetime:
			_recycle(e, i)

func get_effect() -> Node:
	var inst
	if pool.is_empty():
		inst = effect_scene.instantiate()
	else:
		inst = pool.pop_back()
	inst.visible = true
	inst.lifetime_elapsed = 0.0
	active.append(inst)
	return inst

func _recycle(e: Node, active_index: int):
	active.remove_at(active_index)
	if pool.size() < max_pool_size:
		e.visible = false
		if e.get_parent():
			e.get_parent().remove_child(e)
		pool.append(e)
	else:
		e.queue_free()

func recycle_effect(e: Node):
	var idx = active.find(e)
	if idx != -1:
		_recycle(e, idx)
