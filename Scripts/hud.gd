extends CanvasLayer

@onready var ai_label: Label = $ScorePanel/HBoxContainer/AIScore
@onready var player_label: Label = $ScorePanel/HBoxContainer/PlayerScore

func update_score(player: int, ai: int) -> void:
	player_label.text = "Player: " + str(player)
	ai_label.text = "AI: " + str(ai)
