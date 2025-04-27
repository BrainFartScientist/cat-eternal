extends RangeEnemy

func on_death():
	var current_scene = get_tree().current_scene
	if current_scene is World1:
		(current_scene as World1).unlock_finish()
