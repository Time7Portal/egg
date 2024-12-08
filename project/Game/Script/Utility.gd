extends Node
class_name Utility;

#region DEV
static func draw_debug_sphere(parent, location, size) -> MeshInstance3D:
	# Create sphere with low detail of size.
	var sphere = SphereMesh.new()
	sphere.radial_segments = 4
	sphere.rings = 4
	sphere.radius = size
	sphere.height = size * 2
	# Bright red material (unshaded).
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)
	material.flags_unshaded = true
	sphere.surface_set_material(0, material)
	
	# Add to meshinstance in the right place.
	var debugTargetPositionSphere = MeshInstance3D.new()
	debugTargetPositionSphere.mesh = sphere
	parent.add_child(debugTargetPositionSphere)
	debugTargetPositionSphere.global_transform.origin = location
	
	return debugTargetPositionSphere;
#endregion

static var RNG = RandomNumberGenerator.new();

static func randomRangeFloat(rangeMin:float, rangeMax:float) -> float:
	return RNG.randf_range(rangeMin, rangeMax);
	
static func randomFloat() -> float:
	return RNG.randf();
	
static func randomRangeInt(min:int, max:int) -> int:
	return RNG.randi_range(min, max);
