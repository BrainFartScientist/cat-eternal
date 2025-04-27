class_name Enemy
extends RigidBody3D

@export var preffered_distance: float = 30.0
@export var speed: float = 10.0
@export var vision_cone_angle: float = 60.0
@export var max_hp: float = 100

var hp = max_hp

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $Sprite3D

var _camera: Camera3D
var _player: Node3D
var _last_seen_position: Vector3

var _vision_player: Node3D

var state = "idle"

var hit_tween: Tween = null



func _ready():
	_camera = get_viewport().get_camera_3d()
	var wool = get_tree().get_root().find_child("wool_ball", true, false)
	if wool:
		wool.wool_spawned.connect(_on_wool_spawned)
		wool.wool_exploded.connect(_on_wool_exploded)

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
		# Something is blocking the way
		if result.collider != player:
			return false
	
	# No obstacle, player is visible
	return true
	
func _update_navigation_target():
	if has_wool_target:
		navigation_agent.target_position = wool_position
			
	elif _vision_player:
		var to_player = _vision_player.global_transform.origin - global_transform.origin
		var distance = to_player.length()
			
		if distance > preffered_distance:
			navigation_agent.target_position = _vision_player.global_transform.origin
		else:
			navigation_agent.target_position = global_transform.origin
	elif _last_seen_position:
		navigation_agent.target_position = _last_seen_position
		
	
func _apply_navigation_target():
	if navigation_agent.is_navigation_finished() == false:
		var next_path_point = navigation_agent.get_next_path_position()
		var direction = (next_path_point - global_transform.origin).normalized()
		#direction.y = 0
		apply_central_force(direction * speed)
	
func _rotate_to_player():
	var to_camera = _camera.global_transform.origin - global_transform.origin
	to_camera.y = 0
	
	var rot_y = atan2(to_camera.x, to_camera.z)
	sprite.rotation.y = rot_y

func _update_animation_state():
	var velocity = linear_velocity.length()
	if velocity > 0.5:
		sprite.play("walking")
	else:
		sprite.play("idle")

func _physics_process(delta: float):
	#print(global_transform.origin)
	_update_vision()
	_update_navigation_target()
	_apply_navigation_target()
	_rotate_to_player()
	_update_animation_state()

func dmg(amount: float):
	hp -= amount
	_hit_blink()
	if hp <= 0:
		queue_free()

func _hit_blink():
	if hit_tween && hit_tween.is_running():
		hit_tween.kill()
	hit_tween = create_tween()
	for i in range(2):
		hit_tween.tween_property(sprite, "modulate", Color.RED, 0.07)
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.07)


var wool_position: Vector3
var has_wool_target := false

#walk to the wool ball
func _on_wool_spawned(pos: Vector3):
	wool_position = pos
	var distance_to_wool = global_transform.origin.distance_to(wool_position)
	if distance_to_wool <= preffered_distance:
		has_wool_target = true

func _on_wool_exploded():
	has_wool_target = false
