class_name Player
extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 0 #2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8




# Bullets (from Watergun)
var bullet = preload("res://prefabs/items/projectile.tscn")
var instanceItem
@onready var gunPoint = $Head/InvisibleGun/InvisibleGun

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var damage_flash_rect = $Control/CanvasLayer/DamageFlesh
@onready var healthbar = $Control/CanvasLayer/HealthBar
@export var damage_flash_time: float = 0.4
@export var max_hp = 100
@export var damage_indicator_scene: PackedScene
var hp = max_hp
var damage_flash_tween: Tween = null
func _ready():
	healthbar.init_health(max_hp)
	previousItemNode = item_selection_overlay.get_node("Panel0") #start the game with the first item selected
	_select_item(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var holdingItem = $Control/CanvasLayer/HoldingItem
	holdingItem.texture = load("res://assets/items/watergun.png")

func heal(amount: float):
	hp += amount
	healthbar.health = hp
		
func damage(dmg: float, source_position):
	hp -= dmg
	healthbar.health = hp
	camera.trigger_shake()
	if damage_flash_tween:
		damage_flash_tween.stop()
		damage_flash_tween = null
	
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color(1, 1, 1, 0.6), damage_flash_time/2.0)
	damage_flash_tween.tween_property($Control/CanvasLayer/DamageFlesh, "modulate", Color.TRANSPARENT, damage_flash_time/2.0)
	
	var indicator = damage_indicator_scene.instantiate()
	indicator.damage_source_position = source_position
	indicator.player = self
	indicator.camera = camera
	$Control/CanvasLayer.add_child(indicator)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)

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
func _physics_process(delta):
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
		instanceItem = bullet.instantiate()
		(instanceItem as Projectile).damage = 10
		instanceItem.position = gunPoint.global_position
		instanceItem.transform.basis = gunPoint.global_transform.basis
		get_parent().add_child(instanceItem)
		
		
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
