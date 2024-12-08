extends Node3D
class_name Manager

@onready var gTimer: Timer = $Timer;
@onready var gUIPanel: Node = $UI/Money/Label;
@onready var gCamera: Camera3D = $Camera3D;

@export var gHen: PackedScene;
@export var gRooster: PackedScene;
@export var gChick: PackedScene;
@export var gEgg: PackedScene;

@export var gEggDashBoardUIPanel: Array[Label3D];

@export var gScenePosition: Array[Vector3];
@export var gCameraRelativePosition:Vector3 = Vector3(0, 24, 20);
@export var gSceneInterpolationTime: float = 0.2;

# Singleton
static var gManagerNode:Node;

# Property
static var gFarmArray: Array[Farm];
var gCollectionEggCount: Array[int];
static var gCoin: int = 0;

# Private
static var tween: Tween;
static var targetSceneIndex: int = 0;

func _ready():
	gManagerNode = self;
	gCollectionEggCount.resize(int(Egg.Grade.COUNT));

	tween = create_tween();
	tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex] + gCameraRelativePosition, 0).set_ease(Tween.EASE_IN);
	
	gFarmArray.resize(gScenePosition.size());
	for index in range(gScenePosition.size()):
		gFarmArray[index] = Farm.new();
		gFarmArray[index]._eggContainer.resize(int(Egg.Grade.COUNT));
		gFarmArray[index]._farmIndex = index;
	
	readSaveFile();
	refreshCoinUI();
	var gradeIndex = 0;
	for gradeName in Egg.Grade:
		if gradeIndex == int(Egg.Grade.COUNT):
			continue;
		
		refreshEggDashboardUI(gradeIndex);
		gradeIndex += 1;
	
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
		var gradeIndex = 0;
		for gradeName in Egg.Grade:
			if gradeIndex == int(Egg.Grade.COUNT):
				continue;

			gCollectionEggCount[gradeIndex] = int(node_data["CollectionEgg"][gradeIndex]);
			gradeIndex += 1;
	else:
		var gradeIndex = 0;
		for gradeName in Egg.Grade:
			if gradeIndex == int(Egg.Grade.COUNT):
				continue;
			gCollectionEggCount[gradeIndex] = 0;
			gradeIndex += 1;
		
	if node_data.has("Coin"):
		gCoin = node_data["Coin"];
	else:
		gCoin = 0;
		
	if node_data.has("Farm") and node_data["Farm"].size() == gFarmArray.size():
		for farmIndex in range(gFarmArray.size()):
			gFarmArray[farmIndex].readSaveFile(node_data["Farm"][farmIndex]);
	
func writeSaveFile(initial: bool):
	Logger.LogDebug("Save: %s" % GlobalVariable.gSavePath);
	var file = FileAccess.open(GlobalVariable.gSavePath, FileAccess.WRITE);
	
	var saveData = {
			"CollectionEgg": [], 
			"Coin": gCoin,
			"Farm":	[]
		};
		
	var gradeIndex = 0;
	saveData["CollectionEgg"].resize(int(Egg.Grade.COUNT));
	for gradeName in Egg.Grade:
		if gradeIndex == int(Egg.Grade.COUNT):
			continue;
		
		saveData["CollectionEgg"][gradeIndex] = gCollectionEggCount[gradeIndex];
		gradeIndex += 1;
		
	for farm in gFarmArray:
		var data = farm.writeSaveFile(initial);
		saveData["Farm"].append(data);

	var saveDataString:String = JSON.stringify(saveData);
	file.store_line(saveDataString);
	file.close();

func refreshCoinUI() -> void:
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string:String = "$ %d";
	var actual_string:String = format_string % [gCoin];
	gUIPanel.text = actual_string;

func addCollectEggCount(grade, count) -> void:
	gCollectionEggCount[int(grade)] += count;
	refreshEggDashboardUI(grade);
	
func refreshEggDashboardUI(grade) -> void:
	var format_string:String = "%d";
	var actual_string:String = format_string % [gCollectionEggCount[int(grade)]];
	gEggDashBoardUIPanel[int(grade)].text = actual_string;

func _on_collect_button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click") == false:
		return;

	var gradeIndex = 0;
	for container in gFarmArray[targetSceneIndex]._eggContainer:
		addCollectEggCount(gradeIndex, container.size());
		gradeIndex += 1;

	gFarmArray[targetSceneIndex].clearEgg();

static func onAddAnimal(animal:Animal) -> void:
	gFarmArray[animal._farmIndex].onAddAnimal(animal._status._productivity);
static func onRemoveAnimal(animal:Animal) -> void:
	gFarmArray[animal._farmIndex].onRemoveAnimal(animal._status._productivity);
static func onEggHatching(egg: Node) -> void:
	gFarmArray[egg._farmIndex].onEggHatching(egg);
static func onChickEvolution(chick: Node) -> void:
	gFarmArray[chick._farmIndex].onEggHatching(chick);

func _process(delta: float) -> void:
	for farm in gFarmArray:
		farm.update(delta);

var length = 100;
var startPos: Vector2;
var currPos: Vector2;
var swiping: bool = false;
func _input(event):		
	#if not event is InputEventScreenTouch:
	if event is InputEventMouse == false:
		return;
		
	currPos = event.position;
	if event.is_action_pressed("Click"):
		startPos = currPos;
		swiping = true;
	elif event.is_action_released("Click"):
		if startPos.distance_to(currPos) >= length:
			if currPos.x - startPos.x < 0:
				# Right Swipe
				targetSceneIndex = clampi(targetSceneIndex + 1, 0, gScenePosition.size() - 1);
			else:
				#Left Swipe
				targetSceneIndex = clampi(targetSceneIndex - 1, 0, gScenePosition.size() - 1);
			tween = create_tween();
			tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex] + gCameraRelativePosition, gSceneInterpolationTime).set_ease(Tween.EASE_IN);
		swiping = false;
