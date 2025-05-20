extends RigidBody3D
class_name Dice

@export var minRandomForce = 25
@export var maxRandomForce = 50

var isMoving = false

func _physics_process(delta: float) -> void:
	isMoving = linear_velocity.length() > 0.1
	if !isMoving:
		apply_torque(Vector3(0.01, 0.01, 0.01))

##func _unhandled_input(event):
	##if event is InputEventMouseButton and event.pressed:
		##roll_dice()

func roll_dice():
	if isMoving: 
		return
	
	var rng = RandomNumberGenerator.new()
	var randomDirection = [-1, 1]
	var force = Vector3.ZERO
	var force_displace = Vector3.ZERO
	
	force_displace.x += -position.z
	force_displace.z += position.x
	
	force.x = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.x)
	force.y = rng.randi_range(minRandomForce, maxRandomForce) * randomDirection.pick_random()
	force.z = rng.randi_range(minRandomForce, maxRandomForce) * sign(force_displace.z)
	
	
	apply_torque(force)
	apply_force(Vector3(force.x / 2.0, 120.0, force.z / 2.0))
