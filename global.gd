extends Node

var player_bullet_image
var enemy_bullet_image
var homing_bullet_image
var copy_bullet_image
var spam_enemy_image
var sniper_enemy_image
var quick_enemy_image
var boss_image
var screen_size
var margin = 80
var save_file = File.new()
var save_file_path = "res://data.save"


func _ready():
	randomize()
	player_bullet_image = preload("res://assets/bullet.png")
	enemy_bullet_image = preload("res://assets/enemy_bullet.png")
	homing_bullet_image = preload("res://assets/homing_bullet.png")
	copy_bullet_image = preload("res://assets/copy_bullet.png")
	spam_enemy_image = preload("res://assets/spam_enemy.png")
	sniper_enemy_image = preload("res://assets/sniper_enemy.png")
	quick_enemy_image = preload("res://assets/quick_enemy.png")
	boss_image = preload("res://assets/boss.png")
	screen_size = get_viewport().get_rect().size
	if not save_file.file_exists(save_file_path):
		write_save({"high_score": 0})


func write_save(data):
	save_file.open_encrypted_with_pass(save_file_path, File.WRITE, "obfuscate")
	save_file.store_var(data)
	save_file.close()


func read_save():
	save_file.open_encrypted_with_pass(save_file_path, File.READ, "obfuscate")
	var data = save_file.get_var()
	save_file.close()
	if typeof(data) != TYPE_DICTIONARY:
		data = {}
	if not data.has("high_score"):
		data["high_score"] = 0
	return data


static func randint(a, b):
	return int(randf() * (b - a + 1)) + a


static func collides(a, b):
	if abs((a.pos - b.pos).length()) < (a.radius + b.radius) and a.state > 0 and b.state > 0:
		return true
	else:
		return false


static func explode(x, delta, multiplier):
	x.death_timer -= delta
	var modifier = x.death_timer * multiplier
	var scale_val = 2 - modifier
	x.set_scale(Vector2(scale_val, scale_val))
	x.set_modulate(Color(1, 1, 1, modifier))
	if x.death_timer <= 0:
		x.state = -1
