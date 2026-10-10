extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player2: AudioStreamPlayer = $AudioStreamPlayer2

enum State {WALK, IDLE, JUMPING, FALLING, DRAGGING, HONK, URGENT_HONK, PET}
var current_state: State = State.WALK

var speed = 250.0
var direction = Vector2(1,0)
var screen_size = Vector2()
var screen_origin = Vector2()
var window_size = Vector2(200, 200)

var action_timer = 0.0
var state_timer = 0.0

var drag_offset = Vector2()
var click_start_pos = Vector2()

var mouse_wiggle_timer = 0.0
var required_wiggle_time = 0.4
var last_mouse_pos = Vector2()
var wiggle_radius = 600.0

var click_count = 0
var click_timer = 0.0

var vertical_velocity = 0.0
var gravity = 750.0
var max_fall_speed = 300.0
var jump_force = -320.0

func _ready():
	var current_screen = get_window().current_screen
	
	var useable_rect = DisplayServer.screen_get_usable_rect(current_screen)
	screen_size = Vector2(useable_rect.size)
	screen_origin = Vector2(useable_rect.position)
	
	var floor_y = screen_origin.y + screen_size.y - window_size.y
	
	var start_pos = Vector2(screen_origin.x + 100, floor_y)
	DisplayServer.window_set_position(Vector2i(start_pos))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	
	update_facing_direction()
	set_state(State.WALK)
	area.input_event.connect(_on_area_input)
	
	reset_action_timer()

func reset_action_timer():
	action_timer = randf_range(2.0, 6.0)

func set_state(new_state: State):
	current_state = new_state
	
	match current_state:
		State.WALK:
			speed = 250.0
			animated_sprite.play("Walk")
		State.IDLE:
			speed = 0.0
			state_timer = randf_range(2.0,8.0)
			animated_sprite.play("Idle")
		State.PET:
			speed = 0.0
			state_timer = randf_range(1.5,3.0)
			animated_sprite.play("Pet")
		State.HONK:
			speed = 0.0
			state_timer = 1.2
			animated_sprite.play("Honk")
		State.URGENT_HONK:
			speed = 0.0
			state_timer = 1.5
			animated_sprite.play("Urgent Honk")
		State.JUMPING:
			vertical_velocity = jump_force
			animated_sprite.play("Jump")
		State.FALLING:
			animated_sprite.play("Flutter")
		State.DRAGGING:
			vertical_velocity = 0.0
			animated_sprite.play("Swim Idle")

func _process(delta: float) -> void:
	if click_count > 0:
		click_timer -= delta
		if click_timer <= 0:
			click_count = 0
	
	if current_state == State.WALK or current_state == State.IDLE:
		var win_pos = DisplayServer.window_get_position()
		var mouse_pos = DisplayServer.mouse_get_position()
		
		var center = Vector2(win_pos.x + window_size.x / 2.0, win_pos.y + window_size.y / 2.0)
		if mouse_pos.distance_to(center) <= wiggle_radius:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			if mouse_pos.distance_to(last_mouse_pos) > 1:
				mouse_wiggle_timer += delta
				if mouse_wiggle_timer >= required_wiggle_time:
					mouse_wiggle_timer = 0.0
					set_state(State.PET)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			mouse_wiggle_timer = max(0.0, mouse_wiggle_timer - delta * 2)
		
		last_mouse_pos = mouse_pos
	
					
func _physics_process(delta: float) -> void:
	var window_position = Vector2(DisplayServer.window_get_position())
	
	var min_x = screen_origin.x
	var max_x = screen_origin.x + screen_size.x - window_size.x
	var min_y = screen_origin.y
	var max_y = screen_origin.y + screen_size.y -window_size.y
	
	match current_state:
		State.DRAGGING:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var new_win_pos = mouse_pos - drag_offset
			new_win_pos.x = clamp(new_win_pos.x, min_x, max_x)
			new_win_pos.y = clamp(new_win_pos.y, min_y, max_y)
			DisplayServer.window_set_position(Vector2i(new_win_pos))
			return
		
		State.JUMPING, State.FALLING:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			vertical_velocity += gravity * delta
			if vertical_velocity > max_fall_speed:
				vertical_velocity = max_fall_speed
			
			window_position.y += vertical_velocity * delta
			
			if vertical_velocity >= 0 and current_state == State.JUMPING:
				set_state(State.FALLING)
			
			if window_position.y >= max_y:
				window_position.y = max_y
				vertical_velocity = 0.0
				set_state(State.WALK)
				reset_action_timer()
			
			window_position.x += direction.x * (speed * 0.5) * delta
			window_position.x = clamp(window_position.x, min_x, max_x)
			DisplayServer.window_set_position(Vector2i(window_position))
			return
		
		State.IDLE, State.HONK, State.URGENT_HONK, State.PET:
			state_timer -= delta
			
			if current_state == State.IDLE and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var mouse_pos = Vector2(DisplayServer.mouse_get_position())
				if mouse_pos.distance_to(click_start_pos) > 10.0:
					var win_pos = Vector2(DisplayServer.window_get_position())
					drag_offset = mouse_pos - win_pos
					set_state(State.DRAGGING)
					return
					
			if state_timer <= 0:
				set_state(State.WALK)
				reset_action_timer()
			return
		
		State.WALK:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			window_position.x += direction.x * speed * delta
			
			if window_position.x <= min_x:
				window_position.x = min_x
				direction.x = 1
				update_facing_direction()
			elif window_position.x >= max_x:
				window_position.x = max_x
				direction.x = -1
				update_facing_direction()
			
			window_position.y = max_y
			DisplayServer.window_set_position(Vector2i(window_position))
			
			action_timer -= delta
			if action_timer <= 0:
				maybe_choose_action()

func maybe_choose_action():
	reset_action_timer()
	var roll = randf()
	
	if roll < 0.08:
		audio_stream_player.play()
		set_state(State.HONK)
	elif roll < 0.40:
		set_state(State.IDLE)
	elif roll < 0.75:
		if randf() < 0.5:
			direction.x *= -1
			update_facing_direction()
		set_state(State.JUMPING)

func update_facing_direction():
	animated_sprite.flip_h = (direction.x > 0)
	
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var current_y = DisplayServer.window_get_position().y
		var max_y = screen_origin.y + screen_size.y - window_size.y
		var is_on_ground = (current_y >= max_y - 10)
		
		if event.pressed:
			click_start_pos = Vector2(DisplayServer.mouse_get_position())
			
			if is_on_ground:
				click_count += 1
				click_timer = 0.8
				
				if click_count >= 4:
					audio_stream_player2.play()
					set_state(State.URGENT_HONK)
					click_count = 0
					return
			
				if current_state == State.WALK:
					set_state(State.IDLE)
				elif current_state == State.IDLE:
					var win_pos = Vector2(DisplayServer.window_get_position())
					drag_offset = click_start_pos - win_pos
					set_state(State.DRAGGING)
			
			else:
				var win_pos = Vector2(DisplayServer.window_get_position())
				drag_offset = click_start_pos - win_pos
				set_state(State.DRAGGING)
				
		else:
			if current_state == State.DRAGGING:
				if current_y < max_y -10:
					set_state(State.FALLING)
				else:
					set_state(State.WALK)
					reset_action_timer()
			
