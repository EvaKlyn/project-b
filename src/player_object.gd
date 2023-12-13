extends Node3D
class_name BasePlayer

signal teleported
signal died

var user_session_path: NodePath
var controls_default = {
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

@export var speed: float = 4.3
@export var accel: float = 2.5
@export var speed_reverse: float = 2.5
@export var slew_speed: float = 180.0
@export var max_rotate: float = 210.0
@export var recovery_delay: float = 0.35

@export var net_velocity: Vector3 = Vector3.ZERO
@export var net_position: Vector3 = Vector3.ZERO

var gravity: float = 0.7

var _current_slew_speed = slew_speed
var _current_max_rotate = max_rotate
var _rotational_velocity = 0.0
var _current_speed = speed
var _current_speed_reverse = speed_reverse

@onready var player_body: CharacterBody3D = $PhysicsPlayer
@onready var falling_collider: CollisionShape3D = $PhysicsPlayer/FallingCollider

@onready var dummy_pivot: Node3D = $PhysicsPlayer/DummyPivot

@onready var camera_mount: Node3D = $PhysicsPlayer/CameraMount
@onready var camera_look_dummy: Node3D = $CameraRig/CameraLookDummy
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var cam_pos_main: Marker3D = $CameraRig/SpringArm3D/Marker3D
@onready var cam_pos_up: Marker3D = $CameraRig/SpringArm3D2/Marker3D
@onready var state_chart: StateChart = $State

var _current_cam_pos: String = "main"
var _rig_goal_pos: Vector3 = Vector3.ZERO
var _recovery_time: float = 0.0

var _looking_up = false

var inputs = {}
var _has_session = false

func _enter_tree():
	set_multiplayer_authority(1)
	inputs = controls_default

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_rig.position = _rig_goal_pos
	camera.global_position = cam_pos_main.global_position
	camera.global_rotation = cam_pos_main.global_rotation
	player_body.connect("died", die)

func _get_input(button) -> bool:
	if inputs[button] != 0:
		return true
	else:
		return false

@rpc("any_peer", "call_local", "unreliable_ordered")
func recv_input(net_input: Dictionary):
	inputs = net_input

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	camera_look_dummy.position = camera.position
	_rig_goal_pos = player_body.position + Vector3(0, 0.5, 0)
	
	
	if _get_input("down") or _get_input("up") or _get_input("left") or _get_input("right"):
		state_chart.send_event("moved")
	
	if _get_input("shift") and player_body.velocity.length() > 0.05:
		state_chart.send_event("sprint")
	if not _get_input("shift"):
		state_chart.send_event("endsprint")
	
	if _get_input("lmb"):
		state_chart.send_event("neutral_attack")
	if _get_input("rmb"):
		state_chart.send_event("special_attack")
	
	if not player_body.is_on_floor():
		state_chart.send_event("fall")
	else:
		state_chart.send_event("grounded")
	
	player_body.move_and_slide()
	
	if is_multiplayer_authority():
		net_velocity = player_body.velocity
		net_position = player_body.position
	
	if !is_multiplayer_authority():
		player_body.velocity = net_velocity
		player_body.position = player_body.position.lerp(net_position, delta * 5)

func do_movement(delta) -> bool:
	var frame_vel_y = player_body.velocity.y
	var did_move = false
	
	var forward_dir = player_body.get_global_transform().basis.z.normalized()
	if _get_input("up"):
		did_move = true
		player_body.velocity = forward_dir * -1 * min(_current_speed, player_body.velocity.length() + accel)
	elif _get_input("down"):
		did_move = true
		player_body.velocity = forward_dir * _current_speed_reverse
	
#	var horiz_vector = Vector2(player_body.linear_velocity.x, player_body.linear_velocity.z)
#
#	if horiz_vector.length() > (_current_speed * delta):
#		player_body.linear_velocity.x = horiz_vector.normalized().x * (_current_speed * delta)
#		player_body.linear_velocity.z = horiz_vector.normalized().y * (_current_speed * delta)
	
	player_body.velocity.y = frame_vel_y
	
	return did_move

func camera_update(delta):
	camera_rig.position = camera_rig.position.lerp(_rig_goal_pos, delta * 6)
	camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, player_body.rotation.y, delta * 6)
	
	if _get_input("q"):
		camera.global_position = camera.global_position.lerp(cam_pos_up.global_position, delta * 5)
		camera.global_rotation = camera.global_rotation.lerp(cam_pos_up.global_rotation, delta * 5)
	else:
		camera.global_position = camera.global_position.lerp(cam_pos_main.global_position, delta * 5)
		camera.global_rotation = camera.global_rotation.lerp(cam_pos_main.global_rotation, delta * 5)

func do_turn(delta):
	if _get_input("left"):
		_rotational_velocity = min(_rotational_velocity + _current_slew_speed * delta, _current_max_rotate * delta)
	elif _get_input("right"):
		_rotational_velocity = max(_rotational_velocity - _current_slew_speed * delta, -_current_max_rotate * delta)

func _on_grounded_state_physics_processing(delta):
	_rotational_velocity = lerpf(_rotational_velocity, 0, 20.0 * delta)
	var _vel_2d = Vector2(player_body.velocity.x, player_body.velocity.z)
	_vel_2d = _vel_2d.lerp(Vector2.ZERO, delta * 5.0)
	player_body.velocity.x = _vel_2d.x
	player_body.velocity.z = _vel_2d.y
	player_body.rotate_y(deg_to_rad(_rotational_velocity))


func _on_moving_state_physics_processing(delta):
	camera_update(delta)

func _on_walking_state_physics_processing(delta):
	_current_speed = speed
	_current_max_rotate = max_rotate
	_current_slew_speed = slew_speed
	_current_speed_reverse = speed_reverse
	do_turn(delta)
	if do_movement(delta) == false:
		state_chart.send_event("stopped")
		
func _on_sprinting_state_physics_processing(delta):
	_current_speed = speed * 1.5
	_current_max_rotate = max_rotate * 0.85
	_current_slew_speed = slew_speed * 0.5
	_current_speed_reverse = 0.0
	do_turn(delta)
	if do_movement(delta) == false:
		state_chart.send_event("stopped")
	if _get_input("down") or player_body.velocity.length() < 0.05:
		state_chart.send_event("endsprint")

func _on_airborne_state_physics_processing(delta):
	player_body.velocity.y -= gravity

func _on_controlled_state_physics_processing(delta):
	camera_rig.position = camera_rig.position.lerp(_rig_goal_pos, delta * 6)
	camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, player_body.rotation.y, delta * 6)
	player_body.rotate_y(deg_to_rad(_rotational_velocity))

func _on_grounded_state_entered():
	player_body.rotation.x = 0
	player_body.rotation.z = 0

func _on_freefall_state_physics_processing(delta):
	camera_rig.position = camera_rig.position.lerp(_rig_goal_pos, delta * 6)
	camera_look_dummy.look_at(player_body.global_position)
	camera.global_rotation = camera.global_rotation.lerp(camera_look_dummy.global_rotation, delta * 5)
	falling_collider.disabled = false

func _on_freefall_state_entered():
	pass

# ATTACK FUNCTIONS TO OVERRIDE
func _on_neutral_attack():
	pass # Replace with function body.

func _on_special_attack():
	pass # Replace with function body.

func _on_dash_attack():
	pass # Replace with function body.

func _on_attack_state_physics_processing(delta):
	camera_update(delta)
	player_body.velocity.y -= gravity

func get_teleported(new_position: Vector3):
	player_body.position = new_position

func die():
	var thing: MultiplayerWorld = get_parent().get_parent()
	var spawns: Array = thing.spawn_points.get_children()
	var spawn_point = spawns.pick_random().position
	player_body.position = spawn_point

func remove():
	queue_free()
