extends Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var ip_edit: LineEdit = $Control/CenterContainer/PanelContainer/GridContainer/Ip
@onready var port_edit: LineEdit = $Control/CenterContainer/PanelContainer/GridContainer/Port
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

@export var world_paths: Dictionary = {}

func _physics_process(delta):
	world_paths = Coordinator.worlds

func _ready():
	Coordinator.main_node = self
	Coordinator.master_spawner = spawner
	spawner.spawn_function = (_spawn_function)
	Coordinator.view_container = $Control/TextureRect

func _spawn_function(data: Node) -> Node:
	print(data.name)
	return data

func _on_host_button_pressed():
	$Control/CenterContainer.visible = false
	peer.create_server(int(port_edit.text))
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	Coordinator.prepare_world("hub")
	await get_tree().create_timer(0.2).timeout
	_add_player()
	set_multiplayer_authority(1)
	Coordinator.readyup()

func _add_player(id: int = 1):
	await Coordinator.add_player(id)

func _on_connect_button_pressed():
	$Control/CenterContainer.visible = false
	Coordinator.prep_client()
	peer.create_client(ip_edit.text, int(port_edit.text))
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_client_start)

func _client_start():
	pass
