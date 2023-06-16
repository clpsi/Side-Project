extends Bullet

@onready var timer: Timer = $Timer
var bounces: int = 0

func _init():
	vel = Vector2(500, 500)

func _physics_process(delta):
	if bounces > 11:
		queue_free()
	var collision: = move_and_collide(velocity * delta)
	if collision:
		# assume collider is tilemap object
		var tilemap: TileMap = collision.get_collider()
		var pos = collision.get_position() + (collision.get_normal() * 8) #half of the tilesize
		pos = tilemap.local_to_map(pos)
		velocity = velocity.bounce(collision.get_normal())
		bounces += 1
		timer.start()
