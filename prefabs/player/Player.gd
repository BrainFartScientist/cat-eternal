class_name Player
extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.81
var sprayCount = 0




# Bullets (from Watergun)
var bullet = preload("res://prefabs/items/projectile.tscn")
var instanceItem
@onready var gunPoint = $Head/Camera3D/InvisibleGun/InvisibleGun
@onready var health_player = $HealthSound
@onready var gun_player = $GundSound
@onready var damage_player = $DamagePlayer
@onready var ground_ray = $GroundRay
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var damage_flash_rect = $Control/CanvasLayer/DamageFlesh
@onready var healthbar = $Control/CanvasLayer/HealthBar
@export var damage_flash_time: float = 0.4
@export var max_hp = 100
@export var damage_indicator_scene: PackedScene

var damage_sounds = [
	preload("res://assets/sounds/meow1.wav"),
	preload("res://assets/sounds/meow2.wav"),
	preload("res://assets/sounds/meow3.wav"),
	preload("res://assets/sounds/meow4.wav"),
]

var footstep_sounds = {
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

var step_interval = 0.3
var step_timer = 0.0

var hp = max_hp
var damage_flash_tween: Tween = null
var cooldown = 0.5  # Sekunden
var time_since_action = 0.0

func _ready():
	randomize()
	healthbar.init_health(max_hp)
	previousItemNode = item_selection_overlay.get_node("Panel0") #start the game with the first item selected
	_select_item(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var holdingItem = $Control/CanvasLayer/HoldingItem
	holdingItem.texture = load("res://assets/items/watergun.png")
	time_since_action = cooldown
	$woolCooldown.timeout.connect(_on_wool_cooldown_end)
	$cucumberCooldown.timeout.connect(_on_cucumber_cooldown_end)

func heal(amount: float):
	health_player.play()
	hp += amount
	healthbar.health = hp
		
func damage(dmg: float, source_position):
	hp -= dmg
	healthbar.health = hp
	camera.trigger_shake()
	if damage_flash_tween:
		damage_flash_tween.stop()
		damage_flash_tween = null
	
	if damage_player and damage_sounds.size() > 0:
		var random_damage_sound = damage_sounds[randi() % damage_sounds.size()]
		damage_player.stream = random_damage_sound
		damage_player.pitch_scale = randf_range(0.95, 1.05)
		damage_player.volume_db =  remap(dmg, 0, 50, -15, 2)
		damage_player.play()
	
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color(1, 1, 1, 0.6), damage_flash_time/2.0)
	damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color.TRANSPARENT, damage_flash_time/2.0)
	
	var indicator = damage_indicator_scene.instantiate()
	indicator.damage_source_position = source_position
	indicator.player = self
	indicator.camera = camera
	$Control/CanvasLayer.add_child(indicator)
	if hp <= 0:
		$Control/CanvasLayer/death_menu.failLevel()
		$Control/CanvasLayer.remove_child(indicator)

func get_ground_type() -> String:
	if ground_ray.is_colliding():
		var collider = ground_ray.get_collider()
		if collider.has_meta("ground_type"):
			return collider.get_meta("ground_type")
	return "default"

func _unhandled_input(event):	
	#pause menu 
	if event.is_action_pressed("ui_cancel"):
		$pause_menu.pause()
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))


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
				_select_item((currentItem + 1) % 4)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if currentItem == 0:
					_select_item(3)
				else: _select_item((currentItem - 1) % 3)
	
func _process(delta):
	if global_transform.origin.y < -30:
		$Control/CanvasLayer/death_menu.failLevel()

func play_footstep_sound():
	var ground_type = get_ground_type()
	var sounds = footstep_sounds.get(ground_type, null)
	if sounds == null:
		return
	if sounds.size() > 0:
		var random_sound = sounds[randi() % sounds.size()]
		$StepPlayer.stream = random_sound
		$StepPlayer.pitch_scale = randf_range(0.95, 1.05)
		$StepPlayer.play()
		if speed == WALK_SPEED:
			$StepPlayer.volume_db = 6
		else:
			$StepPlayer.volume_db = 10
	
		
func _physics_process(delta):
	if is_on_floor() and velocity.length() > 1.0:
		step_timer += delta * (velocity.length() / speed * 0.9)
		if step_timer >= step_interval:
			step_timer = 0
			play_footstep_sound()
	else:
		step_timer = step_interval
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	if Input.is_action_pressed("action"):
		if sprayCount <= 2:
			gun_player.play()
		if sprayCount < 15:
			instanceItem = bullet.instantiate()
			(instanceItem as Projectile).damage = 1
			instanceItem.position = gunPoint.global_position
			instanceItem.transform.basis = gunPoint.global_transform.basis
			get_parent().add_child(instanceItem)
			sprayCount += 1
			# PUT ANIMATION HERE
		# NOT HERE
	if time_since_action > 0.5:
		time_since_action = 0
		sprayCount = 0
	time_since_action += delta
	
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


@onready var item_selection_overlay = $Control/CanvasLayer/PanelContainer/MarginContainer/ItemSelectionOverlay

const SELECTED_ITEM_BORDER = preload("res://assets/items/selected_item.tres")
const UNSELECTED_ITEM_BORDER = preload("res://assets/items/unselected_item.tres")
#var itemInventory = [wollbombe, wollbombe, wollbombe, wollbombe]
var currentItem = 0
var previousItemNode

# Displays the selected item in the UI
func _select_item(selectedItemSlot):
	previousItemNode.add_theme_stylebox_override("panel", UNSELECTED_ITEM_BORDER)
	currentItem = selectedItemSlot
	var item_node_name = "Panel" + str(selectedItemSlot)
	var item_node = item_selection_overlay.get_node(item_node_name)
	item_node.add_theme_stylebox_override("panel", SELECTED_ITEM_BORDER)
	previousItemNode = item_node

func _input(event):
	if event.is_action_pressed("useItem"):
		match currentItem:
			#wool
			0:
				drop_wool()
			1:
				drop_cucumber()

@export var wool_scene: PackedScene
var can_plant_wool = true
@onready var wool_cooldown_timer = $woolCooldown

func drop_wool():
	if not wool_scene:
		print("⚠️ No bomb scene assigned!")
		return
	if can_plant_wool:
		var wool = wool_scene.instantiate()
		wool.name = "wool"  # Optional: makes it easier to find via code

		# Drop the bomb slightly in front of the player
		wool.global_transform.origin = global_transform.origin + Vector3(0, 0, -1)
		get_tree().current_scene.add_child(wool)
		
		can_plant_wool= false
		wool_cooldown_timer.start()
		
func _on_wool_cooldown_end():
	can_plant_wool = true
		
@export var cucumber_scene: PackedScene
var can_plant_cucumber = true
@onready var cucumber_cooldown_timer = $cucumberCooldown
func drop_cucumber():
	if not cucumber_scene:
		print("⚠️ No bomb scene assigned!")
		return
	if can_plant_cucumber:
		var cucumber = cucumber_scene.instantiate()
		cucumber.name = "cucumber"  # Optional: makes it easier to find via code

		# Drop the bomb slightly in front of the player
		cucumber.global_transform.origin = global_transform.origin + Vector3(0, 0, -1)
		get_tree().current_scene.add_child(cucumber)
		
		can_plant_cucumber= false
		cucumber_cooldown_timer.start()
	
func _on_cucumber_cooldown_end():
	can_plant_cucumber = true
	
