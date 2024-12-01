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
@export var gCameraRelativePosition:Vector3 = Vector3(0, 24, 20);
@export var gSceneInterpolationTime: float = 0.2;

# Singleton
static var gManagerNode:Node;

# Property
static var gFarmArray: Array[Farm];
static var gCollectionEggCount: int = 0;
static var gCoin: int = 0;

# Private
static var tween: Tween;
static var targetSceneIndex: int = 0;

func _ready():
	gManagerNode = self;

	tween = create_tween();
	tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex] + gCameraRelativePosition, 0).set_ease(Tween.EASE_IN);
	
	gFarmArray.resize(gScenePosition.size());
	for index in range(gScenePosition.size()):
		gFarmArray[index] = Farm.new();
		gFarmArray[index]._farmIndex = index;
	
	readSaveFile();
	refreshCoinUI(0);
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
		
	if node_data.has("Farm") and node_data["Farm"].size() == gFarmArray.size():
		for farmIndex in range(gFarmArray.size()):
			gFarmArray[farmIndex].readSaveFile(node_data["Farm"][farmIndex]);
	
func writeSaveFile(initial: bool):
	Logger.LogDebug("Save: %s" % GlobalVariable.gSavePath);
	var file = FileAccess.open(GlobalVariable.gSavePath, FileAccess.WRITE);
	
	var saveData = {
			"CollectionEgg": gCollectionEggCount, 
			"Coin": gCoin,
			"Farm":	[]
		};
	if initial == false:
		for farm in gFarmArray:
			saveData["Farm"].append({"Hen": farm._henContainer.size(), "Rooster": farm._roosterContainer.size(), "Chick": farm._chickContainer.size(), "Egg": farm._eggContainer.size()});
	else:
		for farm in gFarmArray:
			saveData["Farm"].append({"Hen": 1, "Rooster": 1, "Chick": 0, "Egg": 0});

	var saveDataString:String = JSON.stringify(saveData);
	file.store_line(saveDataString);
	file.close();

func refreshCoinUI(value:int) -> void:
	gCollectionEggCount += value;
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string:String = "Egg %d $ %d";
	var actual_string:String = format_string % [gCollectionEggCount, gCoin];
	gUIPanel.text = actual_string;

func _on_left_button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click") == false:
		return;
		
	targetSceneIndex = clampi(targetSceneIndex - 1, 0, gScenePosition.size() - 1);
	tween = create_tween();
	tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex] + gCameraRelativePosition, gSceneInterpolationTime).set_ease(Tween.EASE_IN);

func _on_right_button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click") == false:
		return;
	
	targetSceneIndex = clampi(targetSceneIndex + 1, 0, gScenePosition.size() - 1);
	tween = create_tween();
	tween.tween_property(gCamera, "position", gScenePosition[targetSceneIndex] + gCameraRelativePosition, gSceneInterpolationTime).set_ease(Tween.EASE_IN);

func _on_collect_button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Click") == false:
		return;
		
	refreshCoinUI(gFarmArray[targetSceneIndex]._eggContainer.size());
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
