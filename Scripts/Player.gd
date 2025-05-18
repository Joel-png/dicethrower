extends CharacterBody3D

const SENSITIVITY: float = 0.004

const FALL_SPEED_MAX: float = 30.0
const JUMP_VELOCITY: float = 15.0

const TARGET_LERP: float = 0.7
var WALK_SPEED: float = 10.0
var acc_speed: float = 10.0
var too_fast_slow_down: float = 0.90

var gravity: float = 9.8 * 4

var is_grappling: bool = false
var grapple_hook_position: Vector3 = Vector3.ZERO
const GRAPPLE_RAY_MAX: float = 500.0
const GRAPPLE_FORCE_MAX: float = 55.0
const GRAPPLE_MIN_DIST: float = 5.0

var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO

var current_max_speed: float = WALK_SPEED
var rng = RandomNumberGenerator.new()

var is_focus = false


@onready var head = $PlayerHead
@onready var camera = $PlayerHead/Camera3D
@onready var camera_cast = $PlayerHead/Camera3D/camera_cast
@onready var crosshair = $PlayerHead/Camera3D/Crosshair
@onready var animation_player = $AnimationPlayer

@onready var player_manager = $".."

#inventory


@onready var debug0 = $PlayerHead/Camera3D/DebugLabel0
@onready var debug1 = $PlayerHead/Camera3D/DebugLabel1

func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_cast.set_target_position(Vector3(0, 0, -1 * GRAPPLE_RAY_MAX))
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 1000

func _unhandled_input(event) -> void:
	if is_focus:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		if is_focus:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_focus = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			is_focus = true
		
	# movement
	input_dir = Input.get_vector("left", "right", "up", "down")
	direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
#	transform.basis * 
	var target_speed: Vector3 = direction * current_max_speed
	var jumped: bool = false
	
	if Input.is_action_pressed("jump") and is_on_floor():
		jumped = true
		if input_dir:
			velocity *= too_fast_slow_down
		else:
			velocity *= 0.9
		velocity.y = JUMP_VELOCITY
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
		
	if not input_dir and not jumped and is_on_floor():
		target_speed.x = 0.0
		target_speed.z = 0.0
		velocity.x *= 0.5
		velocity.z *= 0.5
	
	#calculate dif between max and current speed
	#ignore y axis
	
	var local_velocity: Vector3 = transform.basis.inverse() * velocity
	
	#only if bhopping or midair
	if not (not jumped and is_on_floor()):
		#keep velocity if velocity is higher than movement could make
		if local_velocity.x < 0 and target_speed.x < 0 and local_velocity.x < -current_max_speed or local_velocity.x >= 0 and target_speed.x >= 0 and local_velocity.x > current_max_speed:
				target_speed.x = local_velocity.x
		if local_velocity.z < 0 and target_speed.z < 0 and local_velocity.z < -current_max_speed or local_velocity.z >= 0 and target_speed.z >= 0 and local_velocity.z > current_max_speed:
				target_speed.z = local_velocity.z
		
		#keep velocity when using a key that doesnt interupt velocity
		if input_dir.x == 0:
			target_speed.x = local_velocity.x
		if input_dir.y == 0:
			target_speed.z = local_velocity.z
	var speed_difference: Vector3 = target_speed - local_velocity
	speed_difference.y = 0
 
	#final force that will be applied to character
	var movement: Vector3 = speed_difference * acc_speed
	
	if input_dir or (not jumped and is_on_floor()):
		velocity = velocity + (transform.basis * movement) * delta
	move_and_slide()
	#holdable.action(delta)
	debug0.text = str(rad_to_deg(camera.rotation.x)) + "\n " + str(velocity) + "\n " + str(global_position)
	debug1.text = str(Engine.get_frames_per_second()) + " " + str(1.0/(get_process_delta_time()))
	
func get_what_look_at() -> Vector3:
	# if point to shoot at is too close bullets will go to the side | if point isn't in raycast
	if camera_cast.get_collider():
		if position.distance_to(camera_cast.get_collision_point()) > 2:
			return camera_cast.get_collision_point()
	var forward_direction: Vector3 = -camera_cast.global_transform.basis.z.normalized()
	return camera_cast.global_transform.origin + forward_direction * 100
