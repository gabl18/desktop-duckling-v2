extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

var speed = 300
var direction = Vector2(1,0)
var screen_size = Vector2()
var screen_origin = Vector2()
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var is_idling = false
var is_dragging = false
var drag_offset = Vector2()

func _ready():
	var current_screen = get_window().current_screen
	
	screen_size = Vector2(DisplayServer.screen_get_size(current_screen))
	screen_origin = Vector2(DisplayServer.screen_get_position(current_screen))
	
	var start_pos = screen_origin + Vector2(100, 100)
	DisplayServer.window_set_position(Vector2i(start_pos))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	
	animated_sprite.flip_h = !animated_sprite.flip_h
	animated_sprite.play("Walk")
	area.input_event.connect(_on_area_input)
	
func _physics_process(delta: float) -> void:
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return
		
	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			speed = 300
			animated_sprite.play("Walk")
		return
		
	var window_position = Vector2(DisplayServer.window_get_position())
	window_position += direction * speed * delta
	
	var min_x = screen_origin.x
	var max_x = screen_origin.x + screen_size.x - window_size.x
	var min_y = screen_origin.y
	var max_y = screen_origin.y + screen_size.y - window_size.y
	
	window_position.x = clamp(window_position.x, min_x, max_x)
	window_position.y = clamp(window_position.y, min_y, max_y)
	
	DisplayServer.window_set_position(Vector2i(window_position))
	
	if window_position.x <= min_x or window_position.x >= max_x:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		maybe_idle()
	if window_position.y <= min_y or window_position.y >= max_y:
		direction.y *= -1
		maybe_idle()

func maybe_idle():
	if randf() < 0.3:
		is_idling = true
		idle_timer = randf_range(1.0, 3.0)
		var r = randi() % 3
		if r == 0:
			animated_sprite.play("Idle")
			speed = 0
			
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false
			
