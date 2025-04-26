extends Enemy

@export var shooting_delay: float = 2
@export var shooting_speed: float = 40
@export var shooting_damage: float = 5

@onready var bullet_point = $Sprite3D/BulletPoint
@export var bullet_scene: PackedScene;

var _can_shoot = false
var _shooting_timer: float = 0

func _physics_process(delta: float):
	super._physics_process(delta)
	
	if _vision_player:
		var to_player = _vision_player.global_transform.origin - global_transform.origin
		var distance = to_player.length()
		if distance <= preffered_distance:
			_can_shoot = true
		else:
			_can_shoot = false
	else:
		_can_shoot = false
	
	if _shooting_timer > 0:
		_shooting_timer -= delta
			
	if _can_shoot && _shooting_timer <= 0:
		_shooting_timer = shooting_delay
		var bullet = (bullet_scene.instantiate() as EnemyBullet)
		get_parent().add_child(bullet)
		bullet.global_position = bullet_point.global_position
		var to_player = _vision_player.global_transform.origin - global_transform.origin
		var distance = to_player.length()
		var player_speed = (_vision_player as Player).velocity
		player_speed.y = 0
		var to_target = (_vision_player.global_transform.origin + Vector3(0, -0.3, 0) + (player_speed * distance * 0.025) - bullet_point.global_transform.origin).normalized()
		bullet.shoot(self ,to_target, shooting_speed, shooting_damage)
		
