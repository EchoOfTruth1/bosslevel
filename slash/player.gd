extends CharacterBody2D

#normal settings for player
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

#dash input code
var dash = false
var dashspeed := 2 * SPEED
var dashtime = 0.5
var dash_timer = 0.0
var can_dash = true
var dash_cooldown = 0.2

#slide code
var slide = false
var slidespeed := 3 * SPEED
var slidetime = 1.0
var slide_timer = 0.0
var slide_direction = 1.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_animation("jump")

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	
	# Handle dash input
	if Input.is_action_just_pressed("dash") and can_dash and not slide:
		_start_dash(direction)
	
	# Handle slide input
	if Input.is_action_just_pressed("slide") and not dash:
		_start_slide(direction)
	
	# Update based on current state
	if dash:
		_update_dash(delta)
	elif slide:
		_update_slide(delta)
	else:
		# Normal movement
		if direction:
			velocity.x = direction * SPEED
			_play_animation("run")
			# Flip sprite based on direction
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				_play_animation("idle")

	move_and_slide()

func _play_animation(anim_name: String) -> void:
	if current_animation != anim_name:
		current_animation = anim_name
		if animation_player:
			animation_player.play(anim_name)
		elif animated_sprite:
			animated_sprite.play(anim_name)

func _start_slide(direction: float) -> void:
	if slide:
		return
	
	slide = true
	slide_timer = slidetime
	slide_direction = direction if direction != 0 else slide_direction
	velocity.x = slide_direction * slidespeed
	
	_play_animation("slide")

func _update_slide(delta: float) -> void:
	slide_timer -= delta
	
	# Gradually slow down during slide
	velocity.x = move_toward(velocity.x, 0, slidespeed * delta)
	
	if slide_timer <= 0:
		_end_slide()

func _end_slide() -> void:
	slide = false
	velocity.x = 0
	
	if is_on_floor():
		_play_animation("idle")

func _start_dash(direction: float) -> void:
	if not can_dash or dash:
		return
	
	dash = true
	can_dash = false
	dash_timer = dashtime
	
	# Use current direction or last facing direction
	if direction != 0:
		velocity.x = direction * dashspeed
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
	else:
		velocity.x = sign(velocity.x) * dashspeed if velocity.x != 0 else dashspeed
	
	_play_animation("dash")

func _update_dash(delta: float) -> void:
	dash_timer -= delta
	
	# Maintain dash velocity
	if velocity.x > 0:
		velocity.x = dashspeed
	else:
		velocity.x = -dashspeed
	
	if dash_timer <= 0:
		_end_dash()

func _end_dash() -> void:
	dash = false
	velocity.x = 0
	
	if is_on_floor():
		_play_animation("idle")
	
	# Start cooldown
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
#edit
