extends Node3D

@export var fall_speed: float = 5.0
@export var damage: int = 100
@export var explosion_radius: float = 3.0

signal wool_spawned(position: Vector3)
signal wool_exploded 

func _ready():
	$ExplosionRadius.monitoring = false
	emit_signal("wool_spawned", global_transform.origin)
	$Timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta):
	translate(Vector3(0, -fall_speed * delta, 0))

func _on_timer_timeout():
	explode()

func explode():
	$ExplosionRadius.monitoring = true
	var bodies = $ExplosionRadius.get_overlapping_bodies()
	for body in bodies:
		if body is Enemy:
			body.take_damage(damage)
	emit_signal("wool_exploded")
	queue_free()
