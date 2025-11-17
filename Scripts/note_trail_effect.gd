extends Node3D
# NoteTrailEffect.gd - Adds a glowing trail behind moving notes for better visual tracking

class_name NoteTrailEffect

@export var trail_length: float = 2.0  # How long the trail extends behind the note
@export var trail_width: float = 0.6   # Width of the trail
@export var fade_distance: float = 1.5 # Distance over which trail fades out
@export var glow_intensity: float = 1.5

var trail_mesh: MeshInstance3D
var material: StandardMaterial3D
var note_color: Color = Color.WHITE

func _ready():
	_create_trail_mesh()

func _create_trail_mesh():
	# Create ribbon mesh for trail
	trail_mesh = MeshInstance3D.new()
	
	# Use simple quad mesh for trail (Godot doesn't have RibbonTrailMesh built-in)
	var quad_trail = _create_quad_trail()
	trail_mesh.mesh = quad_trail
	
	# Create glowing material
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission_energy_multiplier = glow_intensity
	material.albedo_color = note_color
	material.emission = note_color
	
	trail_mesh.material_override = material
	trail_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail_mesh)

func _create_quad_trail() -> QuadMesh:
	"""Fallback simple trail using QuadMesh"""
	var quad = QuadMesh.new()
	quad.size = Vector2(trail_width, trail_length)
	quad.orientation = PlaneMesh.FACE_Z
	return quad

func set_color(color: Color):
	"""Update the trail color"""
	note_color = color
	if material:
		material.albedo_color = color
		material.emission = color

func update_trail(note_velocity: float):
	"""Update trail based on note movement speed"""
	if not trail_mesh:
		return
	
	# Adjust trail length based on velocity (faster = longer trail)
	var dynamic_length = trail_length * (1.0 + note_velocity * 0.1)
	
	# Update quad mesh size if using fallback
	if trail_mesh.mesh is QuadMesh:
		trail_mesh.mesh.size.y = dynamic_length
		
		# Position trail behind note
		trail_mesh.position = Vector3(0, 0, dynamic_length * 0.5)
		trail_mesh.rotation_degrees = Vector3(90, 0, 0)
		
		# Fade based on distance from note
		var alpha = 1.0 - (dynamic_length / (trail_length * 2.0))
		var current_color = note_color
		current_color.a = clamp(alpha, 0.2, 0.8)
		material.albedo_color = current_color

func enable_trail(enabled: bool):
	"""Show or hide the trail"""
	if trail_mesh:
		trail_mesh.visible = enabled
