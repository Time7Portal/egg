extends Node
class_name Egg;

@onready var egg: MeshInstance3D = $".";
var _farmIndex:int = 0;
var _currentLifeTime:float = 0;

class Status:
	var _hatchTime:float = 0;
var _status:Status;

enum Grade{
	BRONZE, 
	SILVER, 
	GOLD, 
	PLATINUM, 
	DIAMOND, 
	RAINBOW, 
	COUNT
}
@export var _grade = Grade.BRONZE:
	set(new_grade):
		_grade = new_grade;
		#print("LV." + str(_grade) + " egg spawned!")
		
		# Grade 에 따른 달걀 색상 적용
		var material = egg.get_active_material(0).duplicate();
		
		match _grade:
			Grade.BRONZE:
				material.albedo_color = Color(0.953, 0.796, 0.652);
				egg.set_surface_override_material(0, material)
			Grade.SILVER:
				material.albedo_color = Color(1, 1, 1);
				egg.set_surface_override_material(0, material)
			Grade.GOLD:
				material.albedo_color = Color(1, 1, 0);
				egg.set_surface_override_material(0, material)
			Grade.PLATINUM:
				material.albedo_color = Color(0.299, 0.353, 0.372);
				egg.set_surface_override_material(0, material)
			Grade.DIAMOND:
				material.albedo_color = Color(0.566, 0.732, 0.89);
				egg.set_surface_override_material(0, material)
			Grade.RAINBOW:
				material.albedo_color = Color(1, 0.5, 1);
				egg.set_surface_override_material(0, material)


func initializeStatus(hatchTime:float) -> void:
	_status = Status.new();
	_status._hatchTime = hatchTime;


func _process(delta: float) -> void:
	_currentLifeTime += delta;
	if _currentLifeTime >= _status._hatchTime:
		Manager.onEggHatching(self);
		
