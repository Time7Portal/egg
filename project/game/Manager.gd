extends Node3D

@onready var camera = $Camera3D

var coin: int = 0;

func _ready():
	#get save file from server? or client?
	pass;
	
func _input(event):
	if event.is_pressed() == false:
		return;
		
	if event is InputEventMouse == false:
		return;
		
	var mousePosition = event.position;
	var result = findEgg(mousePosition);
	if result == null:
		return;
	
	acquireEgg(result.get_parent());

func findEgg(m_pos):
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * 2000
	var world3d : World3D = get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return null;
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if !("collider" in result):
		return null;
	
	return result["collider"]

func acquireEgg(node):
	coin += 1;
	
	#https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var format_string = "$ %d";
	var actual_string = format_string % coin;
	get_node("Money/Label").text = actual_string;
	
	node.queue_free();
