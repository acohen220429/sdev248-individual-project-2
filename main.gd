extends Node

@export var cue_ball_spawn_position: Vector3 = Vector3(0, 0.5, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is Area3D and child.name.begins_with("Pocket"):
			child.body_entered.connect(_on_pocket_body_entered)


func _on_pocket_body_entered(body: Node3D) -> void:
	if body.is_in_group("cue_ball"):
		respawn_cue_ball(body as RigidBody3D)
		print("cue ball passed!")
	elif body.is_in_group("balls"):
		body.queue_free()
		print("regular ball passed!")

func respawn_cue_ball(cue_ball: RigidBody3D) -> void:
	cue_ball.linear_velocity = Vector3.ZERO
	cue_ball.angular_velocity = Vector3.ZERO
	cue_ball.global_position = cue_ball_spawn_position
		
