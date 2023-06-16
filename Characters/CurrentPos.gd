extends Node2D

@export var step_target: Node2D
@export var step_distance: float = 3.0

func _physics_process(_delta):
	if abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()

func step():
	var target_pos = step_target.global_position
	var half_way = (global_position + step_target.global_position)/2
	
	var t = get_tree().create_tween()
	#t.tween_property(self, "global_position", half_way + owner.y, 0.1)
	t.tween_property(self, "global_position", target_pos, 0.1)
