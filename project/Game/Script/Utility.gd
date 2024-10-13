extends Node
class_name Utility;

static var RNG = RandomNumberGenerator.new();

static func randomRangeFloat(rangeMin:float, rangeMax:float) -> float:
	return RNG.randf_range(rangeMin, rangeMax);
	
static func randomFloat() -> float:
	return RNG.randf();
