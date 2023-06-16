extends Node2D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const custom_mouse_cursor = preload("res://Legacy-Fantasy - High Forest 2.0/Legacy-Fantasy - High Forest 2.3/Assets/smol_light.png")
const Player = preload("res://Characters/Player.tscn")
const level01 = preload("res://Levels/level_01.tscn")
var all_levels = [level01]
var rng = RandomNumberGenerator.new()
var current_level

var thread = null
var local_host: bool = false
const PORT = 4000
var enet_peer = ENetMultiplayerPeer.new()
var ap = []
var pa #needed for ap

func _on_host_button_pressed():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	Input.set_custom_mouse_cursor(custom_mouse_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	if local_host:
		main_menu.hide()
		load_level()
		multiplayer.peer_connected.connect(add_player)
		add_player(multiplayer.get_unique_id())
	else:# UPNP queries take some time.
		thread = Thread.new()
		thread.start(_upnp_setup.bind(PORT))

func _on_join_button_pressed():
	if local_host:
		enet_peer.create_client("localhost", PORT)
	else:
		enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	Input.set_custom_mouse_cursor(custom_mouse_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	main_menu.hide()

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	ap.append(player.get_path())
	player.level = current_level
	if peer_id == 1:
		return
	get_level.rpc(current_level.get_path(), ap)

func load_level():
	if current_level:
		current_level.queue_free()
	rng.randomize()
	var index = rng.randf_range(0, all_levels.size()-1)
	var level = all_levels[index].instantiate()
	add_child(level)
	current_level = level

@rpc
func get_level(path, app):
	if not current_level:
		current_level = get_node(path)
		for p in app:
			pa = get_node(p)
			pa.level = get_node(path)

@rpc
func remove_item(playerpath, itempath):
	var item = get_node(itempath)
	item.is_used = true
	current_level.remove_child(item)
	var player = get_node(playerpath)
	player.item = item
	player.call_deferred("add_child", item)
	item.player_id = int(str(player.name))
	item.call_deferred("set_position", Vector2(12, 0))

@rpc("call_local", "any_peer")
func item_rotation(itempath, rot):
	get_node(itempath).rotation = rot

func _upnp_setup(server_port):
	var upnp = UPNP.new()
	upnp.discover_ipv6 = true #if false -> get_gateway: Couldn't find any UPNPDevices.
	var err = upnp.discover()
	if err != OK:
		push_error(str(err))
		return
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		var map_result_udp = upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "UDP")
		var map_result_tcp = upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "TCP")
		if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
			upnp.add_port_mapping(server_port, server_port, "", "UDP")
		if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
			upnp.add_port_mapping(server_port, server_port, "", "TCP")
	main_menu.hide()
	load_level()
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())

func _exit_tree():
	if thread:
		thread.wait_to_finish()

func _on_check_box_pressed():
	local_host = !local_host
