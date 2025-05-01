class_name Collectable
extends Node3D

@onready var sprite = $Sprite3D

var _camera: Camera3D
var _hover_tween: Tween
var _start_position: Vector3

func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	sprite.rotation.y = rot_y

func _ready():
	_camera = get_viewport().get_camera_3d()
	_start_position = sprite.position
	_hover_tween = create_tween().set_loops()
	_hover_tween.tween_property(sprite, "position:y", _start_position.y + 0.5, 1)
	_hover_tween.tween_property(sprite, "position:y", _start_position.y, 1)
	_hover_tween.play()
	
func _process(delta: float):
	_rotate_to_player()
	
func _on_collected(player: Player):
	return true
	
func _on_hitbox_body_entered(body: Node3D):
	if body.name == "Player":
		if _on_collected(body):
			queue_free()
