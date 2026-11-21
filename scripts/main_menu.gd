extends Control
## Главное меню Snake Yes:
## - фон Light/Dark (по умолчанию Light), переключается кнопкой справа сверху
##   с плавным кроссфейдом и кулдауном от спама;
## - флажок сверху по центру: случайный при каждом входе в меню, при запуске
##   падает сверху с bounce-эффектом, после приземления плавно тянется
##   за курсором в небольших границах;
## - кнопка настроек слева сверху (функционал будет добавлен позже);
## - центральные кнопки «Играть / Магазин / Скины» (пока без функций):
##   спрайты меняются вместе с темой, при наведении слегка наклоняются.

const LIGHT_BG: Texture2D = preload("res://assets/BG/MainMenulightBG.png")
const DARK_BG: Texture2D = preload("res://assets/BG/MainMenudarkBG.png")

const FLAGS: Array[Texture2D] = [
	preload("res://assets/Flag/SnakeYes-1.png"),
	preload("res://assets/Flag/SnakeYes-2.png"),
	preload("res://assets/Flag/SnakeYes-3.png"),
	preload("res://assets/Flag/SnakeYes-4.png"),
	preload("res://assets/Flag/SnakeYes-5.png"),
	preload("res://assets/Flag/SnakeYes-6.png"),
	preload("res://assets/Flag/SnakeYes-7.png"),
	preload("res://assets/Flag/SnakeYes-8.png"),
]

## Спрайты центральных кнопок: [играть, магазин, скины] для каждой темы.
const MENU_BUTTONS_LIGHT: Array[Texture2D] = [
	preload("res://assets/Buttons/Default_Button.png"),
	preload("res://assets/Buttons/Shop_Button.png"),
	preload("res://assets/Buttons/Skins_Button.png"),
]
const MENU_BUTTONS_DARK: Array[Texture2D] = [
	preload("res://assets/Buttons/DefaultDark_Button.png"),
	preload("res://assets/Buttons/ShopDark_Button.png"),
	preload("res://assets/Buttons/SkinsDark_Button.png"),
]

# --- Фон: кроссфейд и защита от спама ---
const BG_FADE_TIME := 0.4
const THEME_COOLDOWN_EXTRA := 0.2 # доп. время блокировки после кроссфейда

# --- Флажок: падение и слежение за курсором ---
const FLAG_FALL_START := Vector2(0, -260) # старт выше экрана
const FLAG_FALL_DELAY := 0.1
const FLAG_FALL_DURATION := 1.15
const FLAG_FOLLOW_STRENGTH := 0.12 # насколько далеко флажок тянется к курсору
const FLAG_FOLLOW_SPEED := 5.0 # скорость догоняния (меньше — более «отстающий»)
const FLAG_FOLLOW_BOUNDS := Vector2(60.0, 28.0) # границы смещения от своего места

# --- Наклон центральных кнопок при наведении ---
const BUTTON_TILT_ANGLE := 0.05 # радиан (~3°)
const BUTTON_TILT_TIME := 0.18

@onready var dark_background: TextureRect = %BackgroundDark
@onready var flag_anchor: Control = %FlagAnchor
@onready var flag: TextureRect = %Flag
@onready var settings_button: TextureButton = %SettingsButton
@onready var theme_toggle_button: TextureButton = %ThemeToggleButton
@onready var play_button: TextureButton = %PlayButton
@onready var shop_button: TextureButton = %ShopButton
@onready var skins_button: TextureButton = %SkinsButton

var _center_buttons: Array[TextureButton] = []
var _flag_landed := false
var _theme_switch_busy := false
var _tilt_tweens: Dictionary = {}


func _ready() -> void:
	ThemeManager.mode_changed.connect(_on_mode_changed)
	theme_toggle_button.pressed.connect(_on_theme_toggle_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	play_button.pressed.connect(_on_play_pressed)

	_center_buttons = [play_button, shop_button, skins_button]
	for i in _center_buttons.size():
		# Кнопки наклоняются в разные стороны, чтобы выглядело игривее.
		var tilt_sign := -1.0 if i % 2 == 0 else 1.0
		_setup_button_tilt(_center_buttons[i], tilt_sign)

	_apply_mode(ThemeManager.is_dark)
	_pick_random_flag()
	_start_flag_drop()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _process(delta: float) -> void:
	if not _flag_landed:
		return

	# Плавное «отстающее» смещение флажка за курсором в маленьких границах.
	# Вверх флажок не поднимается — только в стороны и слегка вниз.
	var home_center := flag_anchor.get_global_rect().get_center()
	var target := (get_global_mouse_position() - home_center) * FLAG_FOLLOW_STRENGTH
	target.x = clampf(target.x, -FLAG_FOLLOW_BOUNDS.x, FLAG_FOLLOW_BOUNDS.x)
	target.y = clampf(target.y, 0.0, FLAG_FOLLOW_BOUNDS.y)
	var weight := 1.0 - exp(-FLAG_FOLLOW_SPEED * delta)
	flag.position = flag.position.lerp(target, weight)


## Выбирает случайный флажок, отличный от текущего.
## Текущий индекс хранится в ThemeManager, поэтому флажок меняется
## при каждом переходе в главное меню, но не при смене фона.
func _pick_random_flag() -> void:
	if FLAGS.is_empty():
		return

	var new_index := randi() % FLAGS.size()
	if FLAGS.size() > 1:
		while new_index == ThemeManager.flag_index:
			new_index = randi() % FLAGS.size()

	ThemeManager.flag_index = new_index
	flag.texture = FLAGS[new_index]


## Падение флажка сверху вниз на своё место с bounce-эффектом
## (ударяется, немного подлетает и опускается на место).
func _start_flag_drop() -> void:
	_flag_landed = false
	flag.position = FLAG_FALL_START

	var tw := create_tween()
	tw.tween_interval(FLAG_FALL_DELAY)
	tw.tween_property(flag, "position", Vector2.ZERO, FLAG_FALL_DURATION) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _flag_landed = true)


func _apply_mode(is_dark: bool, animated: bool = false) -> void:
	var target_alpha := 1.0 if is_dark else 0.0

	if animated:
		# Кроссфейд фонов + кулдаун, чтобы не заспамить переключение.
		var tw := create_tween()
		tw.tween_property(dark_background, "modulate:a", target_alpha, BG_FADE_TIME)
		tw.tween_interval(THEME_COOLDOWN_EXTRA)
		tw.tween_callback(_unlock_theme_switch)
	else:
		dark_background.modulate.a = target_alpha
		_unlock_theme_switch()

	# Спрайты центральных кнопок зависят от темы.
	for i in _center_buttons.size():
		_center_buttons[i].texture_normal = MENU_BUTTONS_DARK[i] if is_dark else MENU_BUTTONS_LIGHT[i]


func _unlock_theme_switch() -> void:
	_theme_switch_busy = false
	theme_toggle_button.disabled = false


func _on_theme_toggle_pressed() -> void:
	if _theme_switch_busy:
		return

	_theme_switch_busy = true
	theme_toggle_button.disabled = true
	ThemeManager.toggle_mode()


## Подключает лёгкий наклон кнопки при наведении и возврат при уходе курсора.
func _setup_button_tilt(button: TextureButton, tilt_sign: float) -> void:
	button.mouse_entered.connect(_tilt_to.bind(button, BUTTON_TILT_ANGLE * tilt_sign))
	button.mouse_exited.connect(_tilt_to.bind(button, 0.0))


func _tilt_to(button: TextureButton, target_angle: float) -> void:
	var old: Tween = _tilt_tweens.get(button)
	if old and old.is_valid():
		old.kill()

	var tw := create_tween()
	tw.tween_property(button, "rotation", target_angle, BUTTON_TILT_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tilt_tweens[button] = tw


func _on_mode_changed(is_dark: bool) -> void:
	_apply_mode(is_dark, true)


func _on_settings_button_pressed() -> void:
	# TODO: открыть меню настроек (функционал добавим позже).
	print_debug("Нажата кнопка настроек — меню настроек ещё не реализовано")
