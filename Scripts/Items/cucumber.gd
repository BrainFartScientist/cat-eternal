extends RigidBody3D

@export var fall_speed: float = 5.0
@export var damage: int = 100
@export var range: int = 5
var avoid_radius = 10.0




func _ready():
	$TimerExists.timeout.connect(_on_exists_timeout)
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.cucumber_spawned(global_transform.origin)

func _process(delta):
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.cucumber_spawned(global_transform.origin)

func _physics_process(delta):
	translate(Vector3(0, -fall_speed * delta, 0))

func _on_exists_timeout():
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.cucumber_despawned()
	queue_free()

	
