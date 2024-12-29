extends Node
class_name City;

@export var _storeUI:Control;

func _on_gui_input(event: InputEvent) -> void:	
	if(event.is_action_pressed("Click") == false):
		return;
		
	if(Manager.targetSceneIndex != 1):
		return;
		
	_storeUI.visible = true;
