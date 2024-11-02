extends Node3D
class_name Manager

@onready var gTimer: Timer = $Timer;
@onready var gUIPanel: Node = $UI/Money/Label;
@onready var gCamera: Camera3D = $Camera3D;

@export var gHen: PackedScene;
@export var gRooster: PackedScene;
@export var gChick: PackedScene;
@export var gEgg: PackedScene;

@export var gScenePosition: Array[Vector3];
@export var gSceneInterpolationTime: float = 0.2;

static var gHenContainer: Array[Node];
static var gRoosterContainer: Array[Node];
static var gChickContainer: Array[Node];
static var gEggContainer: Array[Node];

# Total Status
static var gTotalProductivity: float = 0;

# Property
static var gCollectionEggCount: int = 0;
static var gCoin: int = 0;

static var gManagerNode:Node;

# Screen Swipe Detation
var tween: Tween;
var length = 100;
var startPos: Vector2;
var curPos: Vector2;
var swiping: bool = false;
var targetSceneIndex: int = 2;
var currentSceneIndex: int = 2;

func _ready():
	gManagerNode = self;
	
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
	
	if node_data.has("CollectionEgg"):
		gCollectionEggCount = node_data["CollectionEgg"];
	else:
		gCollectionEggCount = 0;
		
	if node_data.has("Coin"):
		gCoin = node_data["Coin"];
	else:
		gCoin = 0;
		
	for i in node_data["Hen"]:
		var hen:Node = spawnAnimal(gHen, GlobalVariable.getRandomGroundPosition());
		gHenContainer.push_back(hen);
	for i in node_data["Rooster"]:
		var rooster:Node = spawnAnimal(gRooster, GlobalVariable.getRandomGroundPosition());
		gRoosterContainer.push_back(rooster);
	for i in node_data["Chick"]:
		var chick:Node = spawnChick(GlobalVariable.getRandomGroundPosition());
		gChickContainer.push_back(chick);
	for i in node_data["Egg"]:
		var egg:Node = spawnEgg(GlobalVariable.getRandomGroundPosition());
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
	
static func spawn(prefab: PackedScene, pos: Vector3) -> Node:
	Logger.LogDebug("Spawn %s in Pos: %v" % [prefab.resource_path, pos]);
	var instance:Node = prefab.instantiate();
	gManagerNode.add_child(instance);
	instance.position = pos;
		
	return instance;
		
static func spawnAnimal(prefab:PackedScene, pos:Vector3) -> Node:
	var instance:Node = spawn(prefab, pos);
	var animal:Animal = instance as Animal;
	
	# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinLifeTime, GlobalVariable.gMaxLifeTime);
	var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
	var productivity:float = Utility.randomRangeFloat(GlobalVariable.gMinProductivity, GlobalVariable.gMaxProductivity);
	animal.initializeStatus(lifeTime, speed, productivity);
	
	return instance;
		
static func spawnEgg(pos:Vector3) -> Node:
	var instance:Node = spawn(gManagerNode.gEgg, pos);
	
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var egg:Egg = instance as Egg;
	var hatchTime:float = Utility.randomRangeFloat(GlobalVariable.gMinHatchTime, GlobalVariable.gMaxHatchTime);
	egg.initializeStatus(hatchTime);
	
	return instance;
	
static func spawnChick(pos:Vector3) -> Node:
	var instance:Node = spawn(gManagerNode.gChick, pos);
	var chick:Chick = instance as Chick;
	
	# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinEvolutionTime, GlobalVariable.gMaxEvolutionTime);
	var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
	var productivity:float = 0;
	chick.initializeStatus(lifeTime, speed, productivity);
	
	return instance;
	
func _input(event):		
	#if not event is InputEventScreenTouch:
	if event is InputEventMouse == false:
		return;
		
	var mousePosition:Vector2 = event.position;
	if event.is_action_pressed("Click"):
			startPos = mousePosition;
	elif event.is_action_released("Click"):
		curPos = mousePosition;
		if startPos.distance_to(curPos) >= length:
			if curPos.x - startPos.x < 0:
				# Right Swpie
				targetSceneIndex = clampi(targetSceneIndex + 1, 0, gScenePosition.size() - 1);
			else:
				#Left Swipe
				targetSceneIndex = clampi(targetSceneIndex - 1, 0, gScenePosition.size() - 1);
				
			print("Tween: ", gScenePosition[targetSceneIndex]);
			tween = create_tween();
			tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex], gSceneInterpolationTime).set_ease(Tween.EASE_IN);
		else	: #Click
			var result:Node = findEgg(mousePosition);
			if result != null:
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
	
	Logger.LogAssert(gEggContainer.find(node) >= 0, "Spawn되지 않은 Egg의 습득을 시도합니다.");
	gEggContainer.erase(node);
	node.queue_free();

func refreshCoinUI() -> void:
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string:String = "Egg %d $ %d";
	var actual_string:String = format_string % [gCollectionEggCount, gCoin];
	gUIPanel.text = actual_string;

static func onAddAnimal(productivity:float) -> void:
	gTotalProductivity += productivity;
static func onRemoveAnimal(productivity:float) -> void:
	gTotalProductivity -= productivity;
	
static var testEggSpawnTime:float = 15;
static var gEggProductAccumulateTime:float = 0;
func _process(delta: float) -> void:		
	#TODO(Lee): 나중에 경제벨런스 고려해서 잘 수식화 필요
	gEggProductAccumulateTime += delta;
	
	var tempProductivity = log(gTotalProductivity + 1);
	if testEggSpawnTime - (gEggProductAccumulateTime + tempProductivity) < 0:
		var egg:Node = spawnEgg(GlobalVariable.getRandomGroundPosition());
		gEggContainer.push_back(egg);
		
		gEggProductAccumulateTime = 0;
		
static func onEggHatching(egg: Node) -> void:
	Logger.LogAssert(gEggContainer.find(egg) >= 0, "Spawn되지 않았던 Egg의 부화시도.");
	var chick:Node = spawnChick(egg.position);
	gChickContainer.push_back(chick);
	
	gEggContainer.erase(egg);
	egg.queue_free();
	
static func onChickEvolution(chick: Node) -> void:
	Logger.LogAssert(gChickContainer.find(chick) >= 0, "Spawn되지 않았던 Chick의 성장시도.");
	#TODO(Lee): Chick 상태에서부터 암/수 구분할지는 논의 필요
	var isHen:bool = Utility.randomFloat() < 0.5;
	if isHen:
		var hen:Node = spawnAnimal(gManagerNode.gHen, chick.position);
		gHenContainer.push_back(hen);
	else:
		var rooster:Node = spawnAnimal(gManagerNode.gRooster, chick.position);
		gRoosterContainer.push_back(rooster);
		
	gChickContainer.erase(chick);
	chick.queue_free();
