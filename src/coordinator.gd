extends Node

var master_spawner: MultiplayerSpawner
var view_container: TextureRect

var main_node: Node

var session_scene: PackedScene = preload("res://scenes/user_session.tscn")

var player_scene: PackedScene = preload("res://scenes/fighters/longsword.tscn")
var hub_world: PackedScene = preload("res://scenes/worlds/hub_world.tscn")

var world_scenes: Dictionary = {
	"test_dungeon" = preload("res://scenes/worlds/test_dungeon.tscn")
}

signal world_prepared

var spawn_points: Array[Vector3] = []
var prepared: bool = false

var worlds: Dictionary = {}
var players: Dictionary = {}

func readyup():
	set_multiplayer_authority(1)

func prepare_world(id: String):
	if id in worlds.keys():
		return
	print("making world with id ", id)
	print(worlds)
	
	master_spawner = _add_level_scenes(master_spawner)
	
	match id:
		"hub":
			var hub = hub_world.instantiate()
			worlds[id] = hub
			master_spawner.add_sibling(hub)
		_:
			if id not in world_scenes.keys():
				print("no world id ", id)
				return
			
			var instance = world_scenes[id].instantiate()
			worlds[id] = instance
			master_spawner.add_sibling(instance)
	
	print("made world with id ", id)
	world_prepared.emit()
	print("did the emit ")

func add_player(id: int = 1, target_world = "hub") -> SubViewport:
	print("making player with id ", id)
	
	var player: BasePlayer = player_scene.instantiate()
	
	var world = worlds[target_world].get_child(0)
	world.call_deferred("add_child", player, true)
	player.name = str(id)
	
	var world_parent = world.get_parent()
	await get_tree().create_timer(0.1).timeout
	
	player.die()
	
	var user: UserSession = session_scene.instantiate()
	
	user.name = str(id)
	user.multiplayer_id = id
	main_node.add_child(user)
	player.user_session_path = user.get_path()
	
	user.rpc("get_player_path", player.get_path())
	
	return world_parent

func prep_client():
	master_spawner = _add_level_scenes(master_spawner)

func _add_player_scenes(spawner: MultiplayerSpawner):
	spawner.add_spawnable_scene("res://scenes/fighters/longsword.tscn")
	return spawner

func _add_level_scenes(spawner: MultiplayerSpawner):
	spawner.add_spawnable_scene("res://scenes/worlds/hub_world.tscn")
	spawner.add_spawnable_scene("res://scenes/worlds/test_dungeon.tscn")
	return spawner

func set_view_texture(view_texture: ViewportTexture):
	view_container.texture = view_texture
	view_container.visible = true

@rpc("any_peer")
func request_world_crossing(level: String, player_id: String):
	print("world crossing request spotted")
	print(multiplayer.get_remote_sender_id())
	prepare_world(level)
	
	var player
	
	if player_id in players.keys():
		player = get_node(players[player_id])
	else:
		return
	
	player.remove()
	players.erase(player_id)
	await get_tree().create_timer(0.1).timeout
	add_player(player_id.to_int(), level)

