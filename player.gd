extends Sprite

const MAX_SPEED = 300
const SLOW_SPEED = 100
var radius = 1
var state = 1  # >= 1: live, 0: dying, -1: dead
var death_timer = 0.1
var shot_timer = 0
var cooldown = 0.2
var firing = false
var pos
var speed
var direction
var speed_multiplier
var parent


class PlayerBullet extends "game.gd".Bullet:
	func _init(pos, speed, direction).(pos, speed, direction):
		pass
	
	func _ready():
		set_texture(global.player_bullet_image)
	
	func _process(delta):
		for enemy in parent.enemy_dict:
			if global.collides(self, enemy):
				parent.get_node("sfx_player").play("hit")
				state = 0
				enemy.hp -= 1
				break


func _init():
	pos = get_pos()


func _ready():
	parent = get_parent()
	set_process(true)


func _process(delta):
	shot_timer -= delta
	
	if state == -1:
		parent.get_node("sfx_player").play("explode")
		parent.get_node("stage_music").stop()
		var death_messages = [
			"FAREWELL",
			"YOUR SPECIES IS WEAK",
			"SUFFER",
			"DESPAIR",
			"YOU ARE NOTHING TO US",
			"YOUR EFFORTS ARE MEANINGLESS",
			"YOUR SPECIES IS IRREDEEMABLE",
			"YOU MUST BE PUNISHED"
		]
		var game_over_label = parent.get_node("text_node/game_over_label")
		game_over_label.set_text(death_messages[randi()%death_messages.size()])
		game_over_label.show()
		set_process(false)
		return
	elif state == 0:
		global.explode(self, delta, 10)
	else:
		if Input.is_action_pressed("shoot_bullets"):
			if shot_timer <= 0:
				shoot()
			firing = true
		else:
			firing = false
	
	if Input.is_action_pressed("slow_mode"):
		speed = SLOW_SPEED
	else:
		speed = MAX_SPEED
	
	direction = Vector2()
	if Input.is_action_pressed("ui_up"):
		direction += Vector2(0, -1)
	if Input.is_action_pressed("ui_down"):
		direction += Vector2(0, 1)
	if Input.is_action_pressed("ui_left"):
		direction += Vector2(-1, 0)
	if Input.is_action_pressed("ui_right"):
		direction += Vector2(1, 0)
	direction = direction.normalized()
	
	pos = get_pos()
	pos += delta * direction * speed
	if pos.x < 0:
		pos.x = 0
	if pos.x > global.screen_size.x:
		pos.x = global.screen_size.x
	if pos.y < 0:
		pos.y = 0
	if pos.y > global.screen_size.y:
		pos.y = global.screen_size.y
	
	for enemy in parent.enemy_dict:
		if global.collides(self, enemy):
			state = 0
			enemy.hp -= 1
			break
	
	set_pos(pos)


func shoot():
	parent.get_node("sfx_player").play("shoot")
	var bullet = PlayerBullet.new(pos + Vector2(0, -41), 1000, Vector2(0, -1))
	parent.add_child(bullet)
	shot_timer = cooldown
