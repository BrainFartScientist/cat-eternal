class_name EnemyBullet
extends Node3D

var _parent_node: Node3D = null

var _direction: Vector3
var _is_shooting = false
var _speed: float = 0
var _damage: float = 0
var last_position: Vector3

func shoot(parent: Node3D, direction: Vector3, speed: float, damage: float):
	_parent_node = parent
	_speed = speed
	_direction = direction
	_damage = damage
	_is_shooting = true
	
func _physics_process(delta: float):
	if _is_shooting:
		if _parent_node:
			last_position = _parent_node.global_position
		global_translate(_direction * _speed * delta)


func _on_hitbox_body_entered(body: Node3D):
	if body.name == "Player":
		if _parent_node:
			(body as Player).damage(_damage, _parent_node.global_position)
		else:
			(body as Player).damage(_damage, last_position)			
	queue_free()
