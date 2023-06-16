extends Bullet


func _init():
	vel = Vector2(300, 300)

func _physics_process(_delta):
	move_and_slide()

func _on_area_2d_body_entered(_body):
	queue_free()
