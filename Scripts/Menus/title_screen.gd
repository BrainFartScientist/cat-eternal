extends Control

func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level1.tscn")

func _on_start_2_pressed():
	get_tree().change_scene_to_file("res://Scenes/Levels/level2.tscn")


func _on_end_pressed() -> void:
	get_tree().quit()
