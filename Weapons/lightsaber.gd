extends Weapon

@onready var sparkles = preload("res://Particles/spread.tscn")

func ability():
	#dash
	pass

func _on_area_2d_body_entered(body):
	var e = sparkles.instantiate()
	get_tree().get_root().add_child(e)
	e.global_position = body.global_position
	e.emitting = true
	if is_used:
		var y = round(cos(global_rotation))
		if abs(y) == 1:
			if abs(body.velocity.y) < 70:
				body.velocity.x *= -1
			else:
				body.velocity.y *= -1
		else:
			if abs(body.velocity.x) < 70:
				body.velocity.y *= -1
			else:
				body.velocity.x *= -1
