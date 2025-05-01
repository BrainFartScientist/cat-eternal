extends TextureRect

var damage_source_position: Vector3
var player: Node
var camera: Camera3D
var duration = 1.5
var timer = 1

@onready var viewport_size = get_viewport().size

func _ready():
	modulate.a = 1.0
	set_as_top_level(true) # Very important! Otherwise it gets moved with the parent Control layout.

func _process(delta):
	if player and camera:
		update_rotation_and_position()

	timer -= delta
	modulate.a = timer / duration
	
	if timer <= 0:
		queue_free()

func update_rotation_and_position():
	var player_to_source = (damage_source_position - player.global_transform.origin).normalized()
	var camera_basis = camera.global_transform.basis
	var camera_forward = -camera_basis.z
	var camera_right = camera_basis.x

	var forward_dot = camera_forward.dot(player_to_source)
	var right_dot = camera_right.dot(player_to_source)

	var angle = atan2(right_dot, forward_dot)
	rotation = angle

	# Place indicator on the edge of a circle
	var radius = min(viewport_size.x, viewport_size.y) * 0.4
	var center = viewport_size / 2.0

	var offset = Vector2(sin(angle), -cos(angle)) * radius
	position = center + offset - (size / 2.0)
