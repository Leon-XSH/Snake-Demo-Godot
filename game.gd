extends Node2D

# 游戏区域
@export var game_area_base_pos = Vector2(1, 2)
@export var game_area_width = 20
@export var game_area_height = 14

# 蛇的初始位置和长度
@export var snake_start_pos = Vector2(4, 7)
@export var snake_start_length = 3

signal sig_game_start()
signal sig_game_over()
signal sig_score_changed(score)

# 贴图词典key
enum TileKey { 
	SNAKE_HEAD_TO_RIGHT, SNAKE_HEAD_TO_LEFT, SNAKE_HEAD_TO_TOP, SNAKE_HEAD_TO_BOTTOM,
	SNAKE_BODY_TO_RIGHT, SNAKE_BODY_TO_LEFT, SNAKE_BODY_TO_TOP, SNAKE_BODY_TO_BOTTOM,
	SNAKE_TAIL_TO_RIGHT, SNAKE_TAIL_TO_LEFT, SNAKE_TAIL_TO_TOP, SNAKE_TAIL_TO_BOTTOM,
	SNAKE_BODY_BOTTOM_TO_RIGHT, SNAKE_BODY_BOTTOM_TO_LEFT,
	SNAKE_BODY_RIGHT_TO_TOP, SNAKE_BODY_RIGHT_TO_BOTTOM,
	SNAKE_BODY_TOP_TO_RIGHT, SNAKE_BODY_TOP_TO_LEFT,
	SNAKE_BODY_LEFT_TO_TOP, SNAKE_BODY_LEFT_TO_BOTTOM,
	OBJECT_APPLE, OBJECT_ORANGE, OBJECT_GRAPE, OBJECT_MOUSE, OBJECT_ROCK
	}

# 贴图的坐标
var tiles_coor_dict = {
	TileKey.SNAKE_HEAD_TO_RIGHT: Vector2(0, 1),
	TileKey.SNAKE_HEAD_TO_LEFT: Vector2(1, 1),
	TileKey.SNAKE_HEAD_TO_TOP: Vector2(2, 1),
	TileKey.SNAKE_HEAD_TO_BOTTOM: Vector2(3, 1),
	TileKey.SNAKE_BODY_TO_RIGHT: Vector2(0, 2),
	TileKey.SNAKE_BODY_TO_LEFT: Vector2(1, 2),
	TileKey.SNAKE_BODY_TO_TOP: Vector2(2, 2),
	TileKey.SNAKE_BODY_TO_BOTTOM: Vector2(3, 2),
	TileKey.SNAKE_TAIL_TO_RIGHT: Vector2(0, 3),
	TileKey.SNAKE_TAIL_TO_LEFT: Vector2(1, 3),
	TileKey.SNAKE_TAIL_TO_TOP: Vector2(2, 3),
	TileKey.SNAKE_TAIL_TO_BOTTOM: Vector2(3, 3),
	TileKey.SNAKE_BODY_BOTTOM_TO_RIGHT: Vector2(0, 4),
	TileKey.SNAKE_BODY_BOTTOM_TO_LEFT: Vector2(1, 4),
	TileKey.SNAKE_BODY_RIGHT_TO_TOP: Vector2(2, 4),
	TileKey.SNAKE_BODY_RIGHT_TO_BOTTOM: Vector2(3, 4),
	TileKey.SNAKE_BODY_TOP_TO_RIGHT: Vector2(0, 5),
	TileKey.SNAKE_BODY_TOP_TO_LEFT: Vector2(1, 5),
	TileKey.SNAKE_BODY_LEFT_TO_TOP: Vector2(2, 5),
	TileKey.SNAKE_BODY_LEFT_TO_BOTTOM: Vector2(3, 5),
	TileKey.OBJECT_APPLE: Vector2(0, 6),
	TileKey.OBJECT_ORANGE: Vector2(1, 6),
	TileKey.OBJECT_GRAPE: Vector2(2, 6),
	TileKey.OBJECT_MOUSE: Vector2(3, 6),
	TileKey.OBJECT_ROCK: Vector2(4, 6)
}

# 蛇的身躯位置坐标数组，从头到尾
var snake_pos_arr = []
# 蛇移动方向
var snake_move_direction = Vector2.RIGHT
var snake_move_direction_next = Vector2.RIGHT

var object_dict = {}
var food_arr = [TileKey.OBJECT_APPLE, TileKey.OBJECT_ORANGE, 
	TileKey.OBJECT_GRAPE, TileKey.OBJECT_MOUSE]
var last_snake_body_pos = Vector2.ZERO
var score = 0

# 根据传入的snake身躯坐标以及前后坐标，获取身躯坐标tile的key
func get_snake_tile_key(current, last, next):
	var result = TileKey.SNAKE_HEAD_TO_RIGHT
	var temp = Vector2.ZERO
	var temp2 = Vector2.ZERO
	
	if last == -Vector2.ONE and next == -Vector2.ONE:
		return result
	
	# 没有last，说明是head
	if last == -Vector2.ONE:
		temp = current - next
		if temp == Vector2.RIGHT:
			result = TileKey.SNAKE_HEAD_TO_RIGHT
		elif temp == Vector2.LEFT:
			result = TileKey.SNAKE_HEAD_TO_LEFT
		elif temp == Vector2.UP:
			result = TileKey.SNAKE_HEAD_TO_TOP
		elif temp == Vector2.DOWN:
			result = TileKey.SNAKE_HEAD_TO_BOTTOM
		return result
	
	# 没有next，说明是tail
	if next == -Vector2.ONE:
		temp = last - current
		if temp == Vector2.RIGHT:
			result = TileKey.SNAKE_TAIL_TO_RIGHT
		elif temp == Vector2.LEFT:
			result = TileKey.SNAKE_TAIL_TO_LEFT
		elif temp == Vector2.UP:
			result = TileKey.SNAKE_TAIL_TO_TOP
		elif temp == Vector2.DOWN:
			result = TileKey.SNAKE_TAIL_TO_BOTTOM
		return result
	
	# last和next都有，说明是中间的body
	temp = last - current
	temp2 = current - next
	if temp == temp2:
		if temp == Vector2.RIGHT:
			result = TileKey.SNAKE_BODY_TO_RIGHT
		elif temp == Vector2.LEFT:
			result = TileKey.SNAKE_BODY_TO_LEFT
		elif temp == Vector2.UP:
			result = TileKey.SNAKE_BODY_TO_TOP
		elif temp == Vector2.DOWN:
			result = TileKey.SNAKE_BODY_TO_BOTTOM
		return result
	else:
		if temp2 == Vector2.UP and temp == Vector2.RIGHT:
			result = TileKey.SNAKE_BODY_BOTTOM_TO_RIGHT
		elif temp2 == Vector2.UP and temp == Vector2.LEFT:
			result = TileKey.SNAKE_BODY_BOTTOM_TO_LEFT
		elif temp2 == Vector2.DOWN and temp == Vector2.RIGHT:
			result = TileKey.SNAKE_BODY_TOP_TO_RIGHT
		elif temp2 == Vector2.DOWN and temp == Vector2.LEFT:
			result = TileKey.SNAKE_BODY_TOP_TO_LEFT
		elif temp2 == Vector2.RIGHT and temp == Vector2.UP:
			result = TileKey.SNAKE_BODY_LEFT_TO_TOP
		elif temp2 == Vector2.RIGHT and temp == Vector2.DOWN:
			result = TileKey.SNAKE_BODY_LEFT_TO_BOTTOM
		elif temp2 == Vector2.LEFT and temp == Vector2.UP:
			result = TileKey.SNAKE_BODY_RIGHT_TO_TOP
		elif temp2 == Vector2.LEFT and temp == Vector2.DOWN:
			result = TileKey.SNAKE_BODY_RIGHT_TO_BOTTOM
		return result

func clear_game_status():
	snake_pos_arr.clear()
	object_dict.clear()
	$SnakeLayer.clear()
	$ObjectLayer.clear()
	snake_move_direction = Vector2.RIGHT
	snake_move_direction_next = Vector2.RIGHT
	last_snake_body_pos = Vector2.ZERO
	score = 0
	sig_score_changed.emit(score)

func game_start():
	clear_game_status()
	# 设置蛇的初始坐标
	snake_pos_arr.append(snake_start_pos)
	for i in range(snake_start_length - 1):
		snake_pos_arr.append(snake_pos_arr[-1] - Vector2(1, 0))
	set_snake_layer()
	spawn_random_rock(3)
	sig_game_start.emit()
	$UpdateTimer.start()

func game_over():
	$UpdateTimer.stop()
	print("You Lose, score = " + str(score))
	sig_game_over.emit()

# 设置snake层图像
func set_snake_layer():
	$SnakeLayer.clear()
	var arr_length = snake_pos_arr.size()
	var snake_tile_key = TileKey.SNAKE_HEAD_TO_RIGHT
	if arr_length < 2:
		return
	for i in range(arr_length):
		if i == 0:
			snake_tile_key = get_snake_tile_key(snake_pos_arr[i], -Vector2.ONE, snake_pos_arr[i+1])
		elif i == arr_length - 1:
			snake_tile_key = get_snake_tile_key(snake_pos_arr[i], snake_pos_arr[i-1], -Vector2.ONE)
		else:
			snake_tile_key = get_snake_tile_key(snake_pos_arr[i], snake_pos_arr[i-1], snake_pos_arr[i+1])
		$SnakeLayer.set_cell(snake_pos_arr[i], 0, tiles_coor_dict[snake_tile_key], 0)

func update_snake_pos_arr(): 
	var temp = snake_pos_arr[0] + snake_move_direction_next
	snake_pos_arr.push_front(temp)
	last_snake_body_pos = snake_pos_arr.pop_back()
	snake_move_direction = snake_move_direction_next

func length_snake_body():
	snake_pos_arr.push_back(last_snake_body_pos)

func clean_food(food_pos):
	$ObjectLayer.set_cell(food_pos, -1)
	object_dict.erase(food_pos)

func check_snake_pos():
	# 蛇头出了游戏边界
	if snake_pos_arr[0].x < game_area_base_pos.x \
		or snake_pos_arr[0].x > game_area_base_pos.x + game_area_width - 1 \
		or snake_pos_arr[0].y < game_area_base_pos.y \
		or snake_pos_arr[0].y > game_area_base_pos.y + game_area_height - 1 :
		game_over()
		return
	# 蛇头碰到了物体
	if object_dict.has(snake_pos_arr[0]):
		var object_type = object_dict[snake_pos_arr[0]]
		if object_type == TileKey.OBJECT_ROCK:
			game_over()
			return
		elif object_type == TileKey.OBJECT_APPLE:
			score += 1
			sig_score_changed.emit(score)
			length_snake_body()
			clean_food(snake_pos_arr[0])
		elif object_type == TileKey.OBJECT_ORANGE:
			score += 2
			sig_score_changed.emit(score)
			length_snake_body()
			clean_food(snake_pos_arr[0])
		elif object_type == TileKey.OBJECT_GRAPE:
			score += 3
			sig_score_changed.emit(score)
			length_snake_body()
			clean_food(snake_pos_arr[0])
		elif object_type == TileKey.OBJECT_MOUSE:
			score += 4
			sig_score_changed.emit(score)
			length_snake_body()
			clean_food(snake_pos_arr[0])

func check_snake_is_collide_self():
	var temp = snake_pos_arr[0] + snake_move_direction_next
	if snake_pos_arr.has(temp):
		return true
	return false

func update_snake_layer():
	if check_snake_is_collide_self():
		game_over()
		return
	update_snake_pos_arr()
	check_snake_pos()
	set_snake_layer()
	

func get_random_vector2(base_pos: Vector2, width: int, height: int) -> Vector2:
	return base_pos + Vector2(randi() % width, randi() % height)

func get_object_random_pos():
	var random_pos = get_random_vector2(game_area_base_pos, game_area_width, game_area_height)
	while snake_pos_arr.has(random_pos) or object_dict.has(random_pos):
		random_pos = get_random_vector2(game_area_base_pos, game_area_width, game_area_height)
	return random_pos

func spawn_random_rock(num):
	for i in range(num):
		var random_pos = get_object_random_pos()
		$ObjectLayer.set_cell(random_pos, 0, tiles_coor_dict[TileKey.OBJECT_ROCK], 0)
		object_dict[random_pos] = TileKey.OBJECT_ROCK

func spawn_random_food(num):
	for i in range(num):
		var random_pos = get_object_random_pos()
		var random_food = food_arr.pick_random()
		$ObjectLayer.set_cell(random_pos, 0, tiles_coor_dict[random_food], 0)
		object_dict[random_pos] = random_food
		

func update_object_layer():
	if object_dict.size() < 6:
		spawn_random_food(1)

# 根据得分变化游戏速度
func update_game_speed():
	if score > 50:
		$UpdateTimer.wait_time = 0.1
	elif score > 40:
		$UpdateTimer.wait_time = 0.2
	elif score > 30:
		$UpdateTimer.wait_time = 0.3
	elif score > 20:
		$UpdateTimer.wait_time = 0.4
	elif score > 10:
		$UpdateTimer.wait_time = 0.5
	else:
		$UpdateTimer.wait_time = 0.6

func update_layers():
	# 游戏未开始
	if snake_pos_arr.is_empty():
		return
	update_snake_layer()
	update_object_layer()
	update_game_speed()

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		if snake_move_direction != Vector2.DOWN:
			snake_move_direction_next = Vector2.UP
	elif event.is_action_pressed("ui_down"):
		if snake_move_direction != Vector2.UP:
			snake_move_direction_next = Vector2.DOWN
	elif event.is_action_pressed("ui_left"):
		if snake_move_direction != Vector2.RIGHT:
			snake_move_direction_next = Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		if snake_move_direction != Vector2.LEFT:
			snake_move_direction_next = Vector2.RIGHT

# 定时器，每隔一段时间刷新屏幕
func _on_update_timer_timeout() -> void:
	update_layers()

func _on_start_button_pressed() -> void:
	game_start()

func _on_retry_button_pressed() -> void:
	game_start()
