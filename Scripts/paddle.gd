extends CharacterBody3D


const SPEED = 10.0
const FRICTION = 18.0
const MOUSE_LERP = 10.0
const BOUNDARY_X_LEFT = 0.0
const BOUNDARY_X_RIGHT = 13.4
const BOUNDARY_Z = 6.7
const JUMP_FORCE = 10.0
const JUMP_GRAVITY = 20.0
const JUMP_DURATION = 0.65
var locked_y: float
var using_mouse: bool = false
var jump_vel: float = 0.0
var is_jumping: bool = false
var jump_timer: float = 0.0

func _ready() -> void:
	locked_y = position.y
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		using_mouse = true
	elif event is InputEventKey:
		if event.keycode != KEY_SPACE:
			using_mouse = false
		if event.pressed and not event.echo and event.keycode == KEY_SPACE and not is_jumping:
			_do_jump()
	if event is InputEventMouseButton:
		using_mouse = true
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not is_jumping:
			_do_jump()

func _do_jump() -> void:
	velocity.y = JUMP_FORCE
	is_jumping = true
	jump_timer = JUMP_DURATION

func _physics_process(delta: float) -> void:

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

	if is_jumping:
		jump_timer -= delta
		velocity.y -= JUMP_GRAVITY * delta
		if position.y <= locked_y and velocity.y < 0 or jump_timer <= 0.0:
			position.y = locked_y
			velocity.y = 0.0
			is_jumping = false
			jump_timer = 0.0
	else:
		velocity.y = 0.0
		position.y = locked_y

	move_and_slide()

	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
