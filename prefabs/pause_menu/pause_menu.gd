extends Control

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var continue_button: Button =  find_child("continue")
@onready var quit_button: Button = find_child("quit")

func _ready() -> void:
	continue_button.pressed.connect(resume)
	quit_button.pressed.connect(quit)
func quit():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func resume():
	get_tree().paused = false
	animator.play("unpause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func pause():
	get_tree().paused = true 
	animator.play("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc") and get_tree().paused == true:
		resume()
