extends Control


func _ready():
	set_process_input(true)
	var save_data = global.read_save()
	get_node("high_score_label").set_text("Greatest valor: %s" % save_data["high_score"])


func _input(event):
	if event.is_action_released("shoot_bullets"):
		get_tree().change_scene("res://game.tscn")
