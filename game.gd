extends Node2D

var timer = 0
var spawn_count = 0
var score = 0
var kill_count = 0
var boss_mode = false
var boss_defeated = false
var enemy_dict = {}
var player
var score_label
var sfx_player


class Bullet extends Sprite:
	var radius = 4
	var state = 1
	var death_timer = 0.1
	var use_default_image = true
	var pos
	var speed
	var direction
	var parent
	
	func _init(pos, speed, direction):
		self.set_pos(pos)
		self.pos = pos
		self.speed = speed
		self.direction = direction
	
	func _ready():
		parent = get_parent()
		set_process(true)
	
	func _process(delta):
		pos = get_pos()
		if pos.x < -global.margin or pos.y < -global.margin or pos.x > global.screen_size.x + global.margin or pos.y > global.screen_size.y + global.margin:
			state = -1
		if state == -1:
			set_process(false)
			queue_free()
			return
		elif state == 0:
			global.explode(self, delta, 10)
		else:
			pos += direction * speed * delta
			set_pos(pos)


class EnemyBullet extends Bullet:
	func _init(pos, speed, direction).(pos, speed, direction):
		pass
	
	func _ready():
		if use_default_image:
			set_texture(global.enemy_bullet_image)
	
	func _process(delta):
		if global.collides(self, parent.player):
			parent.sfx_player.play("hit")
			state = 0
			parent.player.state = 0


class HomingBullet extends EnemyBullet:
	var brake_speed
	var second_speed
	
	func _init(pos, speed, direction, brake_speed, second_speed).(pos, speed, direction):
		self.brake_speed = brake_speed
		self.second_speed = second_speed
		self.use_default_image = false
	
	func _ready():
		set_texture(global.homing_bullet_image)
	
	func _process(delta):
		speed -= brake_speed * delta
		if speed < 0.05:
			direction = (parent.player.pos - pos).normalized()
			brake_speed = 1
			speed = second_speed


class CopyBullet extends EnemyBullet:
	var timer
	var charge_time
	var rotation
	
	func _init(pos, speed, direction, rotation, charge_time).(pos, speed, direction):
		self.rotation = rotation
		self.charge_time = charge_time
		self.timer = charge_time
		self.use_default_image = false
	
	func _ready():
		set_texture(global.copy_bullet_image)
	
	func _process(delta):
		timer -= delta
		if timer <= 0:
			for i in [-1, 1]:
				var new_bullet = parent.CopyBullet.new(pos, speed, direction.rotated(rotation * i), rotation, charge_time)
				parent.add_child(new_bullet)
			timer = charge_time


class Enemy extends Sprite:
	var state = 1
	var death_timer = 0.1
	var hp
	var radius
	var pos
	var speed
	var direction
	var shot_timer
	var cooldown
	var shot_interval
	var clip_count
	var clip_size
	var points
	var parent
	
	func _init(pos, speed, direction):
		self.set_pos(pos)
		self.pos = pos
		self.speed = speed
		self.direction = direction
	
	func _ready():
		parent = get_parent()
		parent.enemy_dict[self] = null
		set_process(true)
	
	func _process(delta):
		shot_timer -= delta
		
		if hp <= 0 and state > 0:
			parent.sfx_player.play("explode")
			state = 0
			parent.kill_count += 1
			alter_score(1)
		
		pos = get_pos()
		if pos.x < -global.margin or pos.y < -global.margin or pos.x > global.screen_size.x + global.margin or pos.y > global.screen_size.y + global.margin:
			state = -1
			if parent.player.state > 0:
				alter_score(-0.5)
		if state == -1:
			parent.enemy_dict.erase(self)
			set_process(false)
			queue_free()
			return
		elif state == 0:
			global.explode(self, delta, 10)
		elif shot_timer <= 0:
			shoot()
		pos += direction * speed * delta  # keep moving even if dying
		set_pos(pos)
	
	func shoot():
		parent.sfx_player.play("shoot")
		clip_count -= 1
		if clip_count > 0:
			shot_timer = shot_interval
		else:
			shot_timer = cooldown
			clip_count = clip_size
	
	func alter_score(multiplier):
		parent.score += int(multiplier * points)
		parent.score_label.set_text("Valor: %s" % parent.score)


class SpamEnemy extends Enemy:
	var bullet_speed
	
	func _init(pos, direction).(pos, 100, direction):
		self.hp = 8
		self.radius = 32
		self.bullet_speed = global.randint(160, 240)
		self.cooldown = 0.7
		self.shot_interval = 0.1
		self.clip_size = 3
		self.shot_timer = rand_range(0, self.cooldown)
		self.clip_count = self.clip_size
		self.points = 100
	
	func _ready():
		set_texture(global.spam_enemy_image)
	
	func shoot():
		var dir = Vector2(0, 1).rotated(deg2rad(global.randint(-30, 30)))
		var bullet = EnemyBullet.new(pos + Vector2(0, 49), bullet_speed, dir)
		parent.add_child(bullet)
		.shoot()


class SniperEnemy extends Enemy:
	var brake_speed
	var bullet_brake_speed
	var dir_interval
	
	func _init(pos).(pos, 400, Vector2(0, 1)):
		self.hp = 4
		self.radius = 32
		self.brake_speed = global.randint(400, 600)
		self.bullet_brake_speed = global.randint(1200, 1400)
		self.dir_interval = global.randint(10, 50)
		self.cooldown = 2
		self.shot_interval = 0.5
		self.clip_size = 2
		self.shot_timer = rand_range(0, self.cooldown)
		self.clip_count = self.clip_size
		self.points = 200
	
	func _ready():
		set_texture(global.sniper_enemy_image)
	
	func _process(delta):
		speed -= brake_speed * delta
		if speed < 0:
			speed = 0
	
	func shoot():
		var dir
		var bullet
		for x in range(-1.5 * dir_interval, 1.5 * dir_interval + 2, dir_interval):
			dir = Vector2(0, 1).rotated(deg2rad(x))
			bullet = HomingBullet.new(pos + Vector2(0, 40), 600, dir, bullet_brake_speed, 400)
			parent.add_child(bullet)
		.shoot()


class QuickEnemy extends Enemy:
	var copy_angle
	
	func _init(pos, speed, direction).(pos, speed, direction):
		self.hp = 2
		self.radius = 32
		self.copy_angle = deg2rad(global.randint(12, 18))
		self.cooldown = 1
		self.shot_interval = 0
		self.clip_size = 1
		self.shot_timer = rand_range(0, cooldown)
		self.clip_count = self.clip_size
		self.points = 300
	
	func _ready():
		set_texture(global.quick_enemy_image)
	
	func shoot():
		var bullet = CopyBullet.new(pos + Vector2(0, 40), 120, Vector2(0, 1), copy_angle, 1.5)
		parent.add_child(bullet)
		.shoot()


class Boss extends Enemy:
	var timer
	var subtimer
	var bullet_speed
	var rotation
	var rotation2
	var rotation_speed
	var mode
	var chance_shot_range
	var cooldown_dict = {
		0: 1000,
		1: 0.25,
		2: 0.5,
		3: 0.1
	}
	
	func _init().(Vector2(global.screen_size.x / 2, -70), 121, Vector2(0, 1)):
		self.hp = 80
		self.radius = 26
		self.subtimer = -1
		self.rotation = Vector2(0, 1)
		self.rotation2 = self.rotation
		self.mode = 0
		self.points = 2000
		self.cooldown = self.cooldown_dict[self.mode]
		self.shot_timer = self.cooldown
		self.clip_size = 1
		self.clip_count = 1
		self.timer = 1
	
	func _ready():
		set_texture(global.boss_image)
	
	func _process(delta):
		timer -= delta
		if mode == 3:
			subtimer -= delta
		if timer <= 0:
			if mode == 0:
				speed = 0
			change_mode()
		if hp == 0 and not parent.boss_defeated:
			parent.boss_defeated = true
			parent.player.set_process(false)
			parent.get_node("stage_music").stop()
			var game_over_label = parent.get_node("text_node/game_over_label")
			game_over_label.set_text("CONGRATULATIONS")
			game_over_label.show()
	
	func change_mode():
		var original_mode = mode
		subtimer = 4 - mode
		while mode == original_mode:
			mode = global.randint(1, 4)
		if mode > 3:
			mode = 1
		cooldown = cooldown_dict[mode]
		shot_timer = cooldown
		chance_shot_range = 2 * (int(1 / cooldown) - 1)
		bullet_speed = global.randint(60, 80)
		rotation_speed = deg2rad(global.randint(6, 9))
		if global.randint(0, 1) == 0:
			rotation_speed *= -1
		timer = global.randint(8, 12)

	
	func shoot():
		var dir
		var bullet
		var posx
		var posy
		var posx_limit = global.screen_size.x - 40
		if global.randint(0, chance_shot_range) == 0:
			if mode == 2:
				var copy_angle = deg2rad(global.randint(6, 24))
				posx = global.randint(40, posx_limit)
				bullet = CopyBullet.new(Vector2(posx, 100), 60, Vector2(0, 1), copy_angle, 3)
				parent.add_child(bullet)
			else:
				for x in [50, 349]:
					bullet = HomingBullet.new(Vector2(x, 100), 0, Vector2(0, 1), 0, 300)
					parent.add_child(bullet)
		if mode == 1:
			for x in range(0, 361, 15):
				dir = rotation.rotated(deg2rad(x))
				bullet = EnemyBullet.new(pos, bullet_speed, dir)
				parent.add_child(bullet)
				dir = rotation2.rotated(deg2rad(x))
				bullet = EnemyBullet.new(pos, 0.95 * bullet_speed, dir)
				parent.add_child(bullet)
			rotation = rotation.rotated(rotation_speed)
			rotation2 = rotation2.rotated(-rotation_speed - 1)
		elif mode == 2:
			var posy_limit = global.screen_size.y / 2
			var brake_speed
			dir = Vector2(0, 1)
			for i in range(4):
				posx = global.randint(40, posx_limit)
				posy = global.randint(100, posy_limit)
				dir = dir.rotated(deg2rad(global.randint(0, 359)))
				brake_speed = global.randint(500, 600)
				bullet = HomingBullet.new(Vector2(posx, posy), 300, dir, brake_speed, 200)
				parent.add_child(bullet)
		elif mode == 3:
			dir = Vector2(0, 1)
			posy = pos.y + 61
			if subtimer > 0:
				bullet = EnemyBullet.new(Vector2(200, posy), 700, dir)
				parent.add_child(bullet)
			else:
				for x in range(42, posx_limit -1, 4):
					bullet = EnemyBullet.new(Vector2(x, posy), 700, dir)
					parent.add_child(bullet)
		.shoot()


func _ready():
	player = get_node("player")
	score_label = get_node("text_node/score_label")
	sfx_player = get_node("sfx_player")
	set_process(true)


func _process(delta):
	if not boss_mode:
		timer -= delta
		if timer <= 0:
			timer = global.randint(4, 6)
			if spawn_count < 8:
				spawn()
			elif player.state > 0:
				if kill_count > 0:
					boss_mode = true
					for enemy in enemy_dict:
						enemy.state = 0
					add_child(Boss.new())
				else:
					player.set_process(false)
					get_node("stage_music").stop()
					score = 9999
					for enemy in enemy_dict:
						enemy.state = 0
					score_label.set_text("Valor: %s" % score)
					var game_over_label = get_node("text_node/game_over_label")
					game_over_label.set_text("YOU ARE NOT OUR ENEMY")
					game_over_label.show()
					boss_defeated = true

	
	if (player.state == -1 or boss_defeated) and Input.is_action_pressed("shoot_bullets"):
		var save_data = global.read_save()
		if score > save_data["high_score"]:
			save_data["high_score"] = score
			global.write_save(save_data)
		set_process_input(true)

func _input(event):
	if event.is_action_released("shoot_bullets"):
		if player.firing:
			player.firing = false
		else:
			get_tree().change_scene("res://main_menu.tscn")


func spawn():
	var enemy
	var posx
	var posy
	var dir
	var posx_limit = global.screen_size.x - 40
	var difficulty = int(pow(spawn_count, 0.5))
	for i in range(2 + global.randint(0, difficulty)):
		posx = global.randint(40, posx_limit)
		dir = Vector2(0, 1).rotated(deg2rad(rand_range(-15, 15)))
		enemy = SpamEnemy.new(Vector2(posx, -80 + global.randint(0, 20)), dir)
		add_child(enemy)
	for i in range(global.randint(0, difficulty)):
		posx = global.randint(40, posx_limit)
		enemy = SniperEnemy.new(Vector2(posx, -80))
		add_child(enemy)
	for i in range(global.randint(0, difficulty)):
		if global.randint(0, 1) == 1:
			posx = global.screen_size.x + 80
			dir = Vector2(-1, 0)
		else:
			posx = -80
			dir = Vector2(1, 0)
		posy = global.randint(40, 160)
		enemy = QuickEnemy.new(Vector2(posx, posy), global.randint(80, 120), dir)
		add_child(enemy)
	spawn_count += 1
