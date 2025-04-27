extends Collectable

func on_collected(player: Player):
	player.heal(25)
	return true
