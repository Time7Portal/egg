extends Node
class_name Farm;

var _henContainer: Array[Node];
var _roosterContainer: Array[Node];
var _chickContainer: Array[Node];
var _eggContainer: Array[Array];

var _farmIndex: int;

# Total Status
var _totalProductivity: float = 0;
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
	var worldPos:Vector3 = pos + Manager.gManagerNode.gScenePosition[_farmIndex];
	Logger.LogDebug("Spawn %s in Pos: %v. Farm: %d" % [prefab.resource_path, worldPos, _farmIndex]);
	var instance:Node = prefab.instantiate();
	Manager.gManagerNode.add_child(instance);
	instance.position = worldPos;
		
	return instance;
		
func spawnAnimal(prefab:PackedScene, pos:Vector3) -> Node:
	var instance:Node = spawn(prefab, pos);
	var animal:Animal = instance as Animal;
	
	# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinLifeTime, GlobalVariable.gMaxLifeTime);
	var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
	var productivity:float = Utility.randomRangeFloat(GlobalVariable.gMinProductivity, GlobalVariable.gMaxProductivity);
	animal._farmIndex = _farmIndex;
	animal.initializeStatus(lifeTime, speed, productivity);
	
	return instance;
		
func spawnEgg(pos:Vector3, grade:Egg.Grade) -> void:
	var instance:Node = spawn(Manager.gManagerNode.gEgg, pos);
	
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var egg:Egg = instance as Egg;
	var hatchTime:float = Utility.randomRangeFloat(GlobalVariable.gMinHatchTime, GlobalVariable.gMaxHatchTime);
	egg._farmIndex = _farmIndex;
	egg._grade = grade;
	egg.initializeStatus(hatchTime);
	
	_eggContainer[int(grade)].push_back(egg);
	
func spawnChick(pos:Vector3) -> Node:
	var instance:Node = spawn(Manager.gManagerNode.gChick, pos);
	var chick:Chick = instance as Chick;
	
	# TODO(Lee): 부모의 Status를 받아서 뽑아올 수 있도록 개선해야함
	# TODO(Lee): SaveFile을 통해서 Spawn되는 경우 데이터를 유지할 필요가 있음
	var lifeTime:float = Utility.randomRangeFloat(GlobalVariable.gMinEvolutionTime, GlobalVariable.gMaxEvolutionTime);
	var speed:float = Utility.randomRangeFloat(GlobalVariable.gMinSpeed, GlobalVariable.gMaxSpeed);
	var productivity:float = 0;
	chick._farmIndex = _farmIndex;
	chick.initializeStatus(lifeTime, speed, productivity);
	
	return instance;
	
func writeSaveFile(initial: bool):	
	var data = {};
	if initial:
		data["Hen"] = 1;
		data["Rooster"] = 1;
		data["Chick"] = 0;
	else:
		data["Hen"] = _henContainer.size();
		data["Rooster"] = _roosterContainer.size();
		data["Chick"] = _chickContainer.size();
	
	data["Egg"] = {};
	var gradeIndex = 0;
	for gradeName in Egg.Grade:
		if gradeIndex == int(Egg.Grade.COUNT):
			continue;

		var eggCount = _eggContainer[gradeIndex].size();
		data["Egg"][gradeName] = eggCount;
		gradeIndex = gradeIndex + 1;
	
	return data;
	
func readSaveFile(node_data):		
	for i in node_data["Hen"]:
		var hen:Node = spawnAnimal(Manager.gManagerNode.gHen, GlobalVariable.getRandomGroundPosition());
		_henContainer.push_back(hen);
	for i in node_data["Rooster"]:
		var rooster:Node = spawnAnimal(Manager.gManagerNode.gRooster, GlobalVariable.getRandomGroundPosition());
		_roosterContainer.push_back(rooster);
	for i in node_data["Chick"]:
		var chick:Node = spawnChick(GlobalVariable.getRandomGroundPosition());
		_chickContainer.push_back(chick);
		
	var eggData = node_data["Egg"];
	var gradeIndex = 0;
	for gradeName in Egg.Grade:
		if gradeIndex == int(Egg.Grade.COUNT):
			continue;

		if gradeName in eggData:
			for i in eggData[gradeName]:
				spawnEgg(GlobalVariable.getRandomGroundPosition(), gradeIndex);
				
		gradeIndex = gradeIndex + 1;

static var testEggSpawnTime:float = 15;
var gEggProductAccumulateTime:float = 0;
func update(delta: float) -> void:		
	#TODO(Lee): 나중에 경제벨런스 고려해서 잘 수식화 필요
	gEggProductAccumulateTime += delta;
	
	var tempEggGrade = Utility.randomRangeInt(0, int(Egg.Grade.COUNT) - 1);
	
	var tempProductivity = log(_totalProductivity + 1);
	if testEggSpawnTime - (gEggProductAccumulateTime + tempProductivity) < 0:
		spawnEgg(GlobalVariable.getRandomGroundPosition(), tempEggGrade);
		gEggProductAccumulateTime = 0;

func clearEgg():
	for eggGroup in _eggContainer:
		for egg in eggGroup:
			egg.queue_free();
		eggGroup.clear();
