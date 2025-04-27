class_name Projectile
extends Node3D
var _camera: Camera3D
var _player: Node3D
const SPEED = 15.0
const GRAVITY = 9.81
var gravitation = 1
@onready var sprite = $Sprite3D
@onready var ray = $RayCast3D
var damage = 0

func _ready():
	_camera = get_viewport().get_camera_3d()

func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	sprite.rotation.y = rot_y
		
func _process(delta: float) -> void:
	position += transform.basis * Vector3(0, gravitation, -SPEED) * delta
	gravitation -= GRAVITY * delta 

func _physics_process(delta: float):
	#Gegner verfolgen (auf vertikaler achse)
	_rotate_to_player()
	


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Enemy:
		(body as Enemy).dmg(damage)
	queue_free()
