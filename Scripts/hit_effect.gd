extends Node3D

# Simple GPU-less procedural effect using MultiMeshInstance3D or MeshInstance3D quads.
# Designed to be lightweight and pooled.

@export var lifetime: float = 0.35
@export var burst_count: int = 12
@export var color: Color = Color.WHITE
@export var use_streaks: bool = true
@export var spread_x: float = 0.22 # half-width lateral spread (lane confinement)
@export var spread_z: float = 0.12 # forward/back spread (keep near hit line)
@export var rise_min: float = 0.35 # vertical rise range (gives some lift)
@export var rise_max: float = 0.85
@export var velocity_scale: float = 3.0 # base motion scalar
@export var base_particle_width: float = 0.11
@export var base_particle_height: float = 0.26
@export var size_variance: float = 0.15 # +/- percentage randomness per particle
@export var effect_scale: float = 1.25 # overall multiplier (increase effect size after removing score scaling)

var lifetime_elapsed: float = 0.0
var parts: Array = []

func _ready():
	if parts.is_empty():
		_generate()

func _generate():
	# Generate confined particles inside lane bounds instead of radial spray.
	for i in range(burst_count):
		var m = MeshInstance3D.new()
		var quad = QuadMesh.new()
		var w = base_particle_width * effect_scale
		var h = (base_particle_height if use_streaks else base_particle_width) * effect_scale
		# Apply per-particle variance
		var variance = 1.0 + randf_range(-size_variance, size_variance)
		quad.size = Vector2(w * variance, h * variance)
		m.mesh = quad
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.material_override = mat
		add_child(m)
		# Small lateral jitter within lane, slight forward/back, upward lift
		var vx = randf_range(-spread_x, spread_x)
		var vz = randf_range(-spread_z, spread_z)
		var vy = randf_range(rise_min, rise_max)
		var dir = Vector3(vx, vy, vz)
		m.set_meta("dir", dir)
		parts.append(m)

func play(new_color: Color, _scale_factor: float = 1.0):
	# _scale_factor kept for signature compatibility but ignored to keep consistent size
	lifetime_elapsed = 0.0
	color = new_color
	for p in parts:
		if p.material_override:
			p.material_override.albedo_color = new_color
		p.scale = Vector3.ONE * effect_scale
		# Reset base direction (already confined) without extra scaling inflation
		var base_dir: Vector3 = p.get_meta("dir")
		p.set_meta("dir", base_dir) # no change; explicit for clarity
		p.position = Vector3.ZERO
		p.visible = true

func _process(delta):
	lifetime_elapsed += delta
	var t = lifetime_elapsed / lifetime
	for p in parts:
		var dir: Vector3 = p.get_meta("dir")
		# Motion eases out; confined horizontally
		p.position += dir * delta * velocity_scale * (1.0 - t)
		var fade = 1.0 - t
		if p.material_override:
			var c = p.material_override.albedo_color
			c.a = fade
			p.material_override.albedo_color = c
	if lifetime_elapsed >= lifetime:
		# The pool manager will reclaim us on next pool tick.
		visible = false
