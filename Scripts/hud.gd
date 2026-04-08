extends CanvasLayer

@onready var ai_label: Label = $ScorePanel/HBoxContainer/AIScore
@onready var player_label: Label = $ScorePanel/HBoxContainer/PlayerScore
@onready var clock_label: Label = $ScorePanel/HBoxContainer/CenterInfo/Clock
@onready var period_label: Label = $ScorePanel/HBoxContainer/CenterInfo/Period
@onready var overlay: Panel = $Overlay
@onready var overlay_title: Label = $Overlay/VBox/Title
@onready var overlay_subtitle: Label = $Overlay/VBox/Subtitle
@onready var buzzer_sound: AudioStreamPlayer = $BuzzerSound

func update_score(player: int, ai: int) -> void:
	player_label.text = "Player: " + str(player)
	ai_label.text = "AI: " + str(ai)

func update_clock(time_left: float) -> void:
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	clock_label.text = "%d:%02d" % [minutes, seconds]

func update_period(period: int) -> void:
	period_label.text = "Period " + str(period)

func show_period_break(period: int) -> void:
	buzzer_sound.play()
	overlay_title.text = "End of Period " + str(period)
	overlay_subtitle.text = "Press SPACE to continue"
	overlay.visible = true

func show_game_over(player_score: int, ai_score: int) -> void:
	buzzer_sound.play()
	if player_score > ai_score:
		overlay_title.text = "You Win!"
	elif ai_score > player_score:
		overlay_title.text = "AI Wins!"
	else:
		overlay_title.text = "It's a Tie!"
	overlay_subtitle.text = "Final: Player %d - AI %d\nPress SPACE to restart" % [player_score, ai_score]
	overlay.visible = true

func hide_overlay() -> void:
	overlay.visible = false
