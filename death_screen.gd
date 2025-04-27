extends Control

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var restart_button: Button =  find_child("restart")
@onready var quit_button: Button = find_child("quit")

func _ready() -> void:
	restart_button.pressed.connect(restartLevel)
	quit_button.pressed.connect(quit)
func quit():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func restartLevel():
	get_tree().paused = false
	animator.play("unpause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()
	
func failLevel():
	$PanelContainerDeath.visible = true
	get_tree().paused = true 
	animator.play("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
