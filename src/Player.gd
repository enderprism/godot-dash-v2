extends CharacterBody2D

var UP_DIRECTION := Vector2(0, -1)

const GRAVITY: = 5000.0
const SPEED: = Vector2(625.0, -1100.0)
const MAX_SPEED: = Vector2(0.0, -1500.0)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = SPEED.y

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED.x
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED.x)

	move_and_slide()
