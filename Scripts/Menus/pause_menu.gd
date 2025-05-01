extends Control

@onready var _animator: AnimationPlayer = $AnimationPlayer
@onready var _continue_button: Button =  find_child("continue")
@onready var _quit_button: Button = find_child("quit")

func _ready() -> void:
	_continue_button.pressed.connect(resume)
	_quit_button.pressed.connect(quit)
func quit():
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")

func resume():
	get_tree().paused = false
	_animator.play("unpause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func pause():
	get_tree().paused = true 
	_animator.play("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc") and get_tree().paused == true:
		resume()
