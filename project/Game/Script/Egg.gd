extends Node
class_name Egg;

class Status:
	var _hatchTime:float = 0;
	
var _status:Status;

var _currentLifeTime:float = 0;
	
func initializeStatus(hatchTime:float) -> void:
	_status = Status.new();
	_status._hatchTime = hatchTime;

func _process(delta: float) -> void:
	_currentLifeTime += delta;
	if _currentLifeTime >= _status._hatchTime:
		Manager.onEggHatching(self);
