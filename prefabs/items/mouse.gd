extends Collectable

func on_collected(player: Player):
	player.heal(10)
	return true
