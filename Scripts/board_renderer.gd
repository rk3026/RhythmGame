extends MeshInstance3D

var num_lanes: int
var board_width: float
var zone_width: float
var lanes: Array = []
var original_materials: Array = []

func _ready():
	board_width = mesh.size.x
	setup_lanes()
	create_hit_zones()
	create_lane_lines()
	set_board_texture()

func set_board_texture():
	var material = get_surface_override_material(0)
	if material:
		material.uv1_scale = Vector3(num_lanes, 1, 1)

func setup_lanes():
	zone_width = board_width / num_lanes
	lanes = []
	var start = - (num_lanes * zone_width / 2) + zone_width / 2
	var spacing = zone_width
	for i in range(num_lanes):
		lanes.append(start + i * spacing)

func create_hit_zones():
	for i in range(lanes.size()):
		var zone = MeshInstance3D.new()
		zone.name = "HitZone" + str(i)
		zone.mesh = QuadMesh.new()
		zone.mesh.size = Vector2(zone_width, SettingsManager.zone_height)
		var material = StandardMaterial3D.new()
		material.albedo_color = SettingsManager.lane_colors[i % SettingsManager.lane_colors.size()]
		zone.material_override = material
		original_materials.append(material.duplicate())
		zone.position = Vector3(lanes[i], 0.01, 0)
		zone.rotation_degrees = Vector3(-90, 0, 0)
		get_parent().add_child(zone)

func create_lane_lines():
	var boundaries = []
	for i in range(lanes.size() - 1):
		boundaries.append((lanes[i] + lanes[i + 1]) / 2.0)
	boundaries.append(-mesh.size.x / 2)
	boundaries.append(mesh.size.x / 2)
	for x in boundaries:
		var line = MeshInstance3D.new()
		line.mesh = BoxMesh.new()
		line.mesh.size = Vector3(0.1, 0.1, mesh.size.y)
		var material = StandardMaterial3D.new()
		material.albedo_color = SettingsManager.line_color
		line.material_override = material
		line.position = Vector3(x, 0.05, -10)
		get_parent().add_child(line)
