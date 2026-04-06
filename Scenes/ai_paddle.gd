extends CharacterBody3D

const SPEED = 8.0
const BOUNDARY_X_LEFT = -13.4
const BOUNDARY_X_RIGHT = 0.0
const BOUNDARY_Z = 6.7
var locked_y: float
var ball: RigidBody3D

func _ready() -> void:
	locked_y = position.y
	# Find the ball in the scene
	ball = get_node("../Node3D")

func _physics_process(delta: float) -> void:
	if ball == null:
		return

	var ball_pos = ball.global_position
	var my_pos = global_position

	# Move toward the ball's X and Z position to intercept it
	var target_x = ball_pos.x
	var target_z = ball_pos.z

	# When the ball is on the AI's side (left), move under it to hit it
	# When the ball is on the player's side, move to a ready position near center
	if ball_pos.x > 0:
		# Ball is on player's side, return to a ready position
		target_x = -5.0
		target_z = 0.0

	var direction = Vector3(target_x - my_pos.x, 0, target_z - my_pos.z)

	if direction.length() > 0.2:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	position.y = locked_y
	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
