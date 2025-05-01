class_name Projectile
extends Node3D

@export var speed = 15.0
@export var gravity = 9.81

@onready var _sprite = $Sprite3D
@onready var _ray = $RayCast3D
@onready var _animation = $AnimatedSprite3D

var _camera: Camera3D
var _player: Node3D
var _damage = 0
var _gravitation = 1
var _bodyEntered = false
var _velocity

func _ready():
	_camera = get_viewport().get_camera_3d()

func shoot(dmg: float, postion: Vector3, base: Basis):
	_damage = dmg
	position = postion
	transform.basis = base

func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	_sprite.rotation.y = rot_y
		
func _process(delta: float) -> void:
	if (_bodyEntered):
		_velocity = Vector3(0, 0, 0)
	else:
		_velocity = transform.basis * Vector3(0, _gravitation, -speed)	
	position +=  _velocity * delta
	_gravitation -= gravity * delta 
	if _velocity.length() > 0.1:
		_ray.target_position = _velocity.normalized() * 1.0
		
	_ray.force_raycast_update()
	if _ray.is_colliding():
		var collider = _ray.get_collider()
		hit_body(collider)

func _physics_process(delta: float):
	#Gegner verfolgen (auf vertikaler achse)
	_rotate_to_player()
	

func hit_body(body: Node3D):
	if body is Player:
		return
	if body is Enemy && !_bodyEntered:
		(body as Enemy).dmg(_damage)
	_bodyEntered = true
	_animation.play("default")
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	hit_body(body)


func _on_animated_sprite_3d_animation_finished() -> void:
	queue_free()
