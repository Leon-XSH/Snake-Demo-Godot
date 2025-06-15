extends Control



func _ready() -> void:
	$MessagePanel.hide()


func _on_game_sig_game_over() -> void:
	$MessagePanel.show()


func _on_game_sig_game_start() -> void:
	$MessagePanel.hide()


func _on_game_sig_score_changed(score: Variant) -> void:
	$ScoreLabel.text = "Score: " + str(score)
