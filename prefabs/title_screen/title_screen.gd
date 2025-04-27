extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")



func _on_end_pressed() -> void:
	get_tree().quit()


func _on_start_2_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/levels/level2.tscn")
