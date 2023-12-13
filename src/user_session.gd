extends Node
class_name UserSession

@export var multiplayer_id: int
@export var instanced: bool = false

@export var player_path: NodePath

@export var controls = {
	"time" = 0,
	"up" = 0,
	"down" = 0,
	"left" = 0,
	"right" = 0,
	"space" = 0,
	"shift" = 0,
	"q" = 0,
	"lmb" = 0,
	"rmb" = 0,
}

var controls_default: Dictionary
var view = false

var lifetime: int = 0

func _enter_tree():
	controls_default = controls.duplicate()
	set_multiplayer_authority(name.to_int())
	print(player_path)

func _physics_process(delta):
	if is_multiplayer_authority():
		controls.merge(controls_default, true)
		lifetime = lifetime + 1
		controls["time"] = lifetime
		if Input.is_action_pressed("a_forward"):
			controls["up"] = 1
		if Input.is_action_pressed("a_backward"):
			controls["down"] = 1
		if Input.is_action_pressed("a_left"):
			controls["left"] = 1
		if Input.is_action_pressed("a_right"):
			controls["right"] = 1
		if Input.is_action_pressed("a_sprint"):
			controls["shift"] = 1
		if Input.is_action_pressed("a_jump"):
			controls["space"] = 1
		if Input.is_action_pressed("a_look"):
			controls["q"] = 1
		if Input.is_action_pressed("mouse_1"):
			controls["lmb"] = 1
		if Input.is_action_pressed("mouse_2"):
			controls["rmb"] = 1
		
		get_node(player_path).rpc("recv_input", controls)
		
		if player_path:
			#print("woo")
			get_node(player_path).camera.current = true
		if !view and player_path:
			view = true
			Coordinator.set_view_texture(get_node(player_path).camera.get_viewport().get_texture())

@rpc("any_peer", "call_local")
func get_player_path(path: NodePath):
	player_path = path
