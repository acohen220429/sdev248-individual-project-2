extends RigidBody3D

@export_group("Movement & Rotation")
@export var move_speed: float = 0.8
@export var rotate_speed: float = 1.2

@export_group("Strike Mechanics")
@export var max_force: float = 2.0
@export var charge_rate: float = 1.5
@export var min_force: float = 0.2
@export var max_pullback_distance: float = 0.8

var current_force: float = 0.0
var is_charging: bool = false
var strike_origin_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	axis_lock_linear_y = true
	linear_damp = 5.0
	
	freeze = true
	set_cue_collisions(false)

func _physics_process(delta: float) -> void:
	# WASD Positioning
	var move_dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):  move_dir.z -= 1.0
	if Input.is_action_pressed("move_backward"): move_dir.z += 1.0
	if Input.is_action_pressed("move_left"):     move_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):    move_dir.x += 1.0

	if move_dir != Vector3.ZERO and not is_charging:
		global_position += move_dir.normalized() * move_speed * delta

	# Arrow Key Aiming
	if not is_charging:
		if Input.is_action_pressed("rotate_left"):
			rotate_y(rotate_speed * delta)
		if Input.is_action_pressed("rotate_right"):
			rotate_y(-rotate_speed * delta)

	# Spacebar Charging
	if Input.is_action_pressed("strike_charge"):
		if not is_charging:
			is_charging = true
			current_force = min_force
			strike_origin_pos = global_position
		
		if current_force < max_force:
			current_force += charge_rate * delta
			var charge_ratio = (current_force - min_force) / max(max_force - min_force, 0.001)
			var pullback_dist = charge_ratio * max_pullback_distance
			var back_dir: Vector3 = -global_transform.basis.z
			global_position = strike_origin_pos + (back_dir * pullback_dist)
		
	elif Input.is_action_just_released("strike_charge") and is_charging:
		execute_strike()
		is_charging = false

func execute_strike() -> void:
	freeze = true
	set_cue_collisions(false)

	var charge_ratio = (current_force - min_force) / max(max_force - min_force, 0.001)
	var forward_follow_through = 0.2 + (charge_ratio * 0.4)
	var forward_dir: Vector3 = global_transform.basis.z.normalized()
	var target_pos = strike_origin_pos + (forward_dir * forward_follow_through)
	var stroke_duration = lerp(0.12, 0.05, charge_ratio)

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, stroke_duration)

	tween.finished.connect(func() -> void:
		var cue_ball: RigidBody3D = get_tree().get_first_node_in_group("cue_ball") as RigidBody3D

		if cue_ball != null:
			var safe_force: float = min(current_force, 2.0)
			cue_ball.apply_central_impulse(forward_dir * safe_force)

		global_position = strike_origin_pos
		current_force = 0.0
	)

func set_cue_collisions(enabled: bool) -> void:
	for child in find_children("*", "CollisionShape3D", true, false):
		if child is CollisionShape3D:
			child.disabled = not enabled
