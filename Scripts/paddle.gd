extends CharacterBody3D


const SPEED = 10.0
const FRICTION = 18.0
const MOUSE_LERP = 10.0
const ROTATION_LERP = 8.0
const BOUNDARY_X_LEFT = -12.0
const BOUNDARY_X_RIGHT = 13.4
const BOUNDARY_Z = 6.7
const AI_HOOP = Vector3(-11.0, 9.17, 0)
const POWER_BAR_SPEED = 2.5
const JUMP_FORCE = 12.0
const GRAVITY = 30.0
var locked_y: float
var is_jumping: bool = false
var jump_velocity: float = 0.0
var using_mouse: bool = false
var aiming: bool = false
var mouse_down: bool = false
var ball: RigidBody3D
var ball_in_grab_area: bool = false
var holding_ball: bool = false
var hold_timer: float = 0.0
const MAX_HOLD_TIME: float = 1.0
var power_bar_value: float = 0.0
var power_bar_direction: float = 1.0
var power_bar: Control
var power_bar_indicator: Panel
@onready var grab_area: Area3D = $GrabArea

func calculate_shot_velocity(ball_pos: Vector3) -> Vector3:
	# Aim slightly above the hoop so ball arcs down through it
	var target = AI_HOOP + Vector3(0, 1.5, 0)
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
	
	# Power based on power bar (center = perfect, edges = weak/strong)
	var power = 0.5 + power_bar_value * 0.7  # 0.5 to 1.2 range
	
	# Boost velocity scaled by power
	vx *= 1.3 * power
	vz *= 1.3 * power
	vy *= 1.2 * power
	
	return Vector3(vx, vy, vz)

func _ready() -> void:
	locked_y = position.y
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	ball = get_node("../Node3D")
	grab_area.body_entered.connect(_on_grab_area_body_entered)
	grab_area.body_exited.connect(_on_grab_area_body_exited)
	# Get power bar UI references
	var hud = get_node("../HUD")
	power_bar = hud.get_node("PowerBar")
	power_bar_indicator = power_bar.get_node("Indicator")

func _on_grab_area_body_entered(body: Node3D) -> void:
	if body == ball and not holding_ball and not ball.freeze:
		ball_in_grab_area = true
		# Only grab if mouse button is held
		if mouse_down:
			_grab_ball()

func _on_grab_area_body_exited(body: Node3D) -> void:
	if body == ball:
		ball_in_grab_area = false

func _grab_ball() -> void:
	holding_ball = true
	hold_timer = 0.0
	aiming = true
	power_bar_value = 0.0
	power_bar_direction = 1.0
	ball.freeze = true

func _release_ball() -> void:
	if not holding_ball:
		return
	holding_ball = false
	aiming = false
	ball.freeze = false
	power_bar.visible = false
	# Apply shot velocity
	var shot_vel = calculate_shot_velocity(ball.global_position)
	ball.linear_velocity = shot_vel
	ball.angular_velocity = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		using_mouse = true
	elif event is InputEventKey:
		using_mouse = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if event.pressed and ball_in_grab_area and not holding_ball and not ball.freeze:
			# Grab ball on mouse down if ball is in grab area
			_grab_ball()
		elif not event.pressed and holding_ball:
			# Release shot on mouse up
			_release_ball()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not is_jumping:
			is_jumping = true
			jump_velocity = JUMP_FORCE

func _physics_process(delta: float) -> void:
	# Handle jump
	if is_jumping:
		jump_velocity -= GRAVITY * delta
		position.y += jump_velocity * delta
		if position.y <= locked_y:
			position.y = locked_y
			is_jumping = false
			jump_velocity = 0.0

	# Handle ball holding
	if holding_ball:
		hold_timer += delta
		# Keep ball attached to grab area
		ball.global_position = grab_area.global_position
		# Auto-release after max hold time
		if hold_timer >= MAX_HOLD_TIME:
			_release_ball()
			return
	
	# Update power bar when aiming
	if aiming and power_bar != null:
		power_bar.visible = true
		# Animate indicator up and down
		power_bar_value += power_bar_direction * POWER_BAR_SPEED * delta
		if power_bar_value >= 1.0:
			power_bar_value = 1.0
			power_bar_direction = -1.0
		elif power_bar_value <= 0.0:
			power_bar_value = 0.0
			power_bar_direction = 1.0
		# Update indicator position (bar height is 300px total)
		var bar_height = power_bar.size.y - 8
		power_bar_indicator.position.y = power_bar_value * bar_height
	
	# Handle rotation: face AI hoop when aiming, face ball otherwise
	if aiming:
		var dir_to_hoop = (AI_HOOP - global_position).normalized()
		var target_angle = atan2(dir_to_hoop.x, dir_to_hoop.z) + PI / 2
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_LERP * delta)
	elif ball != null:
		var dir_to_ball = (ball.global_position - global_position).normalized()
		var target_angle = atan2(dir_to_ball.x, dir_to_ball.z) + PI / 2
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_LERP * delta)

	if using_mouse:
		# Raycast from camera through mouse onto the paddle's Y plane
		var camera = get_viewport().get_camera_3d()
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		# Intersect with horizontal plane at paddle height
		if dir.y != 0:
			var t = (locked_y - from.y) / dir.y
			var target = from + dir * t
			var smooth = 1.0 - exp(-MOUSE_LERP * delta)
			position.x = lerp(position.x, target.x, smooth)
			position.z = lerp(position.z, target.z, smooth)
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
	else:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

	velocity.y = 0.0
	if not is_jumping:
		position.y = locked_y

	move_and_slide()

	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
