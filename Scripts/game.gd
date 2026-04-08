extends Node3D

var player_score: int = 0
var ai_score: int = 0
var ball_respawn_timer: float = 0.0
var waiting_for_respawn: bool = false

const PERIOD_DURATION: float = 120.0  # 2 minutes per period
const TOTAL_PERIODS: int = 3
var current_period: int = 1
var time_remaining: float = PERIOD_DURATION
var game_paused: bool = false
var game_over: bool = false

@onready var ball: RigidBody3D = $Node3D
@onready var ai_paddle: CharacterBody3D = $AIPaddle

const BALL_START_POS = Vector3(0, 10, 0)

func _ready() -> void:
	$Hoop/ScoreArea.scored.connect(_on_player_scored)
	$Hoop2/ScoreArea.scored.connect(_on_ai_scored)
	$HUD.update_clock(time_remaining)
	$HUD.update_period(current_period)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			_restart_game()
		return
	
	if game_paused:
		if Input.is_action_just_pressed("ui_accept"):
			_resume_game()
		return
	
	# Update game clock
	time_remaining -= delta
	$HUD.update_clock(time_remaining)
	
	# Update AI aggression based on game state
	ai_paddle.update_aggression(ai_score, player_score, time_remaining, PERIOD_DURATION)
	
	if time_remaining <= 0:
		_end_period()
	
	if waiting_for_respawn:
		ball_respawn_timer -= delta
		if ball_respawn_timer <= 0:
			_respawn_ball()
			waiting_for_respawn = false

func _end_period() -> void:
	time_remaining = 0
	$HUD.update_clock(0)
	_pause_ball()
	
	if current_period >= TOTAL_PERIODS:
		game_over = true
		$HUD.show_game_over(player_score, ai_score)
	else:
		game_paused = true
		$HUD.show_period_break(current_period)

func _resume_game() -> void:
	current_period += 1
	time_remaining = PERIOD_DURATION
	$HUD.update_period(current_period)
	$HUD.hide_overlay()
	game_paused = false
	_respawn_ball()

func _restart_game() -> void:
	player_score = 0
	ai_score = 0
	current_period = 1
	time_remaining = PERIOD_DURATION
	game_over = false
	game_paused = false
	$HUD.update_score(player_score, ai_score)
	$HUD.update_period(current_period)
	$HUD.update_clock(time_remaining)
	$HUD.hide_overlay()
	ai_paddle.update_aggression(ai_score, player_score, time_remaining, PERIOD_DURATION)
	_respawn_ball()

func _pause_ball() -> void:
	ball.freeze = true
	ball.global_position = Vector3(0, -10, 0)

func _on_score() -> void:
	if game_paused or game_over:
		return
	
	# Tell AI paddle to move back to start
	ai_paddle.return_to_start()
	
	# Wait 1 second before hiding ball
	await get_tree().create_timer(1.0).timeout
	
	# Hide ball and start respawn timer
	ball.freeze = true
	ball.global_position = Vector3(0, -10, 0)  # Move off screen
	ball_respawn_timer = 2.0
	waiting_for_respawn = true

func _respawn_ball() -> void:
	ball.global_position = BALL_START_POS
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = false

func _on_player_scored() -> void:
	if game_paused or game_over:
		return
	player_score += 2
	$HUD.update_score(player_score, ai_score)
	_on_score()

func _on_ai_scored() -> void:
	if game_paused or game_over:
		return
	ai_score += 2
	$HUD.update_score(player_score, ai_score)
	_on_score()
