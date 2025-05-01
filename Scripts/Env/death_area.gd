extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).damage(1000000000, Vector3.ZERO)
	if body is Enemy:
		(body as Enemy).dmg(1000000000000000)
