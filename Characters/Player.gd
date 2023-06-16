extends CharacterBody2D

@export var speed = 300.0
@export var jump_speed = -450
@export var ang_speed = 3.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stuck: Area2D = $stuck
@onready var l = $L
@onready var r = $R
@onready var hook: RayCast2D = $hook
@onready var mesh: Polygon2D = $hook/Polygon2D
@onready var cam: Camera2D = $Camera
@onready var server = get_parent()
@onready var steps: GPUParticles2D = $implosion

var level
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var item
var animation_locked: bool = false
var direction: float
var org_zoom: Vector2 = Vector2(1.0, 1.0)
var max_zoom: Vector2 =  Vector2(0.5, 0.5)
var swinged: bool = false
var stahp: bool = false
var aim_pos: Vector2 = Vector2.ZERO
var aim_radius: float = 0.0
var ax: float = 0.0
var ay: float = 0.0
var angle: float = 0.0
var Zentripetalforce: Vector2 = Vector2.ZERO
var item_pivot: Vector2 = Vector2(12, 0)
var _new_pos: Vector2

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	steps.emitting = true
	if not is_multiplayer_authority(): return
	cam.make_current()

func _input(event):
	if not is_multiplayer_authority(): return
	if item:
		item.look_at(get_global_mouse_position())
		server.item_rotation.rpc(item.get_path(), item.rotation)
		if event.is_action_pressed("Left_Click"):
			item.ability.rpc()
	if event.is_action_pressed("Right_Click"):
		hook.rotation = 0
		hook.look_at(get_global_mouse_position())
		await get_tree().process_frame 
		hooking()
	elif event.is_action_released("Right_Click") and swinged:
		stahp = false
		swinged = false
		mesh.visible = false

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if Input.is_action_pressed("Right_Click") and swinged:
		swing(delta)
	else:
		cam.zoom = cam.zoom.lerp(org_zoom, delta)
		var x = round(sin(global_rotation))
		var y = round(cos(global_rotation))
		if is_on_floor() or is_on_ceiling() or is_on_wall():
			Zentripetalforce = Vector2.ZERO
			direction = Input.get_axis("ui_left", "ui_right")
			velocity = Vector2(y * direction * speed, x * direction * speed)
			if direction and item:
					item.position = item_pivot * direction
			if Input.is_action_pressed("ui_select"):
				if abs(y) == 1:
					velocity.y = y * jump_speed
				else:
					velocity.x = x * -jump_speed
		else:
			velocity.x -= sign(Zentripetalforce.x)*clamp(abs(Zentripetalforce.x), 0, 300)
			velocity.y -= sign(Zentripetalforce.y)*clamp(abs(Zentripetalforce.y), 0, 300)
			Zentripetalforce = Zentripetalforce.lerp(Vector2.ZERO, 0.5)
		if l.is_colliding() and r.is_colliding():
			velocity += Vector2(x * -gravity*delta, y * gravity*delta)
			var length = l.global_position.distance_to(l.get_collision_point())-r.global_position.distance_to(r.get_collision_point())
			if abs(length) > 1:
				global_rotation -= length*delta
		else:
			velocity.y += gravity*delta
			global_rotation = lerp(global_rotation, 0.0, delta)
	
	move_and_slide()
	update_animation()
	update_facing()

func update_animation():
	if not animation_locked:
		if direction != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func update_facing():
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func hooking():
	if hook.is_colliding():
		aim_pos = hook.get_collision_point()
		swinged = true
		aim_radius = global_position.distance_to(aim_pos)
		mesh.scale.x = aim_radius/100
		mesh.visible = true

		global_rotation = 0
		ax = acos((global_position.x-aim_pos.x)/aim_radius)/ang_speed
		ay = asin((global_position.y-aim_pos.y)/aim_radius)/ang_speed

func swing(delta):
	if stahp:
		velocity = Vector2.ZERO
		return
	if stuck.has_overlapping_bodies():
		stahp = true
		global_position += Vector2(round(sin(global_rotation)) * 30, round(cos(global_rotation)) * 30)
		Zentripetalforce = Vector2.ZERO
		return
	cam.zoom = cam.zoom.lerp(max_zoom, delta)
	#elif is_on_floor() or is_on_ceiling() or is_on_wall():
	aim_radius -= aim_radius/100
	mesh.scale.x = aim_radius/100
	mesh.look_at(aim_pos)
	global_rotation = lerp(global_rotation, global_rotation + get_angle_to(aim_pos) - deg_to_rad(90), 0.1)
	_new_pos = Vector2(cos(ax*ang_speed) * aim_radius, sin(ay*ang_speed) * aim_radius) + aim_pos
	Zentripetalforce = global_position - _new_pos
	Zentripetalforce *= 30
	global_position = _new_pos
	ax += delta
	ay += delta

func _on_item_area_entered(area):
	if not multiplayer.is_server():
		return
	if area.get_parent() == item or area.get_parent().is_used:
		return
	elif item:
		item.queue_free()
		item = null
	item = area.get_parent()
	server.remove_item.rpc(get_path(), item.get_path())
	server.remove_item(get_path(), item.get_path())

func _on_dmg_body_entered(body):
	if body.player_id == int(str(name)):
		return
	global_position = Vector2.ZERO
