extends CharacterBody3D

# Player nodes
@onready var head = $head
@onready var standing_collision_shape_3d = $standing_collision_shape3D
@onready var crouching_collision_shape_3d = $crouching_collision_shape3D
@onready var ray_cast_3d = $RayCast3D

# Speed vars
var current_speed = 5.0 # The players speed. Not a const, because we have sprinting and this will change the speed.
const walking_speed = 5.0 # Use @export var to tweak it during runtime inside the Godot inspector
const sprinting_speed = 8.0
const crouching_speed = 3.0

# Movement Vars
var crouching_depth = -0.5

const jump_velocity = 4.5

var lerp_speed = 10.0 # Makes the movement feel alot more gradual.

# Input vars
var direction = Vector3.ZERO
const mouse_sens = 0.25 

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	"""
	Ran once at the beginning
	"""	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Captures the mouse inside the window, so it doesn't escape


func _input(event):

	# Mouse movement logics
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta):

	# handle movement state

	# Crouching
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, 1.8+crouching_depth, delta * lerp_speed) # Put the players head in a crouch position

		standing_collision_shape_3d.disabled = true
		crouching_collision_shape_3d.disabled = false
	
	elif !ray_cast_3d.is_colliding(): # Check if player can stand (doesnt't collide with mesh)
		# Standing 
		standing_collision_shape_3d.disabled = false
		crouching_collision_shape_3d.disabled = true
		
		# Change the speed according to weather we are sprinting or not
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed) # Put the players head in a standing position
	
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = sprinting_speed
		else:
			# Walking
			current_speed = walking_speed

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
