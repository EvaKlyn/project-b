extends SubViewport
class_name MultiplayerWorld

@export var physics_world: Node3D
@export var spawn_points: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var new_spawner = MultiplayerSpawner.new()
	own_world_3d = true
	physics_world.add_child(new_spawner)
	new_spawner.spawn_path = physics_world.get_path()
	new_spawner = Coordinator._add_player_scenes(new_spawner)
