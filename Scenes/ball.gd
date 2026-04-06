extends RigidBody3D

const HIT_FORCE = 1.0
const BOUNCE_SFX = preload("res://Assets/ball_bounce.wav")
const SOUND_COOLDOWN = 0.12
var bounce_sound: AudioStreamPlayer
var prev_velocity: Vector3 = Vector3.ZERO
var sound_cooldown: float = 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	bounce_sound = AudioStreamPlayer.new()
	bounce_sound.stream = BOUNCE_SFX
	add_child(bounce_sound)

func _physics_process(delta: float) -> void:
	sound_cooldown -= delta
	var vel = linear_velocity
	var speed_change = (vel - prev_velocity).length()
	if speed_change > 2.0 and prev_velocity.length() > 1.0 and sound_cooldown <= 0.0:
		bounce_sound.play()
		sound_cooldown = SOUND_COOLDOWN
	prev_velocity = vel

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		if collider is CharacterBody3D:
			# Calculate offset from paddle center to ball contact point
			var paddle_pos = collider.global_position
			var ball_pos = global_position
			var offset = ball_pos - paddle_pos

			# Horizontal direction based on where ball hits the paddle
			var dir = Vector3(offset.x, 0, offset.z).normalized()

			# Always push upward, angle sideways based on hit offset
			var impulse = Vector3(dir.x * HIT_FORCE, HIT_FORCE, dir.z * HIT_FORCE)
			apply_central_impulse(impulse)
