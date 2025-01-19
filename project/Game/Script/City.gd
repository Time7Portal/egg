extends Node
class_name City;

@export var _storeUI:Control;

# 도시 클릭하면 상점 표시
func _on_gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed("Click") == true):
		print("city clicked!")
		_storeUI.visible = true;
		
	
