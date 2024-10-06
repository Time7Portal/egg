extends Node3D
class_name Manager

static var gGroundWitdh: float = 3;
static var gGroundHeight: float = 5;

@onready var gTimer = $Timer;

@export var gMaxLifeTime:float = 3600 * 24 * 50;	# second
@export var gMinLifeTime:float = 3600 * 24 * 7;	# second
@export var gMaxProductivity:float = 1;
@export var gMinProductivity:float = 0;
@export var gMaxSpeed:float = 2.6;
@export var gMinSpeed:float = 2.3;

@export var gHen: PackedScene;
@export var gRooster: PackedScene;
@export var gChick: PackedScene;
@export var gEgg: PackedScene;

static var gSavePath: String =  "user://saveFile.save";

static var gHenContainer: Array[PackedScene];
static var gRoosterContainer: Array[PackedScene];
static var gChickContainer: Array[PackedScene];
static var gEggContainer: Array[PackedScene];
static var gCollectionEggCount: int = 0;

static var gTotalProductivity: float = 0;

static var gCoin: int = 0;

func _ready():
	readSaveFile();
	refreshCoinUI();
	gTimer.start();
	
func _on_timer_timeout() -> void:
	writeSaveFile(false);
	gTimer.start();
	
func readSaveFile():
	if not FileAccess.file_exists(gSavePath):
		return;
		
	var file = FileAccess.open(gSavePath, FileAccess.READ);
	if file == null:
		writeSaveFile(true);
		
	var json = JSON.new();
	var parse_result = json.parse(file.get_line());
	if not parse_result == OK:
		print("JSON Parsing Error: ", json.get_error_message(), " in ", json.get_line(), "at line ", json.get_error_line());
		return;
	
	var node_data = json.get_data();
	file.close();
	
	gCollectionEggCount = node_data["CollectionEgg"];
	gCoin = node_data["Coin"];
	
	var rng = RandomNumberGenerator.new();
	rng.randomize();
		
	for i in node_data["Hen"]:
		var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
		var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
		var hen:Node = spawn(gHen, Vector3(randX, 0, randZ));
		gHenContainer.push_back(hen);
	for i in node_data["Rooster"]:
		var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
		var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
		var rooster:Node = spawn(gRooster, Vector3(randX, 0, randZ));
		gRoosterContainer.push_back(rooster);
	for i in node_data["Chick"]:
		var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
		var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
		var chick:Node = spawn(gChick, Vector3(randX, 0, randZ));
		gChickContainer.push_back(chick);
	for i in node_data["Egg"]:
		var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
		var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
		var egg:Node = spawn(gEgg, Vector3(randX, 0, randZ));
		gEggContainer.push_back(egg);
	
func writeSaveFile(initial: bool):
	print("Save: ", gSavePath);
	var file = FileAccess.open(gSavePath, FileAccess.WRITE);
	
	if initial == false:
		var saveData = {
			"Hen": gHenContainer.size(), 
			"Rooster": gRoosterContainer.size(), 
			"Chick": gChickContainer.size(), 
			"Egg": gEggContainer.size(), 
			"CollectionEgg": gCollectionEggCount, 
			"Coin": gCoin,
		};
		var saveDataString = JSON.stringify(saveData);
		file.store_line(saveDataString);
	else:
		var saveData = {
			"Hen": 1, 
			"Rooster": 1, 
			"Chick": 0, 
			"Egg": 0, 
			"Coin": gCoin,
		};
		var saveDataString:String = JSON.stringify(saveData);
		file.store_line(saveDataString);
	
	file.close();
	
func spawn(prefab: PackedScene, pos: Vector3):
	print("Spawn ", prefab.resource_path , " in Pos: ", pos);
	var instance:Node = prefab.instantiate();
	add_child(instance);
	instance.position = pos;
	
	var test:Animal = instance as Animal;
	if test != null:
		# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
		var rng:RandomNumberGenerator = RandomNumberGenerator.new();
		var lifeTime:float = rng.randf_range(gMinLifeTime, gMaxLifeTime);
		var speed:float = rng.randf_range(gMinSpeed, gMaxSpeed);
		var productivity:float = rng.randf_range(gMinProductivity, gMaxProductivity);
		test.initializeStatus(lifeTime, speed, productivity);
	
func _input(event):
	if event.is_pressed() == false:
		return;
		
	if event is InputEventMouse == false:
		return;
		
	var mousePosition:Vector2 = event.position;
	var result:Node = findEgg(mousePosition);
	if result == null:
		return;
	
	acquireEgg(result.get_parent());

func findEgg(m_pos) -> Node:
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * 2000
	var world3d : World3D = get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return null;
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if !("collider" in result):
		return null;
	
	return result["collider"]

func acquireEgg(node):
	gCollectionEggCount += 1;
	refreshCoinUI();
	node.queue_free();

func refreshCoinUI():
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string:String = "$ %d";
	var actual_string:String = format_string % gCoin;
	get_node("Money/Label").text = actual_string;

static func onAddAnimal(productivity:float) -> void:
	gTotalProductivity += productivity;
static func onRemoveAnimal(productivity:float) -> void:
	gTotalProductivity -= productivity;
	
static var testEggSpawnTime:float = 15;
static var gEggProductAccumulateTime:float = 0;
func _process(delta: float) -> void:
	#TODO(Lee): 나중에 경제벨런스 고려해서 잘 수식화 필요
	gEggProductAccumulateTime += delta;
	print("test: ", testEggSpawnTime, ", accum:", gEggProductAccumulateTime, ", total: ", gTotalProductivity);
	if testEggSpawnTime - (gEggProductAccumulateTime + gTotalProductivity) < 0:
		var rng:RandomNumberGenerator = RandomNumberGenerator.new();
		var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
		var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
		var egg:Node = spawn(gEgg, Vector3(randX, 0, randZ));
		gEggContainer.push_back(egg);
		
		gEggProductAccumulateTime = 0;
