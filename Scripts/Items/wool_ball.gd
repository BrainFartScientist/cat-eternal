extends Node3D

@export var fall_speed: float = 5.0
@export var damage: int = 100
@export var range: int = 5
@export var explosion_radius: float = 3.0

signal wool_spawned(position: Vector3)
signal wool_exploded 



func _ready():
	$ExplosionRadius.monitoring = false
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.wool_spawned(global_transform.origin)
	$TimerExplosion.timeout.connect(_on_explosion_timeout)
	$TimerParticle.timeout.connect(_on_particle_timeout)


func _physics_process(delta):
	translate(Vector3(0, -fall_speed * delta, 0))

func _process(delta):
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.wool_spawned(global_transform.origin)

func _on_particle_timeout():
	$woolExplosion.emitting = true

func _on_explosion_timeout():
	explode()

func explode():
	$ExplosionRadius.monitoring = true
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		enemy.wool_exploded(damage, range)
	#wwwwwwwwwwwawait get_tree().create_timer(1.2).timeout
	queue_free()
	
