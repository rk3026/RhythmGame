extends Node

# Lightweight centralized animation system avoiding per-event Tween allocations.
# Uses manual interpolation tasks stored in an array for predictable performance.
# Designed to be extensible: add new composite helpers for future animation events.

class_name AnimationDirector
var _anims: Array = [] # Each: {node, property, from, to, elapsed, duration, ease, on_complete}
var _sequences: Array = [] # Each: {steps: [anim dicts], index}

enum EaseType { LINEAR, OUT_QUAD, IN_QUAD, OUT_BACK }

func _process(delta: float) -> void:
	# Update simple animations
	for i in range(_anims.size() - 1, -1, -1):
		var a: Dictionary = _anims[i]
		if not is_instance_valid(a["node"]):
			_anims.remove_at(i)
			continue
		a["elapsed"] += delta
		var t = clamp(a["elapsed"] / a["duration"], 0.0, 1.0)
		t = _ease(t, a["ease"])
		var from_v = a["from"]
		var to_v = a["to"]
		var value = lerp(from_v, to_v, t) if typeof(from_v) in [TYPE_FLOAT, TYPE_INT] else _lerp_variant(from_v, to_v, t)
		_set_property(a["node"], a["property"], value)
		if a["elapsed"] >= a["duration"]:
			var done = _anims[i]
			_anims.remove_at(i)
			if done["on_complete"]:
				done["on_complete"].call()

	# Update sequences (advance when their current step is absent in _anims)
	for s in _sequences:
		if s["index"] >= s["steps"].size():
			continue
		var step = s["steps"][s["index"]]
		if step not in _anims:
			# Step finished, advance
			s["index"] += 1
			if s["index"] < s["steps"].size():
				var nxt = s["steps"][s["index"]]
				_anims.append(nxt)

func _ease(t: float, ease_type: int) -> float:
	match ease_type:
		EaseType.OUT_QUAD:
			return 1.0 - (1.0 - t) * (1.0 - t)
		EaseType.IN_QUAD:
			return t * t
		EaseType.OUT_BACK:
			var c1 = 1.70158
			var c3 = c1 + 1.0
			return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
		_:
			return t

func _lerp_variant(a, b, t: float):
	if typeof(a) == TYPE_VECTOR3:
		return a.lerp(b, t)
	if typeof(a) == TYPE_VECTOR2:
		return a.lerp(b, t)
	if typeof(a) == TYPE_COLOR:
		return Color(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
	return a # Fallback (unsupported type)

func _set_property(node: Object, prop: String, value) -> void:
	if not is_instance_valid(node):
		return
	# Allow nested property path like "modulate:a" for alpha channel.
	if ":" in prop:
		var parts = prop.split(":")
		var base = parts[0]
		var sub = parts[1]
		var curv = node.get(base)
		if typeof(curv) == TYPE_COLOR and sub == "a":
			curv.a = value
			node.set(base, curv)
			return
	node.set(prop, value)

func _animate(node: Object, property: String, from_v, to_v, duration: float, ease_type:=EaseType.OUT_QUAD, on_complete: Callable = Callable()) -> Dictionary:
	var anim = {node = node, property = property, from = from_v, to = to_v, elapsed = 0.0, duration = max(0.0001, duration), ease = ease_type, on_complete = on_complete}
	_anims.append(anim)
	return anim

func _sequence(steps: Array) -> void:
	if steps.is_empty():
		return
	# Steps are dictionaries already produced by _animate but we want to run them sequentially, so remove all but first now.
	for i in range(1, steps.size()):
		_anims.erase(steps[i])
	_sequences.append({"steps": steps, "index": 0})

func _kill_anims(node: Object, property: String = "") -> void:
	# Remove active anims
	for i in range(_anims.size() - 1, -1, -1):
		var a: Dictionary = _anims[i]
		if a["node"] == node and (property == "" or a["property"] == property):
			_anims.remove_at(i)
	# Remove sequences containing steps targeting node/property
	for i in range(_sequences.size() - 1, -1, -1):
		var seq: Dictionary = _sequences[i]
		var purge = false
		for st in seq["steps"]:
			if st["node"] == node and (property == "" or st["property"] == property):
				purge = true
				break
		if purge:
			_sequences.remove_at(i)

# PUBLIC HELPERS -----------------------------------------------------------

func animate_note_spawn(note: Node) -> void:
	if not is_instance_valid(note):
		return
	# Initial squash
	note.scale = Vector3(0.4, 0.4, 0.4)
	var step1 = _animate(note, "scale", note.scale, Vector3(1.15, 1.15, 1.15), 0.11, EaseType.OUT_BACK)
	var step2 = _animate(note, "scale", Vector3(1.15, 1.15, 1.15), Vector3(1,1,1), 0.07, EaseType.OUT_QUAD)
	_sequence([step1, step2])
	# Slight initial color flash (Sprite3D has modulate in Godot 4)
	if note.has_method("get") and note.has_method("set"):
		var base_col = note.modulate
		note.modulate = base_col.lightened(0.6)
		_animate(note, "modulate", note.modulate, base_col, 0.18, EaseType.OUT_QUAD)

func animate_judgement_label(label: Label, grade: int = -1) -> void:
	# Removed
	return

func animate_combo_label(_label: Label) -> void:
	# NO-OP: Previous implementation animated label.scale with a bounce effect.
	# Combo label scaling animations were intentionally removed per user request.
	# Keep this method as a compatibility stub in case external callers exist.
	return

func animate_lane_press(zone: MeshInstance3D, pressed: bool) -> void:
	if not is_instance_valid(zone):
		return
	# Subtle pulse scale on press; revert on release.
	if pressed:
		zone.scale = Vector3(1,1,1)
		_animate(zone, "scale", zone.scale, Vector3(1.08, 1.08, 1.08), 0.06, EaseType.OUT_BACK, func():
			_animate(zone, "scale", zone.scale, Vector3(1,1,1), 0.08)
		)
	else:
		# Smoothly return to baseline if user releases mid-pulse.
		_animate(zone, "scale", zone.scale, Vector3(1,1,1), 0.09)

func animate_screen_pulse(_node: Node, _strength: float = 0.05):
	# Placeholder hook for future camera punch or post-process effect.
	pass
