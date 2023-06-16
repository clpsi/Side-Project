extends Weapon

@onready var bullet: PackedScene = load("res://Weapons/explo.tscn")
@onready var cd: Timer = $Cd
var can_shoot: bool = true

@rpc("call_local", "any_peer")
func ability():
	if can_shoot:
		cd.start()
		can_shoot = false
		var instanced_bullet = bullet.instantiate()
		get_parent().level.add_child(instanced_bullet)
		instanced_bullet.global_position = global_position
		instanced_bullet.velocity = instanced_bullet.vel * Vector2(cos(global_rotation), sin(global_rotation))
		instanced_bullet.player_id = player_id

func _on_cd_timeout():
	can_shoot = true
