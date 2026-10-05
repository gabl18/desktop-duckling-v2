extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

var speed = 250.0
var direction = Vector2(1,0)
var screen_size = Vector2()
var screen_origin = Vector2()
var window_size = Vector2(200, 200)

var idle_timer = 0.0
var action_timer = 0.0

var is_idling = false
var is_dragging = false
var is_falling = false
var is_jumping = false

var drag_offset = Vector2()

var vertical_velocity = 0.0
var gravity = 750.0
var max_fall_speed = 300.0
var jump_force = -220.0

func _ready():
	var current_screen = get_window().current_screen
	
	var useable_rect = DisplayServer.screen_get_usable_rect(current_screen)
	screen_size = Vector2(useable_rect.size)
	screen_origin = Vector2(useable_rect.position)
	
	var floor_y = screen_origin.y + screen_size.y - window_size.y
	
	var start_pos = Vector2(screen_origin.x + 100, floor_y)
	DisplayServer.window_set_position(Vector2i(start_pos))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	
	animated_sprite.flip_h = !animated_sprite.flip_h
	animated_sprite.play("Walk")
	area.input_event.connect(_on_area_input)
	
	reset_action_timer()

func reset_action_timer():
	action_timer = randf_range(2.0, 6.0)
	
func _physics_process(delta: float) -> void:
	var window_position = Vector2(DisplayServer.window_get_position())
	
	var min_x = screen_origin.x
	var max_x = screen_origin.x + screen_size.x - window_size.x
	var min_y = screen_origin.y
	var max_y = screen_origin.y + screen_size.y -window_size.y
	
	if is_dragging:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		new_win_pos.x = clamp(new_win_pos.x, min_x, max_x)
		new_win_pos.y = clamp(new_win_pos.y, min_y, max_y)
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return
	
	if is_falling or is_jumping:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		vertical_velocity += gravity * delta
		if vertical_velocity > max_fall_speed:
			vertical_velocity = max_fall_speed
		
		window_position.y += vertical_velocity * delta
		
		if vertical_velocity < 0:
			if animated_sprite.sprite_frames.has_animation("Jump"):
				animated_sprite.play("Jump")
		else:
			if animated_sprite.sprite_frames.has_animation("Flutter"):
				animated_sprite.play("Flutter")
		
		if window_position.y >= max_y:
			window_position.y = max_y
			is_falling = false
			is_jumping = false
			vertical_velocity = 0.0
			
			speed = 250.0
			animated_sprite.play("Walk")
			reset_action_timer()
		
		window_position.x += direction.x * (speed * 0.5) * delta
		window_position.x = clamp(window_position.x, min_x, max_x)
		
		DisplayServer.window_set_position(Vector2i(window_position))
		return
		
	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			speed = 250.0
			animated_sprite.play("Walk")
			reset_action_timer()
		return
		
	window_position.x += direction.x * speed * delta
	window_position.x = clamp(window_position.x, min_x, max_x)
	window_position.y = clamp(window_position.y, min_y, max_y)
	
	DisplayServer.window_set_position(Vector2i(window_position))
	
	if window_position.x <= min_x:
		window_position.x = min_x
		direction.x = 1
		animated_sprite.flip_h = false
	elif window_position.x >= max_x:
		window_position.x = max_x
		direction.x = -1
		animated_sprite.flip_h = true
	
	window_position.y = max_y
	DisplayServer.window_set_position(Vector2i(window_position))
	
	action_timer -= delta
	if action_timer <= 0:
		maybe_idle_or_jump()

func maybe_idle_or_jump():
	reset_action_timer()
	var roll = randf()
	
	if roll < 0.35:
		is_idling = true
		idle_timer = randf_range(1.5, 5.0)
		var r = randi() % 3
		if r == 0:
			animated_sprite.play("Idle")
			speed = 0
	elif roll < 0.70:
		is_jumping = true
		vertical_velocity = jump_force
		if randf() < 0.5:
			direction.x *= -1
			animated_sprite.flip_h = (direction.x < 0)
			
		if animated_sprite.sprite_frames.has_animation("Jump Front"):
			animated_sprite.play("Jump Front")
			
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			is_falling = false
			is_jumping = false
			is_idling = false
			vertical_velocity = 0.0
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
			
			animated_sprite.play("Jump Front")
		else:
			if is_dragging:
				is_dragging = false
				
				var current_y = DisplayServer.window_get_position().y
				var max_y = screen_origin.y + screen_size.y - window_size.y
				
				if current_y < max_y -10:
					is_falling = true
					vertical_velocity = 0.0

				else:
					animated_sprite.play("Walk")
					reset_action_timer()
			
