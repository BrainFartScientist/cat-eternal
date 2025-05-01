class_name Player
extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.8
@export var sensitivity = 0.004
@export var gravity = 9.81
@export var bob_freq = 2.4
@export var bob_amp = 0.08
@export var base_fov = 90.0
@export var fov_change = 1.5
@export var bullet_scene: PackedScene
@export var damage_flash_time: float = 0.4
@export var max_hp = 100
@export var damage_indicator_scene: PackedScene
@export var wool_scene: PackedScene
@export var cucumber_scene: PackedScene

@onready var _gun_point = $Head/Camera3D/InvisibleGun/InvisibleGun
@onready var _health_player = $HealthSound
@onready var _gun_player = $GundSound
@onready var _damage_player = $DamagePlayer
@onready var _ground_ray = $GroundRay
@onready var _head = $Head
@onready var _camera = $Head/Camera3D
@onready var _damage_flash_rect = $Control/CanvasLayer/DamageFlesh
@onready var _healthbar = $Control/CanvasLayer/HealthBar
@onready var _item_selection_overlay = $Control/CanvasLayer/PanelContainer/MarginContainer/ItemSelectionOverlay
@onready var _wool_cooldown_timer = $woolCooldown
@onready var _panel_cover_0 = $Control/CanvasLayer/PanelContainer/MarginContainer/ItemSelectionOverlay/Panel0/panel_cover_0
@onready var _cucumber_cooldown_timer = $cucumberCooldown
@onready var _panel_cover_1 = $Control/CanvasLayer/PanelContainer/MarginContainer/ItemSelectionOverlay/Panel1/panel_cover_1
		
var _can_plant_cucumber = true
var _current_item = 0
var _previous_item_node
var _t_bob = 0.0
var _speed
var _sprayCount = 0
var _instance_item
var _step_interval = 0.3
var _step_timer = 0.0
var _hp = max_hp
var _damage_flash_tween: Tween = null
var _cooldown = 0.5 
var _time_since_action = 0.0
var _can_plant_wool = true

const SELECTED_ITEM_BORDER = preload("res://assets/items/selected_item.tres")
const UNSELECTED_ITEM_BORDER = preload("res://assets/items/unselected_item.tres")

const DAMAGE_SOUNDS = [
	preload("res://assets/sounds/meow1.wav"),
	preload("res://assets/sounds/meow2.wav"),
	preload("res://assets/sounds/meow3.wav"),
	preload("res://assets/sounds/meow4.wav"),
]

const FOOTSTEP_SOUNDS = {
	"fur": [
		preload("res://assets/sounds/Carpet_Step1.wav"),
		preload("res://assets/sounds/Carpet_Step2.wav"),
		preload("res://assets/sounds/Carpet_Step3.wav")
	],
	"wood": [
		preload("res://assets/sounds/Wood_Step1.mp3"),
		preload("res://assets/sounds/Wood_Step2.mp3"),
		preload("res://assets/sounds/Wood_Step3.mp3")
	],
	"default": [
		preload("res://assets/sounds/Carpet_Step1.wav"),
		preload("res://assets/sounds/Carpet_Step2.wav"),
		preload("res://assets/sounds/Carpet_Step3.wav")
	]
}

func _ready():
	randomize()
	_healthbar.init_health(max_hp)
	_previous_item_node = _item_selection_overlay.get_node("Panel0") #start the game with the first item selected
	_select_item(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var holdingItem = $Control/CanvasLayer/HoldingItem
	holdingItem.texture = load("res://assets/items/watergun.png")
	_time_since_action = _cooldown
	$woolCooldown.timeout.connect(_on_wool_cooldown_end)
	$cucumberCooldown.timeout.connect(_on_cucumber_cooldown_end)
	

func heal(amount: float):
	_health_player.play()
	_hp += amount
	_healthbar.health = _hp
		
func damage(dmg: float, source_position):
	_hp -= dmg
	_healthbar.health = _hp
	_camera.trigger_shake()
	if _damage_flash_tween:
		_damage_flash_tween.kill()
		_damage_flash_tween = null
	
	if _damage_player and DAMAGE_SOUNDS.size() > 0:
		var random_damage_sound = DAMAGE_SOUNDS[randi() % DAMAGE_SOUNDS.size()]
		_damage_player.stream = random_damage_sound
		_damage_player.pitch_scale = randf_range(0.95, 1.05)
		_damage_player.volume_db =  remap(min(50, dmg), 0, 50, -15, 2)
		_damage_player.play()
	
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color(1, 1, 1, 0.6), damage_flash_time/2.0)
	_damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color.TRANSPARENT, damage_flash_time/2.0)
	
	var indicator = damage_indicator_scene.instantiate()
	indicator.damage_source_position = source_position
	indicator.player = self
	indicator.camera = _camera
	$Control/CanvasLayer.add_child(indicator)
	if _hp <= 0:
		$Control/CanvasLayer/death_menu.failLevel()
		$Control/CanvasLayer.remove_child(indicator)

func get_ground_type() -> String:
	if _ground_ray.is_colliding():
		var collider = _ground_ray.get_collider()
		if collider.has_meta("ground_type"):
			return collider.get_meta("ground_type")
	return "default"

func _unhandled_input(event):	
	#pause menu 
	if event.is_action_pressed("ui_cancel"):
		$pause_menu.pause()
	
	if event is InputEventMouseMotion:
		_head.rotate_y(-event.relative.x * sensitivity)
		_camera.rotate_x(-event.relative.y * sensitivity)
		_camera.rotation.x = clamp(_camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

# UI item selection
	if event is InputEventKey:
		if Input.is_action_just_pressed("selectItem"):
			match event.keycode:
				KEY_1:
					_select_item(0)
				KEY_2:
					_select_item(1)
				KEY_3:
					_select_item(2)
				KEY_4:
					_select_item(3)
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_select_item((_current_item + 1) % 4)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if _current_item == 0:
					_select_item(3)
				else: _select_item((_current_item - 1) % 3)
	
func _process(delta):
	if global_transform.origin.y < -30:
		$Control/CanvasLayer/death_menu.failLevel()

func play_footstep_sound():
	var ground_type = get_ground_type()
	var sounds = FOOTSTEP_SOUNDS.get(ground_type, null)
	if sounds == null:
		return
	if sounds.size() > 0:
		var random_sound = sounds[randi() % sounds.size()]
		$StepPlayer.stream = random_sound
		$StepPlayer.pitch_scale = randf_range(0.95, 1.05)
		$StepPlayer.play()
		if _speed == walk_speed:
			$StepPlayer.volume_db = 6
		else:
			$StepPlayer.volume_db = 10
	
		
func _physics_process(delta):
	if is_on_floor() and velocity.length() > 1.0:
		_step_timer += delta * (velocity.length() / _speed * 0.9)
		if _step_timer >= _step_interval:
			_step_timer = 0
			play_footstep_sound()
	else:
		_step_timer = _step_interval
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		_speed = sprint_speed
	else:
		_speed = walk_speed
	
	if Input.is_action_pressed("action"):
		if _sprayCount <= 2:
			_gun_player.play()
		if _sprayCount < 15:
			_instance_item = bullet_scene.instantiate()
			(_instance_item as Projectile).shoot(1, _gun_point.global_position, _gun_point.global_transform.basis)
			get_parent().add_child(_instance_item)
			_sprayCount += 1
	if _time_since_action > 0.5:
		_time_since_action = 0
		_sprayCount = 0
	_time_since_action += delta
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (_head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * _speed
			velocity.z = direction.z * _speed
		else:
			velocity.x = lerp(velocity.x, direction.x * _speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * _speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * _speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * _speed, delta * 3.0)
	
	# Head bob
	_t_bob += delta * velocity.length() * float(is_on_floor())
	_camera.transform.origin = _headbob(_t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	_camera.fov = lerp(_camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

# Displays the selected item in the UI
func _select_item(selectedItemSlot):
	_previous_item_node.add_theme_stylebox_override("panel", UNSELECTED_ITEM_BORDER)
	_current_item = selectedItemSlot
	var item_node_name = "Panel" + str(selectedItemSlot)
	var item_node = _item_selection_overlay.get_node(item_node_name)
	item_node.add_theme_stylebox_override("panel", SELECTED_ITEM_BORDER)
	_previous_item_node = item_node

func _input(event):
	if event.is_action_pressed("useItem"):
		match _current_item:
			#wool
			0:
				drop_wool()
			1:
				drop_cucumber()

func drop_wool():
	if not wool_scene:
		print("⚠️ No bomb scene assigned!")
		return
	if _can_plant_wool:
		var wool = wool_scene.instantiate()
		wool.name = "wool"  # Optional: makes it easier to find via code

		# Drop the bomb slightly in front of the player
		wool.global_transform.origin = global_transform.origin + Vector3(0, 0, -1)
		get_tree().current_scene.add_child(wool)
		
		_can_plant_wool= false
		_wool_cooldown_timer.start()
		_panel_cover_0.visible = true
		
		
func _on_wool_cooldown_end():
	_can_plant_wool = true
	_panel_cover_0.visible = false

func drop_cucumber():
	if not cucumber_scene:
		print("⚠️ No bomb scene assigned!")
		return
	if _can_plant_cucumber:
		var cucumber = cucumber_scene.instantiate()
		cucumber.name = "cucumber"  # Optional: makes it easier to find via code

		# Drop the bomb slightly in front of the player
		cucumber.global_transform.origin = global_transform.origin + Vector3(0, 0, -1)
		get_tree().current_scene.add_child(cucumber)
		
		_can_plant_cucumber= false
		_cucumber_cooldown_timer.start()
		_panel_cover_1.visible = true
	
func _on_cucumber_cooldown_end():
	_can_plant_cucumber = true
	_panel_cover_1.visible = false
	
