extends RayCast2D

@export var step_target: Node2D


func _process(_delta):
	var hit_point = get_collision_point()
	if hit_point:
		step_target.global_position = hit_point
