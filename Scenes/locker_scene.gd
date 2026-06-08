#extends Area3D
#
#
#func enter(player):
	##player.enter_locker(self)
	#$".".visible = false   # hide the locker
	## tween camera to marker, fade in overlay, etc.
#
#func exit(player):
	#$".".visible = true    # show it again
	## tween camera back, fade out overlay, etc.

extends Area3D

var player_ref = null

func enter(player):
	player_ref = player
	$".".visible = false
	player.global_position = global_position
	player.global_rotation = global_rotation
	player.is_hiding = true
	player.hide_screen.visible = true

func exit(player):
	$".".visible = true
	player.hide_screen.visible = false
	player.is_hiding = false
	player_ref = null
