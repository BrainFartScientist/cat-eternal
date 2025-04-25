extends Enemy

@export var damage_delay: float = 1
@export var damage_strength: float = 5
var _damage_timer: float = 0
var _damage_zone_player: Player = null

func _on_damage_zone_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		_damage_zone_player = body

func _on_damage_zone_body_exited(body: Node3D) -> void:
	if body == _damage_zone_player:
		_damage_zone_player = null
		
func _physics_process(delta: float):
	super._physics_process(delta)
	if _damage_timer > 0:
		_damage_timer -= delta
	
	if _damage_timer <= 0 && _damage_zone_player:
		_damage_zone_player.damage(damage_strength, global_transform.origin)
		_damage_timer = damage_delay
