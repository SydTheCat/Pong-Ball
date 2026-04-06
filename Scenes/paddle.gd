extends CharacterBody3D


const SPEED = 10.0
const MOUSE_LERP = 10.0
const BOUNDARY_X_LEFT = 0.0
const BOUNDARY_X_RIGHT = 13.4
const BOUNDARY_Z = 6.7
var locked_y: float
var using_mouse: bool = false

func _ready() -> void:
	locked_y = position.y

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		using_mouse = true
	elif event is InputEventKey:
		using_mouse = false

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
			velocity = Vector3.ZERO
	else:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	position.y = locked_y
	position.x = clamp(position.x, BOUNDARY_X_LEFT, BOUNDARY_X_RIGHT)
	position.z = clamp(position.z, -BOUNDARY_Z, BOUNDARY_Z)
