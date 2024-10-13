extends Animal
class_name Chick;

func processLifeTime() -> void:
	if _currentLifeTime >= _status._lifeTime:
		Manager.onChickEvolution(self);
