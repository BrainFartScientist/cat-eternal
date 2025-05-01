class_name World1
extends Node3D

@export var goal_mesh: MeshInstance3D
var _can_win = false

func _ready() -> void:
	goal_mesh.material_override.albedo_color = Color(1, 0, 0)

func unlock_finish():
	_can_win = true
	goal_mesh.material_override.albedo_color = Color(0, 1, 0)

func _on_winning_area_body_entered(body: Node3D) -> void:
	if body is Player && _can_win:
		get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")
