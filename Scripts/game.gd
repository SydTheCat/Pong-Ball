extends Node3D

var player_score: int = 0
var ai_score: int = 0

func _ready() -> void:
	$Hoop/ScoreArea.scored.connect(_on_player_scored)
	$Hoop2/ScoreArea.scored.connect(_on_ai_scored)

func _on_player_scored() -> void:
	player_score += 1
	$HUD.update_score(player_score, ai_score)

func _on_ai_scored() -> void:
	ai_score += 1
	$HUD.update_score(player_score, ai_score)
