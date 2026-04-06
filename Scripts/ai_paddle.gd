extends CharacterBody3D

const SPEED = 8.0
const FRICTION = 18.0
const BOUNDARY_X_LEFT = -13.4
const BOUNDARY_X_RIGHT = 0.0
const BOUNDARY_Z = 6.7
const APPROACH_DIST = 1.2
const JUMP_FORCE = 10.0
const JUMP_GRAVITY = 20.0
const JUMP_CHANCE = 0.4
const JUMP_TRIGGER_DIST = 2.5
const JUMP_LUNGE_SPEED = 5.0
# Player's basket position (right hoop)
const TARGET_BASKET = Vector3(11.8, 4.387, 0)

var locked_y: float
var ball: RigidBody3D
var jump_vel: float = 0.0
var is_jumping: bool = false
var jump_cooldown: float = 0.0

func _ready() -> void:
	locked_y = position.y
	ball = get_node("../Node3D")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	if ball == null:
		return

	jump_cooldown -= delta

	var ball_pos = ball.global_position
	var my_pos = global_position
	var target_x: float
	var target_z: float

	if ball_pos.x > 0:
		# Ball is on player's side — return to ready position
		target_x = -5.0
		target_z = 0.0
	else:
		var to_basket = Vector3(TARGET_BASKET.x - ball_pos.x, 0, TARGET_BASKET.z - ball_pos.z).normalized()
		var aim_pos = ball_pos - to_basket * APPROACH_DIST
		var dist_to_aim = Vector2(my_pos.x - aim_pos.x, my_pos.z - aim_pos.z).length()

		if dist_to_aim < 1.0:
			# Lined up — charge through the ball
			target_x = ball_pos.x + to_basket.x * 2.0
			target_z = ball_pos.z + to_basket.z * 2.0
		else:
			target_x = aim_pos.x
			target_z = lerp(aim_pos.z, ball_pos.z, 0.7)

		# Jump only when ball is very close, with random chance + cooldown
		var dist_to_ball = Vector2(my_pos.x - ball_pos.x, my_pos.z - ball_pos.z).length()
		if not is_jumping and jump_cooldown <= 0.0 and dist_to_ball < JUMP_TRIGGER_DIST and randf() < JUMP_CHANCE:
			jump_vel = JUMP_FORCE
			is_jumping = true
			jump_cooldown = 3.0
			# Lunge toward the basket on jump
			velocity.x = lerp(velocity.x, to_basket.x * JUMP_LUNGE_SPEED, 0.8)
			velocity.z = lerp(velocity.z, to_basket.z * JUMP_LUNGE_SPEED, 0.8)

	var direction = Vector3(target_x - my_pos.x, 0, target_z - my_pos.z).normalized()
	velocity.x = lerp(velocity.x, direction.x * SPEED, 0.15)
	velocity.z = lerp(velocity.z, direction.z * SPEED, 0.15)

	if is_jumping:
		velocity.y -= JUMP_GRAVITY * delta
		if position.y <= locked_y and velocity.y < 0:
			position.y = locked_y
			velocity.y = 0.0
			is_jumping = false
	else:
		velocity.y = 0.0
		position.y = locked_y

	move_and_slide()

	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
