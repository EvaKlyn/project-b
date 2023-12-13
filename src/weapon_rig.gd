extends Node3D
class_name WeaponRig

@export var weapon_area: Area3D
@onready var player_object: BasePlayer = get_parent()

var activated: bool = false
var hit_objects: Array = []

func _ready():
	weapon_area.connect("body_entered", _body_entered)

func activate_hitbox():
	hit_objects.clear()
	activated = true

func deactivate_hitbox():
	activated = false

func _physics_process(delta):
	pass

func _body_entered(body: Node3D):
	if body.is_class("BasePlayer"):
		var id = body.get_instance_id()
		if id in hit_objects:
			return
		hit_objects.append(id)
