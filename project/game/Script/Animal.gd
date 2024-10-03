extends Node
class_name Animal;

@export var gMaxIdleTime:float = 10.0;
@export var gMinIdleTime:float = 0.3;
@export var gMaxSpeed:float = 0.6;
@export var gMinSpeed:float = 0.3;

enum STATE {IDLE, MOVE}

var gState:STATE = STATE.IDLE;
var gIdleTime:float = 0;
var gCurrentIdleTime:float = 0;
var gTargetPosition:Vector3 = Vector3(0, 0, 0);
var gSpeed = 0; #UnitLength per second

#def
var debugTargetPositionSphere: Node = null;

# Add a debug sphere at global location.
func draw_debug_sphere(location, size):
	# Will usually work, but you might need to adjust this.
	var scene_root = get_tree().root.get_children()[0]
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
	debugTargetPositionSphere = MeshInstance3D.new()
	debugTargetPositionSphere.mesh = sphere
	debugTargetPositionSphere.global_transform.origin = location
	scene_root.add_child(debugTargetPositionSphere)
	
#def

func changeStateIDLE() -> void:	
	var rng:RandomNumberGenerator = RandomNumberGenerator.new();
	gIdleTime = rng.randf_range(gMinIdleTime, gMaxIdleTime);
	gSpeed = rng.randf_range(gMinSpeed, gMaxSpeed);
	print("Idle: ", self.name, " time: ", gIdleTime, ", speed: ", gSpeed);
	gCurrentIdleTime = 0;
	gState = STATE.IDLE;

func _ready() -> void:
	changeStateIDLE();

func _process(delta: float) -> void:
	match gState:
		STATE.IDLE:
			gCurrentIdleTime += delta;
			if gCurrentIdleTime >= gIdleTime:
				var rng:RandomNumberGenerator = RandomNumberGenerator.new();
				rng.randomize();
				gTargetPosition = Vector3(rng.randf_range(-Manager.gGroundWitdh, Manager.gGroundWitdh), 0, rng.randf_range(-Manager.gGroundHeight, Manager.gGroundHeight));
				print("Move: ", self.name, " to ", gTargetPosition);
				draw_debug_sphere(gTargetPosition, 0.2);
				
				var test = self.name;
				var dir:Vector3 = gTargetPosition - self.position;
				dir = dir.normalized();
				var test2 = dir.length();
				var forward:Vector3 = -self.transform.basis.z;
				var angle:float = Vector3(-1, 0, 0).angle_to(dir);
				print(self.rotation.y)
				if Vector3(-1, 0, 0).cross(dir).y < 0:
					self.rotation.y = -angle;
				else:
					self.rotation.y = angle;
				
				gState = STATE.MOVE;
		STATE.MOVE:
			var dir:Vector3 = gTargetPosition - self.position;
			dir = dir.normalized();
			var moveDelta:Vector3 = dir * gSpeed * delta;
			var dist:Vector3 = gTargetPosition - (self.position + moveDelta);
			if dist.length() <= 0.05:
				moveDelta = gTargetPosition - self.position;
				changeStateIDLE();
				debugTargetPositionSphere.queue_free();
				
			self.position += moveDelta;
		_:
			print("Error!");
