extends Area3D

signal scored

const SCORE_COOLDOWN = 2.0
var cooldown: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.linear_velocity.y < -0.5 and cooldown <= 0:
		emit_signal("scored")
		cooldown = SCORE_COOLDOWN
