extends Node

class_name NoteType

enum Type {REGULAR, HOPO, TAP, OPEN}

static func get_multiplier(type: Type) -> int:
	match type:
		Type.REGULAR: return 1
		Type.HOPO: return 2
		Type.TAP: return 2
		Type.OPEN: return 1
		_: return 1

static func get_texture_suffix(type: Type) -> String:
	match type:
		Type.REGULAR: return ""
		Type.HOPO: return "_h"
		Type.TAP: return "_h"
		Type.OPEN: return "_star"
		_: return ""

static func is_special(type: Type) -> bool:
	return type == Type.HOPO or type == Type.TAP

# Add more properties as needed, e.g., color, animation, etc.