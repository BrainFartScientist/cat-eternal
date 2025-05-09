class_name Enemy
extends RigidBody3D

@export var preffered_distance: float = 30.0
@export var speed: float = 10.0
@export var vision_cone_angle: float = 60.0
@export var max_hp: float = 100
@export var wool_target_range: int = 20
@export var wool_explosion_range: int = 5
@export var avoidance_radius = 5

@onready var _hp = max_hp
@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _sprite: AnimatedSprite3D = $Sprite3D

var _camera: Camera3D
var _player: Node3D
var _last_seen_position: Vector3
var _vision_player: Node3D
var _state = "idle"
var _hit_tween: Tween = null
var _custom_animation = null
var _cucumber_position: Vector3
var _has_cucumber_target = false

func _ready():
	_camera = get_viewport().get_camera_3d()

func _on_body_entered(body):
	if body.name == "Player":
		_player = body
		
func _on_body_exited(body):
	if body == _player:
		_player = null

func _on_vision_entered(player):
	_vision_player = player

func _on_vision_left():
	_last_seen_position = _vision_player.global_transform.origin
	_vision_player = null

func _update_vision():
	if !_player && _vision_player:
		_on_vision_left()
		return
	if !_player:
		return
	var in_vision = _player_in_vision(_player)
	if in_vision && !_vision_player:
		_on_vision_entered(_player)
	elif !in_vision && _vision_player:
		_on_vision_left()
		
func _player_in_vision(player):
	var start = global_transform.origin + Vector3(0, 0.5, 0)
	var end = player.global_transform.origin
	
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = start
	params.to = end
	params.exclude = [self]

	params.collision_mask = 1
	var result = space_state.intersect_ray(params)
	
	if result:
		if result.collider != player:
			return false
	return true


func _update_navigation_target():
	if _has_cucumber_target:
		var distance_to_item = global_position.distance_to(_cucumber_position)
		if distance_to_item < avoidance_radius:
			var direction_away_from_cucumber = global_position - _cucumber_position
			direction_away_from_cucumber = direction_away_from_cucumber.normalized()  # Normalisieren
			var new_target_position = global_position + direction_away_from_cucumber * 5.0  # Bewege den Gegner weg
			_navigation_agent.target_position = new_target_position 
		
	elif has_wool_target:
		_navigation_agent.target_position = wool_position
			
	elif _vision_player:
		var to_player = _vision_player.global_transform.origin - global_transform.origin
		var distance = to_player.length()
			
		if distance > preffered_distance:
			_navigation_agent.target_position = _vision_player.global_transform.origin
		else:
			_navigation_agent.target_position = global_transform.origin
	elif _last_seen_position:
		_navigation_agent.target_position = _last_seen_position
		
	
func _apply_navigation_target():
	if !_is_grounded():
		return
	if _navigation_agent.is_navigation_finished() == false:
		var next_path_point = _navigation_agent.get_next_path_position()
		var direction = (next_path_point - global_transform.origin).normalized()
		#direction.y = 0
		apply_central_force(direction * speed)
	
func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	_sprite.rotation.y = rot_y

func _update_animation_state():
	if _custom_animation:
		_sprite.play(_custom_animation)
		return
		
	var velocity = linear_velocity.length()
	if velocity > 0.5:
		_sprite.play("walking")
	else:
		_sprite.play("idle")

func _physics_process(delta: float):
	#print(global_transform.origin)
	_update_vision()
	_update_navigation_target()
	_apply_navigation_target()
	_rotate_to_player()
	_update_animation_state()

func dmg(amount: float):
	_hp -= amount
	_hit_blink()
	if _hp <= 0:
		_on_death()
		queue_free()

func _on_death():
	pass

func _is_grounded() -> bool:
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	
	var start = global_transform.origin + Vector3.UP * 0.2
	var end = start + Vector3.DOWN * 1.0
	
	params.from = start
	params.to = end
	params.exclude = [self]
	params.collision_mask = 1
	
	var result = space_state.intersect_ray(params)
	
	if result and result.has("collider"):
		return true
	else:
		return false

func _hit_blink():
	if _hit_tween && _hit_tween.is_running():
		_hit_tween.kill()
	_hit_tween = create_tween()
	for i in range(2):
		_hit_tween.tween_property(_sprite, "modulate", Color.RED, 0.07)
		_hit_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.07)


var wool_position: Vector3
var has_wool_target := false

#walk to the wool ball
func wool_spawned(pos: Vector3):
	wool_position = pos
	var distance_to_wool = global_transform.origin.distance_to(wool_position)
	if distance_to_wool <= wool_target_range:
		has_wool_target = true

func wool_exploded(damage, range):
	has_wool_target = false
	var distance_to_wool = global_transform.origin.distance_to(wool_position)
	if distance_to_wool <= range:
		dmg(damage)
		
func _cucumber_spawned(pos: Vector3):
	_cucumber_position = pos
	var distance_to_cucumber = global_transform.origin.distance_to(_cucumber_position)
	if distance_to_cucumber <= avoidance_radius:
		_has_cucumber_target = true
	
func _cucumber_despawned():
	_has_cucumber_target = false

func _on_sprite_3d_animation_finished() -> void:
	_on_animation_finished()
	
func _on_animation_finished():
	pass
