extends RigidBody3D

const HIT_FORCE = 1.4
const BOUNCE_SFX = preload("res://Assets/ball_bounce.wav")
const SOUND_COOLDOWN = 0.08
const MIN_IMPACT_VELOCITY = 2.0
const AI_HOOP = Vector3(-11.0, 9.17, 0)
const PLAYER_HOOP = Vector3(11.1, 9.17, 0)
const AIM_ASSIST_STRENGTH = 0.8
const MAX_SPEED = 24.0
var bounce_sound: AudioStreamPlayer
var sound_cooldown: float = 0.0
var aim_assist_target: Vector3 = Vector3.ZERO
var aim_assist_active: bool = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	bounce_sound = AudioStreamPlayer.new()
	bounce_sound.stream = BOUNCE_SFX
	add_child(bounce_sound)

func _physics_process(delta: float) -> void:
	if sound_cooldown > 0:
		sound_cooldown -= delta
	
	# Limit max speed
	var speed = linear_velocity.length()
	if speed > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
	
	# Apply aim assist - curve ball toward target hoop
	if aim_assist_active and linear_velocity.y > 0:
		var dir_to_target = (aim_assist_target - global_position).normalized()
		var assist_force = Vector3(dir_to_target.x, 0, dir_to_target.z) * AIM_ASSIST_STRENGTH
		apply_central_force(assist_force)
	elif linear_velocity.y <= 0:
		aim_assist_active = false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Play bounce sound on any contact with sufficient impact
	if state.get_contact_count() > 0 and sound_cooldown <= 0.0:
		var impact = state.linear_velocity.length()
		if impact > MIN_IMPACT_VELOCITY:
			bounce_sound.play()
			sound_cooldown = SOUND_COOLDOWN
	
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		# Dampen bounce on hoop (only if moving fast)
		if collider is StaticBody3D and collider.name == "Hoop":
			if state.linear_velocity.length() > 5.0:
				state.linear_velocity *= 0.5
		elif collider is CharacterBody3D:
			# Check if ball is in paddle's grab area AND aiming - use calculated shot
			var is_player_aiming = collider.get("ball_in_grab_area") == true and collider.get("aiming") == true
			var is_ai_aiming = collider.get("ball_in_grab_area") == true and collider.get("is_aiming") == true and collider.get("wants_to_shoot") == true
			
			if (is_player_aiming or is_ai_aiming) and collider.has_method("calculate_shot_velocity"):
				var shot_vel = collider.calculate_shot_velocity(global_position)
				state.linear_velocity = shot_vel
				# Set aim assist target based on which paddle
				if collider.global_position.x > 0:
					aim_assist_target = AI_HOOP
				else:
					aim_assist_target = PLAYER_HOOP
				aim_assist_active = true
			else:
				# Calculate offset from paddle center to ball contact point
				var paddle_pos = collider.global_position
				var ball_pos = global_position
				var offset = ball_pos - paddle_pos

				# Horizontal direction based on where ball hits the paddle
				var dir = Vector3(offset.x, 0, offset.z).normalized()

				# Always push upward, angle sideways based on hit offset
				var impulse = Vector3(dir.x * HIT_FORCE, HIT_FORCE, dir.z * HIT_FORCE)
				apply_central_impulse(impulse)
				
				# Activate aim assist if paddle is aiming
				if collider.get("aiming") == true or collider.get("is_aiming") == true:
					# Player aims at AI hoop, AI aims at player hoop
					if collider.global_position.x > 0:
						aim_assist_target = AI_HOOP
					else:
						aim_assist_target = PLAYER_HOOP
					aim_assist_active = true
