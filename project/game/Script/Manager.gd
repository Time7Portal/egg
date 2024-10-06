extends Node3D
class_name Manager

@onready var gTimer = $Timer;

static var gHenContainer: Array[Node];
static var gRoosterContainer: Array[Node];
static var gChickContainer: Array[Node];
static var gEggContainer: Array[Node];

# Status
static var gTotalProductivity: float = 0;

# Property
static var gCollectionEggCount: int = 0;
static var gCoin: int = 0;

func _ready():
	readSaveFile();
	refreshCoinUI();
	gTimer.start();
	
func _on_timer_timeout() -> void:
	writeSaveFile(false);
	gTimer.start();
	
func readSaveFile():
	if not FileAccess.file_exists(GlobalVariable.gSavePath):
		writeSaveFile(true);
		
	var file:FileAccess = FileAccess.open(GlobalVariable.gSavePath, FileAccess.READ);
	Logger.LogError("No Save File!");
		
	var json:JSON = JSON.new();
	var parse_result:Error = json.parse(file.get_line());
	if not parse_result == OK:
		Logger.LogError("JSON Parsing Error: %s in line %d" % [json.get_error_message(), json.get_error_line()]);
		return;
	
	var node_data = json.get_data();
	file.close();
	
	gCollectionEggCount = node_data["CollectionEgg"];
	gCoin = node_data["Coin"];
		
	for i in node_data["Hen"]:
		var hen:Node = spawn(GlobalVariable.gHen, GlobalVariable.getRandomGroundPosition());
		gHenContainer.push_back(hen);
	for i in node_data["Rooster"]:
		var rooster:Node = spawn(GlobalVariable.gRooster, GlobalVariable.getRandomGroundPosition());
		gRoosterContainer.push_back(rooster);
	for i in node_data["Chick"]:
		var chick:Node = spawn(GlobalVariable.gChick, GlobalVariable.getRandomGroundPosition());
		gChickContainer.push_back(chick);
	for i in node_data["Egg"]:
		var egg:Node = spawn(GlobalVariable.gEgg, GlobalVariable.getRandomGroundPosition());
		gEggContainer.push_back(egg);
	
func writeSaveFile(initial: bool):
	Logger.LogDebug("Save: %s" % GlobalVariable.gSavePath);
	var file = FileAccess.open(GlobalVariable.gSavePath, FileAccess.WRITE);
	
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
			"CollectionEgg": gCollectionEggCount, 
			"Coin": gCoin,
		};
		var saveDataString:String = JSON.stringify(saveData);
		file.store_line(saveDataString);
	
	file.close();
	
func spawn(prefab: PackedScene, pos: Vector3):
	Logger.LogDebug("Spawn %s in Pos: %v" % [prefab.resource_path, pos]);
	var instance:Node = prefab.instantiate();
	add_child(instance);
	instance.position = pos;
	
	# 이 곳에 있을 로직은 아닌듯..
	var animal:Animal = instance as Animal;
	if animal != null:
		# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
		var rng:RandomNumberGenerator = RandomNumberGenerator.new();
		var lifeTime:float = rng.randf_range(GlobalVariable.gMinLifeTime, GlobalVariable.gMaxLifeTime);
		var speed:float = rng.randf_range(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
		var productivity:float = rng.randf_range(GlobalVariable.gMinProductivity, GlobalVariable.gMaxProductivity);
		animal.initializeStatus(lifeTime, speed, productivity);
	
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
	var cam:Camera3D = get_viewport().get_camera_3d();
	var ray_start:Vector3 = cam.project_ray_origin(m_pos);
	var ray_end:Vector3 = ray_start + cam.project_ray_normal(m_pos) * 2000;
	var world3d:World3D = get_world_3d();
	var space_state:PhysicsDirectSpaceState3D = world3d.direct_space_state;
	
	if space_state == null:
		return null;
	
	var query:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = true
	var result:Dictionary = space_state.intersect_ray(query)
	if !("collider" in result):
		return null;
	
	return result["collider"]

func acquireEgg(node:Node) -> void:
	gCollectionEggCount += 1;
	refreshCoinUI();
	
	Logger.LogAssert(gEggContainer.find(node) < 0, "Spawn되지 않은 Egg의 습득을 시도합니다.");
	gEggContainer.erase(node);
	node.queue_free();

func refreshCoinUI() -> void:
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
	if testEggSpawnTime - (gEggProductAccumulateTime + gTotalProductivity) < 0:
		var egg:Node = spawn(GlobalVariable.gEgg, GlobalVariable.getRandomGroundPosition());
		gEggContainer.push_back(egg);
		
		gEggProductAccumulateTime = 0;
		
func onHatching(egg: Node) -> void:
	Logger.LogAssert(gEggContainer.find(egg) < 0, "Spawn되지 않았던 Egg의 부화시도.");
	gEggContainer.erase(egg);
	egg.queue_free();
	
	var chick:Node = spawn(GlobalVariable.gChick, GlobalVariable.getRandomGroundPosition());
	gChickContainer.push_back(chick);
	
func onEvolutionChick(chick: Node) -> void:
	Logger.LogAssert(gChickContainer.find(chick) < 0, "Spawn되지 않았던 Chick의 성장시도.");
	gChickContainer.erase(chick);
	chick.queue_free();
	
	#TODO(Lee): Chick 상태에서부터 암/수 구분할지는 논의 필요
	var rng:RandomNumberGenerator = RandomNumberGenerator.new();
	var isHen:bool = rng.randf() < 0.5;
	if isHen:
		var hen:Node = spawn(GlobalVariable.gHen, GlobalVariable.getRandomGroundPosition());
		gHenContainer.push_back(hen);
	else:
		var rooster:Node = spawn(GlobalVariable.gRooster, GlobalVariable.getRandomGroundPosition());
		gRoosterContainer.push_back(rooster);
