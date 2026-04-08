extends CharacterBody3D

const SPEED = 8.0
const FRICTION = 18.0
const ROTATION_LERP = 8.0
const BOUNDARY_X_LEFT = -12.0
const BOUNDARY_X_RIGHT = 13.4
const BOUNDARY_Z = 6.7
const APPROACH_DIST = 1.2
const AIM_DISTANCE = 3.0
# Player's basket position (right hoop)
const TARGET_BASKET = Vector3(11.1, 9.17, 0)

# Accuracy: 1.0 = perfect aim, 0.0 = random aim
var accuracy: float = 0.7
var power_accuracy: float = 0.8  # How good AI is at picking right power
var base_shot_chance: float = 0.3  # Base chance to take a shot
var shot_chance: float = 0.3  # Current chance to take a shot (0.0 to 1.0)
var aim_offset: float = 0.0
var power_value: float = 1.0  # AI's chosen power (0.5 to 1.2)
var wants_to_shoot: bool = false  # Whether AI decided to shoot this time

func update_aggression(ai_score: int, player_score: int, time_remaining: float, period_duration: float) -> void:
	var urgency: float = 0.0
	
	# Increase urgency if losing
	var score_diff = player_score - ai_score
	if score_diff > 0:
		urgency += clamp(score_diff * 0.05, 0.0, 0.3)  # Up to +0.3 for being behind
	
	# Increase urgency if time is running low (last 30 seconds)
	if time_remaining < 30.0:
		urgency += 0.2 * (1.0 - time_remaining / 30.0)  # Up to +0.2 in final seconds
	
	# Increase urgency if time is running low AND losing
	if time_remaining < 30.0 and score_diff > 0:
		urgency += 0.15  # Extra desperation bonus
	
	shot_chance = clamp(base_shot_chance + urgency, 0.0, 0.85)

const START_POS = Vector3(-5, 0.25, 0)
const JUMP_FORCE = 12.0
const GRAVITY = 30.0
const JUMP_CHANCE = 0.4  # Chance to jump when ball is high

var locked_y: float
var ball: RigidBody3D
var is_aiming: bool = false
var returning_to_start: bool = false
var is_jumping: bool = false
var jump_velocity: float = 0.0
var ball_in_grab_area: bool = false
var holding_ball: bool = false
var hold_timer: float = 0.0
var ai_hold_duration: float = 0.5  # How long AI decides to hold before shooting
const MAX_HOLD_TIME: float = 1.0
@onready var grab_area: Area3D = $GrabArea

func _ready() -> void:
	locked_y = position.y
	ball = get_node("../Node3D")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	grab_area.body_entered.connect(_on_grab_area_body_entered)
	grab_area.body_exited.connect(_on_grab_area_body_exited)

func _on_grab_area_body_entered(body: Node3D) -> void:
	if body == ball and not holding_ball and not ball.freeze:
		ball_in_grab_area = true
		# Decide if AI wants to shoot (based on shot_chance)
		wants_to_shoot = randf() < shot_chance
		if wants_to_shoot:
			_grab_ball()

func _on_grab_area_body_exited(body: Node3D) -> void:
	if body == ball:
		ball_in_grab_area = false

func _grab_ball() -> void:
	holding_ball = true
	hold_timer = 0.0
	# AI decides how long to hold (random, but shorter when more urgent)
	ai_hold_duration = randf_range(0.3, 0.9)
	_pick_power()
	ball.freeze = true

func _release_ball() -> void:
	if not holding_ball:
		return
	holding_ball = false
	ball.freeze = false
	# Apply shot velocity
	var shot_vel = calculate_shot_velocity(ball.global_position)
	ball.linear_velocity = shot_vel
	ball.angular_velocity = Vector3.ZERO

func _pick_power() -> void:
	# Perfect power is 1.0, AI picks based on power_accuracy
	var error = (1.0 - power_accuracy) * randf_range(-0.5, 0.5)
	power_value = clamp(1.0 + error, 0.5, 1.2)

func calculate_shot_velocity(ball_pos: Vector3) -> Vector3:
	# Aim at player's hoop
	var target = TARGET_BASKET + Vector3(0, 1.5, 0)
	var gravity = 9.8
	
	# Horizontal distance and direction
	var dx = target.x - ball_pos.x
	var dz = target.z - ball_pos.z
	var horizontal_dist = sqrt(dx * dx + dz * dz)
	var dy = target.y - ball_pos.y
	
	# Calculate time of flight for a nice arc
	var flight_time = 0.8 + horizontal_dist * 0.04
	
	# Calculate required velocities for perfect shot
	var vx = dx / flight_time
	var vz = dz / flight_time
	var vy = (dy + 0.5 * gravity * flight_time * flight_time) / flight_time
	
	# Apply power and accuracy error
	var aim_error = (1.0 - accuracy) * randf_range(-0.3, 0.3)
	vx *= 1.3 * power_value * (1.0 + aim_error)
	vz *= 1.3 * power_value * (1.0 + aim_error)
	vy *= 1.2 * power_value
	
	return Vector3(vx, vy, vz)

func return_to_start() -> void:
	returning_to_start = true
	is_aiming = false
	holding_ball = false
	hold_timer = 0.0

func _physics_process(delta: float) -> void:
	if ball == null:
		return
	
	# Handle ball holding
	if holding_ball:
		hold_timer += delta
		# Keep ball attached to grab area
		ball.global_position = grab_area.global_position
		# Release when AI decides or at max hold time
		if hold_timer >= ai_hold_duration or hold_timer >= MAX_HOLD_TIME:
			_release_ball()
		return
	
	# Handle jump
	if is_jumping:
		jump_velocity -= GRAVITY * delta
		position.y += jump_velocity * delta
		if position.y <= locked_y:
			position.y = locked_y
			is_jumping = false
			jump_velocity = 0.0

	var ball_pos = ball.global_position
	
	# Try to jump to block high balls or intercept shots
	if not is_jumping and ball_pos.y > 3.0:
		var dist_to_ball = Vector2(global_position.x - ball_pos.x, global_position.z - ball_pos.z).length()
		if dist_to_ball < 4.0 and randf() < JUMP_CHANCE:
			is_jumping = true
			jump_velocity = JUMP_FORCE
	var my_pos = global_position
	var target_x: float
	var target_z: float
	var dist_to_ball = Vector2(my_pos.x - ball_pos.x, my_pos.z - ball_pos.z).length()

	# If returning to start or ball is frozen, move to start position
	if returning_to_start or ball.freeze:
		target_x = START_POS.x
		target_z = START_POS.z
		is_aiming = false
		# Check if reached start position (only stop returning when ball is active)
		if not ball.freeze:
			var dist_to_start = Vector2(my_pos.x - START_POS.x, my_pos.z - START_POS.z).length()
			if dist_to_start < 0.5:
				returning_to_start = false
	# Check if AI is under its own hoop - move away randomly
	elif my_pos.x < -10.5 and abs(my_pos.z) < 2.0:
		# Move away from hoop randomly
		target_x = -8.0
		target_z = randf_range(-4.0, 4.0)
		is_aiming = false
	# Check if AI is under player's hoop - move away
	elif my_pos.x > 10.5 and abs(my_pos.z) < 2.0:
		target_x = 8.0
		target_z = randf_range(-4.0, 4.0)
		is_aiming = false
	else:
		# Chase ball anywhere on court
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

		# Start aiming when close to ball
		if dist_to_ball < AIM_DISTANCE and not is_aiming:
			is_aiming = true
			# Calculate aim offset based on accuracy (inaccuracy adds random error)
			aim_offset = randf_range(-PI / 2, PI / 2) * (1.0 - accuracy)

	# Handle rotation toward ball when aiming
	if is_aiming:
		var dir_to_ball = (ball.global_position - global_position).normalized()
		var target_angle = atan2(dir_to_ball.x, dir_to_ball.z) - PI / 2 + aim_offset
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_LERP * delta)
	else:
		rotation.y = lerp_angle(rotation.y, 0.0, ROTATION_LERP * delta)

	var direction = Vector3(target_x - my_pos.x, 0, target_z - my_pos.z).normalized()
	velocity.x = lerp(velocity.x, direction.x * SPEED, 0.15)
	velocity.z = lerp(velocity.z, direction.z * SPEED, 0.15)

	velocity.y = 0.0
	if not is_jumping:
		position.y = locked_y

	move_and_slide()

	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
