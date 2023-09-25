extends CharacterBody3D



# Player nodes
@onready var neck = $neck
@onready var head = $neck/head
@onready var standing_collision_shape_3d = $standing_collision_shape3D
@onready var crouching_collision_shape_3d = $crouching_collision_shape3D
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/Camera3D


# Speed vars
var current_speed = 5.0 # The players speed. Not a const, because we have sprinting and this will change the speed.
const walking_speed = 5.0 # Use @export var to tweak it during runtime inside the Godot inspector
const sprinting_speed = 8.0
const crouching_speed = 3.0

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false


# Slide vars
var slide_timer = 0.0 #end of slide_timer
var slide_timer_max = 1.0 #seconds
var slide_vector = Vector2.ZERO
var slide_speed = 10.0


# Head bobbings vars
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0

# Movement Vars
var crouching_depth = -0.5
const jump_velocity = 4.5
var lerp_speed = 10.0 # Makes the movement feel alot more gradual.
var free_look_tilt_amount = 8

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
		if free_looking == true:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta):
	"""
	Handle movement states and it's changes.
	"""	
	
	# Getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")

	# Crouching
	if Input.is_action_pressed("crouch") or sliding:
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed) # Put the players head in a crouch position

		standing_collision_shape_3d.disabled = true
		crouching_collision_shape_3d.disabled = false
	
		# Handle sliding start
		if sprinting == true and input_dir != Vector2.ZERO and is_on_floor():
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true # Doesnt do anything, just signifies that free_looking is enabled when sliding.

		
		
		walking = false
		sprinting = false
		crouching = true


	elif !ray_cast_3d.is_colliding(): # Check if player can stand (doesnt't collide with mesh)
		# Standing 
		standing_collision_shape_3d.disabled = false
		crouching_collision_shape_3d.disabled = true
		
		# Change the speed according to weather we are sprinting or not
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed) # Put the players head in a standing position
	
		# Handle sprinting
		if Input.is_action_pressed("sprint"): # When adding momentum control, add this and is_on_floor()
			# Sprinting
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			# current_speed = sprinting_speed

			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = walking_speed

			walking = true
			sprinting = false
			crouching = false


	# Handle free looking
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true
		if sliding:
			# camera_3d.rotation.z = lerp(camera_3d.rotation.z ,-deg_to_rad(7.0), delta * lerp_speed * 2) # Adds a tilt to the camera
			camera_3d.rotation.z = +deg_to_rad(neck.rotation.y * free_look_tilt_amount) # Makes the camera move realistically when sliding (similar to free look)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
		#camera_3d.rotation.z =  lerp(camera_3d.rotation.z, +deg_to_rad(neck.rotation.y + free_look_tilt_amount), delta * lerp_speed)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)


	# Handle sliding and its end
	if sliding == true:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
			# set the characters direction equal to the cameras direction coming out of a slide



	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	# Overrides the players direction, if he is sliding. Looks the slide direction for slides duration
	if sliding == true:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
