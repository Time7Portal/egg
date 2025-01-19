extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 돌아가기 버튼을 누르면 창 감추기
func _on_exit_button_pressed() -> void:
	visible = false;


# 구매 버튼을 누르면 아이템 구매
func _on_buy_button_pressed() -> void:
	pass
