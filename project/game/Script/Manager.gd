extends Node3D
class_name Manager

@onready var gTimer = $Timer;

@export var gHen: PackedScene;
@export var gRooster: PackedScene;
@export var gChick: PackedScene;
@export var gEgg: PackedScene;

var gSavePath: String =  "user://saveFile.save";

var gHenContainer: Array[PackedScene];
var gRoosterContainer: Array[PackedScene];
var gChickContainer: Array[PackedScene];
var gEggContainer: Array[PackedScene];
var gCoin: int = 0;

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
	
	gCoin = node_data["Coin"];
	
	var minX = -3;
	var maxX = 3;
	var minZ = -5;
	var maxZ = 5;
	var rng = RandomNumberGenerator.new();
	rng.randomize();
		
	for i in node_data["Hen"]:
		var randX = rng.randi_range(minX, maxX);
		var randZ = rng.randi_range(minZ, maxZ);
		var hen = spawn(gHen, Vector3(randX, 0, randZ));
		gHenContainer.push_back(hen);
	for i in node_data["Rooster"]:
		var randX = rng.randi_range(minX, maxX);
		var randZ = rng.randi_range(minZ, maxZ);
		var rooster = spawn(gRooster, Vector3(randX, 0, randZ));
		gRoosterContainer.push_back(rooster);
	for i in node_data["Chick"]:
		var randX = rng.randi_range(minX, maxX);
		var randZ = rng.randi_range(minZ, maxZ);
		var chick = spawn(gChick, Vector3(randX, 0, randZ));
		gChickContainer.push_back(chick);
	for i in node_data["Egg"]:
		var randX = rng.randi_range(minX, maxX);
		var randZ = rng.randi_range(minZ, maxZ);
		var egg = spawn(gEgg, Vector3(randX, 0, randZ));
		gEggContainer.push_back(egg);
	
func spawn(prefab: PackedScene, pos: Vector3):
	print("Spawn ", prefab.resource_path , " in Pos: ", pos);
	var instance = prefab.instantiate();
	add_child(instance);
	instance.position = pos;
	
func writeSaveFile(initial: bool):
	print("Save: ", gSavePath);
	var file = FileAccess.open(gSavePath, FileAccess.WRITE);
	
	if initial == false:
		var saveData = {
			"Hen": gHenContainer.size(), 
			"Rooster": gRoosterContainer.size(), 
			"Chick": gChickContainer.size(), 
			"Egg": gEggContainer.size(), 
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
		var saveDataString = JSON.stringify(saveData);
		file.store_line(saveDataString);
	
	file.close();
	
func _input(event):
	if event.is_pressed() == false:
		return;
		
	if event is InputEventMouse == false:
		return;
		
	var mousePosition = event.position;
	var result = findEgg(mousePosition);
	if result == null:
		return;
	
	acquireEgg(result.get_parent());

func findEgg(m_pos):
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
	gCoin += 1;
	refreshCoinUI();
	node.queue_free();

func refreshCoinUI():
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string = "$ %d";
	var actual_string = format_string % gCoin;
	get_node("Money/Label").text = actual_string;
