class_name Projectile
extends Node3D
var _camera: Camera3D
var _player: Node3D
const SPEED = 15.0
const GRAVITY = 9.81
var gravitation = 1
var bodyEntered = false
var velocity
@onready var sprite = $Sprite3D
@onready var ray = $RayCast3D
@onready var animation = $AnimatedSprite3D
var damage = 0

func _ready():
	_camera = get_viewport().get_camera_3d()
	 

func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	sprite.rotation.y = rot_y
		
func _process(delta: float) -> void:
	if (bodyEntered):
		velocity = Vector3(0, 0, 0)
	else:
		velocity = transform.basis * Vector3(0, gravitation, -SPEED)	
	position +=  velocity * delta
	gravitation -= GRAVITY * delta 
	if velocity.length() > 0.1:
		ray.target_position = velocity.normalized() * 1.0
		
	ray.force_raycast_update()
	if ray.is_colliding():
		var collider = ray.get_collider()
		hit_body(collider)

func _physics_process(delta: float):
	#Gegner verfolgen (auf vertikaler achse)
	_rotate_to_player()
	

func hit_body(body: Node3D):
	if body is Player:
		return
	if body is Enemy:
		(body as Enemy).dmg(damage)
	bodyEntered = true
	animation.play("default")
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	hit_body(body)


func _on_animated_sprite_3d_animation_finished() -> void:
	queue_free()
