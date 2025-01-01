extends Node
class_name Farm;

#region Information
var _farmIndex: int;

var _henContainer: Array[Node];
var _roosterContainer: Array[Node];
var _chickContainer: Array[Node];
var _eggContainer: Array[Array];
var _poopContainer: Array[Node];
#endregion

#region TotalStatus
var _totalProductivity: float = 0;
#endregion

func onAddAnimal(productivity:float) -> void:
	_totalProductivity += productivity;
func onRemoveAnimal(productivity:float) -> void:
	_totalProductivity -= productivity;
func onEggHatching(egg: Node) -> void:
	Logger.LogAssert(_eggContainer[int(egg._grade)].find(egg) >= 0, "Spawn되지 않았던 Egg의 부화시도.");
	var chick:Node = spawnChick(egg.position);
	_chickContainer.push_back(chick);
	
	_eggContainer[int(egg._grade)].erase(egg);
	egg.queue_free();
func onChickEvolution(chick: Node) -> void:
	Logger.LogAssert(_chickContainer.find(chick) >= 0, "Spawn되지 않았던 Chick의 성장시도.");
	#TODO(Lee): Chick 상태에서부터 암/수 구분할지는 논의 필요
	var isHen:bool = Utility.randomFloat() < 0.5;
	if isHen:
		var hen:Node = spawnAnimal(Manager.gManagerNode.gHen, chick.position);
		_henContainer.push_back(hen);
	else:
		var rooster:Node = spawnAnimal(Manager.gManagerNode.gRooster, chick.position);
		_roosterContainer.push_back(rooster);
		
	_chickContainer.erase(chick);
	chick.queue_free();
	
func spawn(prefab: PackedScene, pos: Vector3) -> Node:
	var worldPos:Vector3 = pos;
	#Logger.LogDebug("Spawn %s in Pos: %v. Farm: %d" % [prefab.resource_path, worldPos, _farmIndex]);
	var instance:Node = prefab.instantiate();
	Manager.gManagerNode.add_child(instance);
	instance.position = worldPos;
		
	return instance;
func spawnAnimal(prefab:PackedScene, pos:Vector3, init:bool = true) -> Node:
	var instance:Node = spawn(prefab, pos);
	var animal:Animal = instance as Animal;
	animal._farmIndex = _farmIndex;
	
	if init:
		# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
		var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinLifeTime, GlobalVariable.gMaxLifeTime);
		var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
		var productivity:float = Utility.randomRangeFloat(GlobalVariable.gMinProductivity, GlobalVariable.gMaxProductivity);
		animal.initializeStatus(lifeTime, speed, productivity);
	
	return instance;	
func spawnEgg(pos:Vector3, grade:Egg.Grade, init:bool = true) -> Egg:
	var instance:Node = spawn(Manager.gManagerNode.gEgg, pos);
	var egg:Egg = instance as Egg;
	egg._farmIndex = _farmIndex;
	egg._grade = grade;

	if init:
		# TODO(Lee): 부화시간 기획 필요
		var hatchTime:float = Utility.randomRangeFloat(GlobalVariable.gMinHatchTime, GlobalVariable.gMaxHatchTime);
		egg.initializeStatus(hatchTime);
	
	_eggContainer[int(grade)].push_back(egg);

	return egg;
func spawnChick(pos:Vector3, init:bool = true) -> Node:
	var instance:Node = spawn(Manager.gManagerNode.gChick, pos);
	var chick:Chick = instance as Chick;
	chick._farmIndex = _farmIndex;
	
	if init:
		# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
		var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinEvolutionTime, GlobalVariable.gMaxEvolutionTime);
		var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
		var productivity:float = 0;
		chick.initializeStatus(lifeTime, speed, productivity);
	
	return instance;
func onAddPoop(pos:Vector3) -> Node:
	var instance:Node = spawn(Manager.gManagerNode.gPoop, pos);
	_poopContainer.push_back(instance);
	return instance;

func writeSaveFile():	
	var saveData = {};
	saveData["Hen"] = [];
	for animal in _henContainer:
		var data = JsonClassConverter.class_to_json(animal);
		saveData["Hen"].append(data);

	saveData["Rooster"] = [];
	for animal in _roosterContainer:
		var data = JsonClassConverter.class_to_json(animal);
		saveData["Rooster"].append(data);

	saveData["Chick"] = [];
	for animal in _chickContainer:
		var data = JsonClassConverter.class_to_json(animal);
		saveData["Chick"].append(data);
	
	saveData["Egg"] = {};
	var gradeIndex = 0;
	for gradeName in Egg.Grade:
		if gradeIndex == int(Egg.Grade.COUNT):
			continue;

		saveData["Egg"][gradeName] = [];
		for egg in _eggContainer[gradeIndex]:
			var data = JsonClassConverter.class_to_json(egg);
			saveData["Egg"][gradeName].append(data);

		gradeIndex = gradeIndex + 1;

	saveData["Poop"] = _poopContainer.size();
	
	return saveData;
	
func readSaveFile(node_data):
	if(node_data.has("Hen")):
		for data in node_data["Hen"]:
			var hen:Node = spawnAnimal(Manager.gManagerNode.gHen, GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex], false);
			hen._status = JsonClassConverter.json_to_class(Animal.Status, data["_status"]);
			hen._updateStatus = JsonClassConverter.json_to_class(Animal.UpdateStatus, data["_updateStatus"]);
			_henContainer.push_back(hen);

	if(node_data.has("Rooster")):
		for data in node_data["Rooster"]:
			var rooster:Node = spawnAnimal(Manager.gManagerNode.gRooster, GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex], false);
			rooster._status = JsonClassConverter.json_to_class(Animal.Status, data["_status"]);
			rooster._updateStatus = JsonClassConverter.json_to_class(Animal.UpdateStatus, data["_updateStatus"]);
			_roosterContainer.push_back(rooster);
	
	if(node_data.has("Chick")):
		for data in node_data["Chick"]:
			var chick:Node = spawnChick(GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex], false);
			chick._status = JsonClassConverter.json_to_class(Animal.Status, data["_status"]);
			chick._updateStatus = JsonClassConverter.json_to_class(Animal.UpdateStatus, data["_updateStatus"]);
			_chickContainer.push_back(chick);
	
	if(node_data.has("Poop")):
		for i in node_data["Poop"]:
			var poop:Node = onAddPoop(GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex]);
			_poopContainer.push_back(poop);
		
	if(node_data.has("Egg")):
		var totalEggData = node_data["Egg"];
		var gradeIndex = 0;
		for gradeName in Egg.Grade:
			if gradeIndex == int(Egg.Grade.COUNT):
				continue;

			if gradeName in totalEggData:
				for eggData in totalEggData[gradeName]:
					var egg = spawnEgg(GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex], gradeIndex, false);
					egg._status = JsonClassConverter.json_to_class(Egg.Status, eggData["_status"]);
					egg._updateStatus = JsonClassConverter.json_to_class(Egg.UpdateStatus, eggData["_updateStatus"]);
				
			gradeIndex = gradeIndex + 1;

func initializeFarm():
	Logger.LogAssert(_henContainer.size() == 0, "농장이 비어 있지 않은데, 농장 초기화 호출!!!");
	Logger.LogAssert(_roosterContainer.size() == 0, "농장이 비어 있지 않은데, 농장 초기화 호출!!!");
	Logger.LogAssert(_chickContainer.size() == 0, "농장이 비어 있지 않은데, 농장 초기화 호출!!!");
	Logger.LogAssert(_poopContainer.size() == 0, "농장이 비어 있지 않은데, 농장 초기화 호출!!!");
	#Logger.LogAssert(_eggContainer.size() == 0, "농장이 비어 있지 않은데, 농장 초기화 호출!!!");
	var hen:Node = spawnAnimal(Manager.gManagerNode.gHen, GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex]);
	_henContainer.push_back(hen);
	var rooster:Node = spawnAnimal(Manager.gManagerNode.gRooster, GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex]);
	_roosterContainer.push_back(rooster);

static var testEggSpawnTime:float = 15;
var gEggProductAccumulateTime:float = 0;
func update(delta: float) -> void:		
	#TODO(Lee): 나중에 경제벨런스 고려해서 잘 수식화 필요
	gEggProductAccumulateTime += delta;
	
	var tempEggGrade = Utility.randomRangeInt(0, int(Egg.Grade.COUNT) - 1);
	
	var tempProductivity = log(_totalProductivity + 1);
	if testEggSpawnTime - (gEggProductAccumulateTime + tempProductivity) < 0:
		spawnEgg(GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex], tempEggGrade);
		gEggProductAccumulateTime = 0;

func clearEgg():
	for eggGroup in _eggContainer:
		for egg in eggGroup:
			egg.queue_free();
		eggGroup.clear();

func clearPoop():
	for poop in _poopContainer:
		poop.queue_free();
	_poopContainer.clear();
