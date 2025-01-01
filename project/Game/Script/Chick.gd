extends Animal
class_name Chick;

func processLifeTime() -> void:
	if _updateStatus._currentLifeTime >= _status._lifeTime:
		Manager.onChickEvolution(self);
