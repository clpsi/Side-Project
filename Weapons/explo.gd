extends Bullet

@onready var xplosion = preload("res://Particles/explosion.tscn")

func _init():
	vel = Vector2(100, 100)

func _physics_process(_delta):
	move_and_slide()

func _on_area_2d_body_entered(body):
	if int(str(body.name)) != player_id and body != self:
		var e = xplosion.instantiate()
		get_tree().get_root().add_child(e)
		e.global_position = global_position
		e.emitting = true
		e.get_child(1).emitting = true
		queue_free()

func _on_area_2d_area_entered(area):
	if int(str(area.get_parent().name)) != player_id:
		var e = xplosion.instantiate()
		get_tree().get_root().add_child(e)
		e.global_position = global_position
		e.emitting = true
		e.get_child(1).emitting = true
		if area.get_parent().is_used:
			area.get_parent().global_position = Vector2.ZERO
		queue_free()
