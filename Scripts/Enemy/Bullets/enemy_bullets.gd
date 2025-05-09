class_name EnemyBullet
extends Node3D

@onready var _raycast = $RayCast3D

var _parent_node: Node3D = null

var _direction: Vector3
var _is_shooting = false
var _speed: float = 0
var _damage: float = 0
var _last_position: Vector3

func shoot(parent: Node3D, direction: Vector3, speed: float, damage: float):
	_parent_node = parent
	_speed = speed
	_direction = direction
	_damage = damage
	_is_shooting = true
	
func _physics_process(delta: float):
	if _is_shooting:
		if _parent_node:
			_last_position = _parent_node.global_position
		var velocity = _direction * _speed
		global_translate(velocity * delta)
		if velocity.length() > 0.1:
			_raycast.target_position = velocity.normalized() * 1.0
			
		_raycast.force_raycast_update()
		if _raycast.is_colliding():
			var collider = _raycast.get_collider()
			_on_hit_body(collider)

func _on_hit_body(body: Node3D):
	if body is Enemy:
		return
	
	if body is Player:
		if _parent_node:
			(body as Player).damage(_damage, _parent_node.global_position)
		else:
			(body as Player).damage(_damage, _last_position)			
	queue_free()
	

func _on_hitbox_body_entered(body: Node3D):
	_on_hit_body(body)
