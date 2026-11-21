extends Node2D
## Игровой экран Snake Yes.
##
## Поле 10×10 из песчаных тайлов (board.png: тайл из примера SSSPICY +
## выпеченные обводка и грань) на голубом фоне. У поля, чья сторона не
## примыкает к другим клеткам, тёмная обводка, а под нижним рядом —
## оранжевая боковая грань (3D-эффект), как в примере. Стен нет: выезд
## за поле (на голубое) — смерть.
##
## Змейка (спрайты GreenSnake, ДИСКРЕТНОЕ перемещение — мгновенный переход
## между клетками, без твинов):
## - голова — head / head_eat (когда яблоко в соседней клетке по курсу);
## - тело — body_h / body_v, на поворотах — уголки corner_* (файлы названы
##   по сторонам соединений: top_right = {вверх, вправо} и т.д.);
## - хвост — tail_* по направлению округлого кончика;
## - одна клетка = один спрайт: куски не накладываются друг на друга.
##
## Змейка начинает двигаться только после первого действия игрока
## (нажатие направления или свайп). Управление: WASD / стрелочки, свайпы.
## Съеденное яблоко удлиняет змейку с хвоста и запускает эффект-звёздочки
## (как в примере). При старте игры всё поле падает сверху и приземляется
## с пылью, отскоком и лёгкой тряской. Столкновение с краем поля или с
## собой: голова смотрит в сторону удара, змейка исчезает с головы до
## хвоста, затем — надпись «you lose!!» шрифтом примера. Полное поле —
## надпись «you win!!» из примера. После сообщения — в главное меню.

const MENU_SCENE := "res://scenes/main_menu.tscn"

const TEX_BODY_H: Texture2D = preload("res://assets/Snakes/GreenSnake/body/GreenSnake_body_h.png")
const TEX_BODY_V: Texture2D = preload("res://assets/Snakes/GreenSnake/body/GreenSnake_body_v.png")
const TEX_CORNER_TR: Texture2D = preload("res://assets/Snakes/GreenSnake/corner/GreenSnake_corner_top_right.png")
const TEX_CORNER_LT: Texture2D = preload("res://assets/Snakes/GreenSnake/corner/GreenSnake_corner_left_top.png")
const TEX_CORNER_RB: Texture2D = preload("res://assets/Snakes/GreenSnake/corner/GreenSnake_corner_right_bottom.png")
const TEX_CORNER_BL: Texture2D = preload("res://assets/Snakes/GreenSnake/corner/GreenSnake_corner_bottom_left.png")
const TEX_HEAD_RIGHT: Texture2D = preload("res://assets/Snakes/GreenSnake/head/GreenSnake_head_right.png")
const TEX_HEAD_DOWN: Texture2D = preload("res://assets/Snakes/GreenSnake/head/GreenSnake_head_down.png")
const TEX_HEAD_LEFT: Texture2D = preload("res://assets/Snakes/GreenSnake/head/GreenSnake_head_left.png")
const TEX_HEAD_UP: Texture2D = preload("res://assets/Snakes/GreenSnake/head/GreenSnake_head_up.png")
const TEX_HEAD_EAT_RIGHT: Texture2D = preload("res://assets/Snakes/GreenSnake/head_eat/GreenSnake_head_eat_right.png")
const TEX_HEAD_EAT_DOWN: Texture2D = preload("res://assets/Snakes/GreenSnake/head_eat/GreenSnake_head_eat_down.png")
const TEX_HEAD_EAT_LEFT: Texture2D = preload("res://assets/Snakes/GreenSnake/head_eat/GreenSnake_head_eat_left.png")
const TEX_HEAD_EAT_UP: Texture2D = preload("res://assets/Snakes/GreenSnake/head_eat/GreenSnake_head_eat_up.png")
const TEX_TAIL_LEFT: Texture2D = preload("res://assets/Snakes/GreenSnake/tail/GreenSnake_tail_left.png")
const TEX_TAIL_RIGHT: Texture2D = preload("res://assets/Snakes/GreenSnake/tail/GreenSnake_tail_right.png")
const TEX_TAIL_UP: Texture2D = preload("res://assets/Snakes/GreenSnake/tail/GreenSnake_tail_up.png")
const TEX_TAIL_DOWN: Texture2D = preload("res://assets/Snakes/GreenSnake/tail/GreenSnake_tail_down.png")
const TEX_BOARD: Texture2D = preload("res://assets/Field/board.png")
const TEX_STAR: Texture2D = preload("res://assets/Effects/star.png")
const TEX_DUST: Texture2D = preload("res://assets/Effects/dust.png")
const TEX_WIN_TEXT: Texture2D = preload("res://assets/UI/win_text.png")
const UI_FONT: FontFile = preload("res://assets/fonts/default-font.fnt")

# --- Поле (как в примере SSSPICY) ---
const SIDE_H := 28.0                     # высота боковой грани (для пыли приземления)

const APPLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/Apple/Red_Apple1.png"),
	preload("res://assets/Apple/Red_Apple2.png"),
	preload("res://assets/Apple/Red_Apple3.png"),
	preload("res://assets/Apple/Red_Apple4.png"),
	preload("res://assets/Apple/Red_Apple5.png"),
	preload("res://assets/Apple/Red_Apple6.png"),
	preload("res://assets/Apple/Red_Apple7.png"),
]

const EFFECT_FRAMES: Array[Texture2D] = [
	preload("res://assets/Snakes/Effect/Effect1.png"),
	preload("res://assets/Snakes/Effect/Effect2.png"),
	preload("res://assets/Snakes/Effect/Effect3.png"),
	preload("res://assets/Snakes/Effect/Effect4.png"),
	preload("res://assets/Snakes/Effect/Effect5.png"),
	preload("res://assets/Snakes/Effect/Effect6.png"),
	preload("res://assets/Snakes/Effect/Effect7.png"),
	preload("res://assets/Snakes/Effect/Effect8.png"),
]

# --- Геометрия ---
const GRID := 10                         # игровое поле 10×10 клеток
const CELL := 64                         # размер клетки, px

const TICK_TIME := 0.3
const DEATH_PAUSE := 0.5
const DEATH_VANISH_INTERVAL := 0.16
const MENU_RETURN_DELAY := 0.8
const SWIPE_MIN_LENGTH := 32.0
const MAX_DIR_QUEUE := 3
const APPLE_FPS := 8.0
const EFFECT_FPS := 14.0

# --- Падение мира при старте (как в примере) ---
const FALL_OFFSET := 760.0               # с какой высоты падает поле
const FALL_TIME := 0.45                  # время падения (ускорение, как у гравитации)
const LAND_BOUNCE_UP := 18.0             # высота отскока после приземления

# --- Сообщения о выигрыше/проигрыше ---
const WIN_HOLD := 2.2                    # сколько висит надпись «you win!!»
const LOSE_HOLD := 1.9                   # сколько висит надпись «you lose!!»
const MESSAGE_TEXT_SCALE := 1.5          # «you win!!» 568×184 → крупнее по центру

# --- Спрайты змейки: 128×128 (контент 96 px) -> масштаб под клетку 64 px ---
const SNAKE_SCALE := 2.0 / 3.0

# --- Звуки (случайная «еда» при поедании, остальные — по событиям) ---
const SND_EAT: Array[AudioStream] = [
	preload("res://assets/sfx/еда1.ogg"),
	preload("res://assets/sfx/еда2.ogg"),
]
const SND_LOSE: AudioStream = preload("res://assets/sfx/проигрыш.ogg")
const SND_WIN: AudioStream = preload("res://assets/sfx/победа.ogg")
const SND_TURN: AudioStream = preload("res://assets/sfx/поворот.ogg")

enum State { PLAYING, DYING, LEAVING }

var state := State.PLAYING
var board_origin := Vector2.ZERO
var snake: Array[Vector2i] = []          # [голова, ..., хвост]
var snake_sprites: Array[Sprite2D] = []  # параллельно snake
var dir := Vector2i.RIGHT
var apple_cell := Vector2i(-1, -1)

var _dir_queue: Array[Vector2i] = []
var _effect_frames: SpriteFrames
var _head_tex: Array[Texture2D] = []     # по индексу направления
var _head_eat_tex: Array[Texture2D] = [] # по индексу направления
var _tail_tex: Array[Texture2D] = []     # по индексу направления кончика
var _swipe_active := false
var _swipe_start := Vector2.ZERO
var _world_landed := false               # поле ещё падает — ввод заблокирован
var _eat_player: AudioStreamPlayer
var _one_shot_players: Dictionary = {}   # «проигрыш»/«победа»/«поворот» -> плеер

@onready var world: Node2D = $World
@onready var board_layer: Node2D = $World/Board
@onready var snake_layer: Node2D = $World/SnakeLayer
@onready var apple_sprite: AnimatedSprite2D = $World/Apple
@onready var effects_layer: Node2D = $World/Effects
@onready var tick_timer: Timer = $TickTimer


func _ready() -> void:
	_head_tex = [TEX_HEAD_RIGHT, TEX_HEAD_DOWN, TEX_HEAD_LEFT, TEX_HEAD_UP]
	_head_eat_tex = [TEX_HEAD_EAT_RIGHT, TEX_HEAD_EAT_DOWN, TEX_HEAD_EAT_LEFT, TEX_HEAD_EAT_UP]
	_tail_tex = [TEX_TAIL_RIGHT, TEX_TAIL_DOWN, TEX_TAIL_LEFT, TEX_TAIL_UP]

	_effect_frames = SpriteFrames.new()
	_effect_frames.set_animation_speed("default", EFFECT_FPS)
	_effect_frames.set_animation_loop("default", false)
	for tex in EFFECT_FRAMES:
		_effect_frames.add_frame("default", tex)

	_make_audio_players()

	board_origin = Vector2(960, 540) - Vector2(GRID, GRID) * CELL * 0.5
	_build_board()
	_setup_apple()
	_spawn_snake()
	_respawn_apple()
	_play_world_drop()

	# Таймер НЕ запускается: змейка стоит до первого действия игрока.
	tick_timer.timeout.connect(_tick)


# --- Звук ---

func _make_audio_players() -> void:
	_eat_player = AudioStreamPlayer.new()
	add_child(_eat_player)
	for item in [["lose", SND_LOSE], ["win", SND_WIN], ["turn", SND_TURN]]:
		var p := AudioStreamPlayer.new()
		p.stream = item[1]
		add_child(p)
		_one_shot_players[item[0]] = p


func _play_eat() -> void:
	_eat_player.stream = SND_EAT[randi() % SND_EAT.size()]
	_eat_player.play()


func _play_sound(sound: String) -> void:
	var p: AudioStreamPlayer = _one_shot_players.get(sound)
	if p:
		p.play()


# --- Построение поля ---

func cell_to_px(c: Vector2i) -> Vector2:
	return board_origin + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func _build_board() -> void:
	# Поле одной текстурой: песчаные тайлы, обводка свободных сторон и
	# боковая грань (3D-эффект) выпечены заранее в board.png — один спрайт
	# вместо ~140 узлов и без рассинхрона при падении мира.
	var board := Sprite2D.new()
	board.texture = TEX_BOARD
	board.centered = false
	board.position = board_origin
	board_layer.add_child(board)


func _setup_apple() -> void:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", APPLE_FPS)
	frames.set_animation_loop("default", true)
	for tex in APPLE_FRAMES:
		frames.add_frame("default", tex)
	apple_sprite.sprite_frames = frames
	apple_sprite.scale = Vector2(0.6, 0.6) # спрайт 128 px -> ~77 px, яблоко ~0.8 клетки
	apple_sprite.play("default")


# --- Падение мира (как в примере: поле падает сверху и приземляется) ---

func _play_world_drop() -> void:
	world.position.y = -FALL_OFFSET
	var tw := create_tween()
	tw.tween_property(world, "position:y", 0.0, FALL_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_on_world_landed)


## Приземление: пыль по нижней грани, небольшой отскок и лёгкая тряска.
func _on_world_landed() -> void:
	_world_landed = true
	_spawn_landing_dust()

	var bounce := create_tween()
	bounce.tween_property(world, "position:y", -LAND_BOUNCE_UP, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.tween_property(world, "position:y", 0.0, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var shake := create_tween()
	for offset in [6.0, -6.0, 4.0, -4.0, 2.0, 0.0]:
		shake.tween_property(world, "position:x", offset, 0.04)


## Облачка пыли вдоль нижней кромки поля при приземлении.
func _spawn_landing_dust() -> void:
	var ground_y := board_origin.y + GRID * CELL + SIDE_H * 0.5
	var count := 8
	for i in count:
		var s := Sprite2D.new()
		s.texture = TEX_DUST
		s.z_index = 3
		var t := (i + 0.5) / count
		s.position = Vector2(
			board_origin.x + t * GRID * CELL + randf_range(-18.0, 18.0),
			ground_y + randf_range(-6.0, 6.0)
		)
		var base_scale := randf_range(0.35, 0.55)
		s.scale = Vector2.ONE * base_scale * 0.5
		s.modulate.a = 0.0
		effects_layer.add_child(s)

		var tw := create_tween().set_parallel(true)
		tw.tween_property(s, "modulate:a", 0.85, 0.08)
		tw.tween_property(s, "scale", Vector2.ONE * base_scale, 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position:y", s.position.y - randf_range(16.0, 34.0), 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(s, "modulate:a", 0.0, 0.18)
		tw.chain().tween_callback(s.queue_free)


func _spawn_snake() -> void:
	# Стартуем в центре: головой вправо, длина 3, до первого действия стоим.
	@warning_ignore("integer_division")
	var start_row := GRID / 2
	snake = [Vector2i(4, start_row), Vector2i(3, start_row), Vector2i(2, start_row)]
	for c in snake:
		var s := Sprite2D.new()
		s.z_index = 0
		snake_layer.add_child(s)
		snake_sprites.append(s)
	_refresh_snake_sprites()


# --- Логика движения ---

func _tick() -> void:
	if state != State.PLAYING:
		return

	if not _dir_queue.is_empty():
		dir = _dir_queue.pop_front()

	var next := snake[0] + dir

	# Выезд за поле (на голубое) или встреча с собственным телом — смерть.
	if _is_outside_field(next) or _snake_contains(next, snake.size() - 1):
		_face_hit(Vector2i(next - snake[0]))
		_die()
		return

	snake.push_front(next)
	if next == apple_cell:
		_on_ate()
	else:
		snake.pop_back() # хвост уходит, длина не меняется

	_refresh_snake_sprites()


func _is_outside_field(c: Vector2i) -> bool:
	return c.x < 0 or c.y < 0 or c.x >= GRID or c.y >= GRID


func _snake_contains(cell: Vector2i, limit: int = -1) -> bool:
	var n := snake.size() if limit < 0 else mini(limit, snake.size())
	for i in n:
		if snake[i] == cell:
			return true
	return false


func _on_ate() -> void:
	_spawn_eat_stars(apple_cell)
	_play_eat()
	# Рост с зада: новый сегмент-хвост остаётся в старой клетке хвоста.
	var s := Sprite2D.new()
	s.z_index = 0
	snake_layer.add_child(s)
	snake_sprites.append(s)
	_respawn_apple()


func _respawn_apple() -> void:
	var free := _free_cells()
	if free.is_empty():
		_field_filled()
		return
	apple_cell = free[randi() % free.size()]
	apple_sprite.position = cell_to_px(apple_cell)


func _free_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in GRID:
		for x in GRID:
			var c := Vector2i(x, y)
			if not _snake_contains(c):
				cells.append(c)
	return cells


# --- Визуал змейки: одна клетка — один спрайт ---

## Расставляет все куски по клеткам snake и подбирает текстуру каждого
## куска по его соседям. Вызывается после каждого шага и при спавне.
func _refresh_snake_sprites() -> void:
	var n := snake.size()
	for i in n:
		var sprite := snake_sprites[i]
		sprite.rotation = 0.0
		sprite.scale = Vector2(SNAKE_SCALE, SNAKE_SCALE)
		sprite.position = cell_to_px(snake[i])
		if i == 0:
			# Голова смотрит по направлению движения; head_eat — если
			# яблоко в соседней клетке прямо по курсу.
			var eat: bool = snake[0] + dir == apple_cell
			sprite.texture = _head_eat_tex[_dir_index(dir)] if eat else _head_tex[_dir_index(dir)]
			sprite.z_index = 2
		elif i == n - 1:
			# Кончик хвоста смотрит назад, против движения.
			var tip := snake[i] - snake[i - 1]
			sprite.texture = _tail_tex[_dir_index(tip)]
			sprite.z_index = 0
		else:
			var to_head := snake[i - 1] - snake[i]
			var to_tail := snake[i + 1] - snake[i]
			sprite.z_index = 0
			if to_head.x != 0 and to_tail.x != 0:
				sprite.texture = TEX_BODY_H
			elif to_head.y != 0 and to_tail.y != 0:
				sprite.texture = TEX_BODY_V
			else:
				# Уголок по паре сторон соединения (файлы названы по ним).
				var sum := to_head + to_tail
				if sum.y < 0:
					sprite.texture = TEX_CORNER_TR if sum.x > 0 else TEX_CORNER_LT
				else:
					sprite.texture = TEX_CORNER_RB if sum.x > 0 else TEX_CORNER_BL


func _dir_index(d: Vector2i) -> int:
	if d.x > 0:
		return 0
	if d.y > 0:
		return 1
	if d.x < 0:
		return 2
	return 3


# --- Эффекты ---

## Эффект поедания, как в примере: жёлтые звёздочки разлетаются из клетки
## с яблоком, раскручиваются и растворяются.
func _spawn_eat_stars(cell: Vector2i) -> void:
	var center := cell_to_px(cell)
	var count := 6
	for i in count:
		var s := Sprite2D.new()
		s.texture = TEX_STAR
		s.z_index = 3
		var ang := TAU * i / count + randf_range(-0.35, 0.35)
		var dir := Vector2.from_angle(ang)
		s.position = center + dir * randf_range(10.0, 26.0)
		s.rotation = randf_range(0.0, TAU)
		var base_scale := randf_range(0.16, 0.3)
		s.scale = Vector2.ONE * base_scale * 0.4
		effects_layer.add_child(s)

		var tw := create_tween().set_parallel(true)
		tw.tween_property(s, "scale", Vector2.ONE * base_scale, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position", s.position + dir * randf_range(14.0, 30.0), 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "rotation", s.rotation + randf_range(-1.6, 1.6), 0.3)
		tw.tween_property(s, "modulate:a", 0.0, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(s.queue_free)


## Белая вспышка на месте сегмента (исчезновение змейки при смерти).
func _spawn_effect(cell: Vector2i) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _effect_frames
	s.scale = Vector2(1, 1) # кадры эффекта 64×64 — ровно клетка
	s.z_index = 3 # эффект виден поверх головы
	s.position = cell_to_px(cell)
	effects_layer.add_child(s)
	s.play("default")
	s.animation_finished.connect(s.queue_free)


# --- Смерть и возврат в меню ---

## Голова в момент удара смотрит в сторону столкновения.
func _face_hit(d: Vector2i) -> void:
	var head := snake_sprites[0]
	head.texture = _head_tex[_dir_index(d)]
	head.rotation = 0.0


func _die() -> void:
	state = State.DYING
	tick_timer.stop()
	_play_sound("lose")

	var tw := create_tween()
	tw.tween_interval(DEATH_PAUSE)
	# План исчезновения строим заранее: по шагу на каждый сегмент,
	# с головы до хвоста (сами сегменты убирает _vanish_head_segment).
	var segments := snake.size()
	for i in segments:
		tw.tween_callback(_vanish_head_segment)
		tw.tween_interval(DEATH_VANISH_INTERVAL)
	tw.tween_callback(_show_lose_message)
	tw.tween_interval(LOSE_HOLD)
	tw.tween_callback(_go_to_menu)


## Убирает голову, на её месте — эффект; шаг повторяется с головы до хвоста.
func _vanish_head_segment() -> void:
	if snake.is_empty():
		return
	var cell: Vector2i = snake.pop_front()
	var sprite: Sprite2D = snake_sprites.pop_front()
	_spawn_effect(cell)
	if sprite:
		sprite.queue_free()


func _field_filled() -> void:
	# Змейка заняла всё поле — показываем «you win!!» и уходим в меню.
	state = State.LEAVING
	tick_timer.stop()
	_play_sound("win")
	_show_win_message()
	var tw := create_tween()
	tw.tween_interval(WIN_HOLD)
	tw.tween_callback(_go_to_menu)


func _go_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


# --- Сообщения о выигрыше и проигрыше ---

## Надпись «you win!!» из примера: выпрыгивает по центру экрана.
func _show_win_message() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var rect := TextureRect.new()
	rect.texture = TEX_WIN_TEXT
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size := Vector2(568, 184) * MESSAGE_TEXT_SCALE
	rect.size = size
	rect.position = Vector2(960, 540) - size * 0.5 - Vector2(0, 90)
	rect.pivot_offset = size * 0.5
	rect.scale = Vector2(0.2, 0.2)
	rect.modulate.a = 0.0
	layer.add_child(rect)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(rect, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(rect, "modulate:a", 1.0, 0.2)


## Надпись «you lose!!» тем же шрифтом примера: тоже выпрыгивает по центру.
## Шрифт битмапный (16 px), поэтому масштабируем сам Label.
func _show_lose_message() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var label := Label.new()
	label.text = "you lose!!"
	var settings := LabelSettings.new()
	settings.font = UI_FONT
	settings.font_size = 16 # нативный размер битмап-шрифта
	settings.font_color = Color.WHITE
	settings.outline_size = 2
	settings.outline_color = Color(0.08, 0.08, 0.08)
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(get_viewport_rect().size.x, 320)
	label.position = Vector2(0, 540 - 240)
	label.pivot_offset = label.size * 0.5
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.scale = Vector2(0.2, 0.2) * 6.0 # 16 px -> ~96 px, со сглаживанием
	label.modulate.a = 0.0
	layer.add_child(label)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE * 6.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)


# --- Управление ---

func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		# physical_keycode — позиция клавиши, не зависит от раскладки
		# (WASD работает и на русской раскладке).
		match event.physical_keycode:
			KEY_W, KEY_UP:
				_try_set_dir(Vector2i.UP)
			KEY_S, KEY_DOWN:
				_try_set_dir(Vector2i.DOWN)
			KEY_A, KEY_LEFT:
				_try_set_dir(Vector2i.LEFT)
			KEY_D, KEY_RIGHT:
				_try_set_dir(Vector2i.RIGHT)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_swipe_active = true
			_swipe_start = event.position
		else:
			_swipe_active = false
	elif event is InputEventScreenDrag and _swipe_active:
		# «Живой» свайп: срабатывает во время жеста, можно цеплять повороты.
		var delta: Vector2 = event.position - _swipe_start
		if delta.length() < SWIPE_MIN_LENGTH:
			return
		if absf(delta.x) > absf(delta.y):
			_try_set_dir(Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT)
		else:
			_try_set_dir(Vector2i.DOWN if delta.y > 0 else Vector2i.UP)
		_swipe_start = event.position


## Направления копятся в очередь: быстрые двойные повороты не теряются.
## Первое действие игрока запускает движение змейку. Пока поле падает,
## ввод игнорируется — змейка поедет после приземления.
func _try_set_dir(d: Vector2i) -> void:
	if not _world_landed:
		return
	if tick_timer.is_stopped() and state == State.PLAYING:
		tick_timer.start(TICK_TIME)

	var last := dir
	if not _dir_queue.is_empty():
		last = _dir_queue[_dir_queue.size() - 1]
	if d == last or d == -last:
		return # повтор или разворот на 180°
	if _dir_queue.size() >= MAX_DIR_QUEUE:
		return
	_dir_queue.append(d)
	_play_sound("turn")
