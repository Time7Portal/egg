extends Node
class_name GlobalVariable;

static var gSavePath: String =  "user://saveFile.save";

static var gGroundWitdh: float = 3;
static var gGroundHeight: float = 5;

static var gMaxLifeTime:float = 3600 * 24 * 50;	# second
static var gMinLifeTime:float = 3600 * 24 * 7;	# second
static var gMaxProductivity:float = 1;
static var gMinProductivity:float = 0;
static var gMaxSpeed:float = 2.6;
static var gMinSpeed:float = 2.3;

static var gHen: PackedScene = preload("res://Game/Hen.tscn");
static var gRooster: PackedScene = preload("res://Game/Rooster.tscn");
static var gChick: PackedScene = preload("res://Game/Chick.tscn");
static var gEgg: PackedScene = preload("res://Game/Egg.tscn");

static var rng:RandomNumberGenerator = RandomNumberGenerator.new();
static func getRandomGroundPosition() -> Vector3:
	var randX:float = rng.randf_range(-gGroundWitdh, gGroundWitdh);
	var randZ:float = rng.randf_range(-gGroundHeight, gGroundWitdh);
	return Vector3(randX, 0, randZ);
