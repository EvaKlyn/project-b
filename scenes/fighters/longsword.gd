extends BasePlayer

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var weapon_rig: Node3D = $WeaponRig

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	animator.play("Idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	super(delta)
	weapon_rig.position = player_body.position
	weapon_rig.rotation = player_body.rotation

# Attack functions
func _on_neutral_attack():
	super()
	animator.play("SimpleSwing")
	await animator.animation_finished
	_anim_finish()

func _on_special_attack():
	super()
	animator.play("OverheadSwing")
	await animator.animation_finished
	_anim_finish()

func _on_dash_attack():
	super()
	_anim_finish()

# function call for animations, signals that animation is done
func _anim_finish():
	animator.play("Idle")
	state_chart.send_event("attack_end")
