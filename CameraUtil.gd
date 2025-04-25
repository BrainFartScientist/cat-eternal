class_name CameraUtil
extends Camera3D

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var shake_strength: float = 0.2

func _process(delta: float):
	if shake_amount > 0:
		shake_amount -= shake_decay * delta
		var random_offset = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength * shake_amount
		global_transform.origin += random_offset
	else:
		shake_amount = 0
		
func trigger_shake():
	shake_amount = 1.0
