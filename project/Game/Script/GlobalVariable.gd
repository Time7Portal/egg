extends Node
class_name GlobalVariable;

static var gSavePath: String =  "user://saveFile.save";

static var gGroundWitdh: float = 8;
static var gGroundHeight: float = 8;

static var gMaxHatchTime:float = 3600 * 24 * 10;
static var gMinHatchTime:float = 3600 * 24 * 5;
static var gMaxEvolutionTime:float = 3600 * 24 * 5;
static var gMinEvolutionTime:float = 3600 * 24 * 5;
static var gMaxLifeTime:float = 3600 * 24 * 50;
static var gMinLifeTime:float = 3600 * 24 * 7;
static var gMaxProductivity:float = 1;
static var gMinProductivity:float = 0;
static var gMaxSpeed:float = 2.6;
static var gMinSpeed:float = 2.3;

static func getRandomGroundPosition() -> Vector3:
	var randX:float = Utility.randomRangeFloat(-gGroundWitdh, gGroundWitdh);
	var randZ:float = Utility.randomRangeFloat(-gGroundHeight, gGroundWitdh);
	return Vector3(randX, 0, randZ);
