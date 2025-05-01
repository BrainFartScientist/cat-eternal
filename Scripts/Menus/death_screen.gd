extends Control

@onready var _animator: AnimationPlayer = $AnimationPlayer
@onready var _restart_button: Button =  find_child("restart")
@onready var _quit_button: Button = find_child("quit")

func _ready() -> void:
	_restart_button.pressed.connect(restartLevel)
	_quit_button.pressed.connect(quit)
func quit():
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")

func restartLevel():
	get_tree().paused = false
	_animator.play("unpause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()
	
func failLevel():
	$PanelContainerDeath.visible = true
	get_tree().paused = true 
	_animator.play("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
