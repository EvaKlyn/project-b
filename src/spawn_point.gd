extends Node3D
class_name SpawnPoint

@export var hub_spawn: bool = false

func _ready():
	if hub_spawn:
		Coordinator.spawn_points.append(position)
		if !Coordinator.prepared:
			Coordinator.prepared = true
